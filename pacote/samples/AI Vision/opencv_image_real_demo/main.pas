unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiopencv, aiframeprocessor, aiopencvruntime, aiplatform;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    chkSimulation: TCheckBox;
    btnRun: TButton;
    btnClearLog: TButton;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIOpenCV: TAIOpenCV; FFrameProc: TAIFrameProcessor; FEditFile: TEdit;
    procedure AddLog(const AMsg: string);
    procedure DetectOpenCVRuntime;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AddLog('Opencv Image Real Demo (aiopencv) initialized.');
  FAIOpenCV := TAIOpenCV.Create(Self);
  FFrameProc := TAIFrameProcessor.Create(Self);
  
  FEditFile := TEdit.Create(Self);
  FEditFile.Parent := pnlTop;
  FEditFile.Left := 15;
  FEditFile.Top := 115;
  FEditFile.Width := 300;
  FEditFile.Text := 'sample.jpg';

  DetectOpenCVRuntime;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
var
  LResolvedPath, LError, LLog: string;
  LNativeAvailable: Boolean;
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
    FFrameProc.Grayscale := True;
    FFrameProc.ScaleFactor := 1.0;
    
    // Check native library availability using the helper
    LNativeAvailable := AIFindOpenCVNativeLibrary('', '', True, LResolvedPath, LError, LLog);
    
    AddLog('OpenCV Real Image Demo Properties:');
    if LNativeAvailable then
      AddLog('  Resolved LibraryPath: ' + LResolvedPath)
    else
      AddLog('  Resolved LibraryPath: Not Found');
    AddLog('  Grayscale: ' + BoolToStr(FFrameProc.Grayscale, True));
    AddLog('  ScaleFactor: ' + FloatToStr(FFrameProc.ScaleFactor));
    
    if chkSimulation.Checked then
    begin
      AddLog('Simulating OpenCV script matrix operations...');
      AddLog('Loaded: ' + FEditFile.Text);
      AddLog('Applied Grayscale conversion filter.');
      AddLog('Resized frame matrix to 640x480 pixels.');
      AddLog('Saved processed frame: sample_processed.jpg');
      AddLog('Process complete (Simulated).');
    end
    else
    begin
      AddLog('Validating environment for OpenCV native runtime...');
      if LNativeAvailable then
      begin
        FAIOpenCV.Backend := ocvNativeDLL;
        FAIOpenCV.UseBundledRuntime := True;
        if FAIOpenCV.LoadLibraries then
        begin
          AddLog('OpenCV binaries loaded successfully.');
          if FAIOpenCV.ProcessFile(FEditFile.Text, 'sample_processed.jpg') then
            AddLog('Frame processed and saved successfully.')
          else
            AddLog('Error processing frame: ' + FAIOpenCV.LastError);
        end
        else
        begin
          AddLog('OpenCV load libraries failed: ' + FAIOpenCV.LastError);
          AddLog('Falling back to Python process backend...');
          FAIOpenCV.Backend := ocvPythonProcess;
          if FAIOpenCV.ProcessFile(FEditFile.Text, 'sample_processed.jpg') then
            AddLog('Frame processed via Python backend successfully.')
          else
            AddLog('Failed to process via Python fallback: ' + FAIOpenCV.LastError);
        end;
      end
      else
      begin
        AddLog('OpenCV native binaries not found. Falling back to Python backend...');
        FAIOpenCV.Backend := ocvPythonProcess;
        if FAIOpenCV.ProcessFile(FEditFile.Text, 'sample_processed.jpg') then
          AddLog('Frame processed via Python backend successfully.')
        else
          AddLog('Failed to process via Python fallback: ' + FAIOpenCV.LastError);
      end;
    end;
    lblStatus.Caption := 'Status: Completed Successfully';
  except
    on E: Exception do
    begin
      AddLog('Critical Error: ' + E.Message);
      lblStatus.Caption := 'Status: Execution Error';
    end;
  end;
  AddLog('--- Execution Finished ---');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
end;

procedure TfrmMain.DetectOpenCVRuntime;
var
  LResolvedPath, LError, LLog: string;
  LFound: Boolean;
begin
  AddLog('=== Detecção de Runtime OpenCV ===');
  AddLog('SO detectado: ' + AIOSName);
  AddLog('Arquitetura: ' + AIArchitectureName);
  AddLog('Pasta esperada do runtime: runtime/opencv/' + AIGetOpenCVPlatformFolder);
  
  LFound := AIFindOpenCVNativeLibrary('', '', True, LResolvedPath, LError, LLog);
  memoLog.Lines.Add(LLog);
  
  if LFound then
  begin
    AddLog('Sucesso: Runtime OpenCV nativo encontrado em: ' + LResolvedPath);
    AddLog('Backend nativo disponível.');
  end
  else
  begin
    AddLog('Aviso: Runtime OpenCV nativo não encontrado.');
    AddLog(LError);
    AddLog('Selecionando backend Python como fallback automático.');
  end;
end;

end.
