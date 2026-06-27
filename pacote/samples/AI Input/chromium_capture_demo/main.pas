unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Buttons, uCEFChromiumWindow, aibase, aichromiumbrowser;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    ChromiumWindow1: TChromiumWindow;
    Label1: TLabel;
    Label2: TLabel;
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

    procedure btnAbrirGoogleClick(Sender: TObject);
    procedure btnPesquisarGoogleClick(Sender: TObject);
    procedure edPesquisaKeyPress(Sender: TObject; var Key: Char);
  private
    procedure AddLog(const AMsg: string);
    procedure ShowComponentState;
    function EnsureBrowser: Boolean;

    // Regras da aplicação/sample. Não pertencem ao componente.
    function UrlEncodeQuery(const S: string): string;
    function BuildGoogleSearchURL(const AText: string): string;
    function PesquisarGooglePorURL(const AText: string): Boolean;
    function PesquisarGooglePorDOM(const AText: string): Boolean;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Caption := 'Web Automation Demo - TAIChromiumBrowser';
  lblTitle.Caption := 'Web Automation Demo - TAIChromiumBrowser';
  lblStatus.Caption := 'Status: Ready';

  edURL.Text := 'https://www.google.com';
  edPesquisa.Text := 'Lazarus Free Pascal';

  edSelector.Text := 'body';
  edValue.Text := 'Marcelo';

  memoJS.Text :=
    'document.body.style.outline = "5px solid red";' + LineEnding +
    'console.log("TAIChromiumBrowser JavaScript test executed");';

  memoHTML.Clear;
  memoHTML.Lines.Add('As capturas do componente são assíncronas.');
  memoHTML.Lines.Add('CaptureHTML/CaptureText/CaptureCookies gravam o resultado no browser em window.__ai_last_capture.');
  memoHTML.Lines.Add('A etapa futura do componente deve trazer este valor para uma propriedade Lazarus via callback/IPC do CEF.');

  AddLog('Demo initialized.');
  AddLog('Este sample demonstra o TAIChromiumBrowser como plataforma genérica de automação web.');
  AddLog('A pesquisa no Google é regra deste sample, não do componente.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // O componente gerencia seu próprio fechamento.
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
    if not EnsureBrowser then
      Exit;

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

  if Trim(edSelector.Text) = '' then
  begin
    AddLog('Informe um seletor CSS.');
    edSelector.SetFocus;
    Exit;
  end;

  if not EnsureBrowser then
    Exit;

  if AIChromiumBrowser1.WaitForSelector(edSelector.Text, 10000) then
    AddLog('Script de verificação do seletor injetado. O resultado fica em window.__ai_last_capture.')
  else
    AddLog('WaitForSelector error: ' + AIChromiumBrowser1.LastError);

  ShowComponentState;
end;

procedure TfrmMain.btnClickClick(Sender: TObject);
begin
  AddLog('Click: ' + edSelector.Text);

  if Trim(edSelector.Text) = '' then
  begin
    AddLog('Informe um seletor CSS.');
    edSelector.SetFocus;
    Exit;
  end;

  if not EnsureBrowser then
    Exit;

  if AIChromiumBrowser1.Click(edSelector.Text) then
    AddLog('Click script executed.')
  else
    AddLog('Click error: ' + AIChromiumBrowser1.LastError);

  ShowComponentState;
end;

procedure TfrmMain.btnSetValueClick(Sender: TObject);
begin
  AddLog('SetValue: ' + edSelector.Text + ' = ' + edValue.Text);

  if Trim(edSelector.Text) = '' then
  begin
    AddLog('Informe um seletor CSS.');
    edSelector.SetFocus;
    Exit;
  end;

  if not EnsureBrowser then
    Exit;

  if AIChromiumBrowser1.SetValue(edSelector.Text, edValue.Text) then
    AddLog('SetValue script executed.')
  else
    AddLog('SetValue error: ' + AIChromiumBrowser1.LastError);

  ShowComponentState;
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
  AddLog('CaptureHTML: html');

  if not EnsureBrowser then
    Exit;

  if AIChromiumBrowser1.CaptureHTML('html') then
  begin
    AddLog('CaptureHTML script executed.');
    memoHTML.Clear;
    memoHTML.Lines.Add('Captura solicitada com sucesso.');
    memoHTML.Lines.Add('Resultado disponível dentro do browser em:');
    memoHTML.Lines.Add('window.' + AIChromiumBrowser1.LastCaptureVarName);
    memoHTML.Lines.Add('');
    memoHTML.Lines.Add('Observação: esta versão ainda não traz o valor capturado de volta para o Lazarus de forma síncrona.');
    memoHTML.Lines.Add('Para isso, o componente precisa receber a próxima evolução com callback/IPC do CEF.');
  end
  else
    AddLog('CaptureHTML error: ' + AIChromiumBrowser1.LastError);

  ShowComponentState;
end;

procedure TfrmMain.btnScreenshotClick(Sender: TObject);
var
  vFileName: string;
begin
  vFileName := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) +
               'chromium_capture_demo_screenshot.png';

  AddLog('Screenshot: ' + vFileName);

  if not EnsureBrowser then
    Exit;

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
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMsg);
end;

function TfrmMain.UrlEncodeQuery(const S: string): string;
const
  Hex: array[0..15] of Char = '0123456789ABCDEF';
var
  I: Integer;
  B: Byte;
begin
  Result := '';

  // Lazarus usa UTF-8 em strings comuns no LCL. Aqui codificamos byte a byte.
  for I := 1 to Length(S) do
  begin
    B := Ord(S[I]);

    if Char(B) in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~'] then
      Result := Result + Char(B)
    else if Char(B) = ' ' then
      Result := Result + '+'
    else
      Result := Result + '%' + Hex[B shr 4] + Hex[B and $0F];
  end;
end;

function TfrmMain.BuildGoogleSearchURL(const AText: string): string;
begin
  Result := 'https://www.google.com/search?q=' + UrlEncodeQuery(AText);
end;

function TfrmMain.PesquisarGooglePorURL(const AText: string): Boolean;
var
  vURL: string;
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

  vURL := BuildGoogleSearchURL(AText);
  AddLog('Pesquisa por URL: ' + vURL);

  AIChromiumBrowser1.Navigate(vURL);
  edURL.Text := vURL;

  Result := AIChromiumBrowser1.LastError = '';
end;

function TfrmMain.PesquisarGooglePorDOM(const AText: string): Boolean;
const
  CGoogleSelector = 'textarea[name="q"]';
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

  // Esta função mostra como a aplicação pode usar os métodos genéricos do componente.
  // A regra de conhecer o seletor do Google continua no sample, não no TAIChromiumBrowser.
  AddLog('Pesquisa por DOM usando seletor específico do sample: ' + CGoogleSelector);

  if not AIChromiumBrowser1.SetValue(CGoogleSelector, AText) then
  begin
    AddLog('Falha ao preencher campo de pesquisa: ' + AIChromiumBrowser1.LastError);
    Exit;
  end;

  if not AIChromiumBrowser1.SubmitForm(CGoogleSelector) then
  begin
    AddLog('Falha ao submeter formulário: ' + AIChromiumBrowser1.LastError);
    Exit;
  end;

  Result := True;
end;

procedure TfrmMain.btnAbrirGoogleClick(Sender: TObject);
begin
  AddLog('Abrindo Google...');

  if not EnsureBrowser then
    Exit;

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

  // Importante:
  // Não existe mais AIChromiumBrowser1.GoogleSearch.
  // Google é regra deste sample. O componente continua genérico.
  // A opção por URL é mais estável porque não depende do carregamento assíncrono da home do Google.
  if PesquisarGooglePorURL(edPesquisa.Text) then
    AddLog('Pesquisa enviada pela aplicação usando Navigate.')
  else
    AddLog('Erro ao pesquisar: ' + AIChromiumBrowser1.LastError);

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

end.

