unit aichromiumbrowser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons,
  Graphics, LCLIntf, LCLType, LResources,
  fpjson, jsonparser,
  uCEFChromiumWindow, uCEFChromium, uCEFInterfaces, uCEFTypes;

type
  TAIChromiumLoadURLEvent = procedure(
    Sender: TObject;
    const AURL: string;
    AIsMainFrame: Boolean
  ) of object;

  TAIChromiumFinishedLoadURLEvent = procedure(
    Sender: TObject;
    const AURL: string;
    AHttpStatusCode: Integer;
    AIsMainFrame: Boolean
  ) of object;

  TAIChromiumDOMEvent = procedure(
    Sender: TObject;
    const AEventName: string;
    const ASelector: string;
    const ATagName: string;
    const AId: string;
    const AName: string;
    const AClassName: string;
    const APropertyName: string;
    const AValue: string;
    const AKey: string;
    AKeyCode: Integer
  ) of object;

  TAIChromiumDOMResultEvent = procedure(
    Sender: TObject;
    const AKind: string;
    const ASelector: string;
    AIndex: Integer;
    ACount: Integer;
    const AJSON: string
  ) of object;

  TAIDOMQueuedEventData = class
  public
    EventName: string;
    Selector: string;
    TagName: string;
    Id: string;
    Name: string;
    DOMClassName: string;
    PropertyName: string;
    Value: string;
    Key: string;
    KeyCode: Integer;
  end;

  TAIURLQueuedEventData = class
  public
    URL: string;
    HttpStatusCode: Integer;
    IsMainFrame: Boolean;
    IsFinished: Boolean;
  end;

  TAIDOMResultQueuedData = class
  public
    Kind: string;
    Selector: string;
    Index: Integer;
    Count: Integer;
    JSON: string;
  end;

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

    // DOM API state
    FDOMSelector: string;
    FDOMIndex: Integer;
    FDOMCount: Integer;
    FLastDOMJSON: string;
    FLastDOMSelector: string;
    FLastDOMIndex: Integer;
    FDOMResultVarName: string;

    // URL events
    FOnLoadURL: TAIChromiumLoadURLEvent;
    FOnFinishedLoadURL: TAIChromiumFinishedLoadURLEvent;

    // DOM monitor events
    FMonitorDOMEvents: Boolean;
    FDOMEventsInstalled: Boolean;
    FDOMEventConsolePrefix: string;
    FDOMResultConsolePrefix: string;
    FLastDOMEventJSON: string;

    FOnKeyPressDOM: TAIChromiumDOMEvent;
    FOnClickDOM: TAIChromiumDOMEvent;
    FOnSetFocusDOM: TAIChromiumDOMEvent;
    FOnOutFocusDOM: TAIChromiumDOMEvent;
    FOnDOMResult: TAIChromiumDOMResultEvent;

    // Address Bar UI Controls
    FAddressPanel: TPanel;
    FEditURL: TEdit;
    FBtnGo: TSpeedButton;
    FBtnBack: TSpeedButton;
    FBtnForward: TSpeedButton;
    FBtnReload: TSpeedButton;

    // External CEF4Delphi Browser Window.
    // This component DOES NOT create or own TChromiumWindow.
    FChromiumWindow: TChromiumWindow;

    FHistory: TStringList;
    FHistoryIdx: Integer;

    procedure SetURL(const AValue: string);
    procedure SetShowAddressBar(AValue: Boolean);
    procedure SetChromiumWindow(AValue: TChromiumWindow);

    procedure HookChromiumWindow;
    procedure UnhookChromiumWindow;
    procedure HookChromiumEvents;
    procedure UnhookChromiumEvents;

    procedure ChromiumAfterCreated(Sender: TObject);
    procedure ChromiumBeforeClose(Sender: TObject);
    procedure ChromiumClose(Sender: TObject);

    procedure ChromiumLoadStart(
      Sender: TObject;
      const browser: ICefBrowser;
      const frame: ICefFrame;
      transitionType: TCefTransitionType
    );

    procedure ChromiumLoadEnd(
      Sender: TObject;
      const browser: ICefBrowser;
      const frame: ICefFrame;
      httpStatusCode: Integer
    );

    procedure ChromiumConsoleMessage(
      Sender: TObject;
      const browser: ICefBrowser;
      level: TCefLogSeverity;
      const message_, source: ustring;
      line: Integer;
      out Result: Boolean
    );

    procedure QueueURLLoadEvent(
      const AURL: string;
      AHttpStatusCode: Integer;
      AIsMainFrame: Boolean;
      AIsFinished: Boolean
    );
    procedure DoURLLoadEventAsync(Data: PtrInt);

    procedure QueueDOMEvent(AData: TAIDOMQueuedEventData);
    procedure DoDOMEventAsync(Data: PtrInt);

    procedure QueueDOMResult(AData: TAIDOMResultQueuedData);
    procedure DoDOMResultAsync(Data: PtrInt);

    procedure ClearError;
    procedure SetError(const AMsg: string);

    function EscapeJSString(const S: string): string;
    function EscapeJSONText(const S: string): string;
    function IsSafeJSPath(const S: string): Boolean;
    function IsSafeDOMMethodName(const S: string): Boolean;
    function HasChromiumWindow: Boolean;

    function CaptureAssignScript(const AKind, ASelector, AValueExpression: string): string;

    // DOM helpers
    procedure MarkDOMRequest(const AKind, ASelector: string; AIndex: Integer);
    function DOMElementExpression(const ASelector: string; AIndex: Integer): string;
    function DOMStoreResultScript(const AKind, ASelector: string; AIndex: Integer; const AValueExpression: string): string;
    function DOMStoreErrorScript(const AKind, ASelector: string; AIndex: Integer; const AErrorMessage: string): string;
    function DOMElementObjectExpression: string;

    function InstallDOMEventMonitor: Boolean;
    function BuildDOMEventMonitorScript: string;
    procedure ProcessDOMConsoleMessage(const AJSON: string);
    procedure ProcessDOMResultConsoleMessage(const AJSON: string);

    function JSONGetStr(AObj: TJSONObject; const AName: string): string;
    function JSONGetInt(AObj: TJSONObject; const AName: string; ADefault: Integer = 0): Integer;

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

    // Cookies
    function CaptureCookies: Boolean;
    function SetCookie(const AName, AValue: string; const AOptions: string = 'path=/'): Boolean;
    function DeleteCookie(const AName: string; const APath: string = '/'; const ADomain: string = ''): Boolean;

    // DOM object model layer
    function DOMList(const ASelector: string = '*'): Boolean;
    function DOMCount(const ASelector: string = '*'): Boolean;
    function DOMGetElement(const ASelector: string; AIndex: Integer = 0): Boolean;

    function DOMGetProperty(const ASelector: string; AIndex: Integer; const APropertyName: string): Boolean;
    function DOMSetProperty(const ASelector: string; AIndex: Integer; const APropertyName, AValue: string): Boolean;

    function DOMGetAttributeValue(const ASelector: string; AIndex: Integer; const AAttributeName: string): Boolean;
    function DOMSetAttributeValue(const ASelector: string; AIndex: Integer; const AAttributeName, AValue: string): Boolean;

    function DOMGetValue(const ASelector: string; AIndex: Integer = 0): Boolean;
    function DOMSetValue(const ASelector: string; AIndex: Integer; const AValue: string): Boolean;

    function DOMGetText(const ASelector: string; AIndex: Integer = 0): Boolean;
    function DOMSetText(const ASelector: string; AIndex: Integer; const AText: string): Boolean;

    function DOMClick(const ASelector: string; AIndex: Integer = 0): Boolean;
    function DOMFocus(const ASelector: string; AIndex: Integer = 0): Boolean;
    function DOMBlur(const ASelector: string; AIndex: Integer = 0): Boolean;

    function DOMDispatchEvent(const ASelector: string; AIndex: Integer; const AEventName: string): Boolean;
    function DOMPressKey(const ASelector: string; AIndex: Integer; const AKey: string; AKeyCode: Integer = 0): Boolean;
    function DOMPressEnter(const ASelector: string; AIndex: Integer = 0): Boolean;
    function DOMSubmitForm(const ASelector: string; AIndex: Integer = 0): Boolean;

    function DOMCallMethod(const ASelector: string; AIndex: Integer; const AMethodName: string; const AArgsJSON: string = '[]'): Boolean;

    // Legacy DOM capture/manipulation methods kept for compatibility
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

    // Generic events/forms
    function Click(const ASelector: string): Boolean; overload;
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

    // DOM API state
    property DOMSelector: string read FDOMSelector write FDOMSelector;
    property DOMIndex: Integer read FDOMIndex write FDOMIndex default 0;
    property DOMCountValue: Integer read FDOMCount;
    property LastDOMJSON: string read FLastDOMJSON;
    property LastDOMSelector: string read FLastDOMSelector;
    property LastDOMIndex: Integer read FLastDOMIndex;
    property DOMResultVarName: string read FDOMResultVarName write FDOMResultVarName;

    // URL load events
    property OnLoadURL: TAIChromiumLoadURLEvent read FOnLoadURL write FOnLoadURL;
    property OnFinishedLoadURL: TAIChromiumFinishedLoadURLEvent read FOnFinishedLoadURL write FOnFinishedLoadURL;

    // DOM event monitor
    property MonitorDOMEvents: Boolean read FMonitorDOMEvents write FMonitorDOMEvents default True;
    property LastDOMEventJSON: string read FLastDOMEventJSON;

    property OnKeyPressDOM: TAIChromiumDOMEvent read FOnKeyPressDOM write FOnKeyPressDOM;
    property OnClickDOM: TAIChromiumDOMEvent read FOnClickDOM write FOnClickDOM;
    property OnSetFocusDOM: TAIChromiumDOMEvent read FOnSetFocusDOM write FOnSetFocusDOM;
    property OnOutFocusDOM: TAIChromiumDOMEvent read FOnOutFocusDOM write FOnOutFocusDOM;
    property OnDOMResult: TAIChromiumDOMResultEvent read FOnDOMResult write FOnDOMResult;

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
    'list DOM elements, count DOM elements, get/set DOM properties and attributes, call DOM methods, dispatch browser events, ' +
    'click buttons, submit forms and call page JavaScript functions. It must not contain site-specific automation such as ' +
    'GoogleSearch, BingSearch, YouTubeSearch or application business rules.';

  Caption := '';

  FShowAddressBar := True;
  FHistory := TStringList.Create;
  FHistoryIdx := -1;
  FDefaultTimeoutMs := 30000;
  FLastCaptureVarName := '__ai_last_capture';

  FDOMSelector := '*';
  FDOMIndex := 0;
  FDOMCount := 0;
  FLastDOMJSON := '';
  FLastDOMSelector := '';
  FLastDOMIndex := -1;
  FDOMResultVarName := '__ai_dom_result';

  FMonitorDOMEvents := True;
  FDOMEventsInstalled := False;
  FDOMEventConsolePrefix := '__AI_DOM_EVENT__';
  FDOMResultConsolePrefix := '__AI_DOM_RESULT__';
  FLastDOMEventJSON := '';

  FOnLoadURL := nil;
  FOnFinishedLoadURL := nil;
  FOnKeyPressDOM := nil;
  FOnClickDOM := nil;
  FOnSetFocusDOM := nil;
  FOnOutFocusDOM := nil;
  FOnDOMResult := nil;

  Width := 600;
  Height := 40;

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

  FChromiumWindow.OnAfterCreated := @ChromiumAfterCreated;
  FChromiumWindow.OnBeforeClose := @ChromiumBeforeClose;
  FChromiumWindow.OnClose := @ChromiumClose;

  HookChromiumEvents;
end;

procedure TAIChromiumBrowser.UnhookChromiumWindow;
begin
  if not Assigned(FChromiumWindow) then
    Exit;

  UnhookChromiumEvents;

  if FChromiumWindow.OnAfterCreated = @ChromiumAfterCreated then
    FChromiumWindow.OnAfterCreated := nil;

  if FChromiumWindow.OnBeforeClose = @ChromiumBeforeClose then
    FChromiumWindow.OnBeforeClose := nil;

  if FChromiumWindow.OnClose = @ChromiumClose then
    FChromiumWindow.OnClose := nil;
end;

procedure TAIChromiumBrowser.HookChromiumEvents;
begin
  if not Assigned(FChromiumWindow) then
    Exit;

  if not Assigned(FChromiumWindow.ChromiumBrowser) then
    Exit;

  FChromiumWindow.ChromiumBrowser.OnLoadStart := @ChromiumLoadStart;
  FChromiumWindow.ChromiumBrowser.OnLoadEnd := @ChromiumLoadEnd;
  FChromiumWindow.ChromiumBrowser.OnConsoleMessage := @ChromiumConsoleMessage;
end;

procedure TAIChromiumBrowser.UnhookChromiumEvents;
begin
  if not Assigned(FChromiumWindow) then
    Exit;

  if not Assigned(FChromiumWindow.ChromiumBrowser) then
    Exit;

  if FChromiumWindow.ChromiumBrowser.OnLoadStart = @ChromiumLoadStart then
    FChromiumWindow.ChromiumBrowser.OnLoadStart := nil;

  if FChromiumWindow.ChromiumBrowser.OnLoadEnd = @ChromiumLoadEnd then
    FChromiumWindow.ChromiumBrowser.OnLoadEnd := nil;

  if FChromiumWindow.ChromiumBrowser.OnConsoleMessage = @ChromiumConsoleMessage then
    FChromiumWindow.ChromiumBrowser.OnConsoleMessage := nil;
end;

procedure TAIChromiumBrowser.ChromiumAfterCreated(Sender: TObject);
begin
  FBrowserReady := True;
  FLastResult := 'Chromium browser initialized.';

  HookChromiumEvents;

  if (FPendingURL <> '') and Assigned(FChromiumWindow) then
  begin
    FChromiumWindow.LoadURL(FPendingURL);
    FPendingURL := '';
  end;

  if FMonitorDOMEvents then
    InstallDOMEventMonitor;
end;

procedure TAIChromiumBrowser.ChromiumBeforeClose(Sender: TObject);
begin
  FBrowserReady := False;
end;

procedure TAIChromiumBrowser.ChromiumClose(Sender: TObject);
begin
  // Handled by ChromiumBeforeClose usually.
end;

procedure TAIChromiumBrowser.ChromiumLoadStart(
  Sender: TObject;
  const browser: ICefBrowser;
  const frame: ICefFrame;
  transitionType: TCefTransitionType
);
var
  vURL: string;
  vIsMainFrame: Boolean;
begin
  vURL := '';

  if Assigned(frame) then
    vURL := frame.Url;

  vIsMainFrame := Assigned(frame) and frame.IsMain;

  FLastResult := 'URL load started: ' + vURL;

  QueueURLLoadEvent(vURL, 0, vIsMainFrame, False);
end;

procedure TAIChromiumBrowser.ChromiumLoadEnd(
  Sender: TObject;
  const browser: ICefBrowser;
  const frame: ICefFrame;
  httpStatusCode: Integer
);
var
  vURL: string;
  vIsMainFrame: Boolean;
begin
  vURL := '';

  if Assigned(frame) then
    vURL := frame.Url;

  vIsMainFrame := Assigned(frame) and frame.IsMain;

  if vIsMainFrame then
    FURL := vURL;

  FLastResult := 'URL load finished: ' + vURL + ' HTTP=' + IntToStr(httpStatusCode);

  QueueURLLoadEvent(vURL, httpStatusCode, vIsMainFrame, True);

  if FMonitorDOMEvents and vIsMainFrame then
  begin
    FDOMEventsInstalled := False;
    InstallDOMEventMonitor;
  end;
end;

procedure TAIChromiumBrowser.ChromiumConsoleMessage(
  Sender: TObject;
  const browser: ICefBrowser;
  level: TCefLogSeverity;
  const message_, source: ustring;
  line: Integer;
  out Result: Boolean
);
var
  Msg: string;
  JSONText: string;
begin
  Result := False;

  Msg := string(message_);

  if (FDOMEventConsolePrefix <> '') and
     (Length(Msg) > Length(FDOMEventConsolePrefix)) and
     (Copy(Msg, 1, Length(FDOMEventConsolePrefix)) = FDOMEventConsolePrefix) then
  begin
    JSONText := Copy(Msg, Length(FDOMEventConsolePrefix) + 1, MaxInt);
    ProcessDOMConsoleMessage(JSONText);
    Result := True;
    Exit;
  end;

  if (FDOMResultConsolePrefix <> '') and
     (Length(Msg) > Length(FDOMResultConsolePrefix)) and
     (Copy(Msg, 1, Length(FDOMResultConsolePrefix)) = FDOMResultConsolePrefix) then
  begin
    JSONText := Copy(Msg, Length(FDOMResultConsolePrefix) + 1, MaxInt);
    ProcessDOMResultConsoleMessage(JSONText);
    Result := True;
    Exit;
  end;
end;

procedure TAIChromiumBrowser.QueueURLLoadEvent(
  const AURL: string;
  AHttpStatusCode: Integer;
  AIsMainFrame: Boolean;
  AIsFinished: Boolean
);
var
  Data: TAIURLQueuedEventData;
begin
  Data := TAIURLQueuedEventData.Create;
  Data.URL := AURL;
  Data.HttpStatusCode := AHttpStatusCode;
  Data.IsMainFrame := AIsMainFrame;
  Data.IsFinished := AIsFinished;

  Application.QueueAsyncCall(@DoURLLoadEventAsync, PtrInt(Data));
end;

procedure TAIChromiumBrowser.DoURLLoadEventAsync(Data: PtrInt);
var
  EventData: TAIURLQueuedEventData;
begin
  EventData := TAIURLQueuedEventData(Data);

  try
    if EventData = nil then
      Exit;

    if EventData.IsFinished then
    begin
      if Assigned(FOnFinishedLoadURL) then
        FOnFinishedLoadURL(Self, EventData.URL, EventData.HttpStatusCode, EventData.IsMainFrame);
    end
    else
    begin
      if Assigned(FOnLoadURL) then
        FOnLoadURL(Self, EventData.URL, EventData.IsMainFrame);
    end;
  finally
    EventData.Free;
  end;
end;

procedure TAIChromiumBrowser.QueueDOMEvent(AData: TAIDOMQueuedEventData);
begin
  if AData = nil then
    Exit;

  Application.QueueAsyncCall(@DoDOMEventAsync, PtrInt(AData));
end;

procedure TAIChromiumBrowser.DoDOMEventAsync(Data: PtrInt);
var
  EventData: TAIDOMQueuedEventData;
begin
  EventData := TAIDOMQueuedEventData(Data);

  try
    if EventData = nil then
      Exit;

    if SameText(EventData.EventName, 'keypress') or
       SameText(EventData.EventName, 'input') then
    begin
      if Assigned(FOnKeyPressDOM) then
        FOnKeyPressDOM(
          Self,
          EventData.EventName,
          EventData.Selector,
          EventData.TagName,
          EventData.Id,
          EventData.Name,
          EventData.DOMClassName,
          EventData.PropertyName,
          EventData.Value,
          EventData.Key,
          EventData.KeyCode
        );
    end
    else if SameText(EventData.EventName, 'click') then
    begin
      if Assigned(FOnClickDOM) then
        FOnClickDOM(
          Self,
          EventData.EventName,
          EventData.Selector,
          EventData.TagName,
          EventData.Id,
          EventData.Name,
          EventData.DOMClassName,
          EventData.PropertyName,
          EventData.Value,
          EventData.Key,
          EventData.KeyCode
        );
    end
    else if SameText(EventData.EventName, 'focusin') then
    begin
      if Assigned(FOnSetFocusDOM) then
        FOnSetFocusDOM(
          Self,
          EventData.EventName,
          EventData.Selector,
          EventData.TagName,
          EventData.Id,
          EventData.Name,
          EventData.DOMClassName,
          EventData.PropertyName,
          EventData.Value,
          EventData.Key,
          EventData.KeyCode
        );
    end
    else if SameText(EventData.EventName, 'focusout') then
    begin
      if Assigned(FOnOutFocusDOM) then
        FOnOutFocusDOM(
          Self,
          EventData.EventName,
          EventData.Selector,
          EventData.TagName,
          EventData.Id,
          EventData.Name,
          EventData.DOMClassName,
          EventData.PropertyName,
          EventData.Value,
          EventData.Key,
          EventData.KeyCode
        );
    end;
  finally
    EventData.Free;
  end;
end;

procedure TAIChromiumBrowser.QueueDOMResult(AData: TAIDOMResultQueuedData);
begin
  if AData = nil then
    Exit;

  Application.QueueAsyncCall(@DoDOMResultAsync, PtrInt(AData));
end;

procedure TAIChromiumBrowser.DoDOMResultAsync(Data: PtrInt);
var
  ResultData: TAIDOMResultQueuedData;
begin
  ResultData := TAIDOMResultQueuedData(Data);

  try
    if ResultData = nil then
      Exit;

    if Assigned(FOnDOMResult) then
      FOnDOMResult(
        Self,
        ResultData.Kind,
        ResultData.Selector,
        ResultData.Index,
        ResultData.Count,
        ResultData.JSON
      );
  finally
    ResultData.Free;
  end;
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

function TAIChromiumBrowser.EscapeJSONText(const S: string): string;
var
  I: Integer;
begin
  Result := '';

  for I := 1 to Length(S) do
  begin
    case S[I] of
      '\': Result := Result + '\\';
      '"': Result := Result + '\"';
      #13: Result := Result + '\r';
      #10: Result := Result + '\n';
      #9: Result := Result + '\t';
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

function TAIChromiumBrowser.IsSafeDOMMethodName(const S: string): Boolean;
var
  I: Integer;
begin
  Result := False;

  if Trim(S) = '' then
    Exit;

  if not (S[1] in ['A'..'Z', 'a'..'z', '_', '$']) then
    Exit;

  for I := 1 to Length(S) do
  begin
    if not (S[I] in ['A'..'Z', 'a'..'z', '0'..'9', '_', '$']) then
      Exit;
  end;

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

procedure TAIChromiumBrowser.MarkDOMRequest(const AKind, ASelector: string; AIndex: Integer);
begin
  FDOMSelector := ASelector;
  FDOMIndex := AIndex;
  FLastDOMSelector := ASelector;
  FLastDOMIndex := AIndex;

  FLastDOMJSON :=
    '{"pending":true,"kind":"' + EscapeJSONText(AKind) +
    '","selector":"' + EscapeJSONText(ASelector) +
    '","index":' + IntToStr(AIndex) +
    ',"resultVar":"' + EscapeJSONText(FDOMResultVarName) + '"}';
end;

function TAIChromiumBrowser.DOMElementExpression(const ASelector: string; AIndex: Integer): string;
begin
  if AIndex < 0 then
    AIndex := 0;

  Result :=
    'document.querySelectorAll("' + EscapeJSString(ASelector) + '")[' + IntToStr(AIndex) + ']';
end;

function TAIChromiumBrowser.DOMStoreResultScript(
  const AKind, ASelector: string;
  AIndex: Integer;
  const AValueExpression: string
): string;
begin
  Result :=
    'window["' + EscapeJSString(FDOMResultVarName) + '"] = {' +
    '  kind: "' + EscapeJSString(AKind) + '",' +
    '  selector: "' + EscapeJSString(ASelector) + '",' +
    '  index: ' + IntToStr(AIndex) + ',' +
    '  success: true,' +
    '  count: (typeof __ai_count !== "undefined") ? __ai_count : -1,' +
    '  value: (' + AValueExpression + ')' +
    '};' +
    'window["' + EscapeJSString(FLastCaptureVarName) + '"] = window["' + EscapeJSString(FDOMResultVarName) + '"];' +
    'console.log("' + EscapeJSString(FDOMResultConsolePrefix) + '" + JSON.stringify(window["' + EscapeJSString(FDOMResultVarName) + '"]));';
end;

function TAIChromiumBrowser.DOMStoreErrorScript(
  const AKind, ASelector: string;
  AIndex: Integer;
  const AErrorMessage: string
): string;
begin
  Result :=
    'window["' + EscapeJSString(FDOMResultVarName) + '"] = {' +
    '  kind: "' + EscapeJSString(AKind) + '",' +
    '  selector: "' + EscapeJSString(ASelector) + '",' +
    '  index: ' + IntToStr(AIndex) + ',' +
    '  success: false,' +
    '  count: 0,' +
    '  value: "",' +
    '  error: "' + EscapeJSString(AErrorMessage) + '"' +
    '};' +
    'window["' + EscapeJSString(FLastCaptureVarName) + '"] = window["' + EscapeJSString(FDOMResultVarName) + '"];' +
    'console.log("' + EscapeJSString(FDOMResultConsolePrefix) + '" + JSON.stringify(window["' + EscapeJSString(FDOMResultVarName) + '"]));';
end;

function TAIChromiumBrowser.DOMElementObjectExpression: string;
begin
  Result :=
    '(function(el, idx){' +
    '  var attrs = {};' +
    '  if (el.attributes) {' +
    '    for (var i = 0; i < el.attributes.length; i++) {' +
    '      attrs[el.attributes[i].name] = el.attributes[i].value;' +
    '    }' +
    '  }' +
    '  var methods = [];' +
    '  var p = el;' +
    '  while (p) {' +
    '    Object.getOwnPropertyNames(p).forEach(function(k){' +
    '      try {' +
    '        if (typeof el[k] === "function" && methods.indexOf(k) < 0) methods.push(k);' +
    '      } catch(e) {}' +
    '    });' +
    '    p = Object.getPrototypeOf(p);' +
    '  }' +
    '  return {' +
    '    index: idx,' +
    '    tagName: el.tagName || "",' +
    '    id: el.id || "",' +
    '    name: el.getAttribute ? (el.getAttribute("name") || "") : "",' +
    '    className: String(el.className || ""),' +
    '    type: el.getAttribute ? (el.getAttribute("type") || "") : "",' +
    '    role: el.getAttribute ? (el.getAttribute("role") || "") : "",' +
    '    title: el.getAttribute ? (el.getAttribute("title") || "") : "",' +
    '    ariaLabel: el.getAttribute ? (el.getAttribute("aria-label") || "") : "",' +
    '    jsname: el.getAttribute ? (el.getAttribute("jsname") || "") : "",' +
    '    value: ("value" in el) ? el.value : "",' +
    '    text: el.innerText || "",' +
    '    html: el.outerHTML || "",' +
    '    attributes: attrs,' +
    '    methods: methods.sort()' +
    '  };' +
    '})';
end;

function TAIChromiumBrowser.InstallDOMEventMonitor: Boolean;
begin
  Result := False;

  if not FMonitorDOMEvents then
    Exit;

  if FDOMEventsInstalled then
  begin
    Result := True;
    Exit;
  end;

  Result := ExecuteJavaScript(BuildDOMEventMonitorScript);

  if Result then
  begin
    FDOMEventsInstalled := True;
    FLastResult := 'DOM event monitor installed.';
  end;
end;

function TAIChromiumBrowser.BuildDOMEventMonitorScript: string;
begin
  Result :=
    '(function(){' +
    '  if (window.__ai_dom_event_monitor_installed) return;' +
    '  window.__ai_dom_event_monitor_installed = true;' +

    '  function safe(v){ return (v === null || typeof v === "undefined") ? "" : String(v); }' +

    '  function cssPath(el){' +
    '    try {' +
    '      if (!el || !el.tagName) return "";' +
    '      if (el.id) return el.tagName.toLowerCase() + "#" + el.id;' +
    '      var parts = [];' +
    '      while (el && el.nodeType === 1 && parts.length < 5) {' +
    '        var part = el.tagName.toLowerCase();' +
    '        var name = el.getAttribute("name");' +
    '        var jsname = el.getAttribute("jsname");' +
    '        var role = el.getAttribute("role");' +
    '        if (name) part += "[name=\"" + name + "\"]";' +
    '        else if (jsname) part += "[jsname=\"" + jsname + "\"]";' +
    '        else if (role) part += "[role=\"" + role + "\"]";' +
    '        parts.unshift(part);' +
    '        el = el.parentElement;' +
    '      }' +
    '      return parts.join(" > ");' +
    '    } catch(e) {' +
    '      return "";' +
    '    }' +
    '  }' +

    '  function propertyName(el){' +
    '    if (!el) return "";' +
    '    if ("value" in el) return "value";' +
    '    if (el.isContentEditable) return "innerText";' +
    '    return "innerText";' +
    '  }' +

    '  function propertyValue(el){' +
    '    if (!el) return "";' +
    '    if ("value" in el) return safe(el.value);' +
    '    if (el.isContentEditable) return safe(el.innerText);' +
    '    return safe(el.innerText);' +
    '  }' +

    '  function buildPayload(ev){' +
    '    var el = ev.target || document.activeElement;' +
    '    return {' +
    '      eventName: safe(ev.type),' +
    '      selector: cssPath(el),' +
    '      tagName: el && el.tagName ? safe(el.tagName) : "",' +
    '      id: el && el.id ? safe(el.id) : "",' +
    '      name: el && el.getAttribute ? safe(el.getAttribute("name")) : "",' +
    '      className: el && el.className ? safe(el.className) : "",' +
    '      propertyName: propertyName(el),' +
    '      value: propertyValue(el),' +
    '      key: safe(ev.key),' +
    '      keyCode: ev.keyCode || ev.which || 0' +
    '    };' +
    '  }' +

    '  function send(ev){' +
    '    try {' +
    '      var payload = buildPayload(ev);' +
    '      window.__ai_last_dom_event = payload;' +
    '      console.log("' + EscapeJSString(FDOMEventConsolePrefix) + '" + JSON.stringify(payload));' +
    '    } catch(e) {' +
    '      console.log("' + EscapeJSString(FDOMEventConsolePrefix) + '" + JSON.stringify({' +
    '        eventName: "error",' +
    '        selector: "",' +
    '        tagName: "",' +
    '        id: "",' +
    '        name: "",' +
    '        className: "",' +
    '        propertyName: "",' +
    '        value: String(e),' +
    '        key: "",' +
    '        keyCode: 0' +
    '      }));' +
    '    }' +
    '  }' +

    '  document.addEventListener("keypress", send, true);' +
    '  document.addEventListener("input", send, true);' +
    '  document.addEventListener("click", send, true);' +
    '  document.addEventListener("focusin", send, true);' +
    '  document.addEventListener("focusout", send, true);' +
    '})();';
end;

function TAIChromiumBrowser.JSONGetStr(AObj: TJSONObject; const AName: string): string;
var
  Data: TJSONData;
begin
  Result := '';

  if AObj = nil then
    Exit;

  Data := AObj.Find(AName);

  if Data <> nil then
    Result := Data.AsString;
end;

function TAIChromiumBrowser.JSONGetInt(
  AObj: TJSONObject;
  const AName: string;
  ADefault: Integer
): Integer;
var
  Data: TJSONData;
begin
  Result := ADefault;

  if AObj = nil then
    Exit;

  Data := AObj.Find(AName);

  if Data <> nil then
    Result := Data.AsInteger;
end;

procedure TAIChromiumBrowser.ProcessDOMConsoleMessage(const AJSON: string);
var
  Parser: TJSONParser;
  Data: TJSONData;
  Obj: TJSONObject;
  EventData: TAIDOMQueuedEventData;
begin
  FLastDOMEventJSON := AJSON;

  Parser := nil;
  Data := nil;

  try
    Parser := TJSONParser.Create(AJSON);
    Data := Parser.Parse;

    if not (Data is TJSONObject) then
      Exit;

    Obj := TJSONObject(Data);

    EventData := TAIDOMQueuedEventData.Create;
    EventData.EventName := JSONGetStr(Obj, 'eventName');
    EventData.Selector := JSONGetStr(Obj, 'selector');
    EventData.TagName := JSONGetStr(Obj, 'tagName');
    EventData.Id := JSONGetStr(Obj, 'id');
    EventData.Name := JSONGetStr(Obj, 'name');
    EventData.DOMClassName := JSONGetStr(Obj, 'className');
    EventData.PropertyName := JSONGetStr(Obj, 'propertyName');
    EventData.Value := JSONGetStr(Obj, 'value');
    EventData.Key := JSONGetStr(Obj, 'key');
    EventData.KeyCode := JSONGetInt(Obj, 'keyCode', 0);

    QueueDOMEvent(EventData);
  finally
    Data.Free;
    Parser.Free;
  end;
end;

procedure TAIChromiumBrowser.ProcessDOMResultConsoleMessage(const AJSON: string);
var
  Parser: TJSONParser;
  Data: TJSONData;
  Obj: TJSONObject;
  ResultData: TAIDOMResultQueuedData;
begin
  FLastDOMJSON := AJSON;

  Parser := nil;
  Data := nil;

  try
    Parser := TJSONParser.Create(AJSON);
    Data := Parser.Parse;

    if not (Data is TJSONObject) then
      Exit;

    Obj := TJSONObject(Data);

    FDOMCount := JSONGetInt(Obj, 'count', FDOMCount);

    ResultData := TAIDOMResultQueuedData.Create;
    ResultData.Kind := JSONGetStr(Obj, 'kind');
    ResultData.Selector := JSONGetStr(Obj, 'selector');
    ResultData.Index := JSONGetInt(Obj, 'index', -1);
    ResultData.Count := JSONGetInt(Obj, 'count', -1);
    ResultData.JSON := AJSON;

    QueueDOMResult(ResultData);
  finally
    Data.Free;
    Parser.Free;
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

  if not HasChromiumWindow then
    Exit;

  if FChromiumWindow.Initialized then
  begin
    FBrowserReady := True;
    HookChromiumEvents;
    Result := True;
    FLastResult := 'Browser already initialized.';

    if FMonitorDOMEvents then
      InstallDOMEventMonitor;

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

  FDOMEventsInstalled := False;
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
    FDOMEventsInstalled := False;
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

  HookChromiumEvents;

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

function TAIChromiumBrowser.DOMList(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  MarkDOMRequest('dom-list', ASelector, -1);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var selector = "' + EscapeJSString(ASelector) + '";' +
    '    var list = Array.prototype.slice.call(document.querySelectorAll(selector));' +
    '    var __ai_count = list.length;' +
    '    var toObj = ' + DOMElementObjectExpression + ';' +
    '    var result = list.map(function(el, idx){ return toObj(el, idx); });' +
    '    window["' + EscapeJSString(FDOMResultVarName) + '"] = {' +
    '      kind: "dom-list",' +
    '      selector: selector,' +
    '      index: -1,' +
    '      success: true,' +
    '      count: result.length,' +
    '      value: result' +
    '    };' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = window["' + EscapeJSString(FDOMResultVarName) + '"];' +
    '    console.log("' + EscapeJSString(FDOMResultConsolePrefix) + '" + JSON.stringify(window["' + EscapeJSString(FDOMResultVarName) + '"]));' +
    '  } catch(e) {' +
    '    window["' + EscapeJSString(FDOMResultVarName) + '"] = {' +
    '      kind: "dom-list",' +
    '      selector: "' + EscapeJSString(ASelector) + '",' +
    '      index: -1,' +
    '      success: false,' +
    '      count: 0,' +
    '      value: [],' +
    '      error: String(e)' +
    '    };' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = window["' + EscapeJSString(FDOMResultVarName) + '"];' +
    '    console.log("' + EscapeJSString(FDOMResultConsolePrefix) + '" + JSON.stringify(window["' + EscapeJSString(FDOMResultVarName) + '"]));' +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMList requested: ' + ASelector;
end;

function TAIChromiumBrowser.DOMCount(const ASelector: string): Boolean;
var
  JSScript: string;
begin
  MarkDOMRequest('dom-count', ASelector, -1);
  FDOMCount := -1;

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var selector = "' + EscapeJSString(ASelector) + '";' +
    '    var c = document.querySelectorAll(selector).length;' +
    '    window["' + EscapeJSString(FDOMResultVarName) + '"] = {' +
    '      kind: "dom-count",' +
    '      selector: selector,' +
    '      index: -1,' +
    '      success: true,' +
    '      count: c,' +
    '      value: String(c)' +
    '    };' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = window["' + EscapeJSString(FDOMResultVarName) + '"];' +
    '    console.log("' + EscapeJSString(FDOMResultConsolePrefix) + '" + JSON.stringify(window["' + EscapeJSString(FDOMResultVarName) + '"]));' +
    '  } catch(e) {' +
    '    window["' + EscapeJSString(FDOMResultVarName) + '"] = {' +
    '      kind: "dom-count",' +
    '      selector: "' + EscapeJSString(ASelector) + '",' +
    '      index: -1,' +
    '      success: false,' +
    '      count: 0,' +
    '      value: "0",' +
    '      error: String(e)' +
    '    };' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = window["' + EscapeJSString(FDOMResultVarName) + '"];' +
    '    console.log("' + EscapeJSString(FDOMResultConsolePrefix) + '" + JSON.stringify(window["' + EscapeJSString(FDOMResultVarName) + '"]));' +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMCount requested: ' + ASelector;
end;

function TAIChromiumBrowser.DOMGetElement(const ASelector: string; AIndex: Integer): Boolean;
var
  JSScript: string;
begin
  MarkDOMRequest('dom-get-element', ASelector, AIndex);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var selector = "' + EscapeJSString(ASelector) + '";' +
    '    var index = ' + IntToStr(AIndex) + ';' +
    '    var el = document.querySelectorAll(selector)[index];' +
    '    var __ai_count = document.querySelectorAll(selector).length;' +
    '    if (!el) {' +
           DOMStoreErrorScript('dom-get-element', ASelector, AIndex, 'Element not found') +
    '      return;' +
    '    }' +
    '    var toObj = ' + DOMElementObjectExpression + ';' +
    '    var obj = toObj(el, index);' +
         DOMStoreResultScript('dom-get-element', ASelector, AIndex, 'obj') +
    '  } catch(e) {' +
         DOMStoreErrorScript('dom-get-element', ASelector, AIndex, 'DOMGetElement exception') +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMGetElement requested: ' + ASelector + '[' + IntToStr(AIndex) + ']';
end;

function TAIChromiumBrowser.DOMGetProperty(const ASelector: string; AIndex: Integer; const APropertyName: string): Boolean;
var
  JSScript: string;
begin
  MarkDOMRequest('dom-get-property', ASelector, AIndex);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var prop = "' + EscapeJSString(APropertyName) + '";' +
    '    var list = document.querySelectorAll("' + EscapeJSString(ASelector) + '");' +
    '    var __ai_count = list.length;' +
    '    var el = list[' + IntToStr(AIndex) + '];' +
    '    if (!el) {' +
           DOMStoreErrorScript('dom-get-property', ASelector, AIndex, 'Element not found') +
    '      return;' +
    '    }' +
         DOMStoreResultScript('dom-get-property', ASelector, AIndex, 'String(el[prop])') +
    '  } catch(e) {' +
         DOMStoreErrorScript('dom-get-property', ASelector, AIndex, 'DOMGetProperty exception') +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMGetProperty requested: ' + APropertyName;
end;

function TAIChromiumBrowser.DOMSetProperty(const ASelector: string; AIndex: Integer; const APropertyName, AValue: string): Boolean;
var
  JSScript: string;
begin
  MarkDOMRequest('dom-set-property', ASelector, AIndex);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var prop = "' + EscapeJSString(APropertyName) + '";' +
    '    var list = document.querySelectorAll("' + EscapeJSString(ASelector) + '");' +
    '    var __ai_count = list.length;' +
    '    var el = list[' + IntToStr(AIndex) + '];' +
    '    if (!el) {' +
           DOMStoreErrorScript('dom-set-property', ASelector, AIndex, 'Element not found') +
    '      return;' +
    '    }' +
    '    el[prop] = "' + EscapeJSString(AValue) + '";' +
    '    el.dispatchEvent(new Event("input", {bubbles: true, cancelable: true}));' +
    '    el.dispatchEvent(new Event("change", {bubbles: true, cancelable: true}));' +
         DOMStoreResultScript('dom-set-property', ASelector, AIndex, 'String(el[prop])') +
    '  } catch(e) {' +
         DOMStoreErrorScript('dom-set-property', ASelector, AIndex, 'DOMSetProperty exception') +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMSetProperty requested: ' + APropertyName;
end;

function TAIChromiumBrowser.DOMGetAttributeValue(const ASelector: string; AIndex: Integer; const AAttributeName: string): Boolean;
var
  JSScript: string;
begin
  MarkDOMRequest('dom-get-attribute', ASelector, AIndex);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var attr = "' + EscapeJSString(AAttributeName) + '";' +
    '    var list = document.querySelectorAll("' + EscapeJSString(ASelector) + '");' +
    '    var __ai_count = list.length;' +
    '    var el = list[' + IntToStr(AIndex) + '];' +
    '    if (!el) {' +
           DOMStoreErrorScript('dom-get-attribute', ASelector, AIndex, 'Element not found') +
    '      return;' +
    '    }' +
         DOMStoreResultScript('dom-get-attribute', ASelector, AIndex, 'el.getAttribute(attr) || ""') +
    '  } catch(e) {' +
         DOMStoreErrorScript('dom-get-attribute', ASelector, AIndex, 'DOMGetAttribute exception') +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMGetAttributeValue requested: ' + AAttributeName;
end;

function TAIChromiumBrowser.DOMSetAttributeValue(const ASelector: string; AIndex: Integer; const AAttributeName, AValue: string): Boolean;
var
  JSScript: string;
begin
  MarkDOMRequest('dom-set-attribute', ASelector, AIndex);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var attr = "' + EscapeJSString(AAttributeName) + '";' +
    '    var list = document.querySelectorAll("' + EscapeJSString(ASelector) + '");' +
    '    var __ai_count = list.length;' +
    '    var el = list[' + IntToStr(AIndex) + '];' +
    '    if (!el) {' +
           DOMStoreErrorScript('dom-set-attribute', ASelector, AIndex, 'Element not found') +
    '      return;' +
    '    }' +
    '    el.setAttribute(attr, "' + EscapeJSString(AValue) + '");' +
         DOMStoreResultScript('dom-set-attribute', ASelector, AIndex, 'el.getAttribute(attr) || ""') +
    '  } catch(e) {' +
         DOMStoreErrorScript('dom-set-attribute', ASelector, AIndex, 'DOMSetAttribute exception') +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMSetAttributeValue requested: ' + AAttributeName;
end;

function TAIChromiumBrowser.DOMGetValue(const ASelector: string; AIndex: Integer): Boolean;
begin
  Result := DOMGetProperty(ASelector, AIndex, 'value');
end;

function TAIChromiumBrowser.DOMSetValue(const ASelector: string; AIndex: Integer; const AValue: string): Boolean;
var
  JSScript: string;
begin
  MarkDOMRequest('dom-set-value', ASelector, AIndex);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var list = document.querySelectorAll("' + EscapeJSString(ASelector) + '");' +
    '    var __ai_count = list.length;' +
    '    var el = list[' + IntToStr(AIndex) + '];' +
    '    if (!el) {' +
           DOMStoreErrorScript('dom-set-value', ASelector, AIndex, 'Element not found') +
    '      return;' +
    '    }' +
    '    el.focus();' +
    '    var proto = Object.getPrototypeOf(el);' +
    '    var desc = Object.getOwnPropertyDescriptor(proto, "value");' +
    '    if (desc && desc.set) desc.set.call(el, "' + EscapeJSString(AValue) + '");' +
    '    else el.value = "' + EscapeJSString(AValue) + '";' +
    '    el.dispatchEvent(new Event("input", {bubbles: true, cancelable: true}));' +
    '    el.dispatchEvent(new Event("change", {bubbles: true, cancelable: true}));' +
         DOMStoreResultScript('dom-set-value', ASelector, AIndex, '("value" in el) ? el.value : ""') +
    '  } catch(e) {' +
         DOMStoreErrorScript('dom-set-value', ASelector, AIndex, 'DOMSetValue exception') +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMSetValue requested: ' + ASelector + '[' + IntToStr(AIndex) + ']';
end;

function TAIChromiumBrowser.DOMGetText(const ASelector: string; AIndex: Integer): Boolean;
begin
  Result := DOMGetProperty(ASelector, AIndex, 'innerText');
end;

function TAIChromiumBrowser.DOMSetText(const ASelector: string; AIndex: Integer; const AText: string): Boolean;
begin
  Result := DOMSetProperty(ASelector, AIndex, 'innerText', AText);
end;

function TAIChromiumBrowser.DOMCallMethod(const ASelector: string; AIndex: Integer; const AMethodName: string; const AArgsJSON: string): Boolean;
var
  JSScript: string;
begin
  Result := False;
  ClearError;

  if not IsSafeDOMMethodName(AMethodName) then
  begin
    SetError('Invalid DOM method name.');
    Exit;
  end;

  MarkDOMRequest('dom-call-method', ASelector, AIndex);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var list = document.querySelectorAll("' + EscapeJSString(ASelector) + '");' +
    '    var __ai_count = list.length;' +
    '    var el = list[' + IntToStr(AIndex) + '];' +
    '    if (!el) {' +
           DOMStoreErrorScript('dom-call-method', ASelector, AIndex, 'Element not found') +
    '      return;' +
    '    }' +
    '    var methodName = "' + EscapeJSString(AMethodName) + '";' +
    '    if (typeof el[methodName] !== "function") {' +
           DOMStoreErrorScript('dom-call-method', ASelector, AIndex, 'Method not found') +
    '      return;' +
    '    }' +
    '    var args = JSON.parse("' + EscapeJSString(AArgsJSON) + '");' +
    '    if (!Array.isArray(args)) args = [args];' +
    '    var r = el[methodName].apply(el, args);' +
         DOMStoreResultScript('dom-call-method', ASelector, AIndex, '(typeof r === "undefined") ? "undefined" : String(r)') +
    '  } catch(e) {' +
         DOMStoreErrorScript('dom-call-method', ASelector, AIndex, 'DOMCallMethod exception') +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMCallMethod requested: ' + AMethodName;
end;

function TAIChromiumBrowser.DOMClick(const ASelector: string; AIndex: Integer): Boolean;
begin
  Result := DOMCallMethod(ASelector, AIndex, 'click', '[]');
end;

function TAIChromiumBrowser.DOMFocus(const ASelector: string; AIndex: Integer): Boolean;
begin
  Result := DOMCallMethod(ASelector, AIndex, 'focus', '[]');
end;

function TAIChromiumBrowser.DOMBlur(const ASelector: string; AIndex: Integer): Boolean;
begin
  Result := DOMCallMethod(ASelector, AIndex, 'blur', '[]');
end;

function TAIChromiumBrowser.DOMDispatchEvent(const ASelector: string; AIndex: Integer; const AEventName: string): Boolean;
var
  JSScript: string;
begin
  MarkDOMRequest('dom-dispatch-event', ASelector, AIndex);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var list = document.querySelectorAll("' + EscapeJSString(ASelector) + '");' +
    '    var __ai_count = list.length;' +
    '    var el = list[' + IntToStr(AIndex) + '];' +
    '    if (!el) {' +
           DOMStoreErrorScript('dom-dispatch-event', ASelector, AIndex, 'Element not found') +
    '      return;' +
    '    }' +
    '    var ev = new Event("' + EscapeJSString(AEventName) + '", {bubbles: true, cancelable: true});' +
    '    el.dispatchEvent(ev);' +
         DOMStoreResultScript('dom-dispatch-event', ASelector, AIndex, '"' + EscapeJSString(AEventName) + '"') +
    '  } catch(e) {' +
         DOMStoreErrorScript('dom-dispatch-event', ASelector, AIndex, 'DOMDispatchEvent exception') +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMDispatchEvent requested: ' + AEventName;
end;

function TAIChromiumBrowser.DOMPressKey(const ASelector: string; AIndex: Integer; const AKey: string; AKeyCode: Integer): Boolean;
var
  JSScript: string;
  EffectiveKeyCode: Integer;
begin
  MarkDOMRequest('dom-press-key', ASelector, AIndex);

  EffectiveKeyCode := AKeyCode;

  if (EffectiveKeyCode <= 0) and (Length(AKey) = 1) then
    EffectiveKeyCode := Ord(AKey[1]);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var list = document.querySelectorAll("' + EscapeJSString(ASelector) + '");' +
    '    var __ai_count = list.length;' +
    '    var el = list[' + IntToStr(AIndex) + '];' +
    '    if (!el) {' +
           DOMStoreErrorScript('dom-press-key', ASelector, AIndex, 'Element not found') +
    '      return;' +
    '    }' +
    '    el.focus();' +
    '    var opt = {' +
    '      key: "' + EscapeJSString(AKey) + '",' +
    '      code: "' + EscapeJSString(AKey) + '",' +
    '      keyCode: ' + IntToStr(EffectiveKeyCode) + ',' +
    '      which: ' + IntToStr(EffectiveKeyCode) + ',' +
    '      bubbles: true,' +
    '      cancelable: true' +
    '    };' +
    '    el.dispatchEvent(new KeyboardEvent("keydown", opt));' +
    '    el.dispatchEvent(new KeyboardEvent("keypress", opt));' +
    '    el.dispatchEvent(new KeyboardEvent("keyup", opt));' +
         DOMStoreResultScript('dom-press-key', ASelector, AIndex, '"' + EscapeJSString(AKey) + '"') +
    '  } catch(e) {' +
         DOMStoreErrorScript('dom-press-key', ASelector, AIndex, 'DOMPressKey exception') +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMPressKey requested: ' + AKey;
end;

function TAIChromiumBrowser.DOMPressEnter(const ASelector: string; AIndex: Integer): Boolean;
begin
  Result := DOMPressKey(ASelector, AIndex, 'Enter', 13);
end;

function TAIChromiumBrowser.DOMSubmitForm(const ASelector: string; AIndex: Integer): Boolean;
var
  JSScript: string;
begin
  MarkDOMRequest('dom-submit-form', ASelector, AIndex);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var list = document.querySelectorAll("' + EscapeJSString(ASelector) + '");' +
    '    var __ai_count = list.length;' +
    '    var el = list[' + IntToStr(AIndex) + '];' +
    '    if (!el) {' +
           DOMStoreErrorScript('dom-submit-form', ASelector, AIndex, 'Element not found') +
    '      return;' +
    '    }' +
    '    var form = (el.tagName && el.tagName.toLowerCase() === "form") ? el : el.form;' +
    '    if (!form) {' +
           DOMStoreErrorScript('dom-submit-form', ASelector, AIndex, 'Form not found') +
    '      return;' +
    '    }' +
    '    if (form.requestSubmit) form.requestSubmit(); else form.submit();' +
         DOMStoreResultScript('dom-submit-form', ASelector, AIndex, '"submitted"') +
    '  } catch(e) {' +
         DOMStoreErrorScript('dom-submit-form', ASelector, AIndex, 'DOMSubmitForm exception') +
    '  }' +
    '})();';

  Result := ExecuteJavaScript(JSScript);

  if Result then
    FLastResult := 'DOMSubmitForm requested.';
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
begin
  Result := DOMGetText(ASelector, 0);

  if Result then
    FLastResult := 'Text capture requested.';
end;

function TAIChromiumBrowser.CaptureValue(const ASelector: string): Boolean;
begin
  Result := DOMGetValue(ASelector, 0);

  if Result then
    FLastResult := 'Value capture requested.';
end;

function TAIChromiumBrowser.CaptureAttribute(const ASelector, AAttributeName: string): Boolean;
begin
  Result := DOMGetAttributeValue(ASelector, 0, AAttributeName);

  if Result then
    FLastResult := 'Attribute capture requested: ' + AAttributeName;
end;

function TAIChromiumBrowser.SetHTML(const ASelector, AHTML: string): Boolean;
begin
  Result := DOMSetProperty(ASelector, 0, 'innerHTML', AHTML);

  if Result then
    FLastResult := 'SetHTML requested.';
end;

function TAIChromiumBrowser.SetText(const ASelector, AText: string): Boolean;
begin
  Result := DOMSetText(ASelector, 0, AText);

  if Result then
    FLastResult := 'SetText requested.';
end;

function TAIChromiumBrowser.SetValue(const ASelector, AValue: string): Boolean;
begin
  Result := DOMSetValue(ASelector, 0, AValue);

  if Result then
    FLastResult := 'SetValue requested.';
end;

function TAIChromiumBrowser.CreateDOMElement(const AParentSelector, ATagName, AElementId, AClassName, AHTML: string): Boolean;
var
  JSScript: string;
begin
  JSScript :=
    '(function() {' +
    '  try {' +
    '    var parent = document.querySelector("' + EscapeJSString(AParentSelector) + '");' +
    '    if (!parent) return false;' +
    '    var el = document.createElement("' + EscapeJSString(ATagName) + '");' +
    '    if ("' + EscapeJSString(AElementId) + '" !== "") el.id = "' + EscapeJSString(AElementId) + '";' +
    '    if ("' + EscapeJSString(AClassName) + '" !== "") el.className = "' + EscapeJSString(AClassName) + '";' +
    '    el.innerHTML = "' + EscapeJSString(AHTML) + '";' +
    '    parent.appendChild(el);' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {kind: "create-dom", selector: "' + EscapeJSString(AParentSelector) + '", success: true, value: el.outerHTML};' +
    '  } catch(e) {' +
    '    window["' + EscapeJSString(FLastCaptureVarName) + '"] = {kind: "create-dom", selector: "' + EscapeJSString(AParentSelector) + '", success: false, value: "", error: String(e)};' +
    '  }' +
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
begin
  Result := DOMSetAttributeValue(ASelector, 0, AAttributeName, AValue);

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
    SetError('GetHtmlContent requested capture, but synchronous DOM readback is not implemented yet. Use LastCaptureVarName in browser context or use OnDOMResult/console bridge.');
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
begin
  Result := DOMClick(ASelector, 0);

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
begin
  Result := DOMFocus(ASelector, 0);

  if Result then
    FLastResult := 'Focus requested.';
end;

function TAIChromiumBrowser.Blur(const ASelector: string): Boolean;
begin
  Result := DOMBlur(ASelector, 0);

  if Result then
    FLastResult := 'Blur requested.';
end;

function TAIChromiumBrowser.DispatchEvent(const ASelector, AEventName: string): Boolean;
begin
  Result := DOMDispatchEvent(ASelector, 0, AEventName);

  if Result then
    FLastResult := 'DispatchEvent requested: ' + AEventName;
end;

function TAIChromiumBrowser.PressKey(const ASelector, AKey: string; AKeyCode: Integer): Boolean;
begin
  Result := DOMPressKey(ASelector, 0, AKey, AKeyCode);

  if Result then
    FLastResult := 'PressKey requested: ' + AKey;
end;

function TAIChromiumBrowser.PressEnter(const ASelector: string): Boolean;
begin
  Result := DOMPressEnter(ASelector, 0);
end;

function TAIChromiumBrowser.SubmitForm(const ASelector: string): Boolean;
begin
  Result := DOMSubmitForm(ASelector, 0);

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
begin
  Result := DOMSetValue(ASelector, 0, AValue);

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
