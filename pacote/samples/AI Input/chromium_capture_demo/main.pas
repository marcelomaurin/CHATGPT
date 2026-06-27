unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Buttons, fpjson, jsonparser,
  uCEFChromiumWindow, aibase, aichromiumbrowser;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    AIChromiumBrowser1: TAIChromiumBrowser;
    btnExecuteJS: TButton;
    Button1: TButton;
    btListVars: TButton;
    cbListProperties: TComboBox;
    ChromiumWindow1: TChromiumWindow;
    edValueVar: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    lbValue: TLabel;
    lstVars: TListBox;
    listJavascript: TListBox;
    listobjects: TListBox;
    memoJS: TMemo;
    Panel1: TPanel;
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;

    edURL: TEdit;
    edPesquisa: TEdit;
    btnInitialize: TButton;
    btnNavigate: TButton;
    btnAbrirGoogle: TButton;
    btnPesquisarGoogle: TButton;
    btnBack: TButton;
    btnForward: TButton;
    btnReload: TButton;
    btnClearLog: TButton;

    PageControl1: TPageControl;
    btSetValueVar: TToggleBox;
    tsCss: TTabSheet;
    tsJavascript: TTabSheet;
    tsBrowser: TTabSheet;
    tsAutomation: TTabSheet;
    tsHTML: TTabSheet;
    tsLog: TTabSheet;

    edValue: TEdit;
    btnSetValue: TButton;
    btnGetHTML: TButton;

    memoHTML: TMemo;
    memoLog: TMemo;

    procedure btListVarsClick(Sender: TObject);
    procedure btSetValueVarClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure cbListPropertiesChangeBounds(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnInitializeClick(Sender: TObject);
    procedure btnNavigateClick(Sender: TObject);
    procedure btnBackClick(Sender: TObject);
    procedure btnForwardClick(Sender: TObject);
    procedure btnReloadClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnSetValueClick(Sender: TObject);
    procedure btnExecuteJSClick(Sender: TObject);
    procedure btnGetHTMLClick(Sender: TObject);

    procedure btnAbrirGoogleClick(Sender: TObject);
    procedure btnPesquisarGoogleClick(Sender: TObject);
    procedure edPesquisaKeyPress(Sender: TObject; var Key: Char);
    procedure listJavascriptChangeBounds(Sender: TObject);
    procedure listobjectsChangeBounds(Sender: TObject);
    procedure lstVarsClick(Sender: TObject);
  private
    FSelectedDOMSelector: string;
    FSelectedDOMTagName: string;
    FSelectedDOMId: string;
    FSelectedDOMName: string;
    FSelectedDOMClassName: string;
    FSelectedDOMPropertyName: string;
    FSelectedDOMValue: string;
    FSelectedDOMRealIndex: Integer;

    FPendingGoogleSearch: string;
    FExecutingPendingGoogleSearch: Boolean;

    // Lista DOM carregada pelo Button1.
    FDOMListData: TJSONData;
    FDOMListSelector: string;

    // Seleção pendente vinda de evento DOM.
    FPendingSelectDOM: Boolean;
    FPendingSelectSelector: string;
    FPendingSelectTagName: string;
    FPendingSelectId: string;
    FPendingSelectName: string;
    FPendingSelectClassName: string;
    FPendingSelectPropertyName: string;
    FPendingSelectValue: string;

    // HTML source.
    FWaitingHTMLSource: Boolean;

    // JavaScript global vars/method source.
    FJSVarsData: TJSONData;
    FSelectedJSVarName: string;
    FWaitingJSMethodSource: Boolean;
    FWaitingJSVars: Boolean;
    FWaitingJSVarValue: Boolean;
    FWaitingJSSetVar: Boolean;

    procedure AddLog(const AMsg: string);
    procedure ShowComponentState;
    function EnsureBrowser: Boolean;

    function EscapeJSString(const S: string): string;

    procedure ClearSelectedDOM;
    procedure SetSelectedDOM(
      const ASelector: string;
      const ATagName: string;
      const AId: string;
      const AName: string;
      const AClassName: string;
      const APropertyName: string;
      const AValue: string
    );

    procedure ShowSelectedDOMInMemo;

    procedure ClearDOMList;
    function GetDOMArray: TJSONArray;
    function GetSelectedDOMObject: TJSONObject;

    function JSONValueToText(AData: TJSONData): string;
    function JSONGetStr(AObj: TJSONObject; const AName: string): string;
    function JSONGetInt(AObj: TJSONObject; const AName: string; ADefault: Integer = 0): Integer;

    function ExtractValueFromDOMResultJSON(const AJSON: string): string;
    procedure ShowHTMLSourceFromDOMResult(const AJSON: string);

    procedure LoadDOMListFromJSON(const AJSON: string);
    procedure FillListObjectsFromDOMArray;
    procedure FillPropertiesFromSelectedObject;
    procedure FillMethodsFromSelectedObject;

    function SelectedPropertyName: string;
    function SelectedPropertyIsAttribute: Boolean;
    function SelectedAttributeName: string;
    function SelectedPropertyLocalValue(AObj: TJSONObject; const AProp: string): string;
    procedure SelectPropertyToValue;

    procedure SavePendingDOMSelection(
      const ASelector: string;
      const ATagName: string;
      const AId: string;
      const AName: string;
      const AClassName: string;
      const APropertyName: string;
      const AValue: string
    );

    procedure ApplyPendingDOMSelection;

    function FindListObjectIndexByDOMInfo(
      const ASelector: string;
      const ATagName: string;
      const AId: string;
      const AName: string;
      const AClassName: string
    ): Integer;

    function SelectListObjectByDOMInfo(
      const ASelector: string;
      const ATagName: string;
      const AId: string;
      const AName: string;
      const AClassName: string;
      const APropertyName: string;
      const AValue: string
    ): Boolean;

    procedure SelectComboPropertyByDOMProperty(const APropertyName: string);
    procedure RefreshSelectedDOMAfterSet;

    procedure ClearJSVars;
    function GetJSVarsArray: TJSONArray;
    function GetSelectedJSVarObject: TJSONObject;
    procedure RequestSelectedDOMMethodSource(const AMethodName: string);
    procedure RequestGlobalJSVars;
    procedure LoadJSVarsFromJSON(const AJSON: string);
    procedure FillJSVarsFromJSON;
    procedure RequestSelectedJSVarValue;
    procedure SetSelectedJSVarValue;

    function GoogleLoaded: Boolean;
    function StartGoogleSearch(const AText: string): Boolean;
    function PesquisarGooglePorDOM(const AText: string): Boolean;

    // Eventos expostos pelo TAIChromiumBrowser
    procedure AIChromiumBrowser1LoadURL(
      Sender: TObject;
      const AURL: string;
      AIsMainFrame: Boolean
    );

    procedure AIChromiumBrowser1FinishedLoadURL(
      Sender: TObject;
      const AURL: string;
      AHttpStatusCode: Integer;
      AIsMainFrame: Boolean
    );

    procedure AIChromiumBrowser1KeyPressDOM(
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
    );

    procedure AIChromiumBrowser1ClickDOM(
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
    );

    procedure AIChromiumBrowser1SetFocusDOM(
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
    );

    procedure AIChromiumBrowser1OutFocusDOM(
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
    );

    procedure AIChromiumBrowser1DOMResult(
      Sender: TObject;
      const AKind: string;
      const ASelector: string;
      AIndex: Integer;
      ACount: Integer;
      const AJSON: string
    );
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Caption := 'Chromium Capture Demo - TAIChromiumBrowser + TChromiumWindow';
  lblTitle.Caption := 'Chromium Capture Demo - TAIChromiumBrowser + TChromiumWindow';
  lblStatus.Caption := 'Status: Ready';

  edURL.Text := 'https://www.google.com';
  edPesquisa.Text := 'Lazarus Free Pascal';
  edValue.Text := 'Marcelo';

  if Assigned(edValueVar) then
    edValueVar.Text := '';

  memoJS.Text :=
    'document.body.style.outline = "5px solid red";' + LineEnding +
    'console.log("TAIChromiumBrowser JavaScript test executed");';

  FDOMListData := nil;
  FDOMListSelector := '*';
  FSelectedDOMRealIndex := -1;

  FPendingGoogleSearch := '';
  FExecutingPendingGoogleSearch := False;

  FPendingSelectDOM := False;
  FPendingSelectSelector := '';
  FPendingSelectTagName := '';
  FPendingSelectId := '';
  FPendingSelectName := '';
  FPendingSelectClassName := '';
  FPendingSelectPropertyName := '';
  FPendingSelectValue := '';

  FWaitingHTMLSource := False;

  FJSVarsData := nil;
  FSelectedJSVarName := '';
  FWaitingJSMethodSource := False;
  FWaitingJSVars := False;
  FWaitingJSVarValue := False;
  FWaitingJSSetVar := False;

  ClearSelectedDOM;

  memoHTML.Clear;
  memoHTML.Lines.Add('DOM Objects');
  memoHTML.Lines.Add('');
  memoHTML.Lines.Add('Fluxo:');
  memoHTML.Lines.Add('1. Clique no Button1 para listar todos os objetos DOM do HTML em listobjects.');
  memoHTML.Lines.Add('2. Ao selecionar um item de listobjects, cbListProperties recebe as propriedades.');
  memoHTML.Lines.Add('3. Ao selecionar uma propriedade, edValue recebe o valor atual.');
  memoHTML.Lines.Add('4. Ao clicar em SetValue, o valor de edValue é aplicado no DOM.');
  memoHTML.Lines.Add('5. Ao clicar em um objeto dentro do browser, OnClickDOM procura o item correspondente em listobjects.');
  memoHTML.Lines.Add('6. listJavascript mostra métodos DOM. Ao selecionar, memoJS mostra o fonte.');
  memoHTML.Lines.Add('7. btListVars lista variáveis globais JS em lstVars.');
  memoHTML.Lines.Add('8. lstVars mostra valor em edValueVar; btSetValueVar altera o valor.');

  listobjects.Clear;
  cbListProperties.Clear;
  listJavascript.Clear;

  if Assigned(lstVars) then
    lstVars.Clear;

  // Garante eventos corretos mesmo se o .lfm estiver usando eventos antigos.
  Button1.OnClick := @Button1Click;
  listobjects.OnClick := @listobjectsChangeBounds;
  cbListProperties.OnChange := @cbListPropertiesChangeBounds;
  listJavascript.OnClick := @listJavascriptChangeBounds;

  if Assigned(btListVars) then
    btListVars.OnClick := @btListVarsClick;

  if Assigned(btSetValueVar) then
    btSetValueVar.OnClick := @btSetValueVarClick;

  if Assigned(lstVars) then
    lstVars.OnClick := @lstVarsClick;

  // Liga o componente ao TChromiumWindow visual.
  AIChromiumBrowser1.ChromiumWindow := ChromiumWindow1;

  // Ativa monitoramento DOM.
  AIChromiumBrowser1.MonitorDOMEvents := True;

  // Eventos de URL.
  AIChromiumBrowser1.OnLoadURL := @AIChromiumBrowser1LoadURL;
  AIChromiumBrowser1.OnFinishedLoadURL := @AIChromiumBrowser1FinishedLoadURL;

  // Eventos de DOM.
  AIChromiumBrowser1.OnKeyPressDOM := @AIChromiumBrowser1KeyPressDOM;
  AIChromiumBrowser1.OnClickDOM := @AIChromiumBrowser1ClickDOM;
  AIChromiumBrowser1.OnSetFocusDOM := @AIChromiumBrowser1SetFocusDOM;
  AIChromiumBrowser1.OnOutFocusDOM := @AIChromiumBrowser1OutFocusDOM;
  AIChromiumBrowser1.OnDOMResult := @AIChromiumBrowser1DOMResult;

  AddLog('Demo initialized.');
  AddLog('TAIChromiumBrowser ligado ao ChromiumWindow1.');
  AddLog('MonitorDOMEvents=True.');
  AddLog('Button1 lista todos os objetos DOM usando DOMList("*").');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  ClearDOMList;
  ClearJSVars;
end;

function TfrmMain.EscapeJSString(const S: string): string;
var
  I: Integer;
begin
  Result := '';

  for I := 1 to Length(S) do
  begin
    case S[I] of
      #92: Result := Result + '\\';
      '"': Result := Result + '\"';
      #39: Result := Result + '\u0027';
      #13: Result := Result + '\r';
      #10: Result := Result + '\n';
      #9:  Result := Result + '\t';
    else
      Result := Result + S[I];
    end;
  end;
end;

procedure TfrmMain.ClearDOMList;
begin
  FreeAndNil(FDOMListData);

  FDOMListSelector := '*';
  FSelectedDOMRealIndex := -1;

  FPendingSelectDOM := False;
  FPendingSelectSelector := '';
  FPendingSelectTagName := '';
  FPendingSelectId := '';
  FPendingSelectName := '';
  FPendingSelectClassName := '';
  FPendingSelectPropertyName := '';
  FPendingSelectValue := '';

  if Assigned(listobjects) then
    listobjects.Clear;

  if Assigned(cbListProperties) then
    cbListProperties.Clear;

  if Assigned(listJavascript) then
    listJavascript.Clear;
end;

procedure TfrmMain.ClearSelectedDOM;
begin
  FSelectedDOMSelector := '';
  FSelectedDOMTagName := '';
  FSelectedDOMId := '';
  FSelectedDOMName := '';
  FSelectedDOMClassName := '';
  FSelectedDOMPropertyName := '';
  FSelectedDOMValue := '';
  FSelectedDOMRealIndex := -1;
end;

procedure TfrmMain.SetSelectedDOM(
  const ASelector: string;
  const ATagName: string;
  const AId: string;
  const AName: string;
  const AClassName: string;
  const APropertyName: string;
  const AValue: string
);
begin
  FSelectedDOMSelector := ASelector;
  FSelectedDOMTagName := ATagName;
  FSelectedDOMId := AId;
  FSelectedDOMName := AName;
  FSelectedDOMClassName := AClassName;
  FSelectedDOMPropertyName := APropertyName;
  FSelectedDOMValue := AValue;

  ShowSelectedDOMInMemo;
end;

procedure TfrmMain.ShowSelectedDOMInMemo;
begin
  memoHTML.Lines.BeginUpdate;
  try
    memoHTML.Clear;
    memoHTML.Lines.Add('Objeto DOM selecionado');
    memoHTML.Lines.Add('');
    memoHTML.Lines.Add('Selector base: ' + FSelectedDOMSelector);
    memoHTML.Lines.Add('Index: ' + IntToStr(FSelectedDOMRealIndex));
    memoHTML.Lines.Add('Tag: ' + FSelectedDOMTagName);
    memoHTML.Lines.Add('Id: ' + FSelectedDOMId);
    memoHTML.Lines.Add('Name: ' + FSelectedDOMName);
    memoHTML.Lines.Add('Class: ' + FSelectedDOMClassName);
    memoHTML.Lines.Add('Property: ' + FSelectedDOMPropertyName);
    memoHTML.Lines.Add('Value: ' + FSelectedDOMValue);
    memoHTML.Lines.Add('');
    memoHTML.Lines.Add('Fluxo:');
    memoHTML.Lines.Add('1. Button1 lista os objetos DOM em listobjects.');
    memoHTML.Lines.Add('2. listobjects seleciona o objeto.');
    memoHTML.Lines.Add('3. cbListProperties seleciona a propriedade.');
    memoHTML.Lines.Add('4. edValue mostra/altera o valor.');
    memoHTML.Lines.Add('5. btnSetValue aplica no DOM.');
  finally
    memoHTML.Lines.EndUpdate;
  end;
end;

function TfrmMain.GetDOMArray: TJSONArray;
var
  Obj: TJSONObject;
  Data: TJSONData;
begin
  Result := nil;

  if not (FDOMListData is TJSONObject) then
    Exit;

  Obj := TJSONObject(FDOMListData);
  Data := Obj.Find('value');

  if Data is TJSONArray then
    Result := TJSONArray(Data);
end;

function TfrmMain.GetSelectedDOMObject: TJSONObject;
var
  Arr: TJSONArray;
  Data: TJSONData;
begin
  Result := nil;

  if listobjects.ItemIndex < 0 then
    Exit;

  Arr := GetDOMArray;
  if Arr = nil then
    Exit;

  if listobjects.ItemIndex >= Arr.Count then
    Exit;

  Data := Arr.Items[listobjects.ItemIndex];

  if Data is TJSONObject then
    Result := TJSONObject(Data);
end;

function TfrmMain.JSONValueToText(AData: TJSONData): string;
begin
  Result := '';

  if AData = nil then
    Exit;

  try
    Result := AData.AsString;
  except
    Result := AData.AsJSON;
  end;
end;

function TfrmMain.JSONGetStr(AObj: TJSONObject; const AName: string): string;
var
  Data: TJSONData;
begin
  Result := '';

  if AObj = nil then
    Exit;

  Data := AObj.Find(AName);

  if Data <> nil then
    Result := JSONValueToText(Data);
end;

function TfrmMain.JSONGetInt(AObj: TJSONObject; const AName: string; ADefault: Integer): Integer;
var
  Data: TJSONData;
begin
  Result := ADefault;

  if AObj = nil then
    Exit;

  Data := AObj.Find(AName);

  if Data <> nil then
  begin
    try
      Result := Data.AsInteger;
    except
      Result := ADefault;
    end;
  end;
end;

function TfrmMain.ExtractValueFromDOMResultJSON(const AJSON: string): string;
var
  Parser: TJSONParser;
  Data: TJSONData;
  Obj: TJSONObject;
  ValueData: TJSONData;
begin
  Result := '';

  Parser := nil;
  Data := nil;

  try
    Parser := TJSONParser.Create(AJSON);
    Data := Parser.Parse;

    if not (Data is TJSONObject) then
      Exit;

    Obj := TJSONObject(Data);
    ValueData := Obj.Find('value');

    if ValueData <> nil then
      Result := JSONValueToText(ValueData);
  finally
    Data.Free;
    Parser.Free;
  end;
end;

procedure TfrmMain.ShowHTMLSourceFromDOMResult(const AJSON: string);
var
  HTMLSource: string;
begin
  HTMLSource := ExtractValueFromDOMResultJSON(AJSON);

  memoHTML.Lines.BeginUpdate;
  try
    memoHTML.Clear;
    memoHTML.Lines.Add('Fonte HTML da página');
    memoHTML.Lines.Add('Tamanho: ' + IntToStr(Length(HTMLSource)) + ' caracteres');
    memoHTML.Lines.Add('');
    memoHTML.Lines.Add(HTMLSource);
  finally
    memoHTML.Lines.EndUpdate;
  end;

  AddLog('Fonte HTML carregada no memoHTML. Tamanho=' + IntToStr(Length(HTMLSource)));
end;

procedure TfrmMain.LoadDOMListFromJSON(const AJSON: string);
var
  Parser: TJSONParser;
begin
  Parser := nil;

  try
    FreeAndNil(FDOMListData);

    Parser := TJSONParser.Create(AJSON);
    FDOMListData := Parser.Parse;

    FillListObjectsFromDOMArray;
    ApplyPendingDOMSelection;
  except
    on E: Exception do
    begin
      AddLog('Erro ao carregar JSON DOMList: ' + E.Message);
      FreeAndNil(FDOMListData);
    end;
  end;

  Parser.Free;
end;

procedure TfrmMain.FillListObjectsFromDOMArray;
var
  Arr: TJSONArray;
  I: Integer;
  Obj: TJSONObject;
  ItemText: string;
  VIndex: Integer;
  VTag: string;
  VId: string;
  VName: string;
  VClass: string;
  VRole: string;
begin
  listobjects.Items.BeginUpdate;
  try
    listobjects.Clear;
    cbListProperties.Clear;
    listJavascript.Clear;
    edValue.Text := '';

    Arr := GetDOMArray;
    if Arr = nil then
    begin
      AddLog('DOMList retornou sem array value.');
      Exit;
    end;

    for I := 0 to Arr.Count - 1 do
    begin
      if not (Arr.Items[I] is TJSONObject) then
        Continue;

      Obj := TJSONObject(Arr.Items[I]);

      VIndex := JSONGetInt(Obj, 'index', I);
      VTag := JSONGetStr(Obj, 'tagName');
      VId := JSONGetStr(Obj, 'id');
      VName := JSONGetStr(Obj, 'name');
      VClass := JSONGetStr(Obj, 'className');
      VRole := JSONGetStr(Obj, 'role');

      ItemText := '[' + IntToStr(VIndex) + '] ' + VTag;

      if VId <> '' then
        ItemText := ItemText + '#' + VId;

      if VName <> '' then
        ItemText := ItemText + ' name=' + VName;

      if VRole <> '' then
        ItemText := ItemText + ' role=' + VRole;

      if VClass <> '' then
        ItemText := ItemText + ' class=' + Copy(VClass, 1, 80);

      listobjects.Items.Add(ItemText);
    end;

    AddLog('listobjects carregado com ' + IntToStr(listobjects.Items.Count) + ' objetos DOM.');
  finally
    listobjects.Items.EndUpdate;
  end;

  if listobjects.Items.Count > 0 then
  begin
    listobjects.ItemIndex := 0;
    listobjectsChangeBounds(listobjects);
  end;
end;

procedure TfrmMain.FillPropertiesFromSelectedObject;
var
  Obj: TJSONObject;
  Attrs: TJSONObject;
  Data: TJSONData;
  I: Integer;

  procedure AddProp(const AName: string);
  begin
    if Obj.Find(AName) <> nil then
      cbListProperties.Items.Add('prop.' + AName);
  end;

begin
  cbListProperties.Items.BeginUpdate;
  try
    cbListProperties.Clear;

    Obj := GetSelectedDOMObject;
    if Obj = nil then
      Exit;

    AddProp('tagName');
    AddProp('id');
    AddProp('name');
    AddProp('className');
    AddProp('type');
    AddProp('role');
    AddProp('title');
    AddProp('ariaLabel');
    AddProp('jsname');
    AddProp('value');
    AddProp('text');
    AddProp('html');

    Data := Obj.Find('attributes');
    if Data is TJSONObject then
    begin
      Attrs := TJSONObject(Data);

      for I := 0 to Attrs.Count - 1 do
        cbListProperties.Items.Add('attr.' + Attrs.Names[I]);
    end;
  finally
    cbListProperties.Items.EndUpdate;
  end;

  if cbListProperties.Items.Count > 0 then
  begin
    cbListProperties.ItemIndex := 0;
    cbListPropertiesChangeBounds(cbListProperties);
  end;
end;

procedure TfrmMain.FillMethodsFromSelectedObject;
var
  Obj: TJSONObject;
  Data: TJSONData;
  Arr: TJSONArray;
  I: Integer;
begin
  listJavascript.Items.BeginUpdate;
  try
    listJavascript.Clear;

    Obj := GetSelectedDOMObject;
    if Obj = nil then
      Exit;

    Data := Obj.Find('methods');
    if not (Data is TJSONArray) then
      Exit;

    Arr := TJSONArray(Data);

    for I := 0 to Arr.Count - 1 do
      listJavascript.Items.Add(JSONValueToText(Arr.Items[I]));
  finally
    listJavascript.Items.EndUpdate;
  end;
end;

function TfrmMain.SelectedPropertyName: string;
begin
  Result := '';

  if cbListProperties.ItemIndex >= 0 then
    Result := cbListProperties.Items[cbListProperties.ItemIndex];
end;

function TfrmMain.SelectedPropertyIsAttribute: Boolean;
begin
  Result := Pos('attr.', SelectedPropertyName) = 1;
end;

function TfrmMain.SelectedAttributeName: string;
begin
  Result := SelectedPropertyName;

  if Pos('attr.', Result) = 1 then
    Delete(Result, 1, Length('attr.'));
end;

function TfrmMain.SelectedPropertyLocalValue(AObj: TJSONObject; const AProp: string): string;
var
  Data: TJSONData;
  Attrs: TJSONObject;
  AttrName: string;
begin
  Result := '';

  if AObj = nil then
    Exit;

  if Pos('prop.', AProp) = 1 then
  begin
    Data := AObj.Find(Copy(AProp, Length('prop.') + 1, MaxInt));
    Result := JSONValueToText(Data);
    Exit;
  end;

  if Pos('attr.', AProp) = 1 then
  begin
    AttrName := Copy(AProp, Length('attr.') + 1, MaxInt);
    Data := AObj.Find('attributes');

    if Data is TJSONObject then
    begin
      Attrs := TJSONObject(Data);
      Result := JSONValueToText(Attrs.Find(AttrName));
    end;
  end;
end;

procedure TfrmMain.SelectPropertyToValue;
var
  Obj: TJSONObject;
  Prop: string;
begin
  Obj := GetSelectedDOMObject;
  Prop := SelectedPropertyName;

  if (Obj = nil) or (Prop = '') then
  begin
    edValue.Text := '';
    Exit;
  end;

  edValue.Text := SelectedPropertyLocalValue(Obj, Prop);

  FSelectedDOMPropertyName := Prop;
  FSelectedDOMValue := edValue.Text;

  ShowSelectedDOMInMemo;
end;

procedure TfrmMain.SavePendingDOMSelection(
  const ASelector: string;
  const ATagName: string;
  const AId: string;
  const AName: string;
  const AClassName: string;
  const APropertyName: string;
  const AValue: string
);
begin
  FPendingSelectDOM := True;
  FPendingSelectSelector := ASelector;
  FPendingSelectTagName := ATagName;
  FPendingSelectId := AId;
  FPendingSelectName := AName;
  FPendingSelectClassName := AClassName;
  FPendingSelectPropertyName := APropertyName;
  FPendingSelectValue := AValue;
end;

procedure TfrmMain.ApplyPendingDOMSelection;
begin
  if not FPendingSelectDOM then
    Exit;

  if SelectListObjectByDOMInfo(
    FPendingSelectSelector,
    FPendingSelectTagName,
    FPendingSelectId,
    FPendingSelectName,
    FPendingSelectClassName,
    FPendingSelectPropertyName,
    FPendingSelectValue
  ) then
  begin
    FPendingSelectDOM := False;
    AddLog('Seleção pendente DOM aplicada no listobjects.');
  end;
end;

function TfrmMain.FindListObjectIndexByDOMInfo(
  const ASelector: string;
  const ATagName: string;
  const AId: string;
  const AName: string;
  const AClassName: string
): Integer;
var
  Arr: TJSONArray;
  Obj: TJSONObject;
  I: Integer;
  VTag: string;
  VId: string;
  VName: string;
  VClass: string;
  VSelector: string;
begin
  Result := -1;

  Arr := GetDOMArray;
  if Arr = nil then
    Exit;

  for I := 0 to Arr.Count - 1 do
  begin
    if not (Arr.Items[I] is TJSONObject) then
      Continue;

    Obj := TJSONObject(Arr.Items[I]);

    VTag := JSONGetStr(Obj, 'tagName');
    VId := JSONGetStr(Obj, 'id');
    VName := JSONGetStr(Obj, 'name');
    VClass := JSONGetStr(Obj, 'className');

    if (Trim(AId) <> '') and SameText(VId, AId) then
    begin
      if (Trim(ATagName) = '') or SameText(VTag, ATagName) then
      begin
        Result := I;
        Exit;
      end;
    end;

    if (Trim(AName) <> '') and SameText(VName, AName) then
    begin
      if (Trim(ATagName) = '') or SameText(VTag, ATagName) then
      begin
        Result := I;
        Exit;
      end;
    end;

    if Trim(VId) <> '' then
    begin
      VSelector := LowerCase(VTag) + '#' + VId;

      if SameText(VSelector, ASelector) then
      begin
        Result := I;
        Exit;
      end;
    end;

    if (Trim(AClassName) <> '') and (Trim(VClass) <> '') then
    begin
      if SameText(VTag, ATagName) and
         ((Pos(LowerCase(AClassName), LowerCase(VClass)) > 0) or
          (Pos(LowerCase(VClass), LowerCase(AClassName)) > 0)) then
      begin
        Result := I;
        Exit;
      end;
    end;
  end;
end;

function TfrmMain.SelectListObjectByDOMInfo(
  const ASelector: string;
  const ATagName: string;
  const AId: string;
  const AName: string;
  const AClassName: string;
  const APropertyName: string;
  const AValue: string
): Boolean;
var
  FoundIndex: Integer;
begin
  Result := False;

  FoundIndex := FindListObjectIndexByDOMInfo(
    ASelector,
    ATagName,
    AId,
    AName,
    AClassName
  );

  if FoundIndex < 0 then
  begin
    AddLog('Objeto clicado não encontrado em listobjects. Solicitando DOMList("*") para atualizar a lista...');

    SavePendingDOMSelection(
      ASelector,
      ATagName,
      AId,
      AName,
      AClassName,
      APropertyName,
      AValue
    );

    FDOMListSelector := '*';

    if EnsureBrowser then
      AIChromiumBrowser1.DOMList(FDOMListSelector);

    Exit;
  end;

  listobjects.ItemIndex := FoundIndex;
  listobjectsChangeBounds(listobjects);

  SelectComboPropertyByDOMProperty(APropertyName);

  if Trim(AValue) <> '' then
    edValue.Text := AValue;

  AddLog(
    'Objeto DOM clicado localizado em listobjects: item=' + IntToStr(FoundIndex) +
    ' selector=' + ASelector +
    ' tag=' + ATagName +
    ' id=' + AId +
    ' name=' + AName
  );

  Result := True;
end;

procedure TfrmMain.SelectComboPropertyByDOMProperty(const APropertyName: string);
var
  I: Integer;
  Wanted: string;
begin
  if Trim(APropertyName) = '' then
    Exit;

  Wanted := 'prop.' + APropertyName;

  if SameText(APropertyName, 'innerText') then
    Wanted := 'prop.text';

  if SameText(APropertyName, 'innerHTML') then
    Wanted := 'prop.html';

  for I := 0 to cbListProperties.Items.Count - 1 do
  begin
    if SameText(cbListProperties.Items[I], Wanted) then
    begin
      cbListProperties.ItemIndex := I;
      cbListPropertiesChangeBounds(cbListProperties);
      Exit;
    end;
  end;

  for I := 0 to cbListProperties.Items.Count - 1 do
  begin
    if SameText(cbListProperties.Items[I], 'prop.value') then
    begin
      cbListProperties.ItemIndex := I;
      cbListPropertiesChangeBounds(cbListProperties);
      Exit;
    end;
  end;
end;

procedure TfrmMain.RefreshSelectedDOMAfterSet;
begin
  if FSelectedDOMRealIndex < 0 then
    Exit;

  AIChromiumBrowser1.DOMGetElement(FDOMListSelector, FSelectedDOMRealIndex);
end;

procedure TfrmMain.ClearJSVars;
begin
  FreeAndNil(FJSVarsData);

  FSelectedJSVarName := '';
  FWaitingJSMethodSource := False;
  FWaitingJSVars := False;
  FWaitingJSVarValue := False;
  FWaitingJSSetVar := False;

  if Assigned(lstVars) then
    lstVars.Clear;

  if Assigned(edValueVar) then
    edValueVar.Text := '';
end;

function TfrmMain.GetJSVarsArray: TJSONArray;
var
  Obj: TJSONObject;
  Data: TJSONData;
begin
  Result := nil;

  if not (FJSVarsData is TJSONObject) then
    Exit;

  Obj := TJSONObject(FJSVarsData);
  Data := Obj.Find('value');

  if Data is TJSONArray then
    Result := TJSONArray(Data);
end;

function TfrmMain.GetSelectedJSVarObject: TJSONObject;
var
  Arr: TJSONArray;
  Data: TJSONData;
begin
  Result := nil;

  if not Assigned(lstVars) then
    Exit;

  if lstVars.ItemIndex < 0 then
    Exit;

  Arr := GetJSVarsArray;
  if Arr = nil then
    Exit;

  if lstVars.ItemIndex >= Arr.Count then
    Exit;

  Data := Arr.Items[lstVars.ItemIndex];

  if Data is TJSONObject then
    Result := TJSONObject(Data);
end;

procedure TfrmMain.RequestSelectedDOMMethodSource(const AMethodName: string);
var
  JSScript: string;
begin
  if FSelectedDOMRealIndex < 0 then
  begin
    AddLog('Nenhum objeto DOM selecionado para buscar fonte JavaScript.');
    Exit;
  end;

  if Trim(AMethodName) = '' then
    Exit;

  if not EnsureBrowser then
    Exit;

  FWaitingJSMethodSource := True;

  memoJS.Clear;
  memoJS.Lines.Add('Carregando fonte JavaScript do método: ' + AMethodName);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var selector = "' + EscapeJSString(FDOMListSelector) + '";' +
    '    var index = ' + IntToStr(FSelectedDOMRealIndex) + ';' +
    '    var methodName = "' + EscapeJSString(AMethodName) + '";' +
    '    var el = document.querySelectorAll(selector)[index];' +
    '    if (!el) throw new Error("Elemento DOM não encontrado.");' +
    '    var v = el[methodName];' +
    '    var src = "";' +
    '    if (typeof v === "function") src = String(v);' +
    '    else src = "O item selecionado não é uma função: " + methodName;' +
    '    console.log("__AI_DOM_RESULT__" + JSON.stringify({' +
    '      kind: "js-method-source",' +
    '      selector: methodName,' +
    '      index: index,' +
    '      count: 1,' +
    '      value: src' +
    '    }));' +
    '  } catch(e) {' +
    '    console.log("__AI_DOM_RESULT__" + JSON.stringify({' +
    '      kind: "js-method-source",' +
    '      selector: "' + EscapeJSString(AMethodName) + '",' +
    '      index: ' + IntToStr(FSelectedDOMRealIndex) + ',' +
    '      count: 0,' +
    '      value: "",' +
    '      error: String(e)' +
    '    }));' +
    '  }' +
    '})();';

  if not AIChromiumBrowser1.ExecuteJavaScript(JSScript) then
  begin
    FWaitingJSMethodSource := False;
    AddLog('Erro ao solicitar fonte JavaScript: ' + AIChromiumBrowser1.LastError);
  end;
end;

procedure TfrmMain.RequestGlobalJSVars;
var
  JSScript: string;
begin
  if not EnsureBrowser then
    Exit;

  FWaitingJSVars := True;

  if Assigned(lstVars) then
    lstVars.Clear;

  if Assigned(edValueVar) then
    edValueVar.Text := '';

  AddLog('Solicitando variáveis globais JavaScript de window...');

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var result = [];' +
    '    var names = Object.getOwnPropertyNames(window).sort();' +
    '    function previewValue(v){' +
    '      try {' +
    '        if (typeof v === "undefined") return "undefined";' +
    '        if (v === null) return "null";' +
    '        if (typeof v === "string") return v;' +
    '        if (typeof v === "number" || typeof v === "boolean") return String(v);' +
    '        var s = Object.prototype.toString.call(v);' +
    '        if (v && v.constructor && v.constructor.name) s = "[" + v.constructor.name + "]";' +
    '        return s;' +
    '      } catch(e) {' +
    '        return "[unreadable]";' +
    '      }' +
    '    }' +
    '    names.forEach(function(n){' +
    '      try {' +
    '        var v = window[n];' +
    '        var t = typeof v;' +
    '        if (t === "function") return;' +
    '        var p = previewValue(v);' +
    '        if (p.length > 200) p = p.substring(0, 200) + "...";' +
    '        result.push({name:n, type:t, valuePreview:p});' +
    '      } catch(e) {}' +
    '    });' +
    '    console.log("__AI_DOM_RESULT__" + JSON.stringify({' +
    '      kind: "js-list-vars",' +
    '      selector: "window",' +
    '      index: -1,' +
    '      count: result.length,' +
    '      value: result' +
    '    }));' +
    '  } catch(e) {' +
    '    console.log("__AI_DOM_RESULT__" + JSON.stringify({' +
    '      kind: "js-list-vars",' +
    '      selector: "window",' +
    '      index: -1,' +
    '      count: 0,' +
    '      value: [],' +
    '      error: String(e)' +
    '    }));' +
    '  }' +
    '})();';

  if not AIChromiumBrowser1.ExecuteJavaScript(JSScript) then
  begin
    FWaitingJSVars := False;
    AddLog('Erro ao listar variáveis JS: ' + AIChromiumBrowser1.LastError);
  end;
end;

procedure TfrmMain.LoadJSVarsFromJSON(const AJSON: string);
var
  Parser: TJSONParser;
begin
  Parser := nil;

  try
    FreeAndNil(FJSVarsData);

    Parser := TJSONParser.Create(AJSON);
    FJSVarsData := Parser.Parse;

    FillJSVarsFromJSON;
  except
    on E: Exception do
    begin
      AddLog('Erro ao carregar JSON de variáveis JS: ' + E.Message);
      FreeAndNil(FJSVarsData);
    end;
  end;

  Parser.Free;
end;

procedure TfrmMain.FillJSVarsFromJSON;
var
  Arr: TJSONArray;
  I: Integer;
  Obj: TJSONObject;
  VName: string;
  VType: string;
  VPreview: string;
begin
  if not Assigned(lstVars) then
    Exit;

  lstVars.Items.BeginUpdate;
  try
    lstVars.Clear;

    if Assigned(edValueVar) then
      edValueVar.Text := '';

    Arr := GetJSVarsArray;
    if Arr = nil then
    begin
      AddLog('Lista de variáveis JS retornou sem array value.');
      Exit;
    end;

    for I := 0 to Arr.Count - 1 do
    begin
      if not (Arr.Items[I] is TJSONObject) then
        Continue;

      Obj := TJSONObject(Arr.Items[I]);

      VName := JSONGetStr(Obj, 'name');
      VType := JSONGetStr(Obj, 'type');
      VPreview := JSONGetStr(Obj, 'valuePreview');

      lstVars.Items.Add(VName + ' [' + VType + '] = ' + VPreview);
    end;

    AddLog('lstVars carregado com ' + IntToStr(lstVars.Items.Count) + ' variáveis globais.');
  finally
    lstVars.Items.EndUpdate;
  end;

  if lstVars.Items.Count > 0 then
  begin
    lstVars.ItemIndex := 0;
    lstVarsClick(lstVars);
  end;
end;

procedure TfrmMain.RequestSelectedJSVarValue;
var
  Obj: TJSONObject;
  VarName: string;
  JSScript: string;
begin
  Obj := GetSelectedJSVarObject;
  if Obj = nil then
    Exit;

  VarName := JSONGetStr(Obj, 'name');

  if Trim(VarName) = '' then
    Exit;

  if not EnsureBrowser then
    Exit;

  FSelectedJSVarName := VarName;
  FWaitingJSVarValue := True;

  AddLog('Solicitando valor da variável JS: ' + VarName);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var name = "' + EscapeJSString(VarName) + '";' +
    '    var v = window[name];' +
    '    function valueToText(x){' +
    '      try {' +
    '        if (typeof x === "undefined") return "undefined";' +
    '        if (x === null) return "null";' +
    '        if (typeof x === "string") return x;' +
    '        if (typeof x === "number" || typeof x === "boolean") return String(x);' +
    '        return JSON.stringify(x, null, 2);' +
    '      } catch(e) {' +
    '        return String(x);' +
    '      }' +
    '    }' +
    '    console.log("__AI_DOM_RESULT__" + JSON.stringify({' +
    '      kind: "js-var-value",' +
    '      selector: name,' +
    '      index: -1,' +
    '      count: 1,' +
    '      value: valueToText(v),' +
    '      type: typeof v' +
    '    }));' +
    '  } catch(e) {' +
    '    console.log("__AI_DOM_RESULT__" + JSON.stringify({' +
    '      kind: "js-var-value",' +
    '      selector: "' + EscapeJSString(VarName) + '",' +
    '      index: -1,' +
    '      count: 0,' +
    '      value: "",' +
    '      error: String(e)' +
    '    }));' +
    '  }' +
    '})();';

  if not AIChromiumBrowser1.ExecuteJavaScript(JSScript) then
  begin
    FWaitingJSVarValue := False;
    AddLog('Erro ao solicitar valor da variável JS: ' + AIChromiumBrowser1.LastError);
  end;
end;

procedure TfrmMain.SetSelectedJSVarValue;
var
  Obj: TJSONObject;
  VarName: string;
  NewValue: string;
  JSScript: string;
begin
  Obj := GetSelectedJSVarObject;
  if Obj = nil then
  begin
    AddLog('Nenhuma variável selecionada em lstVars.');
    Exit;
  end;

  VarName := JSONGetStr(Obj, 'name');
  NewValue := edValueVar.Text;

  if Trim(VarName) = '' then
  begin
    AddLog('Nome da variável JS inválido.');
    Exit;
  end;

  if not EnsureBrowser then
    Exit;

  FSelectedJSVarName := VarName;
  FWaitingJSSetVar := True;

  AddLog('Alterando variável JS: ' + VarName + ' = ' + NewValue);

  JSScript :=
    '(function(){' +
    '  try {' +
    '    var name = "' + EscapeJSString(VarName) + '";' +
    '    var text = "' + EscapeJSString(NewValue) + '";' +
    '    var oldValue = window[name];' +
    '    var oldType = typeof oldValue;' +
    '    var newValue = text;' +
    '    if (oldType === "number") {' +
    '      var n = Number(text);' +
    '      if (!isNaN(n)) newValue = n;' +
    '    } else if (oldType === "boolean") {' +
    '      newValue = (text.toLowerCase() === "true" || text === "1");' +
    '    } else if (oldValue === null) {' +
    '      if (text.toLowerCase() === "null") newValue = null;' +
    '    } else if (oldType === "object") {' +
    '      try { newValue = JSON.parse(text); } catch(e) { newValue = text; }' +
    '    } else if (oldType === "undefined") {' +
    '      if (text.toLowerCase() === "undefined") newValue = undefined;' +
    '    }' +
    '    window[name] = newValue;' +
    '    var finalValue = window[name];' +
    '    function valueToText(x){' +
    '      try {' +
    '        if (typeof x === "undefined") return "undefined";' +
    '        if (x === null) return "null";' +
    '        if (typeof x === "string") return x;' +
    '        if (typeof x === "number" || typeof x === "boolean") return String(x);' +
    '        return JSON.stringify(x, null, 2);' +
    '      } catch(e) {' +
    '        return String(x);' +
    '      }' +
    '    }' +
    '    console.log("__AI_DOM_RESULT__" + JSON.stringify({' +
    '      kind: "js-set-var",' +
    '      selector: name,' +
    '      index: -1,' +
    '      count: 1,' +
    '      value: valueToText(finalValue),' +
    '      type: typeof finalValue' +
    '    }));' +
    '  } catch(e) {' +
    '    console.log("__AI_DOM_RESULT__" + JSON.stringify({' +
    '      kind: "js-set-var",' +
    '      selector: "' + EscapeJSString(VarName) + '",' +
    '      index: -1,' +
    '      count: 0,' +
    '      value: "",' +
    '      error: String(e)' +
    '    }));' +
    '  }' +
    '})();';

  if not AIChromiumBrowser1.ExecuteJavaScript(JSScript) then
  begin
    FWaitingJSSetVar := False;
    AddLog('Erro ao alterar variável JS: ' + AIChromiumBrowser1.LastError);
  end;
end;

procedure TfrmMain.Button1Click(Sender: TObject);
begin
  if not EnsureBrowser then
    Exit;

  FDOMListSelector := '*';

  listobjects.Clear;
  cbListProperties.Clear;
  listJavascript.Clear;
  edValue.Text := '';

  AddLog('Solicitando todos os objetos DOM do HTML: DOMList("*")...');
  AIChromiumBrowser1.DOMList(FDOMListSelector);
end;

procedure TfrmMain.btListVarsClick(Sender: TObject);
begin
  RequestGlobalJSVars;
end;

procedure TfrmMain.btSetValueVarClick(Sender: TObject);
begin
  SetSelectedJSVarValue;
end;

procedure TfrmMain.lstVarsClick(Sender: TObject);
begin
  RequestSelectedJSVarValue;
end;

procedure TfrmMain.listobjectsChangeBounds(Sender: TObject);
var
  Obj: TJSONObject;
  VIndex: Integer;
  VTag: string;
  VId: string;
  VName: string;
  VClass: string;
  VValue: string;
begin
  Obj := GetSelectedDOMObject;

  if Obj = nil then
    Exit;

  VIndex := JSONGetInt(Obj, 'index', listobjects.ItemIndex);
  VTag := JSONGetStr(Obj, 'tagName');
  VId := JSONGetStr(Obj, 'id');
  VName := JSONGetStr(Obj, 'name');
  VClass := JSONGetStr(Obj, 'className');
  VValue := JSONGetStr(Obj, 'value');

  FSelectedDOMRealIndex := VIndex;

  SetSelectedDOM(
    FDOMListSelector,
    VTag,
    VId,
    VName,
    VClass,
    '',
    VValue
  );

  FillPropertiesFromSelectedObject;
  FillMethodsFromSelectedObject;

  AddLog(
    'Objeto DOM selecionado em listobjects: index=' + IntToStr(FSelectedDOMRealIndex) +
    ' tag=' + VTag +
    ' id=' + VId +
    ' name=' + VName
  );
end;

procedure TfrmMain.cbListPropertiesChangeBounds(Sender: TObject);
begin
  SelectPropertyToValue;

  AddLog(
    'Propriedade selecionada: ' + FSelectedDOMPropertyName +
    ' valor=' + FSelectedDOMValue
  );
end;

procedure TfrmMain.listJavascriptChangeBounds(Sender: TObject);
var
  MethodName1: string;
begin
  if listJavascript.ItemIndex < 0 then
    Exit;

  MethodName1 := listJavascript.Items[listJavascript.ItemIndex];

  AddLog('Método DOM selecionado: ' + MethodName1);
  RequestSelectedDOMMethodSource(MethodName1);
end;

procedure TfrmMain.btnSetValueClick(Sender: TObject);
var
  LProp: string;
  LDOMProp: string;
  LAttr: string;
begin
  if FSelectedDOMRealIndex < 0 then
  begin
    AddLog('Nenhum objeto DOM selecionado. Clique em Button1 e selecione um item em listobjects.');
    PageControl1.ActivePage := tsLog;
    Exit;
  end;

  LProp := SelectedPropertyName;

  if LProp = '' then
  begin
    AddLog('Nenhuma propriedade selecionada em cbListProperties.');
    PageControl1.ActivePage := tsLog;
    Exit;
  end;

  if not EnsureBrowser then
    Exit;

  AddLog(
    'SetValue no objeto DOM: selector=' + FDOMListSelector +
    ' index=' + IntToStr(FSelectedDOMRealIndex) +
    ' property=' + LProp +
    ' value=' + edValue.Text
  );

  if SelectedPropertyIsAttribute then
  begin
    LAttr := SelectedAttributeName;

    if AIChromiumBrowser1.DOMSetAttributeValue(FDOMListSelector, FSelectedDOMRealIndex, LAttr, edValue.Text) then
      AddLog('Atributo alterado: ' + LAttr)
    else
      AddLog('Erro ao alterar atributo: ' + AIChromiumBrowser1.LastError);
  end
  else
  begin
    LDOMProp := Copy(LProp, Length('prop.') + 1, MaxInt);

    if SameText(LDOMProp, 'tagName') then
    begin
      AddLog('tagName é somente leitura. Não será alterado.');
      Exit;
    end
    else if SameText(LDOMProp, 'value') then
    begin
      if AIChromiumBrowser1.DOMSetValue(FDOMListSelector, FSelectedDOMRealIndex, edValue.Text) then
      begin
        AIChromiumBrowser1.DOMDispatchEvent(FDOMListSelector, FSelectedDOMRealIndex, 'input');
        AIChromiumBrowser1.DOMDispatchEvent(FDOMListSelector, FSelectedDOMRealIndex, 'change');
        AddLog('Propriedade value alterada.');
      end
      else
        AddLog('Erro ao alterar value: ' + AIChromiumBrowser1.LastError);
    end
    else if SameText(LDOMProp, 'text') then
    begin
      if AIChromiumBrowser1.DOMSetProperty(FDOMListSelector, FSelectedDOMRealIndex, 'innerText', edValue.Text) then
        AddLog('Propriedade innerText alterada.')
      else
        AddLog('Erro ao alterar innerText: ' + AIChromiumBrowser1.LastError);
    end
    else if SameText(LDOMProp, 'html') then
    begin
      if AIChromiumBrowser1.DOMSetProperty(FDOMListSelector, FSelectedDOMRealIndex, 'innerHTML', edValue.Text) then
        AddLog('Propriedade innerHTML alterada.')
      else
        AddLog('Erro ao alterar innerHTML: ' + AIChromiumBrowser1.LastError);
    end
    else if SameText(LDOMProp, 'ariaLabel') then
    begin
      if AIChromiumBrowser1.DOMSetAttributeValue(FDOMListSelector, FSelectedDOMRealIndex, 'aria-label', edValue.Text) then
        AddLog('Atributo aria-label alterado.')
      else
        AddLog('Erro ao alterar aria-label: ' + AIChromiumBrowser1.LastError);
    end
    else if SameText(LDOMProp, 'jsname') then
    begin
      if AIChromiumBrowser1.DOMSetAttributeValue(FDOMListSelector, FSelectedDOMRealIndex, 'jsname', edValue.Text) then
        AddLog('Atributo jsname alterado.')
      else
        AddLog('Erro ao alterar jsname: ' + AIChromiumBrowser1.LastError);
    end
    else if SameText(LDOMProp, 'role') or
            SameText(LDOMProp, 'title') or
            SameText(LDOMProp, 'name') or
            SameText(LDOMProp, 'type') then
    begin
      if AIChromiumBrowser1.DOMSetAttributeValue(FDOMListSelector, FSelectedDOMRealIndex, LDOMProp, edValue.Text) then
        AddLog('Atributo alterado: ' + LDOMProp)
      else
        AddLog('Erro ao alterar atributo ' + LDOMProp + ': ' + AIChromiumBrowser1.LastError);
    end
    else
    begin
      if AIChromiumBrowser1.DOMSetProperty(FDOMListSelector, FSelectedDOMRealIndex, LDOMProp, edValue.Text) then
        AddLog('Propriedade alterada: ' + LDOMProp)
      else
        AddLog('Erro ao alterar propriedade ' + LDOMProp + ': ' + AIChromiumBrowser1.LastError);
    end;
  end;

  FSelectedDOMPropertyName := LProp;
  FSelectedDOMValue := edValue.Text;

  RefreshSelectedDOMAfterSet;
  ShowComponentState;
end;

function TfrmMain.EnsureBrowser: Boolean;
begin
  Result := True;

  if AIChromiumBrowser1.BrowserReady then
    Exit;

  AddLog('Inicializando Chromium...');
  Result := AIChromiumBrowser1.InitializeBrowser;

  if Result then
    AddLog('Browser creation requested.')
  else
    AddLog('Erro ao inicializar Chromium: ' + AIChromiumBrowser1.LastError);
end;

function TfrmMain.GoogleLoaded: Boolean;
var
  LURL: string;
begin
  LURL := LowerCase(AIChromiumBrowser1.URL);

  Result :=
    (Pos('google.com', LURL) > 0) or
    (Pos('google.com.br', LURL) > 0);
end;

function TfrmMain.StartGoogleSearch(const AText: string): Boolean;
begin
  Result := False;

  if Trim(AText) = '' then
  begin
    AddLog('Informe o texto da pesquisa.');
    edPesquisa.SetFocus;
    Exit;
  end;

  if not EnsureBrowser then
    Exit;

  FPendingGoogleSearch := AText;

  if not GoogleLoaded then
  begin
    AddLog('Google ainda não está carregado. Abrindo Google antes da pesquisa...');
    AIChromiumBrowser1.Navigate('https://www.google.com');
    edURL.Text := 'https://www.google.com';
    Result := True;
    Exit;
  end;

  Result := PesquisarGooglePorDOM(AText);
end;

function TfrmMain.PesquisarGooglePorDOM(const AText: string): Boolean;
const
  CGoogleSearchTextArea =
    'textarea#APjFqb[jsname="yZiJbe"][name="q"][role="combobox"],' +
    'textarea#APjFqb[name="q"],' +
    'textarea.gLFyf[name="q"],' +
    'textarea[name="q"],' +
    'input[name="q"]';
begin
  Result := False;

  if Trim(AText) = '' then
  begin
    AddLog('Informe o texto da pesquisa.');
    edPesquisa.SetFocus;
    Exit;
  end;

  if not EnsureBrowser then
    Exit;

  AddLog('Pesquisa Google por DOM usando API do TAIChromiumBrowser.');
  AddLog('Elemento alvo: ' + CGoogleSearchTextArea);

  AIChromiumBrowser1.DOMList('textarea,input,button,form');
  AIChromiumBrowser1.DOMCount(CGoogleSearchTextArea);

  if not AIChromiumBrowser1.DOMFocus(CGoogleSearchTextArea, 0) then
  begin
    AddLog('Falha ao focar campo de pesquisa: ' + AIChromiumBrowser1.LastError);
    Exit;
  end;

  if not AIChromiumBrowser1.DOMSetValue(CGoogleSearchTextArea, 0, AText) then
  begin
    AddLog('Falha ao preencher campo de pesquisa: ' + AIChromiumBrowser1.LastError);
    Exit;
  end;

  AIChromiumBrowser1.DOMDispatchEvent(CGoogleSearchTextArea, 0, 'input');
  AIChromiumBrowser1.DOMDispatchEvent(CGoogleSearchTextArea, 0, 'change');

  if not AIChromiumBrowser1.DOMPressEnter(CGoogleSearchTextArea, 0) then
  begin
    AddLog('Falha ao pressionar Enter no campo de pesquisa: ' + AIChromiumBrowser1.LastError);
    Exit;
  end;

  AddLog('Pesquisa solicitada via DOM API do componente.');
  Result := True;
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

  ShowComponentState;
end;

procedure TfrmMain.btnNavigateClick(Sender: TObject);
begin
  AddLog('Navigate: ' + edURL.Text);

  try
    if not EnsureBrowser then
      Exit;

    FPendingGoogleSearch := '';
    ClearDOMList;
    ClearSelectedDOM;
    ClearJSVars;

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
  ClearDOMList;
  ClearSelectedDOM;
  ClearJSVars;
  AIChromiumBrowser1.GoBack;
  ShowComponentState;
end;

procedure TfrmMain.btnForwardClick(Sender: TObject);
begin
  AddLog('Forward');
  ClearDOMList;
  ClearSelectedDOM;
  ClearJSVars;
  AIChromiumBrowser1.GoForward;
  ShowComponentState;
end;

procedure TfrmMain.btnReloadClick(Sender: TObject);
begin
  AddLog('Reload');
  ClearDOMList;
  ClearSelectedDOM;
  ClearJSVars;
  AIChromiumBrowser1.Reload;
  ShowComponentState;
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.btnExecuteJSClick(Sender: TObject);
begin
  AddLog('Executing JavaScript...');

  if Trim(memoJS.Text) = '' then
  begin
    AddLog('Informe um JavaScript no memo.');
    memoJS.SetFocus;
    Exit;
  end;

  if not EnsureBrowser then
    Exit;

  if AIChromiumBrowser1.ExecuteJavaScript(memoJS.Text) then
    AddLog('JavaScript executed.')
  else
    AddLog('JavaScript error: ' + AIChromiumBrowser1.LastError);

  ShowComponentState;
end;

procedure TfrmMain.btnGetHTMLClick(Sender: TObject);
begin
  AddLog('Solicitando fonte HTML da página: html.outerHTML');

  if not EnsureBrowser then
    Exit;

  FWaitingHTMLSource := True;

  memoHTML.Clear;
  memoHTML.Lines.Add('Solicitando fonte HTML da página...');
  memoHTML.Lines.Add('Aguardando retorno via OnDOMResult...');

  if not AIChromiumBrowser1.DOMGetProperty('html', 0, 'outerHTML') then
  begin
    FWaitingHTMLSource := False;
    AddLog('Erro ao solicitar HTML: ' + AIChromiumBrowser1.LastError);
    Exit;
  end;

  ShowComponentState;
end;

procedure TfrmMain.ShowComponentState;
begin
  lblStatus.Caption :=
    'Status: Ready=' + BoolToStr(AIChromiumBrowser1.BrowserReady, True) +
    ' URL=' + AIChromiumBrowser1.URL +
    ' DOMCount=' + IntToStr(AIChromiumBrowser1.DOMCountValue);

  if AIChromiumBrowser1.LastResult <> '' then
    AddLog('LastResult: ' + AIChromiumBrowser1.LastResult);

  if AIChromiumBrowser1.LastError <> '' then
    AddLog('LastError: ' + AIChromiumBrowser1.LastError);
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMsg);
end;

procedure TfrmMain.btnAbrirGoogleClick(Sender: TObject);
begin
  AddLog('Abrindo Google...');

  if not EnsureBrowser then
    Exit;

  FPendingGoogleSearch := '';
  ClearDOMList;
  ClearSelectedDOM;
  ClearJSVars;

  AIChromiumBrowser1.Navigate('https://www.google.com');
  edURL.Text := 'https://www.google.com';

  if AIChromiumBrowser1.LastError <> '' then
    AddLog('Erro: ' + AIChromiumBrowser1.LastError)
  else
    AddLog('Google solicitado no browser.');

  ShowComponentState;
end;

procedure TfrmMain.btnPesquisarGoogleClick(Sender: TObject);
begin
  AddLog('Pesquisa Google solicitada pela aplicação: ' + edPesquisa.Text);

  if StartGoogleSearch(edPesquisa.Text) then
    AddLog('Pesquisa encaminhada usando API DOM do componente.')
  else
    AddLog('Erro ao pesquisar pelo DOM: ' + AIChromiumBrowser1.LastError);

  ShowComponentState;
end;

procedure TfrmMain.edPesquisaKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    btnPesquisarGoogleClick(Sender);
  end;
end;

procedure TfrmMain.AIChromiumBrowser1LoadURL(
  Sender: TObject;
  const AURL: string;
  AIsMainFrame: Boolean
);
begin
  AddLog(
    'OnLoadURL: URL=' + AURL +
    ' MainFrame=' + BoolToStr(AIsMainFrame, True)
  );

  if AIsMainFrame then
    lblStatus.Caption := 'Status: carregando URL...';
end;

procedure TfrmMain.AIChromiumBrowser1FinishedLoadURL(
  Sender: TObject;
  const AURL: string;
  AHttpStatusCode: Integer;
  AIsMainFrame: Boolean
);
begin
  AddLog(
    'OnFinishedLoadURL: URL=' + AURL +
    ' HTTP=' + IntToStr(AHttpStatusCode) +
    ' MainFrame=' + BoolToStr(AIsMainFrame, True)
  );

  if AIsMainFrame then
  begin
    edURL.Text := AURL;
    lblStatus.Caption := 'Status: URL carregada. HTTP=' + IntToStr(AHttpStatusCode);

    if (Trim(FPendingGoogleSearch) <> '') and
       (not FExecutingPendingGoogleSearch) and
       GoogleLoaded then
    begin
      FExecutingPendingGoogleSearch := True;
      try
        AddLog('Executando pesquisa pendente após carregamento do Google...');
        PesquisarGooglePorDOM(FPendingGoogleSearch);
        FPendingGoogleSearch := '';
      finally
        FExecutingPendingGoogleSearch := False;
      end;
    end;
  end;
end;

procedure TfrmMain.AIChromiumBrowser1KeyPressDOM(
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
);
begin
  AddLog(
    'OnKeyPressDOM: evento=' + AEventName +
    ' objeto=' + ASelector +
    ' tag=' + ATagName +
    ' id=' + AId +
    ' name=' + AName +
    ' propriedade=' + APropertyName +
    ' valor=' + AValue +
    ' tecla=' + AKey +
    ' keyCode=' + IntToStr(AKeyCode)
  );
end;

procedure TfrmMain.AIChromiumBrowser1ClickDOM(
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
);
begin
  AddLog(
    'OnClickDOM: objeto=' + ASelector +
    ' tag=' + ATagName +
    ' id=' + AId +
    ' name=' + AName +
    ' class=' + AClassName
  );

  SelectListObjectByDOMInfo(
    ASelector,
    ATagName,
    AId,
    AName,
    AClassName,
    APropertyName,
    AValue
  );
end;

procedure TfrmMain.AIChromiumBrowser1SetFocusDOM(
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
);
begin
  AddLog(
    'OnSetFocusDOM: objeto=' + ASelector +
    ' tag=' + ATagName +
    ' id=' + AId +
    ' name=' + AName +
    ' propriedade=' + APropertyName +
    ' valor=' + AValue
  );
end;

procedure TfrmMain.AIChromiumBrowser1OutFocusDOM(
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
);
begin
  AddLog(
    'OnOutFocusDOM: objeto=' + ASelector +
    ' tag=' + ATagName +
    ' id=' + AId +
    ' name=' + AName +
    ' propriedade=' + APropertyName +
    ' valor=' + AValue
  );
end;

procedure TfrmMain.AIChromiumBrowser1DOMResult(
  Sender: TObject;
  const AKind: string;
  const ASelector: string;
  AIndex: Integer;
  ACount: Integer;
  const AJSON: string
);
var
  ValueText: string;
begin
  AddLog(
    'OnDOMResult: kind=' + AKind +
    ' selector=' + ASelector +
    ' index=' + IntToStr(AIndex) +
    ' count=' + IntToStr(ACount)
  );

  if FWaitingHTMLSource and
     SameText(AKind, 'dom-get-property') and
     SameText(ASelector, 'html') then
  begin
    FWaitingHTMLSource := False;
    ShowHTMLSourceFromDOMResult(AJSON);
    ShowComponentState;
    Exit;
  end;

  if FWaitingJSMethodSource and SameText(AKind, 'js-method-source') then
  begin
    FWaitingJSMethodSource := False;
    ValueText := ExtractValueFromDOMResultJSON(AJSON);

    memoJS.Lines.BeginUpdate;
    try
      memoJS.Clear;
      memoJS.Lines.Add(ValueText);
    finally
      memoJS.Lines.EndUpdate;
    end;

    AddLog('Fonte JavaScript carregado no memoJS.');
    ShowComponentState;
    Exit;
  end;

  if FWaitingJSVars and SameText(AKind, 'js-list-vars') then
  begin
    FWaitingJSVars := False;
    LoadJSVarsFromJSON(AJSON);
    ShowComponentState;
    Exit;
  end;

  if FWaitingJSVarValue and SameText(AKind, 'js-var-value') then
  begin
    FWaitingJSVarValue := False;
    ValueText := ExtractValueFromDOMResultJSON(AJSON);

    if Assigned(edValueVar) then
      edValueVar.Text := ValueText;

    AddLog('Valor da variável JS carregado: ' + ASelector);
    ShowComponentState;
    Exit;
  end;

  if FWaitingJSSetVar and SameText(AKind, 'js-set-var') then
  begin
    FWaitingJSSetVar := False;
    ValueText := ExtractValueFromDOMResultJSON(AJSON);

    if Assigned(edValueVar) then
      edValueVar.Text := ValueText;

    AddLog('Variável JS alterada: ' + ASelector + ' = ' + ValueText);

    RequestGlobalJSVars;
    ShowComponentState;
    Exit;
  end;

  if SameText(AKind, 'dom-list') and SameText(ASelector, FDOMListSelector) then
  begin
    LoadDOMListFromJSON(AJSON);
    ShowComponentState;
    Exit;
  end;

  memoHTML.Lines.BeginUpdate;
  try
    memoHTML.Clear;
    memoHTML.Lines.Add('DOM Result');
    memoHTML.Lines.Add('Kind: ' + AKind);
    memoHTML.Lines.Add('Selector: ' + ASelector);
    memoHTML.Lines.Add('Index: ' + IntToStr(AIndex));
    memoHTML.Lines.Add('Count: ' + IntToStr(ACount));
    memoHTML.Lines.Add('');
    memoHTML.Lines.Add('Último objeto selecionado:');
    memoHTML.Lines.Add('SelectedSelector: ' + FSelectedDOMSelector);
    memoHTML.Lines.Add('SelectedIndex: ' + IntToStr(FSelectedDOMRealIndex));
    memoHTML.Lines.Add('SelectedProperty: ' + FSelectedDOMPropertyName);
    memoHTML.Lines.Add('SelectedValue: ' + FSelectedDOMValue);
    memoHTML.Lines.Add('');
    memoHTML.Lines.Add('JSON:');

    if Length(AJSON) > 6000 then
    begin
      memoHTML.Lines.Add(Copy(AJSON, 1, 6000));
      memoHTML.Lines.Add('');
      memoHTML.Lines.Add('... JSON truncado no memo para não travar a interface ...');
      memoHTML.Lines.Add('Tamanho total: ' + IntToStr(Length(AJSON)) + ' caracteres.');
    end
    else
      memoHTML.Lines.Add(AJSON);
  finally
    memoHTML.Lines.EndUpdate;
  end;

  ShowComponentState;
end;

end.
