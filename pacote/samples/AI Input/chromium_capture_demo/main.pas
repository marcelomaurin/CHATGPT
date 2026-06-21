unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aichromiumbrowser;

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
    FAIChromium: TAIChromiumBrowser; FEditURL: TEdit;
    procedure AddLog(const AMsg: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AddLog('Chromium Capture Demo (aichromiumbrowser) initialized.');
  FAIChromium := TAIChromiumBrowser.Create(Self);
  
  FEditURL := TEdit.Create(Self);
  FEditURL.Parent := pnlTop;
  FEditURL.Left := 15;
  FEditURL.Top := 115;
  FEditURL.Width := 300;
  FEditURL.Text := 'https://www.lazarus-ide.org';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
  FAIChromium.URL := FEditURL.Text;
  
  AddLog('Chromium Browser Properties:');
  AddLog('  URL: ' + FAIChromium.URL);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating browser ingestion & snapshot extraction...');
    AddLog('Connected to: ' + FAIChromium.URL);
    AddLog('Extracted Title: "Lazarus Homepage"');
    AddLog('Extracted text body length: 15234 characters.');
    AddLog('Simulated Page Read Success.');
  end
  else
  begin
    AddLog('Connecting to Chromium engine...');
    try
      FAIChromium.Navigate(FAIChromium.URL);
      AddLog('Loaded successfully.');
      AddLog('HTML: ' + Copy(FAIChromium.GetHtmlContent, 1, 200) + '...');
    except
      on E: Exception do AddLog('Exception: ' + E.Message);
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

end.
