unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Spin, aiopencv, aibase;

type

  { TfrmOpenCVDemo }

  TfrmOpenCVDemo = class(TForm)
    pnlTop: TPanel;
    pnlImages: TPanel;
    pnlBottom: TPanel;
    
    imgOriginal: TImage;
    imgProcessed: TImage;
    
    btnLoadImage: TButton;
    btnSelfTest: TButton;
    btnProcess: TButton;
    btnSave: TButton;
    btnClearLog: TButton;
    
    cbFilter: TComboBox;
    cbBackend: TComboBox;
    
    lblInputFile: TLabel;
    lblOutputFile: TLabel;
    lblStatus: TLabel;
    lblImageInfo: TLabel;
    
    edInputFile: TEdit;
    edOutputFile: TEdit;
    
    seBlurKernel: TSpinEdit;
    seThresholdValue: TSpinEdit;
    seCanny1: TSpinEdit;
    seCanny2: TSpinEdit;
    seResizeWidth: TSpinEdit;
    seResizeHeight: TSpinEdit;
    
    chkAutoSave: TCheckBox;
    chkOverwrite: TCheckBox;
    
    memoLog: TMemo;
    
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure btnLoadImageClick(Sender: TObject);
    procedure btnSelfTestClick(Sender: TObject);
    procedure btnProcessClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure cbFilterChange(Sender: TObject);
    
    // OpenCV Component Event Handlers
    procedure AIOpenCVBeforeProcess(Sender: TObject);
    procedure AIOpenCVAfterProcess(Sender: TObject);
    procedure AIOpenCVImageProcessed(Sender: TObject);
    procedure AIOpenCVError(Sender: TObject; const AError: string);
    procedure AIOpenCVLog(Sender: TObject; Level: TAILogLevel; const Message: string);
    
  private
    AIOpenCV1: TAIOpenCV;
    
    procedure AddLog(const AMsg: string);
    procedure ConfiguraOpenCV;
    procedure AtualizaFiltroSelecionado;
    procedure AtualizaBackendSelecionado;
    procedure AtualizaParametros;
    procedure CarregaImagemOriginal(const AFileName: string);
    procedure CarregaImagemProcessada(const AFileName: string);
    function GeraNomeSaida(const AInputFile: string): string;
    procedure AtualizaInfoImagem;
  public

  end;

var
  frmOpenCVDemo: TfrmOpenCVDemo;

implementation

{$R *.lfm}

{ TfrmOpenCVDemo }

procedure TfrmOpenCVDemo.FormCreate(Sender: TObject);
begin
  AIOpenCV1 := TAIOpenCV.Create(Self);
  AIOpenCV1.OnBeforeProcess := @AIOpenCVBeforeProcess;
  AIOpenCV1.OnAfterProcess := @AIOpenCVAfterProcess;
  AIOpenCV1.OnImageProcessed := @AIOpenCVImageProcessed;
  AIOpenCV1.OnOpenCVError := @AIOpenCVError;
  AIOpenCV1.OnLog := @AIOpenCVLog;

  Caption := 'TAIOpenCV Filter Demo';

  cbBackend.Items.Clear;
  cbBackend.Items.Add('Python Process');
  cbBackend.Items.Add('Native DLL');
  cbBackend.ItemIndex := 0; // Default to Python Process

  cbFilter.Items.Clear;
  cbFilter.Items.Add('None');
  cbFilter.Items.Add('Gray');
  cbFilter.Items.Add('Blur');
  cbFilter.Items.Add('Canny');
  cbFilter.Items.Add('Threshold');
  cbFilter.Items.Add('Resize');
  cbFilter.ItemIndex := 1; // Default to Gray

  seBlurKernel.Value := 5;
  seThresholdValue.Value := 127;
  seCanny1.Value := 100;
  seCanny2.Value := 200;
  seResizeWidth.Value := 640;
  seResizeHeight.Value := 480;

  chkAutoSave.Checked := True;
  chkOverwrite.Checked := True;

  OpenDialog1.Filter := 'Images|*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff|All files|*.*';
  SaveDialog1.Filter := 'JPEG|*.jpg|PNG|*.png|BMP|*.bmp';

  lblStatus.Caption := 'Status: aguardando';
  lblImageInfo.Caption := 'Image: none';

  AddLog('Demo iniciado.');
end;

procedure TfrmOpenCVDemo.btnLoadImageClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    edInputFile.Text := OpenDialog1.FileName;
    CarregaImagemOriginal(OpenDialog1.FileName);
    
    // Sugerir output file
    edOutputFile.Text := GeraNomeSaida(OpenDialog1.FileName);
    
    // Configura e puxa informações da imagem
    ConfiguraOpenCV;
    AtualizaInfoImagem;
  end;
end;

procedure TfrmOpenCVDemo.btnSelfTestClick(Sender: TObject);
begin
  ConfiguraOpenCV;

  if AIOpenCV1.SelfTest then
  begin
    lblStatus.Caption := 'Status: OpenCV disponível';
    AddLog('SelfTest OK: ' + AIOpenCV1.LastResult);
  end
  else
  begin
    lblStatus.Caption := 'Status: erro';
    AddLog('SelfTest ERRO: ' + AIOpenCV1.LastError);
  end;
end;

procedure TfrmOpenCVDemo.btnProcessClick(Sender: TObject);
begin
  ConfiguraOpenCV;

  if not FileExists(edInputFile.Text) then
  begin
    AddLog('Arquivo de entrada não encontrado.');
    Exit;
  end;

  if AIOpenCV1.ProcessFile(edInputFile.Text, edOutputFile.Text) then
  begin
    AddLog('Processamento concluído.');
    CarregaImagemProcessada(edOutputFile.Text);
    lblStatus.Caption := 'Status: imagem processada';
  end
  else
  begin
    AddLog('Erro: ' + AIOpenCV1.LastError);
    lblStatus.Caption := 'Status: erro no processamento';
  end;
end;

procedure TfrmOpenCVDemo.btnSaveClick(Sender: TObject);
var
  SourceStream, DestStream: TFileStream;
begin
  if not FileExists(edOutputFile.Text) then
  begin
    AddLog('Nenhuma imagem processada para salvar.');
    Exit;
  end;
  
  SaveDialog1.FileName := edOutputFile.Text;
  if SaveDialog1.Execute then
  begin
    try
      SourceStream := TFileStream.Create(edOutputFile.Text, fmOpenRead or fmShareDenyWrite);
      try
        DestStream := TFileStream.Create(SaveDialog1.FileName, fmCreate);
        try
          DestStream.CopyFrom(SourceStream, SourceStream.Size);
          AddLog('Imagem salva com sucesso: ' + SaveDialog1.FileName);
        finally
          DestStream.Free;
        end;
      finally
        SourceStream.Free;
      end;
    except
      on E: Exception do
        AddLog('Erro ao salvar imagem: ' + E.Message);
    end;
  end;
end;

procedure TfrmOpenCVDemo.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmOpenCVDemo.cbFilterChange(Sender: TObject);
begin
  if edInputFile.Text <> '' then
    edOutputFile.Text := GeraNomeSaida(edInputFile.Text);
end;

{ OpenCV Component Event Handlers }

procedure TfrmOpenCVDemo.AIOpenCVBeforeProcess(Sender: TObject);
begin
  AddLog('Iniciando processamento...');
end;

procedure TfrmOpenCVDemo.AIOpenCVAfterProcess(Sender: TObject);
begin
  AddLog('Processamento finalizado.');
end;

procedure TfrmOpenCVDemo.AIOpenCVImageProcessed(Sender: TObject);
begin
  AddLog('Imagem processada e salva com sucesso.');
end;

procedure TfrmOpenCVDemo.AIOpenCVError(Sender: TObject; const AError: string);
begin
  AddLog('ERRO: ' + AError);
end;

procedure TfrmOpenCVDemo.AIOpenCVLog(Sender: TObject; Level: TAILogLevel; const Message: string);
begin
  AddLog(Message);
end;

{ Métodos auxiliares do form }

procedure TfrmOpenCVDemo.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMsg);
end;

procedure TfrmOpenCVDemo.ConfiguraOpenCV;
begin
  AtualizaBackendSelecionado;
  AtualizaFiltroSelecionado;
  AtualizaParametros;

  AIOpenCV1.InputFile := edInputFile.Text;
  AIOpenCV1.OutputFile := edOutputFile.Text;
  AIOpenCV1.AutoSave := chkAutoSave.Checked;
  AIOpenCV1.OverwriteOutput := chkOverwrite.Checked;
end;

procedure TfrmOpenCVDemo.AtualizaFiltroSelecionado;
begin
  case cbFilter.ItemIndex of
    0: AIOpenCV1.FilterType := ocvfNone;
    1: AIOpenCV1.FilterType := ocvfGray;
    2: AIOpenCV1.FilterType := ocvfBlur;
    3: AIOpenCV1.FilterType := ocvfCanny;
    4: AIOpenCV1.FilterType := ocvfThreshold;
    5: AIOpenCV1.FilterType := ocvfResize;
  end;
end;

procedure TfrmOpenCVDemo.AtualizaBackendSelecionado;
begin
  case cbBackend.ItemIndex of
    0: AIOpenCV1.Backend := ocvPythonProcess;
    1: AIOpenCV1.Backend := ocvNativeDLL;
  end;
end;

procedure TfrmOpenCVDemo.AtualizaParametros;
begin
  AIOpenCV1.BlurKernelSize := seBlurKernel.Value;
  AIOpenCV1.ThresholdValue := seThresholdValue.Value;
  AIOpenCV1.CannyThreshold1 := seCanny1.Value;
  AIOpenCV1.CannyThreshold2 := seCanny2.Value;
  AIOpenCV1.ResizeWidth := seResizeWidth.Value;
  AIOpenCV1.ResizeHeight := seResizeHeight.Value;
end;

procedure TfrmOpenCVDemo.CarregaImagemOriginal(const AFileName: string);
begin
  if FileExists(AFileName) then
  begin
    try
      imgOriginal.Picture.LoadFromFile(AFileName);
      AddLog('Imagem original exibida: ' + ExtractFileName(AFileName));
    except
      on E: Exception do
        AddLog('Erro ao exibir imagem original: ' + E.Message);
    end;
  end;
end;

procedure TfrmOpenCVDemo.CarregaImagemProcessada(const AFileName: string);
begin
  if FileExists(AFileName) then
  begin
    try
      imgProcessed.Picture.LoadFromFile(AFileName);
      AddLog('Imagem processada exibida: ' + ExtractFileName(AFileName));
    except
      on E: Exception do
        AddLog('Erro ao exibir imagem processada: ' + E.Message);
    end;
  end;
end;

function TfrmOpenCVDemo.GeraNomeSaida(const AInputFile: string): string;
var
  Dir, Name, Ext: string;
  FilterName: string;
begin
  Dir := ExtractFilePath(AInputFile);
  Name := ChangeFileExt(ExtractFileName(AInputFile), '');
  Ext := ExtractFileExt(AInputFile);
  
  case cbFilter.ItemIndex of
    0: FilterName := 'none';
    1: FilterName := 'gray';
    2: FilterName := 'blur';
    3: FilterName := 'canny';
    4: FilterName := 'threshold';
    5: FilterName := 'resize';
    else FilterName := 'output';
  end;
  
  Result := Dir + Name + '_' + FilterName + Ext;
end;

procedure TfrmOpenCVDemo.AtualizaInfoImagem;
begin
  if FileExists(edInputFile.Text) then
  begin
    if AIOpenCV1.GetImageInfo(edInputFile.Text) then
    begin
      lblImageInfo.Caption := Format('Image: %dx%d, channels: %d', 
        [AIOpenCV1.LastImageWidth, AIOpenCV1.LastImageHeight, AIOpenCV1.LastChannels]);
    end
    else
      lblImageInfo.Caption := 'Image: error reading info';
  end
  else
    lblImageInfo.Caption := 'Image: none';
end;

end.
