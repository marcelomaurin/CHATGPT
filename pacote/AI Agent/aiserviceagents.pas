unit aiserviceagents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, opensslsockets, LResources, aibase;

type
  TAIServiceAgent = class(TAIBaseComponent)
  private
    FAccessToken: string;
    FAllowWrite: Boolean;
    FTimeoutMs: Integer;
    FLastHTTPStatus: Integer;
  protected
    function URLencode(const S: string): string;
    function DoRequest(const AMethod, AURL, ABody, AContentType: string;
      const AHeaders: array of string): Boolean;
    function RequireWrite: Boolean;
    property AccessTokenValue: string read FAccessToken;
  public
    constructor Create(AOwner: TComponent); override;
    property LastHTTPStatus: Integer read FLastHTTPStatus;
  published
    property AccessToken: string read FAccessToken write FAccessToken;
    property AllowWrite: Boolean read FAllowWrite write FAllowWrite default False;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 30000;
  end;

  TAIGitHubAgent = class(TAIServiceAgent)
  private
    FOwner: string;
    FRepository: string;
    FBaseURL: string;
    FAPIVersion: string;
    function RepoURL(const ASuffix: string): string;
    function GitHubHeaders: TStringList;
  public
    constructor Create(AOwner: TComponent); override;
    function GetRepository: Boolean;
    function ListIssues(const AState: string = 'open'): Boolean;
    function GetIssue(AIssueNumber: Integer): Boolean;
    function CreateIssue(const ATitle, ABody: string): Boolean;
    function AddIssueComment(AIssueNumber: Integer; const ABody: string): Boolean;
  published
    property Owner: string read FOwner write FOwner;
    property Repository: string read FRepository write FRepository;
    property BaseURL: string read FBaseURL write FBaseURL;
    property APIVersion: string read FAPIVersion write FAPIVersion;
  end;

  TAIFacebookAgent = class(TAIServiceAgent)
  private
    FPageID: string;
    FBaseURL: string;
    FAPIVersion: string;
    function GraphURL(const APath: string): string;
    function WithToken(const AURL: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    function GetPage(const AFields: string = 'id,name'): Boolean;
    function GetFeed(ALimit: Integer = 25): Boolean;
    function PublishPost(const AMessage: string): Boolean;
  published
    property PageID: string read FPageID write FPageID;
    property BaseURL: string read FBaseURL write FBaseURL;
    property APIVersion: string read FAPIVersion write FAPIVersion;
  end;

  TAIYouTubeAgent = class(TAIServiceAgent)
  private
    FAPIKey: string;
    FChannelID: string;
    FBaseURL: string;
    function YouTubeURL(const APath: string): string;
    function WithAPIKey(const AURL: string): string;
    function OAuthHeaders: TStringList;
  public
    constructor Create(AOwner: TComponent); override;
    function GetChannel: Boolean;
    function GetMyChannel: Boolean;
    function Search(const AQuery: string; AMaxResults: Integer = 10): Boolean;
    function GetVideo(const AVideoID: string): Boolean;
    function ListComments(const AVideoID: string; AMaxResults: Integer = 20): Boolean;
    function CreateComment(const AVideoID, AText: string): Boolean;
  published
    property APIKey: string read FAPIKey write FAPIKey;
    property ChannelID: string read FChannelID write FChannelID;
    property BaseURL: string read FBaseURL write FBaseURL;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Agents', [TAIGitHubAgent, TAIFacebookAgent, TAIYouTubeAgent]);
end;

{ TAIServiceAgent }

constructor TAIServiceAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FAllowWrite := False;
  FTimeoutMs := 30000;
  FLastHTTPStatus := 0;
end;

function TAIServiceAgent.URLencode(const S: string): string;
var
  I: Integer;
  B: Byte;
  U: UTF8String;
begin
  Result := '';
  U := UTF8Encode(S);
  for I := 1 to Length(U) do
  begin
    B := Ord(U[I]);
    if ((B >= Ord('A')) and (B <= Ord('Z'))) or
       ((B >= Ord('a')) and (B <= Ord('z'))) or
       ((B >= Ord('0')) and (B <= Ord('9'))) or
       (B = Ord('-')) or (B = Ord('_')) or (B = Ord('.')) or (B = Ord('~')) then
      Result := Result + Chr(B)
    else
      Result := Result + '%' + IntToHex(B, 2);
  end;
end;

function TAIServiceAgent.DoRequest(const AMethod, AURL, ABody, AContentType: string;
  const AHeaders: array of string): Boolean;
var
  Client: TFPHTTPClient;
  ResponseStream, BodyStream: TStringStream;
  I, P: Integer;
  HName, HValue: string;
begin
  Result := False;
  ClearError;
  FLastHTTPStatus := 0;
  ResponseStream := TStringStream.Create('');
  BodyStream := nil;
  Client := TFPHTTPClient.Create(nil);
  try
    Client.AllowRedirect := True;
    Client.ConnectTimeout := FTimeoutMs;
    Client.IOTimeout := FTimeoutMs;
    for I := Low(AHeaders) to High(AHeaders) do
    begin
      P := Pos(':', AHeaders[I]);
      if P > 0 then
      begin
        HName := Trim(Copy(AHeaders[I], 1, P - 1));
        HValue := Trim(Copy(AHeaders[I], P + 1, MaxInt));
        if HName <> '' then Client.AddHeader(HName, HValue);
      end;
    end;
    if AContentType <> '' then Client.AddHeader('Content-Type', AContentType);
    if ABody <> '' then
    begin
      BodyStream := TStringStream.Create(ABody);
      Client.RequestBody := BodyStream;
    end;
    try
      Client.HTTPMethod(UpperCase(AMethod), AURL, ResponseStream, [200, 201, 202, 204]);
      FLastHTTPStatus := Client.ResponseStatusCode;
      FLastResult := ResponseStream.DataString;
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        FLastHTTPStatus := Client.ResponseStatusCode;
        FLastResult := ResponseStream.DataString;
        SetError(E.Message);
      end;
    end;
  finally
    Client.RequestBody := nil;
    BodyStream.Free;
    Client.Free;
    ResponseStream.Free;
  end;
end;

function TAIServiceAgent.RequireWrite: Boolean;
begin
  Result := FAllowWrite;
  if not Result then SetError('AllowWrite=False. Operacao de escrita bloqueada.');
end;

{ TAIGitHubAgent }

constructor TAIGitHubAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBaseURL := 'https://api.github.com';
  FAPIVersion := '2026-03-10';
end;

function TAIGitHubAgent.RepoURL(const ASuffix: string): string;
begin
  Result := ExcludeTrailingPathDelimiter(FBaseURL) + '/repos/' + URLencode(FOwner) + '/' +
    URLencode(FRepository) + ASuffix;
end;

function TAIGitHubAgent.GitHubHeaders: TStringList;
begin
  Result := TStringList.Create;
  Result.Add('Accept: application/vnd.github+json');
  Result.Add('X-GitHub-Api-Version: ' + FAPIVersion);
  Result.Add('User-Agent: CHATGPT-Lazarus-Agent');
  if Trim(AccessTokenValue) <> '' then
    Result.Add('Authorization: Bearer ' + AccessTokenValue);
end;

function TAIGitHubAgent.GetRepository: Boolean;
var H: TStringList;
begin
  H := GitHubHeaders;
  try Result := DoRequest('GET', RepoURL(''), '', '', H.ToStringArray); finally H.Free; end;
end;

function TAIGitHubAgent.ListIssues(const AState: string): Boolean;
var H: TStringList;
begin
  H := GitHubHeaders;
  try Result := DoRequest('GET', RepoURL('/issues?state=' + URLencode(AState)), '', '', H.ToStringArray); finally H.Free; end;
end;

function TAIGitHubAgent.GetIssue(AIssueNumber: Integer): Boolean;
var H: TStringList;
begin
  H := GitHubHeaders;
  try Result := DoRequest('GET', RepoURL('/issues/' + IntToStr(AIssueNumber)), '', '', H.ToStringArray); finally H.Free; end;
end;

function TAIGitHubAgent.CreateIssue(const ATitle, ABody: string): Boolean;
var H: TStringList; Body: string;
begin
  if not RequireWrite then Exit(False);
  Body := '{"title":"' + StringReplace(StringReplace(ATitle, '\', '\\', [rfReplaceAll]), '"', '\"', [rfReplaceAll]) +
    '","body":"' + StringReplace(StringReplace(StringReplace(ABody, '\', '\\', [rfReplaceAll]), '"', '\"', [rfReplaceAll]), LineEnding, '\n', [rfReplaceAll]) + '"}';
  H := GitHubHeaders;
  try Result := DoRequest('POST', RepoURL('/issues'), Body, 'application/json; charset=utf-8', H.ToStringArray); finally H.Free; end;
end;

function TAIGitHubAgent.AddIssueComment(AIssueNumber: Integer; const ABody: string): Boolean;
var H: TStringList; Body: string;
begin
  if not RequireWrite then Exit(False);
  Body := '{"body":"' + StringReplace(StringReplace(StringReplace(ABody, '\', '\\', [rfReplaceAll]), '"', '\"', [rfReplaceAll]), LineEnding, '\n', [rfReplaceAll]) + '"}';
  H := GitHubHeaders;
  try Result := DoRequest('POST', RepoURL('/issues/' + IntToStr(AIssueNumber) + '/comments'), Body,
    'application/json; charset=utf-8', H.ToStringArray); finally H.Free; end;
end;

{ TAIFacebookAgent }

constructor TAIFacebookAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBaseURL := 'https://graph.facebook.com';
  FAPIVersion := '';
end;

function TAIFacebookAgent.GraphURL(const APath: string): string;
begin
  Result := ExcludeTrailingPathDelimiter(FBaseURL);
  if Trim(FAPIVersion) <> '' then Result := Result + '/' + Trim(FAPIVersion);
  if (APath <> '') and (APath[1] <> '/') then Result := Result + '/';
  Result := Result + APath;
end;

function TAIFacebookAgent.WithToken(const AURL: string): string;
begin
  Result := AURL;
  if Trim(AccessTokenValue) = '' then Exit;
  if Pos('?', Result) > 0 then Result := Result + '&' else Result := Result + '?';
  Result := Result + 'access_token=' + URLencode(AccessTokenValue);
end;

function TAIFacebookAgent.GetPage(const AFields: string): Boolean;
begin
  Result := DoRequest('GET', WithToken(GraphURL(FPageID + '?fields=' + URLencode(AFields))), '', '', []);
end;

function TAIFacebookAgent.GetFeed(ALimit: Integer): Boolean;
begin
  if ALimit < 1 then ALimit := 1;
  if ALimit > 100 then ALimit := 100;
  Result := DoRequest('GET', WithToken(GraphURL(FPageID + '/feed?limit=' + IntToStr(ALimit))), '', '', []);
end;

function TAIFacebookAgent.PublishPost(const AMessage: string): Boolean;
var Body: string;
begin
  if not RequireWrite then Exit(False);
  Body := 'message=' + URLencode(AMessage) + '&access_token=' + URLencode(AccessTokenValue);
  Result := DoRequest('POST', GraphURL(FPageID + '/feed'), Body,
    'application/x-www-form-urlencoded; charset=utf-8', []);
end;

{ TAIYouTubeAgent }

constructor TAIYouTubeAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBaseURL := 'https://www.googleapis.com/youtube/v3';
end;

function TAIYouTubeAgent.YouTubeURL(const APath: string): string;
begin
  Result := ExcludeTrailingPathDelimiter(FBaseURL);
  if (APath <> '') and (APath[1] <> '/') then Result := Result + '/';
  Result := Result + APath;
end;

function TAIYouTubeAgent.WithAPIKey(const AURL: string): string;
begin
  Result := AURL;
  if Trim(FAPIKey) = '' then Exit;
  if Pos('?', Result) > 0 then Result := Result + '&' else Result := Result + '?';
  Result := Result + 'key=' + URLencode(FAPIKey);
end;

function TAIYouTubeAgent.OAuthHeaders: TStringList;
begin
  Result := TStringList.Create;
  if Trim(AccessTokenValue) <> '' then Result.Add('Authorization: Bearer ' + AccessTokenValue);
  Result.Add('Accept: application/json');
end;

function TAIYouTubeAgent.GetChannel: Boolean;
begin
  Result := DoRequest('GET', WithAPIKey(YouTubeURL('channels?part=snippet,statistics,contentDetails&id=' +
    URLencode(FChannelID))), '', '', []);
end;

function TAIYouTubeAgent.GetMyChannel: Boolean;
var H: TStringList;
begin
  H := OAuthHeaders;
  try Result := DoRequest('GET', YouTubeURL('channels?part=snippet,statistics,contentDetails&mine=true'), '', '', H.ToStringArray); finally H.Free; end;
end;

function TAIYouTubeAgent.Search(const AQuery: string; AMaxResults: Integer): Boolean;
begin
  if AMaxResults < 1 then AMaxResults := 1;
  if AMaxResults > 50 then AMaxResults := 50;
  Result := DoRequest('GET', WithAPIKey(YouTubeURL('search?part=snippet&type=video&maxResults=' +
    IntToStr(AMaxResults) + '&q=' + URLencode(AQuery))), '', '', []);
end;

function TAIYouTubeAgent.GetVideo(const AVideoID: string): Boolean;
begin
  Result := DoRequest('GET', WithAPIKey(YouTubeURL('videos?part=snippet,statistics,contentDetails&id=' +
    URLencode(AVideoID))), '', '', []);
end;

function TAIYouTubeAgent.ListComments(const AVideoID: string; AMaxResults: Integer): Boolean;
begin
  if AMaxResults < 1 then AMaxResults := 1;
  if AMaxResults > 100 then AMaxResults := 100;
  Result := DoRequest('GET', WithAPIKey(YouTubeURL('commentThreads?part=snippet&videoId=' +
    URLencode(AVideoID) + '&maxResults=' + IntToStr(AMaxResults))), '', '', []);
end;

function TAIYouTubeAgent.CreateComment(const AVideoID, AText: string): Boolean;
var
  H: TStringList;
  Body, SafeText: string;
begin
  if not RequireWrite then Exit(False);
  SafeText := StringReplace(StringReplace(StringReplace(AText, '\', '\\', [rfReplaceAll]), '"', '\"', [rfReplaceAll]), LineEnding, '\n', [rfReplaceAll]);
  Body := '{"snippet":{"videoId":"' + URLencode(AVideoID) + '","topLevelComment":{"snippet":{"textOriginal":"' + SafeText + '"}}}}';
  H := OAuthHeaders;
  try Result := DoRequest('POST', YouTubeURL('commentThreads?part=snippet'), Body,
    'application/json; charset=utf-8', H.ToStringArray); finally H.Free; end;
end;

end.
