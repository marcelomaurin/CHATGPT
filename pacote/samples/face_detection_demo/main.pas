unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  pythonconnector, facedetection;

type

  { TfrmFaceDemo }

  TfrmFaceDemo = class(TForm)
    pnlConfig: TPanel;
    lblDLLPath: TLabel;
    edDLLPath: TEdit;
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
begin
  FConnector := TPythonConnector.Create(Self);
  FDetector := TFaceDetection.Create(Self);
  FDetector.PythonConnector := FConnector;
  
  edDLLPath.Text := 'python3.dll';
  UpdateStatusUI;
  LogMsg('FaceDetection Demo iniciado.');
  LogMsg('Para começar, ative o Python e instale a dependência "opencv-python" se necessário.');
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
begin
  if FConnector.Active then
  begin
    FConnector.Active := False;
    LogMsg('Python desativado.');
  end
  else
  begin
    FConnector.DLLPath := Trim(edDLLPath.Text);
    LogMsg('Carregando interpretador Python...');
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
