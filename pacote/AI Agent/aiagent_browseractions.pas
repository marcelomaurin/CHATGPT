unit aiagent_browseractions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiagent_actions, aichromiumbrowser;

type
  { TAIBrowserCustomAction }
  TAIBrowserCustomAction = class(TAICustomAgentAction)
  private
    FBrowser: TAIChromiumBrowser;
  protected
    function CheckBrowser: Boolean; virtual;
  public
    property Browser: TAIChromiumBrowser read FBrowser write FBrowser;
  end;

  { TAIBrowserNavigateAction }
  TAIBrowserNavigateAction = class(TAIBrowserCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TAIBrowserWaitSelectorAction }
  TAIBrowserWaitSelectorAction = class(TAIBrowserCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TAIBrowserReadPageAction }
  TAIBrowserReadPageAction = class(TAIBrowserCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TAIBrowserDOMListAction }
  TAIBrowserDOMListAction = class(TAIBrowserCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TAIBrowserCaptureTextAction }
  TAIBrowserCaptureTextAction = class(TAIBrowserCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TAIBrowserSetValueAction }
  TAIBrowserSetValueAction = class(TAIBrowserCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TAIBrowserFocusAction }
  TAIBrowserFocusAction = class(TAIBrowserCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TAIBrowserClickAction }
  TAIBrowserClickAction = class(TAIBrowserCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TAIBrowserPressEnterAction }
  TAIBrowserPressEnterAction = class(TAIBrowserCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TAIBrowserSubmitFormAction }
  TAIBrowserSubmitFormAction = class(TAIBrowserCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

  { TAIBrowserScreenshotAction }
  TAIBrowserScreenshotAction = class(TAIBrowserCustomAction)
  public
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; override;
  end;

implementation

function LocalEscapeJSString(const S: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    case S[i] of
      '\': Result := Result + '\\';
      '''': Result := Result + '\''';
      '"': Result := Result + '\"';
      #13: Result := Result + '\r';
      #10: Result := Result + '\n';
      #09: Result := Result + '\t';
      else Result := Result + S[i];
    end;
  end;
end;

{ TAIBrowserCustomAction }

function TAIBrowserCustomAction.CheckBrowser: Boolean;
begin
  Result := Assigned(FBrowser) and FBrowser.BrowserReady;
end;

{ TAIBrowserNavigateAction }

constructor TAIBrowserNavigateAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'BROWSER_NAVIGATE';
end;

function TAIBrowserNavigateAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  URL: string;
begin
  SetError('');
  if not CheckBrowser then
  begin
    SetError('Browser não associado ou não está pronto para a ação ' + ActionName);
    Exit(False);
  end;

  URL := Trim(AParams.Values['url']);
  if URL = '' then
  begin
    SetError('URL vazia para navegação.');
    Exit(False);
  end;

  if (not SameText(Copy(URL, 1, 7), 'http://')) and (not SameText(Copy(URL, 1, 8), 'https://')) then
  begin
    SetError('URL inválida ou insegura para navegação: ' + URL);
    Exit(False);
  end;

  if ASimulate then
  begin
    Result := True;
    Exit;
  end;

  Browser.Navigate(URL);
  Result := True;
end;

{ TAIBrowserWaitSelectorAction }

constructor TAIBrowserWaitSelectorAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'BROWSER_WAIT_SELECTOR';
end;

function TAIBrowserWaitSelectorAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  Selector: string;
  Timeout: Integer;
begin
  SetError('');
  if not CheckBrowser then
  begin
    SetError('Browser não associado ou não está pronto para a ação ' + ActionName);
    Exit(False);
  end;

  Selector := Trim(AParams.Values['selector']);
  if Selector = '' then
  begin
    SetError('Selector vazio em BROWSER_WAIT_SELECTOR.');
    Exit(False);
  end;

  Timeout := StrToIntDef(AParams.Values['timeout'], 5000);

  if ASimulate then
  begin
    Result := True;
    Exit;
  end;

  Result := Browser.WaitForSelector(Selector, Timeout);
end;

{ TAIBrowserReadPageAction }

constructor TAIBrowserReadPageAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'BROWSER_READ_PAGE';
end;

function TAIBrowserReadPageAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  Selector, DOMSelector: string;
begin
  SetError('');
  if not CheckBrowser then
  begin
    SetError('Browser não associado ou não está pronto para a ação ' + ActionName);
    Exit(False);
  end;

  Selector := Trim(AParams.Values['selector']);
  if Selector = '' then Selector := 'body';

  DOMSelector := Trim(AParams.Values['dom_list_selector']);
  if DOMSelector = '' then DOMSelector := 'input, textarea, button, form';

  if ASimulate then
  begin
    Result := True;
    Exit;
  end;

  // Realiza leitura do texto e depois lista elementos DOM relevantes
  Result := Browser.CaptureText(Selector);
  if Result then
    Result := Browser.DOMList(DOMSelector);
end;

{ TAIBrowserDOMListAction }

constructor TAIBrowserDOMListAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'BROWSER_DOM_LIST';
end;

function TAIBrowserDOMListAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  Selector: string;
begin
  SetError('');
  if not CheckBrowser then
  begin
    SetError('Browser não associado ou não está pronto para a ação ' + ActionName);
    Exit(False);
  end;

  Selector := Trim(AParams.Values['selector']);
  if Selector = '' then Selector := 'input, textarea, button, form';

  if ASimulate then
  begin
    Result := True;
    Exit;
  end;

  Result := Browser.DOMList(Selector);
end;

{ TAIBrowserCaptureTextAction }

constructor TAIBrowserCaptureTextAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'BROWSER_CAPTURE_TEXT';
end;

function TAIBrowserCaptureTextAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  Selector: string;
begin
  SetError('');
  if not CheckBrowser then
  begin
    SetError('Browser não associado ou não está pronto para a ação ' + ActionName);
    Exit(False);
  end;

  Selector := Trim(AParams.Values['selector']);
  if Selector = '' then Selector := 'body';

  if ASimulate then
  begin
    Result := True;
    Exit;
  end;

  Result := Browser.CaptureText(Selector);
end;

{ TAIBrowserSetValueAction }

constructor TAIBrowserSetValueAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'BROWSER_SET_VALUE';
end;

function TAIBrowserSetValueAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  Selector, Val: string;
  Idx: Integer;
begin
  SetError('');
  if not CheckBrowser then
  begin
    SetError('Browser não associado ou não está pronto para a ação ' + ActionName);
    Exit(False);
  end;

  Selector := Trim(AParams.Values['selector']);
  if Selector = '' then
  begin
    SetError('Selector vazio para preenchimento de campo (BROWSER_SET_VALUE).');
    Exit(False);
  end;

  Val := AParams.Values['value'];
  Idx := StrToIntDef(AParams.Values['index'], 0); // Tarefa 52 — Normalizar index

  if ASimulate then
  begin
    Result := True;
    Exit;
  end;

  Result := Browser.DOMSetValue(Selector, Idx, Val);
end;

{ TAIBrowserFocusAction }

constructor TAIBrowserFocusAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'BROWSER_FOCUS';
end;

function TAIBrowserFocusAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  Selector: string;
  Idx: Integer;
begin
  SetError('');
  if not CheckBrowser then
  begin
    SetError('Browser não associado ou não está pronto para a ação ' + ActionName);
    Exit(False);
  end;

  Selector := Trim(AParams.Values['selector']);
  if Selector = '' then
  begin
    SetError('Selector vazio para BROWSER_FOCUS.');
    Exit(False);
  end;

  Idx := StrToIntDef(AParams.Values['index'], 0);

  if ASimulate then
  begin
    Result := True;
    Exit;
  end;

  Result := Browser.DOMFocus(Selector, Idx);
end;

{ TAIBrowserClickAction }

constructor TAIBrowserClickAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'BROWSER_CLICK';
end;

function TAIBrowserClickAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  Selector: string;
  Idx: Integer;
begin
  SetError('');
  if not CheckBrowser then
  begin
    SetError('Browser não associado ou não está pronto para a ação ' + ActionName);
    Exit(False);
  end;

  Selector := Trim(AParams.Values['selector']);
  if Selector = '' then
  begin
    SetError('Selector vazio para BROWSER_CLICK.');
    Exit(False);
  end;

  Idx := StrToIntDef(AParams.Values['index'], 0);

  if ASimulate then
  begin
    Result := True;
    Exit;
  end;

  Result := Browser.DOMClick(Selector, Idx);
end;

{ TAIBrowserPressEnterAction }

constructor TAIBrowserPressEnterAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'BROWSER_PRESS_ENTER';
end;

function TAIBrowserPressEnterAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  Selector: string;
  Idx: Integer;
  JSScript: string;
begin
  SetError('');
  if not CheckBrowser then
  begin
    SetError('Browser não associado ou não está pronto para a ação ' + ActionName);
    Exit(False);
  end;

  Selector := Trim(AParams.Values['selector']);
  if Selector = '' then
  begin
    SetError('Selector vazio para BROWSER_PRESS_ENTER.');
    Exit(False);
  end;

  Idx := StrToIntDef(AParams.Values['index'], 0);

  if ASimulate then
  begin
    Result := True;
    Exit;
  end;

  JSScript :=
    '(function() {' +
    '  try {' +
    '    var list = document.querySelectorAll("' + LocalEscapeJSString(Selector) + '");' +
    '    var el = list[' + IntToStr(Idx) + '];' +
    '    if (!el) {' +
    '      return JSON.stringify({ ok:false, error: "element not found", selector: "' + LocalEscapeJSString(Selector) + '" });' +
    '    }' +
    '    el.focus();' +
    '    ["keydown", "keypress", "keyup"].forEach(function(type) {' +
    '      var ev = new KeyboardEvent(type, {' +
    '        key: "Enter",' +
    '        code: "Enter",' +
    '        keyCode: 13,' +
    '        which: 13,' +
    '        bubbles: true,' +
    '        cancelable: true' +
    '      });' +
    '      el.dispatchEvent(ev);' +
    '    });' +
    '    var form = el.form || el.closest("form");' +
    '    if (form) {' +
    '      if (form.requestSubmit) {' +
    '        form.requestSubmit();' +
    '        return JSON.stringify({ ok:true, method: "requestSubmit" });' +
    '      }' +
    '      form.submit();' +
    '      return JSON.stringify({ ok:true, method: "form.submit" });' +
    '    }' +
    '    var btn = document.querySelector(''button[type="submit"], input[type="submit"]'');' +
    '    if (btn) {' +
    '      btn.click();' +
    '      return JSON.stringify({ ok:true, method: "submit_button_click" });' +
    '    }' +
    '    return JSON.stringify({ ok:true, method: "enter_events_only" });' +
    '  } catch(e) {' +
    '    return JSON.stringify({ ok:false, error: e.message });' +
    '  }' +
    '})();';

  Result := Browser.ExecuteJavaScript(JSScript);
end;

{ TAIBrowserSubmitFormAction }

constructor TAIBrowserSubmitFormAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'BROWSER_SUBMIT_FORM';
end;

function TAIBrowserSubmitFormAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  Selector: string;
  Idx: Integer;
  JSScript: string;
begin
  SetError('');
  if not CheckBrowser then
  begin
    SetError('Browser não associado ou não está pronto para a ação ' + ActionName);
    Exit(False);
  end;

  Selector := Trim(AParams.Values['selector']);
  if Selector = '' then
  begin
    SetError('Selector vazio para BROWSER_SUBMIT_FORM.');
    Exit(False);
  end;

  Idx := StrToIntDef(AParams.Values['index'], 0);

  if ASimulate then
  begin
    Result := True;
    Exit;
  end;

  JSScript :=
    '(function() {' +
    '  try {' +
    '    var list = document.querySelectorAll("' + LocalEscapeJSString(Selector) + '");' +
    '    var el = list[' + IntToStr(Idx) + '];' +
    '    if (!el) {' +
    '      return JSON.stringify({ ok:false, error: "element not found", selector: "' + LocalEscapeJSString(Selector) + '" });' +
    '    }' +
    '    var form = el.form || el.closest("form");' +
    '    if (form) {' +
    '      if (form.requestSubmit) {' +
    '        form.requestSubmit();' +
    '        return JSON.stringify({ ok:true, method: "requestSubmit" });' +
    '      }' +
    '      form.submit();' +
    '      return JSON.stringify({ ok:true, method: "form.submit" });' +
    '    }' +
    '    var btn = document.querySelector(''button[type="submit"], input[type="submit"]'');' +
    '    if (btn) {' +
    '      btn.click();' +
    '      return JSON.stringify({ ok:true, method: "submit_button_click" });' +
    '    }' +
    '    return JSON.stringify({ ok:false, error: "form or submit button not found" });' +
    '  } catch(e) {' +
    '    return JSON.stringify({ ok:false, error: e.message });' +
    '  }' +
    '})();';

  Result := Browser.ExecuteJavaScript(JSScript);
end;

{ TAIBrowserScreenshotAction }

constructor TAIBrowserScreenshotAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ActionName := 'BROWSER_SCREENSHOT';
end;

function TAIBrowserScreenshotAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  FileName: string;
begin
  SetError('');
  if not CheckBrowser then
  begin
    SetError('Browser não associado ou não está pronto para a ação ' + ActionName);
    Exit(False);
  end;

  FileName := Trim(AParams.Values['filename']);
  if FileName = '' then
  begin
    SetError('Nome de arquivo vazio para captura de tela (BROWSER_SCREENSHOT).');
    Exit(False);
  end;

  if ASimulate then
  begin
    Result := True;
    Exit;
  end;

  Result := Browser.Screenshot(FileName);
end;

end.
