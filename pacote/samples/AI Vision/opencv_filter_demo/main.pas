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
    procedure AIOpenCVImageLoaded(Sender: TObject);
    procedure AIOpenCVImageSaved(Sender: TObject);
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
  AIOpenCV1.OnImageLoaded := @AIOpenCVImageLoaded;
  AIOpenCV1.OnImageSaved := @AIOpenCVImageSaved;
  AIOpenCV1.OnOpenCVError := @AIOpenCVError;
  AIOpenCV1.OnLog := @AIOpenCVLog;

  Caption := 'TAIOpenCV Filter Demo';

  cbBackend.Items.Clear;
  cbBackend.Items.Add('Auto');
  cbBackend.Items.Add('Native DLL');
  cbBackend.Items.Add('Python Process');
  cbBackend.ItemIndex := 2; // Default to Python Process

  cbFilter.Items.Clear;
  cbFilter.Items.Add('None');
  cbFilter.Items.Add('Gray');
  cbFilter.Items.Add('Blur');
  cbFilter.Items.Add('Gaussian Blur');
  cbFilter.Items.Add('Median Blur');
  cbFilter.Items.Add('Canny');
  cbFilter.Items.Add('Threshold');
  cbFilter.Items.Add('Adaptive Threshold');
  cbFilter.Items.Add('Sharpen');
  cbFilter.Items.Add('Invert');
  cbFilter.Items.Add('Erode');
  cbFilter.Items.Add('Dilate');
  cbFilter.Items.Add('Resize');
  cbFilter.Items.Add('Normalize');
  cbFilter.Items.Add('Equalize Histogram');
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
begin
  if not FileExists(edOutputFile.Text) then
  begin
    AddLog('Nenhuma imagem processada para salvar.');
    Exit;
  end;
  
  SaveDialog1.FileName := edOutputFile.Text;
  if SaveDialog1.Execute then
  begin
    if AIOpenCV1.SaveImage(SaveDialog1.FileName) then
    begin
      AddLog('Imagem salva com sucesso: ' + SaveDialog1.FileName);
    end
    else
    begin
      AddLog('Erro ao salvar imagem: ' + AIOpenCV1.LastError);
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

procedure TfrmOpenCVDemo.AIOpenCVImageLoaded(Sender: TObject);
begin
  AddLog('Imagem carregada.');
end;

procedure TfrmOpenCVDemo.AIOpenCVImageSaved(Sender: TObject);
begin
  AddLog('Imagem salva.');
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
    3: AIOpenCV1.FilterType := ocvfGaussianBlur;
    4: AIOpenCV1.FilterType := ocvfMedianBlur;
    5: AIOpenCV1.FilterType := ocvfCanny;
    6: AIOpenCV1.FilterType := ocvfThreshold;
    7: AIOpenCV1.FilterType := ocvfAdaptiveThreshold;
    8: AIOpenCV1.FilterType := ocvfSharpen;
    9: AIOpenCV1.FilterType := ocvfInvert;
    10: AIOpenCV1.FilterType := ocvfErode;
    11: AIOpenCV1.FilterType := ocvfDilate;
    12: AIOpenCV1.FilterType := ocvfResize;
    13: AIOpenCV1.FilterType := ocvfNormalize;
    14: AIOpenCV1.FilterType := ocvfEqualizeHistogram;
  end;
end;

procedure TfrmOpenCVDemo.AtualizaBackendSelecionado;
begin
  case cbBackend.ItemIndex of
    0: AIOpenCV1.Backend := ocvAuto;
    1: AIOpenCV1.Backend := ocvNativeDLL;
    2: AIOpenCV1.Backend := ocvPythonProcess;
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
    3: FilterName := 'gaussian_blur';
    4: FilterName := 'median_blur';
    5: FilterName := 'canny';
    6: FilterName := 'threshold';
    7: FilterName := 'adaptive_threshold';
    8: FilterName := 'sharpen';
    9: FilterName := 'invert';
    10: FilterName := 'erode';
    11: FilterName := 'dilate';
    12: FilterName := 'resize';
    13: FilterName := 'normalize';
    14: FilterName := 'equalize';
    else FilterName := 'output';
  end;
  
  Result := Dir + Name + '_' + FilterName + Ext;
end;

procedure TfrmOpenCVDemo.AtualizaInfoImagem;
var
  Info: string;
begin
  if FileExists(edInputFile.Text) then
  begin
    Info := AIOpenCV1.GetImageInfo(edInputFile.Text);
    lblImageInfo.Caption := 'Image: ' + Info;
  end
  else
    lblImageInfo.Caption := 'Image: none';
end;

end.
