unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  pythonconnector, yolodetect;

type

  { TfrmYoloDemo }

  TfrmYoloDemo = class(TForm)
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
    lblDemoImages: TLabel;
    cbDemoImages: TComboBox;
    
    imgView: TImage;
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnToggleActiveClick(Sender: TObject);
    procedure btnInstallDepsClick(Sender: TObject);
    procedure btnSelectImgClick(Sender: TObject);
    procedure btnDetectClick(Sender: TObject);
    procedure cbDemoImagesChange(Sender: TObject);
  private
    FConnector: TPythonConnector;
    FYolo: TYOLO;
    procedure LogMsg(const AMsg: string);
    procedure UpdateStatusUI;
    procedure LoadDemoImages;
  public

  end;

var
  frmYoloDemo: TfrmYoloDemo;

implementation

{$R *.lfm}

{ TfrmYoloDemo }

procedure TfrmYoloDemo.FormCreate(Sender: TObject);
var
  SR: TSearchRec;
  AppDir, Ext: string;
  ArchStr: string;
  I: Integer;
begin
  FConnector := TPythonConnector.Create(Self);
  FYolo := TYOLO.Create(Self);
  FYolo.PythonConnector := FConnector;

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

  // Load preloaded demo images
  LoadDemoImages;

  UpdateStatusUI;
  LogMsg('YOLOv8 Object Detection Demo iniciado. Plataforma: ' + ArchStr);
  LogMsg('Para começar, ative o Python e instale a dependência "ultralytics" se necessário.');
end;

procedure TfrmYoloDemo.FormDestroy(Sender: TObject);
begin
  // FConnector e FYolo são liberados pelo Owner (Self)
end;

procedure TfrmYoloDemo.LoadDemoImages;
var
  SR: TSearchRec;
  ImagesDir: string;
begin
  cbDemoImages.Items.Clear;
  ImagesDir := ExtractFilePath(ParamStr(0)) + 'images' + PathDelim;
  if FindFirst(ImagesDir + '*.png', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory) = 0 then
        cbDemoImages.Items.Add(SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

procedure TfrmYoloDemo.cbDemoImagesChange(Sender: TObject);
var
  ImgPath: string;
begin
  if cbDemoImages.ItemIndex >= 0 then
  begin
    ImgPath := ExtractFilePath(ParamStr(0)) + 'images' + PathDelim + cbDemoImages.Text;
    if FileExists(ImgPath) then
    begin
      edImagePath.Text := ImgPath;
      imgView.Picture.LoadFromFile(ImgPath);
      LogMsg('Carregada imagem de demonstração: ' + cbDemoImages.Text);
    end;
  end;
end;

procedure TfrmYoloDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmYoloDemo.UpdateStatusUI;
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

procedure TfrmYoloDemo.btnToggleActiveClick(Sender: TObject);
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
    LogMsg('Carregando interpretador Python: ' + SelectedDLL + '...');
    FConnector.Active := True;
    if FConnector.IsInitialized then
      LogMsg('Python inicializado com sucesso. Versão: ' + FConnector.Version)
    else
      LogMsg('ERRO ao inicializar Python: ' + FConnector.LastError);
  end;
  UpdateStatusUI;
end;

procedure TfrmYoloDemo.btnInstallDepsClick(Sender: TObject);
begin
  LogMsg('Instalando dependência "ultralytics" (YOLOv8) via pip interno. Por favor, aguarde... (Isso pode demorar alguns minutos dependendo da sua internet)');
  Screen.Cursor := crHourGlass;
  try
    if FYolo.InstallDependencies then
    begin
      LogMsg('Dependência "ultralytics" instalada/verificada com SUCESSO!');
      ShowMessage('Biblioteca ultralytics instalada com sucesso!');
    end
    else
    begin
      LogMsg('ERRO na instalação de dependências: ' + FYolo.LastError);
      ShowMessage('Falha ao instalar dependências: ' + FYolo.LastError);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmYoloDemo.btnSelectImgClick(Sender: TObject);
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

procedure TfrmYoloDemo.btnDetectClick(Sender: TObject);
var
  Objects: TYoloObjectArray;
  i: Integer;
begin
  if Trim(edImagePath.Text) = '' then
  begin
    ShowMessage('Selecione uma imagem primeiro!');
    Exit;
  end;

  LogMsg('Iniciando detecção de objetos via YOLOv8 (baixará o modelo yolov8n.pt de 6MB automaticamente na primeira execução)...');
  Screen.Cursor := crHourGlass;
  try
    // Recarrega a imagem para limpar retângulos antigos
    imgView.Picture.LoadFromFile(edImagePath.Text);
    
    if FYolo.DetectObjects(edImagePath.Text, Objects) then
    begin
      LogMsg(Format('Detecção concluída. Total de objetos encontrados: %d', [Length(Objects)]));
      
      if Length(Objects) > 0 then
      begin
        // Desenha os retângulos dos objetos na imagem na tela
        imgView.Canvas.Pen.Color := clBlue;
        imgView.Canvas.Pen.Width := 3;
        imgView.Canvas.Brush.Style := bsClear;
        imgView.Canvas.Font.Color := clBlue;
        imgView.Canvas.Font.Size := 10;
        
        for i := 0 to Length(Objects) - 1 do
        begin
          LogMsg(Format('Objeto %d: %s (%0.1f%%) em [%d, %d, %d, %d]', 
            [i + 1, Objects[i].ClassName, Objects[i].Confidence * 100, 
             Objects[i].X1, Objects[i].Y1, Objects[i].X2, Objects[i].Y2]));
            
          imgView.Canvas.Rectangle(
            Objects[i].X1,
            Objects[i].Y1,
            Objects[i].X2,
            Objects[i].Y2
          );
          
          imgView.Canvas.TextOut(
            Objects[i].X1 + 5,
            Objects[i].Y1 + 5,
            Objects[i].ClassName + ': ' + Format('%0.0f%%', [Objects[i].Confidence * 100])
          );
        end;
        ShowMessage(Format('%d objeto(s) detectado(s) e marcado(s) em azul na imagem!', [Length(Objects)]));
      end
      else
        ShowMessage('Nenhum objeto detectado na imagem.');
    end
    else
    begin
      LogMsg('ERRO na detecção: ' + FYolo.LastError);
      ShowMessage('Erro ao detectar objetos: ' + FYolo.LastError);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

end.
