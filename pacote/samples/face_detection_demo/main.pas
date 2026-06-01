unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  pythonconnector, facedetection, lazpng;

type

  { TfrmFaceDemo }

  TfrmFaceDemo = class(TForm)
    pnlConfig: TPanel;
    lblDLLPath: TLabel;
    lbDLLs: TListBox;
    btnToggleActive: TButton;
    btnInstallDeps: TButton;
    lblStatus: TLabel;
    
    pnlImage: TPanel;
    lblImage: TLabel;
    edImagePath: TEdit;
    btnSelectImg: TButton;
    btnDetect: TButton;
    
    imgView: TImage;
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnToggleActiveClick(Sender: TObject);
    procedure btnInstallDepsClick(Sender: TObject);
    procedure btnSelectImgClick(Sender: TObject);
    procedure btnDetectClick(Sender: TObject);
  private
    FConnector: TPythonConnector;
    FDetector: TFaceDetection;
    procedure LogMsg(const AMsg: string);
    procedure UpdateStatusUI;
  public

  end;

var
  frmFaceDemo: TfrmFaceDemo;

implementation

{$R *.lfm}

{ TfrmFaceDemo }

procedure TfrmFaceDemo.FormCreate(Sender: TObject);
var
  SR: TSearchRec;
  AppDir, Ext: string;
  ArchStr: string;
  I: Integer;
begin
  FConnector := TPythonConnector.Create(Self);
  FDetector := TFaceDetection.Create(Self);
  FDetector.PythonConnector := FConnector;
  
  // Detect platform bitness
  {$IFDEF CPU64}
  ArchStr := '64-bit';
  Ext := '.dll';
  {$ELSE}
  ArchStr := '32-bit';
  Ext := '.dll';
  {$ENDIF}

  lblDLLPath.Caption := 'Escolha a DLL do Python (' + ArchStr + '):';

  // Search and populate ListBox
  lbDLLs.Items.Clear;
  AppDir := ExtractFilePath(ParamStr(0));
  
  if FindFirst(AppDir + 'python*' + Ext, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory) = 0 then
        lbDLLs.Items.Add(AppDir + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;

  // Add default candidate paths
  {$IFDEF MSWINDOWS}
  lbDLLs.Items.Add('python3.dll');
  {$IFDEF CPU64}
  lbDLLs.Items.Add('python3_64.dll');
  {$ELSE}
  lbDLLs.Items.Add('python3_32.dll');
  {$ENDIF}
  lbDLLs.Items.Add('python312.dll');
  lbDLLs.Items.Add('python311.dll');
  lbDLLs.Items.Add('python310.dll');
  {$ELSE}
  lbDLLs.Items.Add('libpython3.so');
  lbDLLs.Items.Add('libpython3_64.so');
  lbDLLs.Items.Add('libpython3.12.so');
  lbDLLs.Items.Add('libpython3.11.so');
  {$ENDIF}

  // Deduplicate
  for I := lbDLLs.Items.Count - 1 downto 0 do
  begin
    if lbDLLs.Items.IndexOf(lbDLLs.Items[I]) < I then
      lbDLLs.Items.Delete(I);
  end;

  if lbDLLs.Items.Count > 0 then
    lbDLLs.ItemIndex := 0;

  UpdateStatusUI;
  LogMsg('FaceDetection Demo iniciado. Plataforma: ' + ArchStr);
  LogMsg('Para começar, selecione a DLL na lista, ative o Python e instale "opencv-python" se necessário.');
end;

procedure TfrmFaceDemo.FormDestroy(Sender: TObject);
begin
  // FConnector e FDetector são liberados pelo Owner (Self)
end;

procedure TfrmFaceDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmFaceDemo.UpdateStatusUI;
begin
  if FConnector.IsInitialized then
  begin
    lblStatus.Caption := 'Status: Python ATIVO | ' + FConnector.Version;
    lblStatus.Font.Color := clGreen;
    btnToggleActive.Caption := 'Desativar Python';
    btnInstallDeps.Enabled := True;
    btnDetect.Enabled := True;
  end
  else
  begin
    lblStatus.Caption := 'Status: Python INATIVO';
    lblStatus.Font.Color := clRed;
    btnToggleActive.Caption := 'Ativar Python';
    btnInstallDeps.Enabled := False;
    btnDetect.Enabled := False;
  end;
end;

procedure TfrmFaceDemo.btnToggleActiveClick(Sender: TObject);
var
  SelectedDLL: string;
begin
  if FConnector.Active then
  begin
    FConnector.Active := False;
    LogMsg('Python desativado.');
  end
  else
  begin
    SelectedDLL := 'python3.dll';
    if lbDLLs.ItemIndex >= 0 then
      SelectedDLL := lbDLLs.Items[lbDLLs.ItemIndex];

    FConnector.DLLPath := Trim(SelectedDLL);
    LogMsg('Carregando interpretador Python: ' + FConnector.DLLPath + '...');
    FConnector.Active := True;
    if FConnector.IsInitialized then
      LogMsg('Python inicializado com sucesso. Versão: ' + FConnector.Version)
    else
      LogMsg('ERRO ao inicializar Python: ' + FConnector.LastError);
  end;
  UpdateStatusUI;
end;

procedure TfrmFaceDemo.btnInstallDepsClick(Sender: TObject);
begin
  LogMsg('Instalando dependência "opencv-python" via pip interno. Por favor, aguarde...');
  Screen.Cursor := crHourGlass;
  try
    if FDetector.InstallDependencies then
    begin
      LogMsg('Dependência "opencv-python" instalada/verificada com SUCESSO!');
      ShowMessage('Biblioteca opencv-python instalada com sucesso!');
    end
    else
    begin
      LogMsg('ERRO na instalação de dependências: ' + FDetector.LastError);
      ShowMessage('Falha ao instalar dependências: ' + FDetector.LastError);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmFaceDemo.btnSelectImgClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Title := 'Selecionar Imagem';
    OpenDlg.Filter := 'Imagens (*.jpg;*.jpeg;*.png)|*.jpg;*.jpeg;*.png';
    if OpenDlg.Execute then
    begin
      edImagePath.Text := OpenDlg.FileName;
      imgView.Picture.LoadFromFile(OpenDlg.FileName);
      LogMsg('Imagem carregada: ' + OpenDlg.FileName);
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TfrmFaceDemo.btnDetectClick(Sender: TObject);
var
  Faces: TFaceRectArray;
  i: Integer;
begin
  if Trim(edImagePath.Text) = '' then
  begin
    ShowMessage('Selecione uma imagem primeiro!');
    Exit;
  end;

  LogMsg('Iniciando detecção de faces via OpenCV...');
  Screen.Cursor := crHourGlass;
  try
    // Recarrega a imagem para limpar retângulos antigos
    imgView.Picture.LoadFromFile(edImagePath.Text);
    
    if FDetector.DetectFaces(edImagePath.Text, Faces) then
    begin
      LogMsg(Format('Detecção concluída. Total de faces encontradas: %d', [Length(Faces)]));
      
      if Length(Faces) > 0 then
      begin
        // Desenha os retângulos das faces na imagem na tela
        imgView.Canvas.Pen.Color := clRed;
        imgView.Canvas.Pen.Width := 3;
        imgView.Canvas.Brush.Style := bsClear;
        
        for i := 0 to Length(Faces) - 1 do
        begin
          LogMsg(Format('Face %d detectada em X:%d, Y:%d, Larg:%d, Alt:%d', 
            [i + 1, Faces[i].X, Faces[i].Y, Faces[i].Width, Faces[i].Height]));
            
          imgView.Canvas.Rectangle(
            Faces[i].X,
            Faces[i].Y,
            Faces[i].X + Faces[i].Width,
            Faces[i].Y + Faces[i].Height
          );
        end;
        ShowMessage(Format('%d face(s) detectada(s) e marcada(s) em vermelho na imagem!', [Length(Faces)]));
      end
      else
        ShowMessage('Nenhuma face humana detectada na imagem.');
    end
    else
    begin
      LogMsg('ERRO na detecção: ' + FDetector.LastError);
      ShowMessage('Erro ao detectar faces: ' + FDetector.LastError);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

end.
