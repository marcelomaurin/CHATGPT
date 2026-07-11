unit main;

{-------------------------------------------------------------------------------
  Posprinter Demo — com aba "Tamanho do papel"

  A geometria (largura, altura, gap, margens, dpi) NAO e' assunto da UI:
  ela pertence ao PROTOCOLO. Esta aba so' coleta os valores e os entrega ao
  componente, que os repassa a linguagem ativa, que por sua vez emite:

      TSPL    : SIZE / GAP / REFERENCE
      EPL     : q / Q / R
      ZPL     : ^PW / ^LL / ^LH
      ESC/POS : GS L (margem esq.) / GS W (largura da area de impressao)

  PADRAO DO PROJETO: area util de 51 mm x 25 mm, 203 dpi, gap 2 mm.

  ATENCAO - conversao mm->dots:
    NAO e' "mm * 8". A 203 dpi sao 7,992 dots/mm; a 300 dpi sao 11,81.
    Sempre  Round(mm * Dpi / 25.4).  Ver MMToDots em aiprinter_types.

  DEPENDENCIAS (ver SPEC-GEOMETRIA.md, T24..T30):
    - aiprinter_types: TAIPrinterGeometry, MMToDots, DefaultGeometry
    - aiposprinter   : propriedade Geometry + UsableWidthMM/UsableHeightMM
-------------------------------------------------------------------------------}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Spin,
  aiposprinter, aiprinter_types, aiprinter_transport_spooler;

type
  TJobProc = procedure of object;

  { TfrmMain }

  TfrmMain = class(TForm)
    pgConfig: TPageControl;
    tabPrinter: TTabSheet;
    tabPaper: TTabSheet;

    { --- aba Impressora --- }
    lblModel: TLabel;
    cmbModel: TComboBox;
    lblProtocol: TLabel;
    cmbProtocol: TComboBox;
    lblInterface: TLabel;
    cmbInterface: TComboBox;
    lblDevice: TLabel;
    edtDevice: TEdit;
    lblPort: TLabel;
    edtPort: TEdit;
    lblPrinterSO: TLabel;
    cmbPrinterSO: TComboBox;
    btnRefreshPrinters: TButton;
    chkRemoveAccents: TCheckBox;
    chkHexLog: TCheckBox;
    lblGeometryInfo: TLabel;

    btnRun: TButton;
    btnTestConn: TButton;
    btnBoldText: TButton;
    btnBarcode: TButton;
    btnQRCode: TButton;
    btnCut: TButton;
    btnPrintLabel: TButton;
    btnDrawer: TButton;
    btnBeep: TButton;
    btnClearLog: TButton;
    btnSaveBin: TButton;

    { --- aba Tamanho do papel --- }
    gbPhysical: TGroupBox;
    lblPaperW: TLabel;
    spPaperW: TFloatSpinEdit;
    lblPaperH: TLabel;
    spPaperH: TFloatSpinEdit;
    lblGap: TLabel;
    spGap: TFloatSpinEdit;
    lblDpi: TLabel;
    cmbDpi: TComboBox;

    gbMargins: TGroupBox;
    lblMLeft: TLabel;
    spMarginLeft: TFloatSpinEdit;
    lblMTop: TLabel;
    spMarginTop: TFloatSpinEdit;
    lblMRight: TLabel;
    spMarginRight: TFloatSpinEdit;
    lblMBottom: TLabel;
    spMarginBottom: TFloatSpinEdit;

    gbUsable: TGroupBox;
    lblUsableMM: TLabel;
    lblUsableDots: TLabel;
    lblGeomWarn: TLabel;
    btnResetGeometry: TButton;

    memoLog: TMemo;
    dlgSave: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cmbModelChange(Sender: TObject);
    procedure cmbProtocolChange(Sender: TObject);
    procedure cmbInterfaceChange(Sender: TObject);
    procedure GeometryChange(Sender: TObject);
    procedure btnResetGeometryClick(Sender: TObject);
    procedure btnRefreshPrintersClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnTestConnClick(Sender: TObject);
    procedure btnBoldTextClick(Sender: TObject);
    procedure btnBarcodeClick(Sender: TObject);
    procedure btnQRCodeClick(Sender: TObject);
    procedure btnCutClick(Sender: TObject);
    procedure btnPrintLabelClick(Sender: TObject);
    procedure btnDrawerClick(Sender: TObject);
    procedure btnBeepClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnSaveBinClick(Sender: TObject);
  private
    FPrinter: TAIPOSPrinter;
    FLastHex: string;
    FLoading: Boolean;      { evita reentrancia no GeometryChange }

    procedure LoadSystemPrinters;
    function  IsLabelLanguage: Boolean;

    function  BuildGeometry: TAIPrinterGeometry;
    procedure GeometryToUI(const G: TAIPrinterGeometry);
    function  UpdateGeometryPreview: Boolean;   { False = geometria invalida }

    procedure ApplySettings;
    procedure RunJob(const AName: string; AJob: TJobProc);

    procedure JobNothing;
    procedure JobReceipt;
    procedure JobBold;
    procedure JobBarcode;
    procedure JobQRCode;
    procedure JobCut;
    procedure JobLabel;
    procedure JobDrawer;
    procedure JobBeep;

    procedure AddLog(const AMsg: string);
    procedure SetStatus(const AMsg: string);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

const
  PROTO_ESCPOS = 0;
  PROTO_NATIVE = 1;
  PROTO_EPL    = 2;
  PROTO_ZPL    = 3;
  PROTO_TSPL   = 4;

  IFACE_SERIAL  = 0;
  IFACE_TCP     = 1;
  IFACE_DEVICE  = 2;
  IFACE_SPOOLER = 3;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FPrinter := TAIPOSPrinter.Create(Self);

  {$IFDEF UNIX}
  edtDevice.Text := '/dev/usb/lp0';
  {$ENDIF}

  { PADRAO DO PROJETO: 51 x 25 mm. Vem de DefaultGeometry, nao de numero
    solto na UI - assim o default e' o mesmo no componente e na tela. }
  FLoading := True;
  try
    GeometryToUI(DefaultGeometry);
  finally
    FLoading := False;
  end;
  UpdateGeometryPreview;

  LoadSystemPrinters;

  AddLog('Posprinter Demo inicializado.');
  AddLog('Area util padrao: 51 x 25 mm @ 203 dpi (408 x 200 dots).');
  AddLog('DICA: imprima a etiqueta de autoteste da L42 DT (segure FEED ao');
  AddLog('      ligar) para descobrir a linguagem ativa antes de tudo.');
  AddLog('');

  cmbModelChange(nil);
  SetStatus('Pronto');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  { LCL libera pelo Owner }
end;

{============================ GEOMETRIA ======================================}

function TfrmMain.BuildGeometry: TAIPrinterGeometry;
begin
  Result.WidthMM        := spPaperW.Value;
  Result.HeightMM       := spPaperH.Value;
  Result.GapMM          := spGap.Value;
  Result.MarginLeftMM   := spMarginLeft.Value;
  Result.MarginTopMM    := spMarginTop.Value;
  Result.MarginRightMM  := spMarginRight.Value;
  Result.MarginBottomMM := spMarginBottom.Value;
  Result.Dpi := StrToIntDef(cmbDpi.Text, 203);
end;

procedure TfrmMain.GeometryToUI(const G: TAIPrinterGeometry);
begin
  spPaperW.Value       := G.WidthMM;
  spPaperH.Value       := G.HeightMM;
  spGap.Value          := G.GapMM;
  spMarginLeft.Value   := G.MarginLeftMM;
  spMarginTop.Value    := G.MarginTopMM;
  spMarginRight.Value  := G.MarginRightMM;
  spMarginBottom.Value := G.MarginBottomMM;
  cmbDpi.ItemIndex     := cmbDpi.Items.IndexOf(IntToStr(G.Dpi));
  if cmbDpi.ItemIndex < 0 then cmbDpi.ItemIndex := 0;
end;

function TfrmMain.UpdateGeometryPreview: Boolean;
var
  G: TAIPrinterGeometry;
  UW, UH: Double;
  DW, DH: Integer;
begin
  G := BuildGeometry;

  UW := UsableWidthMM(G);    { largura - margens esq/dir }
  UH := UsableHeightMM(G);   { altura  - margens sup/inf }

  Result := (UW > 0) and (UH > 0);

  if not Result then
  begin
    lblUsableMM.Caption := 'Area util: INVALIDA';
    lblUsableMM.Font.Color := clRed;
    lblUsableDots.Caption := '';
    lblGeomWarn.Caption :=
      'As margens excedem o tamanho do papel. Reduza as margens ou ' +
      'aumente o papel.';
    lblGeometryInfo.Caption := 'Area util: INVALIDA';
    lblGeometryInfo.Font.Color := clRed;
    Exit;
  end;

  { mm -> dots: Dpi/25.4, NUNCA "* 8" }
  DW := MMToDots(UW, G.Dpi);
  DH := MMToDots(UH, G.Dpi);

  lblUsableMM.Font.Color := clDefault;
  lblUsableMM.Caption := Format('Area util: %.1f x %.1f mm', [UW, UH]);
  lblUsableDots.Caption := Format('Em dots (%d dpi): %d x %d', [G.Dpi, DW, DH]);
  lblGeomWarn.Caption := '';

  lblGeometryInfo.Font.Color := clDefault;
  lblGeometryInfo.Caption := Format('Area util: %.1f x %.1f mm (%d x %d dots)',
    [UW, UH, DW, DH]);
end;

procedure TfrmMain.GeometryChange(Sender: TObject);
begin
  if FLoading then Exit;
  UpdateGeometryPreview;
end;

procedure TfrmMain.btnResetGeometryClick(Sender: TObject);
begin
  FLoading := True;
  try
    GeometryToUI(DefaultGeometry);   { 51 x 25 mm, gap 2, margens 0, 203 dpi }
  finally
    FLoading := False;
  end;
  UpdateGeometryPreview;
  AddLog('Geometria restaurada para o padrao: 51 x 25 mm @ 203 dpi.');
end;

{========================= Filas de impressao do SO ===========================}

procedure TfrmMain.LoadSystemPrinters;
var
  Err, Padrao: string;
  N, Idx: Integer;
begin
  Err := '';
  cmbPrinterSO.Items.BeginUpdate;
  try
    N := ListSystemPrinters(cmbPrinterSO.Items, Err);
  finally
    cmbPrinterSO.Items.EndUpdate;
  end;

  if N = 0 then
  begin
    AddLog('[Fila do SO] Nenhuma impressora encontrada. ' + Err);
    cmbPrinterSO.ItemIndex := -1;
    Exit;
  end;

  Padrao := DefaultSystemPrinter;
  Idx := cmbPrinterSO.Items.IndexOf(Padrao);
  if Idx < 0 then Idx := 0;
  cmbPrinterSO.ItemIndex := Idx;

  AddLog(Format('[Fila do SO] %d impressora(s). Padrao: %s',
    [N, cmbPrinterSO.Items[Idx]]));
end;

procedure TfrmMain.btnRefreshPrintersClick(Sender: TObject);
begin
  LoadSystemPrinters;
end;

{============================ Sincronizacao da UI =============================}

function TfrmMain.IsLabelLanguage: Boolean;
begin
  Result := cmbProtocol.ItemIndex in [PROTO_EPL, PROTO_ZPL, PROTO_TSPL];
end;

procedure TfrmMain.cmbModelChange(Sender: TObject);
begin
  { Sem isto, escolher "Elgin L42DT" e deixar o protocolo no default
    (ESC/POS) manda ESC/POS para uma ETIQUETADORA. Silenciosamente. }
  case cmbModel.ItemIndex of
    0, 1:
      if IsLabelLanguage then
        cmbProtocol.ItemIndex := PROTO_ESCPOS;
    2:
      if not IsLabelLanguage then
      begin
        cmbProtocol.ItemIndex := PROTO_TSPL;
        AddLog('Modelo L42DT: protocolo ajustado para TSPL.');
        AddLog('  Se o autoteste indicar ZPL ou EPL, troque no combo.');
      end;
  end;
  cmbProtocolChange(nil);
end;

procedure TfrmMain.cmbProtocolChange(Sender: TObject);
var
  IsNative, IsLbl: Boolean;
begin
  IsNative := cmbProtocol.ItemIndex = PROTO_NATIVE;
  IsLbl := IsLabelLanguage;

  cmbInterface.Enabled := not IsNative;

  { Em cupom (papel continuo) a ALTURA e o GAP nao fazem sentido:
    o papel nao acaba. A largura e as margens continuam valendo (GS L/GS W). }
  spPaperH.Enabled := IsLbl;
  spGap.Enabled    := IsLbl;

  btnPrintLabel.Enabled := IsLbl;
  btnCut.Enabled        := not IsLbl;
  btnDrawer.Enabled     := (not IsLbl) and (not IsNative);
  btnBeep.Enabled       := (not IsLbl) and (not IsNative);

  cmbInterfaceChange(nil);
end;

procedure TfrmMain.cmbInterfaceChange(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := cmbInterface.ItemIndex;

  edtDevice.Enabled    := Idx in [IFACE_SERIAL, IFACE_TCP, IFACE_DEVICE];
  edtPort.Enabled      := Idx in [IFACE_SERIAL, IFACE_TCP];
  cmbPrinterSO.Enabled := Idx = IFACE_SPOOLER;
  btnRefreshPrinters.Enabled := Idx = IFACE_SPOOLER;

  case Idx of
    IFACE_SERIAL:
      begin
        {$IFDEF WINDOWS}
        if Pos('COM', edtDevice.Text) = 0 then edtDevice.Text := 'COM1';
        {$ELSE}
        if Pos('tty', edtDevice.Text) = 0 then edtDevice.Text := '/dev/ttyUSB0';
        {$ENDIF}
        edtPort.Text := '9600';
      end;
    IFACE_TCP:
      begin
        if Pos('.', edtDevice.Text) = 0 then edtDevice.Text := '192.168.1.100';
        edtPort.Text := '9100';
      end;
    IFACE_DEVICE:
      begin
        {$IFDEF WINDOWS}
        if edtDevice.Text = '' then edtDevice.Text := 'saida.bin';
        {$ELSE}
        if edtDevice.Text = '' then edtDevice.Text := '/dev/usb/lp0';
        {$ENDIF}
      end;
  end;
end;

{============================== Configuracao =================================}

procedure TfrmMain.ApplySettings;
begin
  if not UpdateGeometryPreview then
    raise Exception.Create(
      'Geometria invalida: as margens excedem o tamanho do papel. ' +
      'Corrija na aba "Tamanho do papel".');

  case cmbModel.ItemIndex of
    0: FPrinter.PrinterModel := pmElginI9;
    1: FPrinter.PrinterModel := pmQR203;
    2: FPrinter.PrinterModel := pmElginL42DT;
  end;

  case cmbProtocol.ItemIndex of
    PROTO_ESCPOS: begin
        FPrinter.Language := plEscPos;
        FPrinter.RenderMode := rmRawCommand;
      end;
    PROTO_NATIVE:
        FPrinter.RenderMode := rmNativeCanvas;
    PROTO_EPL: begin
        FPrinter.Language := plEpl;
        FPrinter.RenderMode := rmRawCommand;
      end;
    PROTO_ZPL: begin
        FPrinter.Language := plZpl;
        FPrinter.RenderMode := rmRawCommand;
      end;
    PROTO_TSPL: begin
        FPrinter.Language := plTspl;
        FPrinter.RenderMode := rmRawCommand;
      end;
  end;

  { A geometria vai INTEIRA para o componente, que a repassa para a
    linguagem, que emite SIZE/GAP/REFERENCE, q/Q/R, ^PW/^LL/^LH ou GS L/GS W.
    O modelo e' definido ANTES, entao o valor da UI prevalece sobre o
    default do profile. }
  FPrinter.Geometry := BuildGeometry;

  FPrinter.RemoveAccents := chkRemoveAccents.Checked;

  case cmbInterface.ItemIndex of
    IFACE_SERIAL:
      begin
        FPrinter.TransportKind := ptSerial;
        FPrinter.DeviceName := edtDevice.Text;
        FPrinter.SerialBaud := StrToIntDef(edtPort.Text, 9600);
      end;
    IFACE_TCP:
      begin
        FPrinter.TransportKind := ptTcp9100;
        FPrinter.Host := edtDevice.Text;
        FPrinter.Port := StrToIntDef(edtPort.Text, 9100);
      end;
    IFACE_DEVICE:
      begin
        FPrinter.TransportKind := ptFile;
        FPrinter.DeviceName := edtDevice.Text;
      end;
    IFACE_SPOOLER:
      begin
        if cmbPrinterSO.ItemIndex < 0 then
          raise Exception.Create(
            'Selecione uma fila do SO. Se o combo estiver vazio, clique em ' +
            '"Atualizar" e veja o motivo no log.');
        FPrinter.TransportKind := ptPrinterRaw;
        FPrinter.DeviceName := cmbPrinterSO.Items[cmbPrinterSO.ItemIndex];
      end;
  end;
end;

{=============================== Motor de job ================================}

procedure TfrmMain.RunJob(const AName: string; AJob: TJobProc);
var
  G: TAIPrinterGeometry;
begin
  AddLog('--- ' + AName + ' ---');
  SetStatus('Executando: ' + AName);
  FLastHex := '';
  try
    ApplySettings;

    G := FPrinter.Geometry;
    AddLog(Format('  Papel: %.1f x %.1f mm | margens L%.1f T%.1f R%.1f B%.1f | %d dpi',
      [G.WidthMM, G.HeightMM, G.MarginLeftMM, G.MarginTopMM,
       G.MarginRightMM, G.MarginBottomMM, G.Dpi]));
    AddLog(Format('  Area util: %.1f x %.1f mm (%d x %d dots)',
      [FPrinter.UsableWidthMM, FPrinter.UsableHeightMM,
       MMToDots(FPrinter.UsableWidthMM, G.Dpi),
       MMToDots(FPrinter.UsableHeightMM, G.Dpi)]));

    FPrinter.Active := True;
    if not FPrinter.Active then
    begin
      AddLog('FALHA ao conectar: ' + FPrinter.LastError);
      SetStatus('Erro de conexao');
      Exit;
    end;

    try
      if not FPrinter.BeginJob then
      begin
        AddLog('FALHA em BeginJob: ' + FPrinter.LastError);
        Exit;
      end;

      AJob();

      FPrinter.EndJob;

      if FPrinter.PrintJob then
      begin
        AddLog(Format('OK - %d bytes enviados.', [FPrinter.LastBytesSent]));
        SetStatus('Concluido');
      end
      else
      begin
        AddLog('FALHA em PrintJob: ' + FPrinter.LastError);
        SetStatus('Erro de envio');
      end;

      { Hex SEMPRE, inclusive na falha: e' justamente ai que voce precisa
        ver os bytes. }
      FLastHex := FPrinter.LastCommandHex;
      if chkHexLog.Checked and (FLastHex <> '') then
        AddLog('  HEX: ' + FLastHex);

    finally
      FPrinter.Active := False;
    end;
  except
    on E: Exception do
    begin
      AddLog('ERRO: ' + E.Message);
      SetStatus('Erro');
    end;
  end;
  AddLog('');
end;

{================================ Roteiros ===================================}

procedure TfrmMain.JobNothing;
begin
end;

procedure TfrmMain.JobReceipt;
begin
  FPrinter.AlignCenter;
  FPrinter.SetDoubleText;
  FPrinter.PrintTextLine('MERCADO EXEMPLO');
  FPrinter.SetNormal;
  FPrinter.PrintTextLine('CNPJ 00.000.000/0001-00');
  FPrinter.AlignLeft;
  FPrinter.PrintTextLine('--------------------------------');
  FPrinter.PrintTextLine('Coca-Cola 2L            12,90');
  FPrinter.PrintTextLine('Pao Frances kg           9,50');
  FPrinter.PrintTextLine('--------------------------------');
  FPrinter.SetBold(True);
  FPrinter.PrintTextLine('TOTAL                   22,40');
  FPrinter.SetBold(False);
  FPrinter.AlignCenter;
  FPrinter.PrintQRCode('https://exemplo.com/nfce/12345');
  FPrinter.AlignLeft;

  if IsLabelLanguage then
    FPrinter.PrintLabel(1)
  else
    FPrinter.CutPaper;
end;

procedure TfrmMain.JobBold;
begin
  FPrinter.SetBold(True);
  FPrinter.PrintTextLine('TEXTO EM NEGRITO');
  FPrinter.SetBold(False);
  FPrinter.PrintTextLine('Texto normal');
  if IsLabelLanguage then FPrinter.PrintLabel(1);
end;

procedure TfrmMain.JobBarcode;
begin
  FPrinter.PrintBarcode('7891234567895');
  if IsLabelLanguage then FPrinter.PrintLabel(1);
end;

procedure TfrmMain.JobQRCode;
begin
  FPrinter.PrintQRCode('https://github.com/marcelomaurin/CHATGPT');
  if IsLabelLanguage then FPrinter.PrintLabel(1);
end;

procedure TfrmMain.JobCut;
begin
  FPrinter.CutPaper;
end;

procedure TfrmMain.JobLabel;
begin
  { Etiqueta de 51 x 25 mm: conteudo curto, senao estoura a area util. }
  FPrinter.PrintTextLine('PRODUTO TESTE');
  FPrinter.PrintTextLine('Lote 2026-A');
  FPrinter.PrintBarcode('7891234567895');
  FPrinter.PrintLabel(1);
end;

procedure TfrmMain.JobDrawer;
begin
  FPrinter.OpenDrawer;
end;

procedure TfrmMain.JobBeep;
begin
  FPrinter.Beep;
end;

{================================ Handlers ===================================}

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  RunJob('Cupom / etiqueta completa', @JobReceipt);
end;

procedure TfrmMain.btnTestConnClick(Sender: TObject);
begin
  RunJob('Teste de conexao', @JobNothing);
end;

procedure TfrmMain.btnBoldTextClick(Sender: TObject);
begin
  RunJob('Teste de negrito', @JobBold);
end;

procedure TfrmMain.btnBarcodeClick(Sender: TObject);
begin
  RunJob('Teste de codigo de barras', @JobBarcode);
end;

procedure TfrmMain.btnQRCodeClick(Sender: TObject);
begin
  RunJob('Teste de QR Code', @JobQRCode);
end;

procedure TfrmMain.btnCutClick(Sender: TObject);
begin
  RunJob('Teste de corte', @JobCut);
end;

procedure TfrmMain.btnPrintLabelClick(Sender: TObject);
begin
  RunJob('Teste de etiqueta', @JobLabel);
end;

procedure TfrmMain.btnDrawerClick(Sender: TObject);
begin
  RunJob('Teste de gaveta', @JobDrawer);
end;

procedure TfrmMain.btnBeepClick(Sender: TObject);
begin
  RunJob('Teste de beep', @JobBeep);
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.btnSaveBinClick(Sender: TObject);
var
  L: TStringList;
begin
  if FLastHex = '' then
  begin
    ShowMessage('Nenhum job executado ainda.');
    Exit;
  end;
  if not dlgSave.Execute then Exit;

  L := TStringList.Create;
  try
    L.Text := FLastHex;
    L.SaveToFile(dlgSave.FileName);
    AddLog('HEX salvo em: ' + dlgSave.FileName);
  finally
    L.Free;
  end;
end;

{================================= Utils =====================================}

procedure TfrmMain.AddLog(const AMsg: string);
begin
  if Assigned(memoLog) then
    memoLog.Lines.Add(AMsg);
end;

procedure TfrmMain.SetStatus(const AMsg: string);
begin
  Caption := 'Posprinter Demo — ' + AMsg;
end;

end.
