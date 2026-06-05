unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Spin, Buttons, FileUtil, aiopencv, aibase;

type

  { TfrmOpenCVFilterDemo }

  TfrmOpenCVFilterDemo = class(TForm)
    pnlTop: TPanel;
    pnlParams: TPanel;
    pnlImages: TPanel;
    pnlStatus: TPanel;
    pnlLog: TPanel;
    
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
    lblOriginal: TLabel;
    lblProcessed: TLabel;
    lblLogText: TLabel;
    lblBackendText: TLabel;
    lblFilterText: TLabel;
    lblBlurKernel: TLabel;
    lblThresholdValue: TLabel;
    lblCannyT1: TLabel;
    lblCannyT2: TLabel;
    lblResizeWidth: TLabel;
    lblResizeHeight: TLabel;
    
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
    procedure ConfigureOpenCV;
    procedure ApplyFilterSelection;
    function GenerateOutputName(const AInputFile: string): string;
    procedure LoadOriginalImage(const AFileName: string);
    procedure LoadProcessedImage(const AFileName: string);
    procedure UpdateImageInfo;
  public

  end;

var
  frmOpenCVFilterDemo: TfrmOpenCVFilterDemo;

implementation

{$R *.lfm}

{ TfrmOpenCVFilterDemo }

procedure TfrmOpenCVFilterDemo.FormCreate(Sender: TObject);
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

  AIOpenCV1.Backend := ocvPythonProcess;
  AIOpenCV1.FilterType := ocvfGray;
  AIOpenCV1.AutoSave := True;
  AIOpenCV1.OverwriteOutput := True;

  lblStatus.Caption := 'Status: aguardando';
  lblImageInfo.Caption := 'Imagem: nenhuma';

  OpenDialog1.Filter := 'Images|*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff|All files|*.*';
  SaveDialog1.Filter := 'JPEG|*.jpg|PNG|*.png|BMP|*.bmp|All files|*.*';

  AddLog('Demo iniciado.');
end;

procedure TfrmOpenCVFilterDemo.btnLoadImageClick(Sender: TObject);
begin
  if not OpenDialog1.Execute then
    Exit;

  edInputFile.Text := OpenDialog1.FileName;
  edOutputFile.Text := GenerateOutputName(OpenDialog1.FileName);

  LoadOriginalImage(edInputFile.Text);

  ConfigureOpenCV;

  if AIOpenCV1.GetImageInfo(edInputFile.Text) then
  begin
    lblImageInfo.Caption :=
      Format('Imagem: %dx%d, canais: %d',
        [AIOpenCV1.LastImageWidth,
         AIOpenCV1.LastImageHeight,
         AIOpenCV1.LastChannels]);

    AddLog(lblImageInfo.Caption);
  end
  else
  begin
    lblImageInfo.Caption := 'Imagem: erro ao ler informações';
    AddLog('Erro ao ler imagem: ' + AIOpenCV1.LastError);
  end;
end;

procedure TfrmOpenCVFilterDemo.btnSelfTestClick(Sender: TObject);
begin
  ConfigureOpenCV;

  if AIOpenCV1.SelfTest then
  begin
    lblStatus.Caption := 'Status: OpenCV disponível';
    AddLog('SelfTest OK: ' + AIOpenCV1.LastResult);
    AddLog('Versão: ' + AIOpenCV1.Version);
  end
  else
  begin
    lblStatus.Caption := 'Status: erro no SelfTest';
    AddLog('SelfTest ERRO: ' + AIOpenCV1.LastError);
  end;
end;

procedure TfrmOpenCVFilterDemo.btnProcessClick(Sender: TObject);
begin
  ConfigureOpenCV;

  if edInputFile.Text = '' then
  begin
    AddLog('Selecione uma imagem de entrada.');
    Exit;
  end;

  if not FileExists(edInputFile.Text) then
  begin
    AddLog('Arquivo de entrada não encontrado.');
    Exit;
  end;

  if edOutputFile.Text = '' then
    edOutputFile.Text := GenerateOutputName(edInputFile.Text);

  if AIOpenCV1.ProcessFile(edInputFile.Text, edOutputFile.Text) then
  begin
    lblStatus.Caption := 'Status: imagem processada';
    AddLog('Processamento OK: ' + AIOpenCV1.LastResult);

    if FileExists(edOutputFile.Text) then
      LoadProcessedImage(edOutputFile.Text)
    else
      AddLog('Aviso: arquivo de saída não encontrado após processamento.');
  end
  else
  begin
    lblStatus.Caption := 'Status: erro no processamento';
    AddLog('Erro: ' + AIOpenCV1.LastError);
  end;
end;

procedure TfrmOpenCVFilterDemo.btnSaveClick(Sender: TObject);
begin
  if (edOutputFile.Text = '') or (not FileExists(edOutputFile.Text)) then
  begin
    AddLog('Nenhuma imagem processada para salvar.');
    Exit;
  end;

  if SaveDialog1.Execute then
  begin
    CopyFile(edOutputFile.Text, SaveDialog1.FileName);
    AddLog('Imagem salva em: ' + SaveDialog1.FileName);
  end;
end;

procedure TfrmOpenCVFilterDemo.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmOpenCVFilterDemo.cbFilterChange(Sender: TObject);
begin
  if edInputFile.Text <> '' then
    edOutputFile.Text := GenerateOutputName(edInputFile.Text);
end;

{ OpenCV Component Event Handlers }

procedure TfrmOpenCVFilterDemo.AIOpenCVBeforeProcess(Sender: TObject);
begin
  AddLog('Iniciando processamento...');
end;

procedure TfrmOpenCVFilterDemo.AIOpenCVAfterProcess(Sender: TObject);
begin
  AddLog('Processamento finalizado.');
end;

procedure TfrmOpenCVFilterDemo.AIOpenCVImageProcessed(Sender: TObject);
begin
  AddLog('Imagem processada pelo componente.');
end;

procedure TfrmOpenCVFilterDemo.AIOpenCVError(Sender: TObject; const AError: string);
begin
  AddLog('ERRO: ' + AError);
end;

procedure TfrmOpenCVFilterDemo.AIOpenCVLog(Sender: TObject; Level: TAILogLevel; const Message: string);
begin
  AddLog(Message);
end;

{ Métodos auxiliares do form }

procedure TfrmOpenCVFilterDemo.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMsg);
end;

procedure TfrmOpenCVFilterDemo.ConfigureOpenCV;
begin
  ApplyFilterSelection;

  case cbBackend.ItemIndex of
    0: AIOpenCV1.Backend := ocvPythonProcess;
    1: AIOpenCV1.Backend := ocvNativeDLL;
  end;

  AIOpenCV1.InputFile := edInputFile.Text;
  AIOpenCV1.OutputFile := edOutputFile.Text;

  AIOpenCV1.BlurKernelSize := seBlurKernel.Value;
  AIOpenCV1.ThresholdValue := seThresholdValue.Value;
  AIOpenCV1.CannyThreshold1 := seCanny1.Value;
  AIOpenCV1.CannyThreshold2 := seCanny2.Value;
  AIOpenCV1.ResizeWidth := seResizeWidth.Value;
  AIOpenCV1.ResizeHeight := seResizeHeight.Value;

  AIOpenCV1.AutoSave := True;
  AIOpenCV1.OverwriteOutput := True;
end;

procedure TfrmOpenCVFilterDemo.ApplyFilterSelection;
begin
  case cbFilter.ItemIndex of
    0: AIOpenCV1.FilterType := ocvfNone;
    1: AIOpenCV1.FilterType := ocvfGray;
    2: AIOpenCV1.FilterType := ocvfBlur;
    3: AIOpenCV1.FilterType := ocvfCanny;
    4: AIOpenCV1.FilterType := ocvfThreshold;
    5: AIOpenCV1.FilterType := ocvfResize;
  else
    AIOpenCV1.FilterType := ocvfGray;
  end;
end;

function TfrmOpenCVFilterDemo.GenerateOutputName(const AInputFile: string): string;
var
  DirName, BaseName, ExtName, FilterName: string;
begin
  DirName := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'output';

  if not DirectoryExists(DirName) then
    CreateDir(DirName);

  BaseName := ChangeFileExt(ExtractFileName(AInputFile), '');
  ExtName := ExtractFileExt(AInputFile);

  case cbFilter.ItemIndex of
    0: FilterName := 'none';
    1: FilterName := 'gray';
    2: FilterName := 'blur';
    3: FilterName := 'canny';
    4: FilterName := 'threshold';
    5: FilterName := 'resize';
  else
    FilterName := 'processed';
  end;

  Result := IncludeTrailingPathDelimiter(DirName) +
            BaseName + '_' + FilterName + ExtName;
end;

procedure TfrmOpenCVFilterDemo.LoadOriginalImage(const AFileName: string);
begin
  if FileExists(AFileName) then
  begin
    try
      imgOriginal.Picture.LoadFromFile(AFileName);
      AddLog('Imagem original carregada: ' + ExtractFileName(AFileName));
    except
      on E: Exception do
        AddLog('Erro ao carregar imagem original: ' + E.Message);
    end;
  end;
end;

procedure TfrmOpenCVFilterDemo.LoadProcessedImage(const AFileName: string);
begin
  if FileExists(AFileName) then
  begin
    try
      imgProcessed.Picture.LoadFromFile(AFileName);
      AddLog('Imagem processada carregada: ' + ExtractFileName(AFileName));
    except
      on E: Exception do
        AddLog('Erro ao carregar imagem processada: ' + E.Message);
    end;
  end;
end;

procedure TfrmOpenCVFilterDemo.UpdateImageInfo;
begin
  if FileExists(edInputFile.Text) then
  begin
    if AIOpenCV1.GetImageInfo(edInputFile.Text) then
    begin
      lblImageInfo.Caption :=
        Format('Imagem: %dx%d, canais: %d',
          [AIOpenCV1.LastImageWidth,
           AIOpenCV1.LastImageHeight,
           AIOpenCV1.LastChannels]);

      AddLog(lblImageInfo.Caption);
    end
    else
    begin
      lblImageInfo.Caption := 'Imagem: erro ao ler informações';
      AddLog('Erro ao ler imagem: ' + AIOpenCV1.LastError);
    end;
  end
  else
    lblImageInfo.Caption := 'Imagem: nenhuma';
end;

end.
