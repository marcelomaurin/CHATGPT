unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Buttons, aibase, aichromiumbrowser;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;

    edURL: TEdit;
    btnInitialize: TButton;
    btnNavigate: TButton;
    btnBack: TButton;
    btnForward: TButton;
    btnReload: TButton;
    btnClearLog: TButton;

    PageControl1: TPageControl;
    tsBrowser: TTabSheet;
    tsAutomation: TTabSheet;
    tsHTML: TTabSheet;
    tsLog: TTabSheet;

    AIChromiumBrowser1: TAIChromiumBrowser;

    edSelector: TEdit;
    edValue: TEdit;
    btnWaitSelector: TButton;
    btnClick: TButton;
    btnSetValue: TButton;
    btnExecuteJS: TButton;
    btnGetHTML: TButton;
    btnScreenshot: TButton;

    memoJS: TMemo;
    memoHTML: TMemo;
    memoLog: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnInitializeClick(Sender: TObject);
    procedure btnNavigateClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnForwardClick(Sender: TObject);
    procedure btnReloadClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnWaitSelectorClick(Sender: TObject);
    procedure btnClickClick(Sender: TObject);
    procedure btnSetValueClick(Sender: TObject);
    procedure btnExecuteJSClick(Sender: TObject);
    procedure btnGetHTMLClick(Sender: TObject);
    procedure btnScreenshotClick(Sender: TObject);
  private
    procedure AddLog(const AMsg: string);
    procedure ShowComponentState;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Caption := 'Chromium Capture Demo - CEF4Delphi TChromiumWindow';
  lblTitle.Caption := 'Chromium Capture Demo - TAIChromiumBrowser + TChromiumWindow';
  lblStatus.Caption := 'Status: Ready';

  edURL.Text := 'https://www.lazarus-ide.org';
  edSelector.Text := 'body';
  edValue.Text := 'Marcelo';

  memoJS.Text :=
    'document.body.style.outline = "5px solid red";' + LineEnding +
    'console.log("TAIChromiumBrowser JavaScript test executed");';

  AddLog('Demo initialized.');
  AddLog('This demo uses TAIChromiumBrowser based on CEF4Delphi TChromiumWindow.');
  AddLog('Click Initialize before Navigate if AutoCreateBrowser is disabled.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  //
end;

procedure TfrmMain.btnInitializeClick(Sender: TObject);
begin
  AddLog('Initializing Chromium...');
  if AIChromiumBrowser1.InitializeBrowser then
  begin
    AddLog('Browser creation requested.');
    lblStatus.Caption := 'Status: Browser initialization requested';
  end
  else
  begin
    AddLog('Error: ' + AIChromiumBrowser1.LastError);
    lblStatus.Caption := 'Status: Error';
  end;
end;

procedure TfrmMain.btnNavigateClick(Sender: TObject);
begin
  AddLog('Navigate: ' + edURL.Text);

  try
    AIChromiumBrowser1.Navigate(edURL.Text);

    if AIChromiumBrowser1.LastError <> '' then
      AddLog('Error: ' + AIChromiumBrowser1.LastError)
    else
      AddLog('Navigation requested.');

    ShowComponentState;
  except
    on E: Exception do
      AddLog('Exception: ' + E.Message);
  end;
end;

procedure TfrmMain.btnBackClick(Sender: TObject);
begin
  AddLog('Back');
  AIChromiumBrowser1.GoBack;
  ShowComponentState;
end;

procedure TfrmMain.btnForwardClick(Sender: TObject);
begin
  AddLog('Forward');
  AIChromiumBrowser1.GoForward;
  ShowComponentState;
end;

procedure TfrmMain.btnReloadClick(Sender: TObject);
begin
  AddLog('Reload');
  AIChromiumBrowser1.Reload;
  ShowComponentState;
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.btnWaitSelectorClick(Sender: TObject);
begin
  AddLog('WaitForSelector: ' + edSelector.Text);

  if AIChromiumBrowser1.WaitForSelector(edSelector.Text, 10000) then
    AddLog('Selector found.')
  else
    AddLog('Selector not found: ' + AIChromiumBrowser1.LastError);

  ShowComponentState;
end;

procedure TfrmMain.btnClickClick(Sender: TObject);
begin
  AddLog('Click: ' + edSelector.Text);

  if AIChromiumBrowser1.Click(edSelector.Text) then
    AddLog('Click script executed.')
  else
    AddLog('Click error: ' + AIChromiumBrowser1.LastError);

  ShowComponentState;
end;

procedure TfrmMain.btnSetValueClick(Sender: TObject);
begin
  AddLog('SetValue: ' + edSelector.Text + ' = ' + edValue.Text);

  if AIChromiumBrowser1.SetValue(edSelector.Text, edValue.Text) then
    AddLog('SetValue script executed.')
  else
    AddLog('SetValue error: ' + AIChromiumBrowser1.LastError);

  ShowComponentState;
end;

procedure TfrmMain.btnExecuteJSClick(Sender: TObject);
begin
  AddLog('Executing JavaScript...');

  if AIChromiumBrowser1.ExecuteJavaScript(memoJS.Text) then
    AddLog('JavaScript executed.')
  else
    AddLog('JavaScript error: ' + AIChromiumBrowser1.LastError);

  ShowComponentState;
end;

procedure TfrmMain.btnGetHTMLClick(Sender: TObject);
var
  vHTML: string;
begin
  AddLog('Getting HTML content...');

  vHTML := AIChromiumBrowser1.GetHtmlContent;
  memoHTML.Text := vHTML;

  if AIChromiumBrowser1.LastError <> '' then
    AddLog('GetHTML warning/error: ' + AIChromiumBrowser1.LastError)
  else
    AddLog('HTML length: ' + IntToStr(Length(vHTML)));

  ShowComponentState;
end;

procedure TfrmMain.btnScreenshotClick(Sender: TObject);
var
  vFileName: string;
begin
  vFileName := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) +
               'chromium_capture_demo_screenshot.png';

  AddLog('Screenshot: ' + vFileName);

  if AIChromiumBrowser1.Screenshot(vFileName) then
    AddLog('Screenshot saved.')
  else
    AddLog('Screenshot error: ' + AIChromiumBrowser1.LastError);

  ShowComponentState;
end;

procedure TfrmMain.ShowComponentState;
begin
  lblStatus.Caption :=
    'Status: Ready=' + BoolToStr(AIChromiumBrowser1.BrowserReady, True) +
    ' URL=' + AIChromiumBrowser1.URL;

  if AIChromiumBrowser1.LastResult <> '' then
    AddLog('LastResult: ' + AIChromiumBrowser1.LastResult);

  if AIChromiumBrowser1.LastError <> '' then
    AddLog('LastError: ' + AIChromiumBrowser1.LastError);
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
end;

end.
