unit aichromiumbrowser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons,
  Graphics, iphtml, fphttpclient, opensslsockets, LCLIntf, LCLType;

type
  { TAIChromiumBrowser }

  TAIChromiumBrowser = class(TPanel)
  private
    FURL: string;
    FHTML: string;
    FShowAddressBar: Boolean;
    
    // Address Bar UI Controls
    FAddressPanel: TPanel;
    FEditURL: TEdit;
    FBtnGo: TSpeedButton;
    FBtnBack: TSpeedButton;
    
    // Web Rendering Engine Panel (Cross-platform out-of-the-box fallback)
    FHtmlPanel: TIpHtmlPanel;
    FHistory: TStringList;
    FHistoryIdx: Integer;
    
    procedure SetURL(const AValue: string);
    procedure SetShowAddressBar(AValue: Boolean);
    
    // Event Handlers
    procedure BtnGoClick(Sender: TObject);
    procedure BtnBackClick(Sender: TObject);
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
  published
    property URL: string read FURL write SetURL;
    property HTML: string read FHTML write FHTML;
    property ShowAddressBar: Boolean read FShowAddressBar write SetShowAddressBar default True;
    
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
  RegisterComponents('IA Input', [TAIChromiumBrowser]);
end;

{ TAIChromiumBrowser }

constructor TAIChromiumBrowser.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := '';
  FShowAddressBar := True;
  FHistory := TStringList.Create;
  FHistoryIdx := -1;
  
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
  
  // 3. Go Button
  FBtnGo := TSpeedButton.Create(Self);
  FBtnGo.Parent := FAddressPanel;
  FBtnGo.Caption := 'Ir';
  FBtnGo.Width := 40;
  FBtnGo.Height := 28;
  FBtnGo.Top := 5;
  FBtnGo.OnClick := @BtnGoClick;
  FBtnGo.Flat := True;
  
  // 4. URL Edit Box
  FEditURL := TEdit.Create(Self);
  FEditURL.Parent := FAddressPanel;
  FEditURL.Text := 'https://www.google.com';
  FEditURL.Top := 5;
  FEditURL.Height := 28;
  FEditURL.OnKeyPress := @EditURLKeyPress;
  
  // 5. Create native HTML Rendering Panel
  FHtmlPanel := TIpHtmlPanel.Create(Self);
  FHtmlPanel.Parent := Self;
  FHtmlPanel.Align := alClient;
  FHtmlPanel.BorderStyle := bsNone;
  FHtmlPanel.Color := clWhite;
  
  // Place controls correctly
  Resize;
  
  // Navigate to initial default page
  Navigate(FEditURL.Text);
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
    FEditURL.Left := FBtnBack.Left + FBtnBack.Width + 8;
    FEditURL.Width := FBtnGo.Left - FEditURL.Left - 8;
  end;
end;

procedure TAIChromiumBrowser.SetURL(const AValue: string);
begin
  if FURL <> AValue then
  begin
    FURL := AValue;
    Navigate(FURL);
  end;
end;

procedure TAIChromiumBrowser.SetShowAddressBar(AValue: Boolean);
begin
  if FShowAddressBar <> AValue then
  begin
    FShowAddressBar := AValue;
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
  Client: TFPHTTPClient;
  SafeURL: string;
  Stream: TStringStream;
  ErrStream: TStringStream;
  NewHTML: TIpHtml;
begin
  SafeURL := Trim(AURL);
  if SafeURL = '' then Exit;
  
  // Simple autocomplete protocol prefix if missing
  if (Pos('http://', LowerCase(SafeURL)) <> 1) and (Pos('https://', LowerCase(SafeURL)) <> 1) then
    SafeURL := 'https://' + SafeURL;
    
  FURL := SafeURL;
  if FEditURL.Text <> FURL then
    FEditURL.Text := FURL;
    
  // Add to history
  if (FHistory.Count = 0) or (FHistory[FHistory.Count - 1] <> FURL) then
  begin
    FHistory.Add(FURL);
    FHistoryIdx := FHistory.Count - 1;
  end;
  
  // Fetch Web HTML content via cross-platform SSL client
  Client := TFPHTTPClient.Create(nil);
  Stream := TStringStream.Create('');
  try
    try
      Client.AllowRedirect := True;
      Client.Get(FURL, Stream);
      Stream.Position := 0;
      FHTML := Stream.DataString;
      
      // Load standard LCL HTML panel
      FHtmlPanel.OpenURL(FURL);
      
      NewHTML := TIpHtml.Create;
      FHtmlPanel.SetHtml(NewHTML);
      NewHTML.LoadFromStream(Stream);
    except
      on E: Exception do
      begin
        FHTML := '<html><body style="font-family: sans-serif; padding: 20px; color: #444;">' +
                 '<h2 style="color: #d32f2f;">Erro de Navegação</h2>' +
                 '<p>Não foi possível carregar a página: <b>' + FURL + '</b></p>' +
                 '<p>Detalhe técnico: <i>' + E.Message + '</i></p>' +
                 '<hr><p style="font-size: 11px; color: #888;">TAIChromiumBrowser Embedded cross-platform widget</p>' +
                 '</body></html>';
        
        ErrStream := TStringStream.Create(FHTML);
        try
          NewHTML := TIpHtml.Create;
          FHtmlPanel.SetHtml(NewHTML);
          NewHTML.LoadFromStream(ErrStream);
        finally
          ErrStream.Free;
        end;
      end;
    end;
  finally
    Stream.Free;
    Client.Free;
  end;
end;

procedure TAIChromiumBrowser.GoBack;
begin
  if (FHistory.Count > 0) and (FHistoryIdx > 0) then
  begin
    Dec(FHistoryIdx);
    Navigate(FHistory[FHistoryIdx]);
  end;
end;

procedure TAIChromiumBrowser.GoForward;
begin
  if (FHistory.Count > 0) and (FHistoryIdx < FHistory.Count - 1) then
  begin
    Inc(FHistoryIdx);
    Navigate(FHistory[FHistoryIdx]);
  end;
end;

procedure TAIChromiumBrowser.Reload;
begin
  Navigate(FURL);
end;

function TAIChromiumBrowser.GetHtmlContent: string;
begin
  Result := FHTML;
end;

end.
