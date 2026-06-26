unit aichromiumbrowser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons,
  Graphics, LCLIntf, LCLType, LResources,
  uCEFChromiumWindow, uCEFChromium, uCEFInterfaces, uCEFTypes;

type
  { TAIChromiumBrowser }

  TAIChromiumBrowser = class(TPanel)
  private
    FPrompt: string;
    FURL: string;
    FHTML: string;
    FShowAddressBar: Boolean;
    FLastError: string;
    FLastResult: string;
    FBrowserReady: Boolean;
    FDefaultTimeoutMs: Integer;
    FPendingURL: string;

    // Address Bar UI Controls
    FAddressPanel: TPanel;
    FEditURL: TEdit;
    FBtnGo: TSpeedButton;
    FBtnBack: TSpeedButton;
    FBtnForward: TSpeedButton;
    FBtnReload: TSpeedButton;

    // CEF4Delphi Browser Window
    FChromiumWindow: TChromiumWindow;
    FHistory: TStringList;
    FHistoryIdx: Integer;

    procedure SetURL(const AValue: string);
    procedure SetShowAddressBar(AValue: Boolean);
    
    procedure CreateChromiumWindow;
    procedure ChromiumAfterCreated(Sender: TObject);
    procedure ChromiumBeforeClose(Sender: TObject);
    procedure ChromiumClose(Sender: TObject);

    procedure ClearError;
    procedure SetError(const AMsg: string);
    function EscapeJSString(const S: string): string;

    // Event Handlers
    procedure BtnGoClick(Sender: TObject);
    procedure BtnBackClick(Sender: TObject);
    procedure BtnForwardClick(Sender: TObject);
    procedure BtnReloadClick(Sender: TObject);
    procedure EditURLKeyPress(Sender: TObject; var Key: Char);
  protected
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Navigate(const AURL: string);
    procedure GoBack;
    procedure GoForward;
    procedure Reload;
    function GetHtmlContent: string;

    function InitializeBrowser: Boolean;
    function ExecuteJavaScript(const AScript: string): Boolean;
    function WaitForSelector(const ASelector: string; ATimeoutMs: Integer = 0): Boolean;
    function Click(const ASelector: string): Boolean;
    function SetValue(const ASelector, AValue: string): Boolean;
    function GoogleSearch(const AText: string): Boolean;
    function Screenshot(const AFileName: string): Boolean;
    procedure CloseBrowser;

  published
    property Prompt: string read FPrompt write FPrompt;
    property URL: string read FURL write SetURL;
    property HTML: string read FHTML write FHTML;
    property ShowAddressBar: Boolean read FShowAddressBar write SetShowAddressBar default True;

    property LastError: string read FLastError;
    property LastResult: string read FLastResult;
    property BrowserReady: Boolean read FBrowserReady;
    property DefaultTimeoutMs: Integer read FDefaultTimeoutMs write FDefaultTimeoutMs default 30000;

    // Standard panel properties exposed for styling
    property Align;
    property Anchors;
    property BorderStyle;
    property BorderWidth;
    property Color;
    property DoubleBuffered;
    property ParentColor;
    property Visible;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Communication', [TAIChromiumBrowser]);
end;

{ TAIChromiumBrowser }

constructor TAIChromiumBrowser.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIChromiumBrowser is an embedded Chromium browser based on CEF4Delphi TChromiumWindow. ' +
             'It can navigate real web pages, execute JavaScript, capture DOM HTML, click elements, fill fields, ' +
             'wait for selectors and support web application validation workflows.';
  Caption := '';
  FShowAddressBar := True;
  FHistory := TStringList.Create;
  FHistoryIdx := -1;
  FDefaultTimeoutMs := 30000;
  
  // Set default dimensions
  Width := 600;
  Height := 400;

  // 1. Create Address Bar panel
  FAddressPanel := TPanel.Create(Self);
  FAddressPanel.Parent := Self;
  FAddressPanel.Align := alTop;
  FAddressPanel.Height := 38;
  FAddressPanel.Caption := '';
  FAddressPanel.BevelOuter := bvNone;
  FAddressPanel.Color := $F4F4F4;

  // 2. Back Button
  FBtnBack := TSpeedButton.Create(Self);
  FBtnBack.Parent := FAddressPanel;
  FBtnBack.Caption := '<';
  FBtnBack.Width := 28;
  FBtnBack.Height := 28;
  FBtnBack.Top := 5;
  FBtnBack.Left := 5;
  FBtnBack.OnClick := @BtnBackClick;
  FBtnBack.Flat := True;

  // 3. Forward Button
  FBtnForward := TSpeedButton.Create(Self);
  FBtnForward.Parent := FAddressPanel;
  FBtnForward.Caption := '>';
  FBtnForward.Width := 28;
  FBtnForward.Height := 28;
  FBtnForward.Top := 5;
  FBtnForward.Left := FBtnBack.Left + FBtnBack.Width + 2;
  FBtnForward.OnClick := @BtnForwardClick;
  FBtnForward.Flat := True;

  // 4. Reload Button
  FBtnReload := TSpeedButton.Create(Self);
  FBtnReload.Parent := FAddressPanel;
  FBtnReload.Caption := '⟳';
  FBtnReload.Width := 28;
  FBtnReload.Height := 28;
  FBtnReload.Top := 5;
  FBtnReload.Left := FBtnForward.Left + FBtnForward.Width + 2;
  FBtnReload.OnClick := @BtnReloadClick;
  FBtnReload.Flat := True;

  // 5. Go Button
  FBtnGo := TSpeedButton.Create(Self);
  FBtnGo.Parent := FAddressPanel;
  FBtnGo.Caption := 'Ir';
  FBtnGo.Width := 40;
  FBtnGo.Height := 28;
  FBtnGo.Top := 5;
  FBtnGo.OnClick := @BtnGoClick;
  FBtnGo.Flat := True;

  // 6. URL Edit Box
  FEditURL := TEdit.Create(Self);
  FEditURL.Parent := FAddressPanel;
  FEditURL.Text := 'https://www.google.com';
  FEditURL.Top := 5;
  FEditURL.Height := 28;
  FEditURL.OnKeyPress := @EditURLKeyPress;
  
  // Place controls correctly
  Resize;

  if not (csDesigning in ComponentState) then
    CreateChromiumWindow;
end;

destructor TAIChromiumBrowser.Destroy;
begin
  FHistory.Free;
  inherited Destroy;
end;

procedure TAIChromiumBrowser.Resize;
begin
  inherited Resize;
  if FAddressPanel <> nil then
  begin
    FBtnGo.Left := FAddressPanel.Width - FBtnGo.Width - 8;
    FEditURL.Left := FBtnReload.Left + FBtnReload.Width + 8;
    FEditURL.Width := FBtnGo.Left - FEditURL.Left - 8;
  end;
end;

procedure TAIChromiumBrowser.CreateChromiumWindow;
begin
  if Assigned(FChromiumWindow) then
    Exit;

  FChromiumWindow := TChromiumWindow.Create(Self);
  FChromiumWindow.Parent := Self;
  FChromiumWindow.Align := alClient;

  FChromiumWindow.OnAfterCreated := @ChromiumAfterCreated;
  FChromiumWindow.OnBeforeClose := @ChromiumBeforeClose;
  FChromiumWindow.OnClose := @ChromiumClose;
end;

procedure TAIChromiumBrowser.ChromiumAfterCreated(Sender: TObject);
begin
  FBrowserReady := True;
  FLastResult := 'Chromium browser initialized.';
  if FPendingURL <> '' then
  begin
    FChromiumWindow.LoadURL(FPendingURL);
    FPendingURL := '';
  end;
end;

procedure TAIChromiumBrowser.ChromiumBeforeClose(Sender: TObject);
begin
  FBrowserReady := False;
end;

procedure TAIChromiumBrowser.ChromiumClose(Sender: TObject);
begin
  // Handled by ChromiumBeforeClose usually, cleanups if any
end;

procedure TAIChromiumBrowser.ClearError;
begin
  FLastError := '';
  FLastResult := '';
end;

procedure TAIChromiumBrowser.SetError(const AMsg: string);
begin
  FLastError := AMsg;
end;

function TAIChromiumBrowser.EscapeJSString(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    case S[I] of
      '\': Result := Result + '\\';
      '"': Result := Result + '\"';
      '''': Result := Result + '\''';
      #13: Result := Result + '\r';
      #10: Result := Result + '\n';
      #9:  Result := Result + '\t';
    else
      Result := Result + S[I];
    end;
  end;
end;

function TAIChromiumBrowser.InitializeBrowser: Boolean;
begin
  Result := False;
  ClearError;

  if csDesigning in ComponentState then
  begin
    SetError('Chromium browser cannot be initialized at design-time.');
    Exit;
  end;

  CreateChromiumWindow;

  if FChromiumWindow.Initialized then
  begin
    FBrowserReady := True;
    Result := True;
    Exit;
  end;

  Result := FChromiumWindow.CreateBrowser;
  if not Result then
    SetError('TChromiumWindow.CreateBrowser failed.')
  else
    FLastResult := 'Browser creation requested.';
end;

procedure TAIChromiumBrowser.SetURL(const AValue: string);
begin
  if FURL <> AValue then
  begin
    FURL := AValue;
    if not (csDesigning in ComponentState) then
      Navigate(FURL);
  end;
end;

procedure TAIChromiumBrowser.SetShowAddressBar(AValue: Boolean);
begin
  if FShowAddressBar <> AValue then
  begin
    FShowAddressBar := AValue;
    if Assigned(FAddressPanel) then
      FAddressPanel.Visible := FShowAddressBar;
  end;
end;

procedure TAIChromiumBrowser.BtnGoClick(Sender: TObject);
begin
  Navigate(FEditURL.Text);
end;

procedure TAIChromiumBrowser.BtnBackClick(Sender: TObject);
begin
  GoBack;
end;

procedure TAIChromiumBrowser.BtnForwardClick(Sender: TObject);
begin
  GoForward;
end;

procedure TAIChromiumBrowser.BtnReloadClick(Sender: TObject);
begin
  Reload;
end;

procedure TAIChromiumBrowser.EditURLKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    Navigate(FEditURL.Text);
  end;
end;

procedure TAIChromiumBrowser.Navigate(const AURL: string);
var
  SafeURL: string;
begin
  SafeURL := Trim(AURL);
  if SafeURL = '' then Exit;

  if (Pos('http://', LowerCase(SafeURL)) <> 1) and (Pos('https://', LowerCase(SafeURL)) <> 1) then
    SafeURL := 'https://' + SafeURL;

  FURL := SafeURL;
  if FEditURL.Text <> FURL then
    FEditURL.Text := FURL;

  if (FHistory.Count = 0) or (FHistory[FHistory.Count - 1] <> FURL) then
  begin
    FHistory.Add(FURL);
    FHistoryIdx := FHistory.Count - 1;
  end;

  if not Assigned(FChromiumWindow) or not FChromiumWindow.Initialized then
  begin
    FPendingURL := SafeURL;
    InitializeBrowser;
    Exit;
  end;

  if FBrowserReady then
    FChromiumWindow.LoadURL(SafeURL)
  else
    FPendingURL := SafeURL;
end;

procedure TAIChromiumBrowser.GoBack;
begin
  if Assigned(FChromiumWindow) and FChromiumWindow.Initialized then
  begin
    if FChromiumWindow.ChromiumBrowser.CanGoBack then
      FChromiumWindow.ChromiumBrowser.GoBack
    else if (FHistory.Count > 0) and (FHistoryIdx > 0) then
    begin
      Dec(FHistoryIdx);
      Navigate(FHistory[FHistoryIdx]);
    end;
  end
  else if (FHistory.Count > 0) and (FHistoryIdx > 0) then
  begin
    Dec(FHistoryIdx);
    Navigate(FHistory[FHistoryIdx]);
  end;
end;

procedure TAIChromiumBrowser.GoForward;
begin
  if Assigned(FChromiumWindow) and FChromiumWindow.Initialized then
  begin
    if FChromiumWindow.ChromiumBrowser.CanGoForward then
      FChromiumWindow.ChromiumBrowser.GoForward
    else if (FHistory.Count > 0) and (FHistoryIdx < FHistory.Count - 1) then
    begin
      Inc(FHistoryIdx);
      Navigate(FHistory[FHistoryIdx]);
    end;
  end
  else if (FHistory.Count > 0) and (FHistoryIdx < FHistory.Count - 1) then
  begin
    Inc(FHistoryIdx);
    Navigate(FHistory[FHistoryIdx]);
  end;
end;

procedure TAIChromiumBrowser.Reload;
begin
  if Assigned(FChromiumWindow) and FChromiumWindow.Initialized then
    FChromiumWindow.ChromiumBrowser.Reload
  else
    Navigate(FURL);
end;

function TAIChromiumBrowser.ExecuteJavaScript(const AScript: string): Boolean;
begin
  Result := False;
  ClearError;
  if not FBrowserReady or not Assigned(FChromiumWindow) or not FChromiumWindow.Initialized then
  begin
    SetError('Browser is not ready to execute JavaScript.');
    Exit;
  end;
  if Trim(AScript) = '' then
  begin
    SetError('Script is empty.');
    Exit;
  end;

  FChromiumWindow.ChromiumBrowser.ExecuteJavaScript(
    AScript,
    FChromiumWindow.ChromiumBrowser.DefaultUrl,
    0
  );
  FLastResult := 'JavaScript executed.';
  Result := True;
end;

function TAIChromiumBrowser.Click(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript := '(function() { ' +
              '  var el = document.querySelector("' + EscapeJSString(ASelector) + '"); ' +
              '  if (!el) { return false; } ' +
              '  el.scrollIntoView({block: "center", inline: "center"}); ' +
              '  el.click(); ' +
              '  return true; ' +
              '})();';
  Result := ExecuteJavaScript(JSScript);
end;

function TAIChromiumBrowser.SetValue(const ASelector, AValue: string): Boolean;
var
  JSScript: string;
begin
  JSScript := '(function() { ' +
              '  var el = document.querySelector("' + EscapeJSString(ASelector) + '"); ' +
              '  if (!el) { return false; } ' +
              '  el.focus(); ' +
              '  el.value = "' + EscapeJSString(AValue) + '"; ' +
              '  el.dispatchEvent(new Event("input", { bubbles: true })); ' +
              '  el.dispatchEvent(new Event("change", { bubbles: true })); ' +
              '  return true; ' +
              '})();';
  Result := ExecuteJavaScript(JSScript);
end;

function TAIChromiumBrowser.GoogleSearch(const AText: string): Boolean;
var
  JSScript: string;
begin
  Result := False;
  ClearError;

  if Trim(AText) = '' then
  begin
    SetError('Texto da pesquisa não informado.');
    Exit;
  end;

  if not FBrowserReady then
  begin
    SetError('Browser não está pronto.');
    Exit;
  end;

  JSScript :=
    '(function() {' +
    '  var value = "' + EscapeJSString(AText) + '";' +

    '  var el = document.querySelector(''textarea[name="q"]'');' +
    '  if (!el) el = document.querySelector(''input[name="q"]'');' +
    '  if (!el) el = document.querySelector(''[aria-label*="Pesquisar"]'');' +
    '  if (!el) el = document.querySelector(''[aria-label*="Search"]'');' +
    '  if (!el) el = document.querySelector(''[title*="Pesquisar"]'');' +
    '  if (!el) el = document.querySelector(''[title*="Search"]'');' +

    '  if (!el) {' +
    '    window.__ai_last_google_search = "SEARCH_BOX_NOT_FOUND";' +
    '    return false;' +
    '  }' +

    '  el.focus();' +
    '  el.value = value;' +

    '  el.dispatchEvent(new Event("input", { bubbles: true }));' +
    '  el.dispatchEvent(new Event("change", { bubbles: true }));' +

    '  var form = el.form;' +
    '  if (form) {' +
    '    window.__ai_last_google_search = "FORM_SUBMIT";' +
    '    form.submit();' +
    '    return true;' +
    '  }' +

    '  var ev = new KeyboardEvent("keydown", {' +
    '    key: "Enter",' +
    '    code: "Enter",' +
    '    keyCode: 13,' +
    '    which: 13,' +
    '    bubbles: true' +
    '  });' +
    '  el.dispatchEvent(ev);' +

    '  window.__ai_last_google_search = "ENTER_SENT";' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'Pesquisa enviada para o Google.'
  else
    SetError('Falha ao enviar pesquisa para o Google.');
end;

function TAIChromiumBrowser.WaitForSelector(const ASelector: string; ATimeoutMs: Integer = 0): Boolean;
var
  JSScript: string;
begin
  if ATimeoutMs <= 0 then
    ATimeoutMs := FDefaultTimeoutMs;
  
  // As JavaScript execution in CEF is asynchronous and doesn't return immediately,
  // we are just injecting the script to check and saving it into a global variable for now.
  // Full blocking wait requires more complex callback mechanics or IPC which will be added later.
  JSScript := 'window.__ai_last_selector_exists = !!document.querySelector("' + EscapeJSString(ASelector) + '");';
  Result := ExecuteJavaScript(JSScript);
  
  if Result then
    FLastResult := 'WaitForSelector script injected. Real synchronous waiting requires IPC callbacks.'
  else
    SetError('Failed to inject WaitForSelector script.');
end;

function TAIChromiumBrowser.GetHtmlContent: string;
var
  JSScript: string;
begin
  // Standard way to get HTML synchronously isn't fully supported without visitor callbacks in CEF.
  // For MVP we request the outerHTML.
  JSScript := 'document.documentElement.outerHTML';
  ExecuteJavaScript(JSScript);
  
  Result := FHTML; // FHTML will be updated via async callbacks in future versions
  SetError('GetHtmlContent returns last cached HTML or empty until async DOM Visitor callback is implemented.');
end;

function TAIChromiumBrowser.Screenshot(const AFileName: string): Boolean;
begin
  Result := False;
  SetError('Screenshot is not implemented yet for TChromiumWindow mode.');
end;

procedure TAIChromiumBrowser.CloseBrowser;
begin
  if Assigned(FChromiumWindow) then
  begin
    FChromiumWindow.CloseBrowser(True);
    FBrowserReady := False;
  end;
end;

initialization
  {$I aichromiumbrowser_icon.lrs}

end.
