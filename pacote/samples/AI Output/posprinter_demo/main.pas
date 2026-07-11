unit main;

{-------------------------------------------------------------------------------
  Posprinter Demo - VERSAO CORRIGIDA

  Correcoes principais em relacao a versao anterior:

  [1] cmbModel.OnChange -> sincroniza o protocolo com o modelo.
      ANTES: escolher "Elgin L42DT" e deixar o combo de protocolo no default
      (ESC/POS) enviava ESC/POS para uma ETIQUETADORA. Nada saia, sem erro.

  [2] Novo combo de INTERFACE com "Device/Arquivo" e "Impressora do SO (RAW)".
      ANTES: so' Serial e TCP. Uma L42 DT no USB era INALCANCAVEL.

  [3] Botao "Print Label" chamando PrintLabel (PRINT 1,1 / P1).
      ANTES: tudo terminava em CutPaper, que em EPL emite ZERO bytes e em
      TSPL emite CUT (guilhotina que a L42 nao tem). Etiqueta nunca saia.

  [4] Checagem de Active apos conectar + preservacao do LastError real.
      ANTES: falha de conexao era engolida e virava "Transport not active".

  [5] Hex logado SEMPRE (inclusive na falha) - e' o principal instrumento
      de debug. ANTES: so' no sucesso.

  [6] Campos de tamanho de etiqueta (mm) e gap na UI.

  [7] RunJob() unico no lugar de 6 handlers copia-e-cola.

  NOTA: ptPrinterRaw depende do TAIPrinterSpoolerTransport (winspool RAW /
  lp -o raw), que ainda precisa ser implementado no pacote. Enquanto isso,
  use "Device/Arquivo" apontando para /dev/usb/lp0 (Linux) ou um .bin.
-------------------------------------------------------------------------------}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Spin, Math, aibase, aiposprinter, aiprinter_types, ailistprinters;

type
  { Assinatura de um "roteiro" de impressao. Cada botao so' descreve O QUE
    imprimir; toda a mecanica de conectar/abrir/fechar/logar fica no RunJob. }
  TJobProc = procedure of object;

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    btnRun: TButton;
    btnClearLog: TButton;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIPosPrinter: TAIPOSPrinter;
    FListPrinters: TAIListPrinters;

    cmbModel: TComboBox;
    cmbInterface: TComboBox;
    cmbProtocol: TComboBox;
    cmbPrinterSO: TComboBox;      { filas do SO, quando interface = RAW }
    edtDevice: TEdit;
    edtPort: TEdit;
    spLabelW: TSpinEdit;
    spLabelH: TSpinEdit;
    spGap: TSpinEdit;
    chkRemoveAccents: TCheckBox;

    btnBoldText: TButton;
    btnBarcode: TButton;
    btnQRCode: TButton;
    btnCut: TButton;
    btnPrintLabel: TButton;
    btnDrawer: TButton;
    btnBeep: TButton;
    btnTestConn: TButton;

    procedure BuildUI;
    procedure cmbModelChange(Sender: TObject);
    procedure cmbInterfaceChange(Sender: TObject);
    procedure cmbProtocolChange(Sender: TObject);

    { Handlers - cada um so' delega pro RunJob com o roteiro certo }
    procedure btnBoldTextClick(Sender: TObject);
    procedure btnBarcodeClick(Sender: TObject);
    procedure btnQRCodeClick(Sender: TObject);
    procedure btnCutClick(Sender: TObject);
    procedure btnPrintLabelClick(Sender: TObject);
    procedure btnDrawerClick(Sender: TObject);
    procedure btnBeepClick(Sender: TObject);
    procedure btnTestConnClick(Sender: TObject);

    { Roteiros }
    procedure JobReceipt;
    procedure JobBold;
    procedure JobBarcode;
    procedure JobQRCode;
    procedure JobCut;
    procedure JobLabel;
    procedure JobDrawer;
    procedure JobBeep;
    procedure JobNothing;

    function  IsLabelLanguage: Boolean;
    procedure ApplySettings;
    procedure RunJob(const AName: string; AJob: TJobProc);
    procedure AddLog(const AMsg: string);
    procedure SetStatus(const AMsg: string);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

const
  { indices do cmbProtocol }
  PROTO_ESCPOS = 0;
  PROTO_NATIVE = 1;
  PROTO_EPL    = 2;
  PROTO_ZPL    = 3;
  PROTO_TSPL   = 4;

  { indices do cmbInterface }
  IFACE_SERIAL  = 0;
  IFACE_TCP     = 1;
  IFACE_DEVICE  = 2;   { /dev/usb/lp0, LPT1, ou um .bin }
  IFACE_SPOOLER = 3;   { fila do SO, RAW }

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FAIPosPrinter := TAIPOSPrinter.Create(Self);
  FListPrinters := TAIListPrinters.Create(Self);

  BuildUI;

  AddLog('Posprinter Demo inicializado.');
  AddLog('DICA: antes de tudo, imprima a etiqueta de autoteste da L42 DT');
  AddLog('      (segure FEED ao ligar) para descobrir a linguagem ativa.');
  SetStatus('Pronto');

  { estado inicial coerente }
  cmbModelChange(nil);
  cmbInterfaceChange(nil);
  cmbProtocolChange(nil);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  { LCL libera pelo Owner }
end;

procedure TfrmMain.BuildUI;

  function MkLabel(const ACaption: string; ALeft, ATop: Integer): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := pnlTop;
    Result.Left := ALeft;
    Result.Top := ATop;
    Result.Caption := ACaption;
  end;

  function MkButton(const ACaption: string; ALeft, ATop, AWidth: Integer;
    AHandler: TNotifyEvent): TButton;
  begin
    Result := TButton.Create(Self);
    Result.Parent := pnlTop;
    Result.Left := ALeft;
    Result.Top := ATop;
    Result.Width := AWidth;
    Result.Caption := ACaption;
    Result.OnClick := AHandler;
  end;

  function MkSpin(ALeft, ATop, AWidth, AMin, AMax, AValue: Integer): TSpinEdit;
  begin
    Result := TSpinEdit.Create(Self);
    Result.Parent := pnlTop;
    Result.Left := ALeft;
    Result.Top := ATop;
    Result.Width := AWidth;
    Result.MinValue := AMin;
    Result.MaxValue := AMax;
    Result.Value := AValue;
  end;

begin
  pnlTop.Height := 250;

  { ---------- Linha 1: modelo / interface / protocolo ---------- }
  MkLabel('Modelo:', 15, 30);
  cmbModel := TComboBox.Create(Self);
  cmbModel.Parent := pnlTop;
  cmbModel.SetBounds(15, 48, 150, 23);
  cmbModel.Style := csDropDownList;
  cmbModel.Items.Add('Elgin i9 (80mm)');
  cmbModel.Items.Add('QR203 (58mm)');
  cmbModel.Items.Add('Elgin L42DT (Label)');
  cmbModel.ItemIndex := 0;
  cmbModel.OnChange := @cmbModelChange;   { <-- [1] o que faltava }

  MkLabel('Protocolo:', 175, 30);
  cmbProtocol := TComboBox.Create(Self);
  cmbProtocol.Parent := pnlTop;
  cmbProtocol.SetBounds(175, 48, 110, 23);
  cmbProtocol.Style := csDropDownList;
  cmbProtocol.Items.Add('ESC/POS');
  cmbProtocol.Items.Add('Native OS');
  cmbProtocol.Items.Add('EPL');
  cmbProtocol.Items.Add('ZPL');
  cmbProtocol.Items.Add('TSPL');
  cmbProtocol.ItemIndex := PROTO_ESCPOS;
  cmbProtocol.OnChange := @cmbProtocolChange;

  MkLabel('Interface:', 295, 30);
  cmbInterface := TComboBox.Create(Self);
  cmbInterface.Parent := pnlTop;
  cmbInterface.SetBounds(295, 48, 150, 23);
  cmbInterface.Style := csDropDownList;
  cmbInterface.Items.Add('Serial (COM)');
  cmbInterface.Items.Add('Ethernet (TCP 9100)');
  cmbInterface.Items.Add('Device / Arquivo');       { <-- [2] }
  cmbInterface.Items.Add('Impressora do SO (RAW)'); { <-- [2] }
  cmbInterface.ItemIndex := IFACE_DEVICE;
  cmbInterface.OnChange := @cmbInterfaceChange;

  MkLabel('Porta / IP / Caminho:', 455, 30);
  edtDevice := TEdit.Create(Self);
  edtDevice.Parent := pnlTop;
  edtDevice.SetBounds(455, 48, 190, 23);
  {$IFDEF WINDOWS}
  edtDevice.Text := 'saida.bin';
  {$ELSE}
  edtDevice.Text := '/dev/usb/lp0';
  {$ENDIF}

  MkLabel('Baud / Porta:', 655, 30);
  edtPort := TEdit.Create(Self);
  edtPort.Parent := pnlTop;
  edtPort.SetBounds(655, 48, 80, 23);
  edtPort.Text := '9100';

  { fila do SO - so' aparece quando interface = RAW }
  MkLabel('Fila do SO:', 745, 30);
  cmbPrinterSO := TComboBox.Create(Self);
  cmbPrinterSO.Parent := pnlTop;
  cmbPrinterSO.SetBounds(745, 48, 200, 23);
  cmbPrinterSO.Style := csDropDownList;
  try
    if Assigned(FListPrinters) then
    begin
      cmbPrinterSO.Items.Assign(FListPrinters.Printers);
      if cmbPrinterSO.Items.Count > 0 then
        cmbPrinterSO.ItemIndex :=
          Max(0, cmbPrinterSO.Items.IndexOf(FListPrinters.DefaultPrinter));
    end;
  except
    on E: Exception do
      AddLog('Nao foi possivel listar impressoras do SO: ' + E.Message);
  end;

  { ---------- Linha 2: etiqueta ---------- }
  MkLabel('Etiqueta L (mm):', 15, 85);
  spLabelW := MkSpin(15, 103, 70, 10, 300, 100);

  MkLabel('A (mm):', 95, 85);
  spLabelH := MkSpin(95, 103, 70, 10, 300, 50);

  MkLabel('Gap (mm):', 175, 85);
  spGap := MkSpin(175, 103, 70, 0, 20, 2);

  chkRemoveAccents := TCheckBox.Create(Self);
  chkRemoveAccents.Parent := pnlTop;
  chkRemoveAccents.SetBounds(255, 105, 160, 19);
  chkRemoveAccents.Caption := 'Remover acentos';

  { ---------- Linha 3: acoes ---------- }
  btnRun.SetBounds(15, 145, 150, 28);
  btnRun.Caption := 'Cupom completo';

  btnTestConn   := MkButton('Testar conexao', 175, 145, 110, @btnTestConnClick);
  btnBoldText   := MkButton('Negrito',        295, 145,  90, @btnBoldTextClick);
  btnBarcode    := MkButton('Barcode',        395, 145,  90, @btnBarcodeClick);
  btnQRCode     := MkButton('QR Code',        495, 145,  90, @btnQRCodeClick);
  btnCut        := MkButton('Cortar',         595, 145,  90, @btnCutClick);
  btnPrintLabel := MkButton('Imprimir etiqueta', 695, 145, 130, @btnPrintLabelClick); { [3] }
  btnDrawer     := MkButton('Gaveta',         835, 145,  90, @btnDrawerClick);
  btnBeep       := MkButton('Beep',           935, 145,  70, @btnBeepClick);

  btnClearLog.SetBounds(15, 185, 150, 28);
  btnClearLog.Caption := 'Limpar log';
end;

{============================ Sincronizacao da UI =============================}

function TfrmMain.IsLabelLanguage: Boolean;
begin
  Result := cmbProtocol.ItemIndex in [PROTO_EPL, PROTO_ZPL, PROTO_TSPL];
end;

procedure TfrmMain.cmbModelChange(Sender: TObject);
begin
  { [1] CORRECAO CENTRAL.
    Antes, escolher a L42DT e deixar o protocolo no default (ESC/POS)
    mandava ESC/POS pra uma etiquetadora. Silenciosamente. }
  case cmbModel.ItemIndex of
    0, 1:  { Elgin i9 / QR203 - cupom }
      if IsLabelLanguage then
        cmbProtocol.ItemIndex := PROTO_ESCPOS;

    2:     { Elgin L42DT - ETIQUETA. ESC/POS aqui nao faz sentido. }
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

  { campos de etiqueta so' fazem sentido em linguagem de etiqueta }
  spLabelW.Enabled := IsLbl;
  spLabelH.Enabled := IsLbl;
  spGap.Enabled := IsLbl;

  { em etiquetadora nao ha guilhotina nem gaveta }
  btnPrintLabel.Enabled := IsLbl;
  btnCut.Enabled := not IsLbl;
  btnDrawer.Enabled := not IsLbl and not IsNative;
  btnBeep.Enabled := not IsLbl and not IsNative;
  btnBarcode.Enabled := True;
  btnQRCode.Enabled := True;

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
  { ORDEM IMPORTA: o modelo mexe na linguagem (via profile), entao o
    protocolo escolhido pelo usuario e' aplicado DEPOIS, sobrescrevendo. }
  case cmbModel.ItemIndex of
    0: FAIPosPrinter.PrinterModel := pmElginI9;
    1: FAIPosPrinter.PrinterModel := pmQR203;
    2: FAIPosPrinter.PrinterModel := pmElginL42DT;
  end;

  case cmbProtocol.ItemIndex of
    PROTO_ESCPOS: begin
        FAIPosPrinter.Language := plEscPos;
        FAIPosPrinter.RenderMode := rmRawCommand;
      end;
    PROTO_NATIVE:
        FAIPosPrinter.RenderMode := rmNativeCanvas;
    PROTO_EPL: begin
        FAIPosPrinter.Language := plEpl;
        FAIPosPrinter.RenderMode := rmRawCommand;
      end;
    PROTO_ZPL: begin
        FAIPosPrinter.Language := plZpl;
        FAIPosPrinter.RenderMode := rmRawCommand;
      end;
    PROTO_TSPL: begin
        FAIPosPrinter.Language := plTspl;
        FAIPosPrinter.RenderMode := rmRawCommand;
      end;
  end;

  { [6] tamanho da etiqueta - antes ficava preso no default 100x50 }
  FAIPosPrinter.LabelWidthMM  := spLabelW.Value;
  FAIPosPrinter.LabelHeightMM := spLabelH.Value;
  FAIPosPrinter.GapMM         := spGap.Value;
  FAIPosPrinter.RemoveAccents := chkRemoveAccents.Checked;

  case cmbInterface.ItemIndex of
    IFACE_SERIAL:
      begin
        FAIPosPrinter.TransportKind := ptSerial;
        FAIPosPrinter.DeviceName := edtDevice.Text;
        FAIPosPrinter.SerialBaud := StrToIntDef(edtPort.Text, 9600);
      end;
    IFACE_TCP:
      begin
        FAIPosPrinter.TransportKind := ptTcp9100;
        FAIPosPrinter.Host := edtDevice.Text;
        FAIPosPrinter.Port := StrToIntDef(edtPort.Text, 9100);
      end;
    IFACE_DEVICE:
      begin
        { [2] Requer a correcao no InitTransport: ptFile deve usar
          FDeviceName, e nao o caminho hardcoded output/test_print.bin }
        FAIPosPrinter.TransportKind := ptFile;
        FAIPosPrinter.DeviceName := edtDevice.Text;
      end;
    IFACE_SPOOLER:
      begin
        { PENDENTE: exige ptPrinterRaw + TAIPrinterSpoolerTransport
          (winspool RAW no Windows / lp -o raw no Linux).
          Enquanto nao existir, avisamos em vez de fingir que funciona. }
        raise Exception.Create(
          'Transporte "Impressora do SO (RAW)" ainda nao implementado no ' +
          'pacote. Falta TAIPrinterSpoolerTransport (ptPrinterRaw). ' +
          'Use "Device / Arquivo" por enquanto.');
      end;
  end;
end;

{=============================== Motor de job ================================}

procedure TfrmMain.RunJob(const AName: string; AJob: TJobProc);
begin
  AddLog('--- ' + AName + ' ---');
  SetStatus('Executando: ' + AName);
  try
    ApplySettings;

    FAIPosPrinter.Active := True;

    { [4] Antes nao havia esta checagem: a falha de conexao era engolida
      e reaparecia depois como o generico "Transport not active",
      perdendo o erro real (connection refused, porta ocupada...). }
    if not FAIPosPrinter.Active then
    begin
      AddLog('FALHA ao conectar: ' + FAIPosPrinter.LastError);
      SetStatus('Erro de conexao');
      Exit;
    end;

    try
      if not FAIPosPrinter.BeginJob then
      begin
        AddLog('FALHA em BeginJob: ' + FAIPosPrinter.LastError);
        Exit;
      end;

      AJob();          { <- o roteiro especifico do botao }

      FAIPosPrinter.EndJob;

      if FAIPosPrinter.PrintJob then
      begin
        AddLog(Format('OK - %d bytes enviados.',
          [FAIPosPrinter.LastBytesSent]));
        SetStatus('Concluido');
      end
      else
      begin
        AddLog('FALHA em PrintJob: ' + FAIPosPrinter.LastError);
        SetStatus('Erro de envio');
      end;

      { [5] Hex SEMPRE, inclusive na falha. SendDocument preenche
        LastCommandHex antes de checar a conexao, entao os bytes estao
        disponiveis mesmo quando o envio falha - e e' justamente ai
        que voce mais precisa deles. }
      if FAIPosPrinter.LastCommandHex <> '' then
        AddLog('  HEX: ' + FAIPosPrinter.LastCommandHex);

    finally
      FAIPosPrinter.Active := False;
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
  { so' abre e fecha - serve pro "Testar conexao" }
end;

procedure TfrmMain.JobReceipt;
begin
  FAIPosPrinter.AlignCenter;
  FAIPosPrinter.SetDoubleText;
  FAIPosPrinter.PrintTextLine('MERCADO EXEMPLO');
  FAIPosPrinter.SetNormal;
  FAIPosPrinter.PrintTextLine('CNPJ 00.000.000/0001-00');
  FAIPosPrinter.AlignLeft;
  FAIPosPrinter.PrintTextLine('--------------------------------');
  FAIPosPrinter.PrintTextLine('Coca-Cola 2L            12,90');
  FAIPosPrinter.PrintTextLine('Pao Frances kg           9,50');
  FAIPosPrinter.PrintTextLine('--------------------------------');
  FAIPosPrinter.SetBold(True);
  FAIPosPrinter.PrintTextLine('TOTAL                   22,40');
  FAIPosPrinter.SetBold(False);
  FAIPosPrinter.AlignCenter;
  FAIPosPrinter.PrintQRCode('https://exemplo.com/nfce/12345');
  FAIPosPrinter.AlignLeft;

  { fecha do jeito certo pra cada tipo de impressora }
  if IsLabelLanguage then
    FAIPosPrinter.PrintLabel
  else
    FAIPosPrinter.CutPaper;
end;

procedure TfrmMain.JobBold;
begin
  FAIPosPrinter.SetBold(True);
  FAIPosPrinter.PrintTextLine('TEXTO EM NEGRITO');
  FAIPosPrinter.SetBold(False);
  FAIPosPrinter.PrintTextLine('Texto normal');
  if IsLabelLanguage then FAIPosPrinter.PrintLabel;
end;

procedure TfrmMain.JobBarcode;
begin
  FAIPosPrinter.PrintBarcode('7891234567895');
  if IsLabelLanguage then FAIPosPrinter.PrintLabel;
end;

procedure TfrmMain.JobQRCode;
begin
  FAIPosPrinter.PrintQRCode('https://github.com/marcelomaurin/CHATGPT');
  if IsLabelLanguage then FAIPosPrinter.PrintLabel;
end;

procedure TfrmMain.JobCut;
begin
  FAIPosPrinter.CutPaper;
end;

procedure TfrmMain.JobLabel;
begin
  { [3] o teste que faltava: uma etiqueta de verdade, terminando em
    PRINT 1,1 (TSPL) / P1 (EPL) / ^XZ (ZPL) - e NAO em CutPaper. }
  FAIPosPrinter.PrintTextLine('PRODUTO TESTE');
  FAIPosPrinter.PrintTextLine('Lote 2026-A');
  FAIPosPrinter.PrintTextLine('Val: 31/12/2026');
  FAIPosPrinter.PrintBarcode('7891234567895');
  FAIPosPrinter.PrintQRCode('https://exemplo.com/prod/1');
  FAIPosPrinter.PrintLabel;
end;

procedure TfrmMain.JobDrawer;
begin
  FAIPosPrinter.OpenDrawer;
end;

procedure TfrmMain.JobBeep;
begin
  FAIPosPrinter.Beep;
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

{================================= Utils =====================================}

procedure TfrmMain.AddLog(const AMsg: string);
begin
  if Assigned(memoLog) then
    memoLog.Lines.Add(AMsg);
end;

procedure TfrmMain.SetStatus(const AMsg: string);
begin
  if Assigned(lblStatus) then
    lblStatus.Caption := 'Status: ' + AMsg;
end;

end.
