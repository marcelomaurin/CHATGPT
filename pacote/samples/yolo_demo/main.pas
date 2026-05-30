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
    FYolo: TYOLO;
    procedure LogMsg(const AMsg: string);
    procedure UpdateStatusUI;
  public

  end;

var
  frmYoloDemo: TfrmYoloDemo;

implementation

{$R *.lfm}

{ TfrmYoloDemo }

procedure TfrmYoloDemo.FormCreate(Sender: TObject);
begin
  FConnector := TPythonConnector.Create(Self);
  FYolo := TYOLO.Create(Self);
  FYolo.PythonConnector := FConnector;
  
  edDLLPath.Text := 'python3.dll';
  UpdateStatusUI;
  LogMsg('YOLOv8 Object Detection Demo iniciado.');
  LogMsg('Para começar, ative o Python e instale a dependência "ultralytics" se necessário.');
end;

procedure TfrmYoloDemo.FormDestroy(Sender: TObject);
begin
  // FConnector e FYolo são liberados pelo Owner (Self)
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
