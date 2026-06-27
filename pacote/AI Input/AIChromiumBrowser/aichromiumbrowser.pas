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
    FLastCaptureVarName: string;
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

    // External CEF4Delphi Browser Window.
    // This component DOES NOT create or own TChromiumWindow anymore.
    FChromiumWindow: TChromiumWindow;

    FHistory: TStringList;
    FHistoryIdx: Integer;

    procedure SetURL(const AValue: string);
    procedure SetShowAddressBar(AValue: Boolean);
    procedure SetChromiumWindow(AValue: TChromiumWindow);

    procedure HookChromiumWindow;
    procedure UnhookChromiumWindow;

    procedure ChromiumAfterCreated(Sender: TObject);
    procedure ChromiumBeforeClose(Sender: TObject);
    procedure ChromiumClose(Sender: TObject);

    procedure ClearError;
    procedure SetError(const AMsg: string);
    function EscapeJSString(const S: string): string;
    function IsSafeJSPath(const S: string): Boolean;
    function CaptureAssignScript(const AKind, ASelector, AValueExpression: string): string;
    function HasChromiumWindow: Boolean;

    // Event Handlers
    procedure BtnGoClick(Sender: TObject);
    procedure BtnBackClick(Sender: TObject);
    procedure BtnForwardClick(Sender: TObject);
    procedure BtnReloadClick(Sender: TObject);
    procedure EditURLKeyPress(Sender: TObject; var Key: Char);
  protected
    procedure Resize; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Browser/navigation
    function InitializeBrowser: Boolean;
    procedure Navigate(const AURL: string);
    procedure GoBack;
    procedure GoForward;
    procedure Reload;
    procedure CloseBrowser;
    function Screenshot(const AFileName: string): Boolean;

    // Generic JavaScript layer
    function ExecuteJavaScript(const AScript: string): Boolean;
    function InjectJavaScript(const AScript: string): Boolean;
    function CaptureJavaScript(const AExpression: string): Boolean;
    function DefineJavaScriptFunction(const AFunctionName, AFunctionBody: string): Boolean;
    function CallJavaScriptFunction(const AFunctionName: string; const AArgsJSON: string = '[]'): Boolean;

    // Cookies - implemented via document.cookie for the current page/domain.
    // HttpOnly cookies cannot be read or changed by JavaScript.
    function CaptureCookies: Boolean;
    function SetCookie(const AName, AValue: string; const AOptions: string = 'path=/'): Boolean;
    function DeleteCookie(const AName: string; const APath: string = '/'; const ADomain: string = ''): Boolean;

    // DOM capture/manipulation
    function WaitForSelector(const ASelector: string; ATimeoutMs: Integer = 0): Boolean;
    function CaptureHTML(const ASelector: string = 'html'): Boolean;
    function CaptureText(const ASelector: string): Boolean;
    function CaptureValue(const ASelector: string): Boolean;
    function CaptureAttribute(const ASelector, AAttributeName: string): Boolean;
    function SetHTML(const ASelector, AHTML: string): Boolean;
    function SetText(const ASelector, AText: string): Boolean;
    function SetValue(const ASelector, AValue: string): Boolean;
    function CreateDOMElement(const AParentSelector, ATagName, AElementId, AClassName, AHTML: string): Boolean;
    function AppendHTML(const AParentSelector, AHTML: string): Boolean;
    function RemoveElement(const ASelector: string): Boolean;
    function SetAttribute(const ASelector, AAttributeName, AValue: string): Boolean;
    function RemoveAttribute(const ASelector, AAttributeName: string): Boolean;
    function GetHtmlContent: string;

    // CSS capture/manipulation
    function InjectCSS(const ACSS: string; const AStyleId: string = 'ai-injected-style'): Boolean;
    function RemoveCSS(const AStyleId: string = 'ai-injected-style'): Boolean;
    function SetStyle(const ASelector, APropertyName, AValue: string): Boolean;
    function CaptureComputedStyle(const ASelector, APropertyName: string): Boolean;

    // Generic events/forms - useful for web testing platforms
    function Click(const ASelector: string): Boolean;
    function DoubleClick(const ASelector: string): Boolean;
    function RightClick(const ASelector: string): Boolean;
    function Focus(const ASelector: string): Boolean;
    function Blur(const ASelector: string): Boolean;
    function DispatchEvent(const ASelector, AEventName: string): Boolean;
    function PressKey(const ASelector, AKey: string; AKeyCode: Integer = 0): Boolean;
    function PressEnter(const ASelector: string): Boolean;
    function SubmitForm(const ASelector: string): Boolean;
    function Check(const ASelector: string): Boolean;
    function Uncheck(const ASelector: string): Boolean;
    function SelectOption(const ASelector, AValue: string): Boolean;

  published
    property Prompt: string read FPrompt write FPrompt;

    // Required external visual component.
    // Put a TChromiumWindow visually on the form and link it here.
    property ChromiumWindow: TChromiumWindow read FChromiumWindow write SetChromiumWindow;

    property URL: string read FURL write SetURL;
    property HTML: string read FHTML write FHTML;
    property ShowAddressBar: Boolean read FShowAddressBar write SetShowAddressBar default True;

    property LastError: string read FLastError;
    property LastResult: string read FLastResult;
    property LastCaptureVarName: string read FLastCaptureVarName write FLastCaptureVarName;
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

  FPrompt :=
    'Component TAIChromiumBrowser is a generic web automation controller for an external CEF4Delphi TChromiumWindow. ' +
    'It does not create or own the Chromium visual component. The application must drop a TChromiumWindow on the form ' +
    'and link it through the ChromiumWindow property. It provides a reusable automation surface for Lazarus applications: ' +
    'navigate URLs, execute and inject JavaScript, capture and manipulate cookies, capture/change/create DOM nodes, ' +
    'inject/change CSS, dispatch browser events, click buttons, submit forms and call page JavaScript functions. ' +
    'It must not contain site-specific automation such as GoogleSearch, BingSearch, YouTubeSearch or application business rules.';

  Caption := '';
  FShowAddressBar := True;
  FHistory := TStringList.Create;
  FHistoryIdx := -1;
  FDefaultTimeoutMs := 30000;
  FLastCaptureVarName := '__ai_last_capture';

  Width := 600;
  Height := 40;

  // Address bar only. Browser visual area belongs to the external TChromiumWindow.
  FAddressPanel := TPanel.Create(Self);
  FAddressPanel.Parent := Self;
  FAddressPanel.Align := alClient;
  FAddressPanel.Height := 38;
  FAddressPanel.Caption := '';
  FAddressPanel.BevelOuter := bvNone;
  FAddressPanel.Color := $F4F4F4;

  FBtnBack := TSpeedButton.Create(Self);
  FBtnBack.Parent := FAddressPanel;
  FBtnBack.Caption := '<';
  FBtnBack.Width := 28;
  FBtnBack.Height := 28;
  FBtnBack.Top := 5;
  FBtnBack.Left := 5;
  FBtnBack.OnClick := @BtnBackClick;
  FBtnBack.Flat := True;

  FBtnForward := TSpeedButton.Create(Self);
  FBtnForward.Parent := FAddressPanel;
  FBtnForward.Caption := '>';
  FBtnForward.Width := 28;
  FBtnForward.Height := 28;
  FBtnForward.Top := 5;
  FBtnForward.Left := FBtnBack.Left + FBtnBack.Width + 2;
  FBtnForward.OnClick := @BtnForwardClick;
  FBtnForward.Flat := True;

  FBtnReload := TSpeedButton.Create(Self);
  FBtnReload.Parent := FAddressPanel;
  FBtnReload.Caption := 'R';
  FBtnReload.Width := 28;
  FBtnReload.Height := 28;
  FBtnReload.Top := 5;
  FBtnReload.Left := FBtnForward.Left + FBtnForward.Width + 2;
  FBtnReload.OnClick := @BtnReloadClick;
  FBtnReload.Flat := True;

  FBtnGo := TSpeedButton.Create(Self);
  FBtnGo.Parent := FAddressPanel;
  FBtnGo.Caption := 'Ir';
  FBtnGo.Width := 40;
  FBtnGo.Height := 28;
  FBtnGo.Top := 5;
  FBtnGo.OnClick := @BtnGoClick;
  FBtnGo.Flat := True;

  FEditURL := TEdit.Create(Self);
  FEditURL.Parent := FAddressPanel;
  FEditURL.Text := 'https://www.google.com';
  FEditURL.Top := 5;
  FEditURL.Height := 28;
  FEditURL.OnKeyPress := @EditURLKeyPress;

  Resize;
end;

destructor TAIChromiumBrowser.Destroy;
begin
  UnhookChromiumWindow;
  FHistory.Free;
  inherited Destroy;
end;

procedure TAIChromiumBrowser.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);

  if (Operation = opRemove) and (AComponent = FChromiumWindow) then
  begin
    UnhookChromiumWindow;
    FChromiumWindow := nil;
    FBrowserReady := False;
  end;
end;

procedure TAIChromiumBrowser.Resize;
begin
  inherited Resize;
  if FAddressPanel <> nil then
  begin
    FBtnGo.Left := FAddressPanel.Width - FBtnGo.Width - 8;
    FEditURL.Left := FBtnReload.Left + FBtnReload.Width + 8;
    FEditURL.Width := FBtnGo.Left - FEditURL.Left - 8;
    if FEditURL.Width < 40 then
      FEditURL.Width := 40;
  end;
end;

procedure TAIChromiumBrowser.SetChromiumWindow(AValue: TChromiumWindow);
begin
  if FChromiumWindow = AValue then
    Exit;

  UnhookChromiumWindow;

  FChromiumWindow := AValue;

  if Assigned(FChromiumWindow) then
  begin
    FChromiumWindow.FreeNotification(Self);
    HookChromiumWindow;
    FBrowserReady := FChromiumWindow.Initialized;
    FLastResult := 'External TChromiumWindow assigned.';
  end
  else
  begin
    FBrowserReady := False;
    FLastResult := 'External TChromiumWindow cleared.';
  end;
end;

procedure TAIChromiumBrowser.HookChromiumWindow;
begin
  if not Assigned(FChromiumWindow) then
    Exit;

  // This controller needs these events to maintain BrowserReady and pending navigation.
  // If the application needs its own events, it should call this component's methods
  // or extend this component with event chaining.
  FChromiumWindow.OnAfterCreated := @ChromiumAfterCreated;
  FChromiumWindow.OnBeforeClose := @ChromiumBeforeClose;
  FChromiumWindow.OnClose := @ChromiumClose;
end;

procedure TAIChromiumBrowser.UnhookChromiumWindow;
begin
  if not Assigned(FChromiumWindow) then
    Exit;

  if FChromiumWindow.OnAfterCreated = @ChromiumAfterCreated then
    FChromiumWindow.OnAfterCreated := nil;

  if FChromiumWindow.OnBeforeClose = @ChromiumBeforeClose then
    FChromiumWindow.OnBeforeClose := nil;

  if FChromiumWindow.OnClose = @ChromiumClose then
    FChromiumWindow.OnClose := nil;
end;

procedure TAIChromiumBrowser.ChromiumAfterCreated(Sender: TObject);
begin
  FBrowserReady := True;
  FLastResult := 'Chromium browser initialized.';

  if (FPendingURL <> '') and Assigned(FChromiumWindow) then
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
  // Handled by ChromiumBeforeClose usually.
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

function TAIChromiumBrowser.HasChromiumWindow: Boolean;
begin
  Result := Assigned(FChromiumWindow);
  if not Result then
    SetError('ChromiumWindow property is not assigned. Drop a TChromiumWindow on the form and link it to this component.');
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

function TAIChromiumBrowser.IsSafeJSPath(const S: string): Boolean;
var
  I: Integer;
  NewPart: Boolean;
  C: Char;
begin
  Result := False;

  if Trim(S) = '' then
    Exit;

  NewPart := True;

  for I := 1 to Length(S) do
  begin
    C := S[I];

    if C = '.' then
    begin
      if NewPart then
        Exit;
      NewPart := True;
      Continue;
    end;

    if NewPart then
    begin
      if not (C in ['A'..'Z', 'a'..'z', '_', '$']) then
        Exit;
      NewPart := False;
    end
    else
    begin
      if not (C in ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) then
        Exit;
    end;
  end;

  if NewPart then
    Exit;

  Result := True;
end;

function TAIChromiumBrowser.CaptureAssignScript(const AKind, ASelector, AValueExpression: string): string;
begin
  Result :=
    'window["' + EscapeJSString(FLastCaptureVarName) + '"] = {' +
    '  kind: "' + EscapeJSString(AKind) + '",' +
    '  selector: "' + EscapeJSString(ASelector) + '",' +
    '  success: true,' +
    '  value: (' + AValueExpression + ')' +
    '};';
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

  if not HasChromiumWindow then
    Exit;

  if FChromiumWindow.Initialized then
  begin
    FBrowserReady := True;
    Result := True;
    FLastResult := 'Browser already initialized.';
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
  ClearError;

  SafeURL := Trim(AURL);
  if SafeURL = '' then
  begin
    SetError('URL is empty.');
    Exit;
  end;

  if (Pos('http://', LowerCase(SafeURL)) <> 1) and
     (Pos('https://', LowerCase(SafeURL)) <> 1) and
     (Pos('file://', LowerCase(SafeURL)) <> 1) and
     (Pos('about:', LowerCase(SafeURL)) <> 1) then
    SafeURL := 'https://' + SafeURL;

  FURL := SafeURL;
  if Assigned(FEditURL) and (FEditURL.Text <> FURL) then
    FEditURL.Text := FURL;

  if (FHistory.Count = 0) or (FHistory[FHistory.Count - 1] <> FURL) then
  begin
    FHistory.Add(FURL);
    FHistoryIdx := FHistory.Count - 1;
  end;

  if not HasChromiumWindow then
    Exit;

  if not FChromiumWindow.Initialized then
  begin
    FPendingURL := SafeURL;
    InitializeBrowser;
    Exit;
  end;

  FChromiumWindow.LoadURL(SafeURL);
  FLastResult := 'Navigation requested: ' + SafeURL;
end;

procedure TAIChromiumBrowser.GoBack;
begin
  ClearError;

  if not HasChromiumWindow then
    Exit;

  if FChromiumWindow.Initialized then
  begin
    if FChromiumWindow.ChromiumBrowser.CanGoBack then
    begin
      FChromiumWindow.ChromiumBrowser.GoBack;
      FLastResult := 'GoBack requested.';
    end
    else if (FHistory.Count > 0) and (FHistoryIdx > 0) then
    begin
      Dec(FHistoryIdx);
      Navigate(FHistory[FHistoryIdx]);
    end
    else
      SetError('No previous page available.');
  end
  else if (FHistory.Count > 0) and (FHistoryIdx > 0) then
  begin
    Dec(FHistoryIdx);
    Navigate(FHistory[FHistoryIdx]);
  end
  else
    SetError('Browser is not ready and no previous URL is available.');
end;

procedure TAIChromiumBrowser.GoForward;
begin
  ClearError;

  if not HasChromiumWindow then
    Exit;

  if FChromiumWindow.Initialized then
  begin
    if FChromiumWindow.ChromiumBrowser.CanGoForward then
    begin
      FChromiumWindow.ChromiumBrowser.GoForward;
      FLastResult := 'GoForward requested.';
    end
    else if (FHistory.Count > 0) and (FHistoryIdx < FHistory.Count - 1) then
    begin
      Inc(FHistoryIdx);
      Navigate(FHistory[FHistoryIdx]);
    end
    else
      SetError('No next page available.');
  end
  else if (FHistory.Count > 0) and (FHistoryIdx < FHistory.Count - 1) then
  begin
    Inc(FHistoryIdx);
    Navigate(FHistory[FHistoryIdx]);
  end
  else
    SetError('Browser is not ready and no next URL is available.');
end;

procedure TAIChromiumBrowser.Reload;
begin
  ClearError;

  if not HasChromiumWindow then
    Exit;

  if FChromiumWindow.Initialized then
  begin
    FChromiumWindow.ChromiumBrowser.Reload;
    FLastResult := 'Reload requested.';
  end
  else if Trim(FURL) <> '' then
    Navigate(FURL)
  else
    SetError('Browser is not ready and URL is empty.');
end;

function TAIChromiumBrowser.ExecuteJavaScript(const AScript: string): Boolean;
begin
  Result := False;
  ClearError;

  if not HasChromiumWindow then
    Exit;

  if not FChromiumWindow.Initialized then
  begin
    SetError('Browser is not initialized.');
    Exit;
  end;

  if not FBrowserReady then
    FBrowserReady := True;

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

  FLastResult := 'JavaScript executed asynchronously.';
  Result := True;
end;

function TAIChromiumBrowser.InjectJavaScript(const AScript: string): Boolean;
begin
  Result := ExecuteJavaScript(AScript);
  if Result then
    FLastResult := 'JavaScript injected.';
end;

function TAIChromiumBrowser.CaptureJavaScript(const AExpression: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  try {' +
    '    var v = (' + AExpression + ');' +
    '    var value = (typeof v === "object") ? JSON.stringify(v) : String(v);' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {' +
    '      kind: "javascript", selector: "", success: true, value: value' +
    '    };' +
    '  } catch (e) {' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {' +
    '      kind: "javascript", selector: "", success: false, value: "", error: String(e)' +
    '    };' +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'JavaScript capture requested. Result is stored in window.' + FLastCaptureVarName + '.';
end;

function TAIChromiumBrowser.DefineJavaScriptFunction(const AFunctionName, AFunctionBody: string): Boolean;
var
  JSScript: string;
begin
  Result := False;
  ClearError;

  if not IsSafeJSPath(AFunctionName) then
  begin
    SetError('Invalid JavaScript function name/path.');
    Exit;
  end;

  JSScript :=
    '(function() {' +
    '  var path = "' + EscapeJSString(AFunctionName) + '".split(".");' +
    '  var ctx = window;' +
    '  for (var i = 0; i < path.length - 1; i++) {' +
    '    if (!ctx[path[i]]) ctx[path[i]] = {};' +
    '    ctx = ctx[path[i]];' +
    '  }' +
    '  ctx[path[path.length - 1]] = function() {' + AFunctionBody + ' };' +
    '  window["' + EscapeJSString(FLastCaptureVarName) + '"] = {' +
    '    kind: "define-function", selector: "' + EscapeJSString(AFunctionName) + '", success: true, value: "defined"' +
    '  };' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'JavaScript function defined: ' + AFunctionName;
end;

function TAIChromiumBrowser.CallJavaScriptFunction(const AFunctionName: string; const AArgsJSON: string): Boolean;
var
  JSScript: string;
begin
  Result := False;
  ClearError;

  if not IsSafeJSPath(AFunctionName) then
  begin
    SetError('Invalid JavaScript function name/path.');
    Exit;
  end;

  JSScript :=
    '(function() {' +
    '  try {' +
    '    var path = "' + EscapeJSString(AFunctionName) + '".split(".");' +
    '    var ctx = window;' +
    '    var fn = window;' +
    '    for (var i = 0; i < path.length; i++) {' +
    '      if (i === path.length - 1) {' +
    '        fn = ctx[path[i]];' +
    '      } else {' +
    '        ctx = ctx[path[i]];' +
    '      }' +
    '      if (!ctx && i < path.length - 1) throw new Error("Path not found");' +
    '    }' +
    '    if (typeof fn !== "function") throw new Error("Function not found");' +
    '    var args = JSON.parse("' + EscapeJSString(AArgsJSON) + '");' +
    '    if (!Array.isArray(args)) args = [args];' +
    '    var r = fn.apply(ctx, args);' +
    '    var value = (typeof r === "object") ? JSON.stringify(r) : String(r);' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {' +
    '      kind: "call-function", selector: "' + EscapeJSString(AFunctionName) + '", success: true, value: value' +
    '    };' +
    '  } catch (e) {' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {' +
    '      kind: "call-function", selector: "' + EscapeJSString(AFunctionName) + '", success: false, value: "", error: String(e)' +
    '    };' +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'JavaScript function call requested: ' + AFunctionName;
end;

function TAIChromiumBrowser.CaptureCookies: Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  window["' + EscapeJSString(FLastCaptureVarName) + '"] = {' +
    '    kind: "cookies", selector: "document.cookie", success: true, value: document.cookie' +
    '  };' +
    '  window.__ai_last_cookies = document.cookie;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Cookie capture requested. HttpOnly cookies are not visible to document.cookie.';
end;

function TAIChromiumBrowser.SetCookie(const AName, AValue: string; const AOptions: string): Boolean;
var
  Options: string;
  JSScript: string;
begin
  Result := False;
  ClearError;

  if Trim(AName) = '' then
  begin
    SetError('Cookie name is empty.');
    Exit;
  end;

  Options := Trim(AOptions);
  if Options = '' then
    Options := 'path=/';

  JSScript :=
    '(function() {' +
    '  document.cookie = encodeURIComponent("' + EscapeJSString(AName) + '") + "=" + ' +
    '                    encodeURIComponent("' + EscapeJSString(AValue) + '") + "; ' + EscapeJSString(Options) + '";' +
    '  window["' + EscapeJSString(FLastCaptureVarName) + '"] = {' +
    '    kind: "set-cookie", selector: "' + EscapeJSString(AName) + '", success: true, value: document.cookie' +
    '  };' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Cookie set requested: ' + AName;
end;

function TAIChromiumBrowser.DeleteCookie(const AName: string; const APath: string; const ADomain: string): Boolean;
var
  DomainPart: string;
  JSScript: string;
begin
  Result := False;
  ClearError;

  if Trim(AName) = '' then
  begin
    SetError('Cookie name is empty.');
    Exit;
  end;

  DomainPart := '';
  if Trim(ADomain) <> '' then
    DomainPart := '; domain=' + Trim(ADomain);

  JSScript :=
    '(function() {' +
    '  document.cookie = encodeURIComponent("' + EscapeJSString(AName) + '") + ' +
    '    "=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=' + EscapeJSString(APath) + EscapeJSString(DomainPart) + '";' +
    '  window["' + EscapeJSString(FLastCaptureVarName) + '"] = {' +
    '    kind: "delete-cookie", selector: "' + EscapeJSString(AName) + '", success: true, value: document.cookie' +
    '  };' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Cookie delete requested: ' + AName;
end;

function TAIChromiumBrowser.WaitForSelector(const ASelector: string; ATimeoutMs: Integer): Boolean;
var
  JSScript: string;
begin
  if ATimeoutMs <= 0 then
    ATimeoutMs := FDefaultTimeoutMs;

  JSScript :=
    '(function() {' +
    '  var start = Date.now();' +
    '  var timeout = ' + IntToStr(ATimeoutMs) + ';' +
    '  function check() {' +
    '    var ok = !!document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {' +
    '      kind: "wait-selector", selector: "' + EscapeJSString(ASelector) + '", success: ok, value: ok ? "FOUND" : "WAITING"' +
    '    };' +
    '    if (!ok && ((Date.now() - start) < timeout)) window.setTimeout(check, 100);' +
    '  }' +
    '  check();' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'WaitForSelector requested asynchronously. Result is stored in window.' + FLastCaptureVarName + '.';
end;

function TAIChromiumBrowser.CaptureHTML(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) {' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {kind: "html", selector: "' + EscapeJSString(ASelector) + '", success: false, value: "", error: "Element not found"};' +
    '    return;' +
    '  }' +
    '  window.__ai_last_html = el.outerHTML;' +
       CaptureAssignScript('html', ASelector, 'el.outerHTML') +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'HTML capture requested.';
end;

function TAIChromiumBrowser.CaptureText(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) {' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {kind: "text", selector: "' + EscapeJSString(ASelector) + '", success: false, value: "", error: "Element not found"};' +
    '    return;' +
    '  }' +
       CaptureAssignScript('text', ASelector, 'el.innerText') +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Text capture requested.';
end;

function TAIChromiumBrowser.CaptureValue(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) {' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {kind: "value", selector: "' + EscapeJSString(ASelector) + '", success: false, value: "", error: "Element not found"};' +
    '    return;' +
    '  }' +
       CaptureAssignScript('value', ASelector, 'el.value') +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Value capture requested.';
end;

function TAIChromiumBrowser.CaptureAttribute(const ASelector, AAttributeName: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) {' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {kind: "attribute", selector: "' + EscapeJSString(ASelector) + '", success: false, value: "", error: "Element not found"};' +
    '    return;' +
    '  }' +
       CaptureAssignScript('attribute', ASelector, 'el.getAttribute("' + EscapeJSString(AAttributeName) + '")') +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Attribute capture requested: ' + AAttributeName;
end;

function TAIChromiumBrowser.SetHTML(const ASelector, AHTML: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.innerHTML = "' + EscapeJSString(AHTML) + '";' +
    '  el.dispatchEvent(new Event("change", { bubbles: true }));' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'SetHTML requested.';
end;

function TAIChromiumBrowser.SetText(const ASelector, AText: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.innerText = "' + EscapeJSString(AText) + '";' +
    '  el.dispatchEvent(new Event("change", { bubbles: true }));' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'SetText requested.';
end;

function TAIChromiumBrowser.SetValue(const ASelector, AValue: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) { return false; }' +
    '  el.focus();' +
    '  el.value = "' + EscapeJSString(AValue) + '";' +
    '  el.dispatchEvent(new Event("input", { bubbles: true }));' +
    '  el.dispatchEvent(new Event("change", { bubbles: true }));' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'SetValue requested.';
end;

function TAIChromiumBrowser.CreateDOMElement(const AParentSelector, ATagName, AElementId, AClassName, AHTML: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var parent = document.querySelector("' + EscapeJSString(AParentSelector) + '");' +
    '  if (!parent) return false;' +
    '  var el = document.createElement("' + EscapeJSString(ATagName) + '");' +
    '  if ("' + EscapeJSString(AElementId) + '" !== "") el.id = "' + EscapeJSString(AElementId) + '";' +
    '  if ("' + EscapeJSString(AClassName) + '" !== "") el.className = "' + EscapeJSString(AClassName) + '";' +
    '  el.innerHTML = "' + EscapeJSString(AHTML) + '";' +
    '  parent.appendChild(el);' +
    '  window["' + EscapeJSString(FLastCaptureVarName) + '"] = {kind: "create-dom", selector: "' + EscapeJSString(AParentSelector) + '", success: true, value: el.outerHTML};' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'CreateDOMElement requested.';
end;

function TAIChromiumBrowser.AppendHTML(const AParentSelector, AHTML: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var parent = document.querySelector("' + EscapeJSString(AParentSelector) + '");' +
    '  if (!parent) return false;' +
    '  parent.insertAdjacentHTML("beforeend", "' + EscapeJSString(AHTML) + '");' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'AppendHTML requested.';
end;

function TAIChromiumBrowser.RemoveElement(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el || !el.parentNode) return false;' +
    '  el.parentNode.removeChild(el);' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'RemoveElement requested.';
end;

function TAIChromiumBrowser.SetAttribute(const ASelector, AAttributeName, AValue: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.setAttribute("' + EscapeJSString(AAttributeName) + '", "' + EscapeJSString(AValue) + '");' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'SetAttribute requested: ' + AAttributeName;
end;

function TAIChromiumBrowser.RemoveAttribute(const ASelector, AAttributeName: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.removeAttribute("' + EscapeJSString(AAttributeName) + '");' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'RemoveAttribute requested: ' + AAttributeName;
end;

function TAIChromiumBrowser.GetHtmlContent: string;
begin
  CaptureHTML('html');
  Result := FHTML;
  if Result = '' then
    SetError('GetHtmlContent requested capture, but synchronous DOM readback is not implemented yet. Use LastCaptureVarName in browser context or add CEF IPC/callback support.');
end;

function TAIChromiumBrowser.InjectCSS(const ACSS: string; const AStyleId: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var id = "' + EscapeJSString(AStyleId) + '";' +
    '  var style = document.getElementById(id);' +
    '  if (!style) {' +
    '    style = document.createElement("style");' +
    '    style.type = "text/css";' +
    '    style.id = id;' +
    '    document.head.appendChild(style);' +
    '  }' +
    '  style.textContent = "' + EscapeJSString(ACSS) + '";' +
    '  window["' + EscapeJSString(FLastCaptureVarName) + '"] = {kind: "inject-css", selector: id, success: true, value: style.textContent};' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'CSS injected/updated: ' + AStyleId;
end;

function TAIChromiumBrowser.RemoveCSS(const AStyleId: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var style = document.getElementById("' + EscapeJSString(AStyleId) + '");' +
    '  if (!style || !style.parentNode) return false;' +
    '  style.parentNode.removeChild(style);' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'CSS remove requested: ' + AStyleId;
end;

function TAIChromiumBrowser.SetStyle(const ASelector, APropertyName, AValue: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.style.setProperty("' + EscapeJSString(APropertyName) + '", "' + EscapeJSString(AValue) + '");' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'SetStyle requested: ' + APropertyName;
end;

function TAIChromiumBrowser.CaptureComputedStyle(const ASelector, APropertyName: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) {' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {kind: "computed-style", selector: "' + EscapeJSString(ASelector) + '", success: false, value: "", error: "Element not found"};' +
    '    return;' +
    '  }' +
    '  var v = window.getComputedStyle(el).getPropertyValue("' + EscapeJSString(APropertyName) + '");' +
       CaptureAssignScript('computed-style', ASelector, 'v') +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Computed style capture requested: ' + APropertyName;
end;

function TAIChromiumBrowser.Click(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) { return false; }' +
    '  el.scrollIntoView({block: "center", inline: "center"});' +
    '  el.click();' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Click requested.';
end;

function TAIChromiumBrowser.DoubleClick(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.scrollIntoView({block: "center", inline: "center"});' +
    '  el.dispatchEvent(new MouseEvent("dblclick", {bubbles: true, cancelable: true, view: window}));' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'DoubleClick requested.';
end;

function TAIChromiumBrowser.RightClick(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.scrollIntoView({block: "center", inline: "center"});' +
    '  el.dispatchEvent(new MouseEvent("contextmenu", {bubbles: true, cancelable: true, view: window, button: 2}));' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'RightClick/contextmenu requested.';
end;

function TAIChromiumBrowser.Focus(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.focus();' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Focus requested.';
end;

function TAIChromiumBrowser.Blur(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.blur();' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Blur requested.';
end;

function TAIChromiumBrowser.DispatchEvent(const ASelector, AEventName: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  var ev = new Event("' + EscapeJSString(AEventName) + '", {bubbles: true, cancelable: true});' +
    '  el.dispatchEvent(ev);' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'DispatchEvent requested: ' + AEventName;
end;

function TAIChromiumBrowser.PressKey(const ASelector, AKey: string; AKeyCode: Integer): Boolean;
var
  JSScript: string;
  EffectiveKeyCode: Integer;
begin
  EffectiveKeyCode := AKeyCode;
  if (EffectiveKeyCode <= 0) and (Length(AKey) = 1) then
    EffectiveKeyCode := Ord(AKey[1]);

  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.focus();' +
    '  var opt = {key: "' + EscapeJSString(AKey) + '", code: "' + EscapeJSString(AKey) + '", keyCode: ' + IntToStr(EffectiveKeyCode) + ', which: ' + IntToStr(EffectiveKeyCode) + ', bubbles: true, cancelable: true};' +
    '  el.dispatchEvent(new KeyboardEvent("keydown", opt));' +
    '  el.dispatchEvent(new KeyboardEvent("keypress", opt));' +
    '  el.dispatchEvent(new KeyboardEvent("keyup", opt));' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'PressKey requested: ' + AKey;
end;

function TAIChromiumBrowser.PressEnter(const ASelector: string): Boolean;
begin
  Result := PressKey(ASelector, 'Enter', 13);
end;

function TAIChromiumBrowser.SubmitForm(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  var form = (el.tagName && el.tagName.toLowerCase() === "form") ? el : el.form;' +
    '  if (!form) return false;' +
    '  if (form.requestSubmit) form.requestSubmit(); else form.submit();' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'SubmitForm requested.';
end;

function TAIChromiumBrowser.Check(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.checked = true;' +
    '  el.dispatchEvent(new Event("input", { bubbles: true }));' +
    '  el.dispatchEvent(new Event("change", { bubbles: true }));' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Check requested.';
end;

function TAIChromiumBrowser.Uncheck(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.checked = false;' +
    '  el.dispatchEvent(new Event("input", { bubbles: true }));' +
    '  el.dispatchEvent(new Event("change", { bubbles: true }));' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'Uncheck requested.';
end;

function TAIChromiumBrowser.SelectOption(const ASelector, AValue: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  var el = document.querySelector("' + EscapeJSString(ASelector) + '");' +
    '  if (!el) return false;' +
    '  el.value = "' + EscapeJSString(AValue) + '";' +
    '  el.dispatchEvent(new Event("input", { bubbles: true }));' +
    '  el.dispatchEvent(new Event("change", { bubbles: true }));' +
    '  return true;' +
    '})();';

  Result := ExecuteJavaScript(JSScript);
  if Result then
    FLastResult := 'SelectOption requested.';
end;

function TAIChromiumBrowser.Screenshot(const AFileName: string): Boolean;
begin
  Result := False;
  SetError('Screenshot is not implemented yet for external TChromiumWindow mode.');
end;

procedure TAIChromiumBrowser.CloseBrowser;
begin
  ClearError;

  if not HasChromiumWindow then
    Exit;

  FChromiumWindow.CloseBrowser(True);
  FBrowserReady := False;
  FLastResult := 'CloseBrowser requested.';
end;

initialization
  {$I aichromiumbrowser_icon.lrs}

end.

