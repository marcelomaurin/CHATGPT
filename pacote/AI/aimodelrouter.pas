unit aimodelrouter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, LResources, aibase, aillmproviders,
  aicapabilities;

type
  TAIModelRoute = class
  private
    FProviderKind: TAILLMProviderKind;
    FModel: string;
    FEndpoint: string;
    FToken: string;
    FEnabled: Boolean;
    FPriority: Integer;
    FLocal: Boolean;
  public
    constructor Create;
  published
    property ProviderKind: TAILLMProviderKind read FProviderKind write FProviderKind;
    property Model: string read FModel write FModel;
    property Endpoint: string read FEndpoint write FEndpoint;
    property Token: string read FToken write FToken;
    property Enabled: Boolean read FEnabled write FEnabled default True;
    property Priority: Integer read FPriority write FPriority default 100;
    property Local: Boolean read FLocal write FLocal;
  end;

  TAIModelRouter = class(TAIBaseComponent)
  private
    FRoutes: TObjectList;
    FCapabilities: TAICapabilityRegistry;
    FPreferLocal: Boolean;
    function GetRouteCount: Integer;
    function GetRoute(AIndex: Integer): TAIModelRoute;
    function RouteSupports(ARoute: TAIModelRoute;
      const ARequired: TAICapabilities): Boolean;
    function ScoreRoute(ARoute: TAIModelRoute): Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    function AddRoute(AProvider: TAILLMProviderKind; const AModel: string;
      const AEndpoint: string = ''; const AToken: string = '';
      APriority: Integer = 100): TAIModelRoute;
    function Select(const ARequired: TAICapabilities): TAIModelRoute;
    function SelectProvider(const ARequired: TAICapabilities;
      out AProvider: TAILLMProviderKind; out AModel, AEndpoint,
      AToken: string): Boolean;
    property RouteCount: Integer read GetRouteCount;
    property Routes[AIndex: Integer]: TAIModelRoute read GetRoute;
    property CapabilityRegistry: TAICapabilityRegistry read FCapabilities;
  published
    property PreferLocal: Boolean read FPreferLocal write FPreferLocal default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Core', [TAIModelRouter]);
end;

constructor TAIModelRoute.Create;
begin
  inherited Create;
  FProviderKind := llmOpenAICompatible;
  FEnabled := True;
  FPriority := 100;
  FLocal := False;
end;

constructor TAIModelRouter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FRoutes := TObjectList.Create(True);
  FCapabilities := TAICapabilityRegistry.Create(Self);
  FPreferLocal := True;
end;

destructor TAIModelRouter.Destroy;
begin
  FRoutes.Free;
  inherited Destroy;
end;

procedure TAIModelRouter.Clear;
begin
  FRoutes.Clear;
  ClearError;
end;

function TAIModelRouter.GetRouteCount: Integer;
begin
  Result := FRoutes.Count;
end;

function TAIModelRouter.GetRoute(AIndex: Integer): TAIModelRoute;
begin
  Result := TAIModelRoute(FRoutes[AIndex]);
end;

function TAIModelRouter.AddRoute(AProvider: TAILLMProviderKind;
  const AModel, AEndpoint, AToken: string; APriority: Integer): TAIModelRoute;
begin
  Result := TAIModelRoute.Create;
  Result.ProviderKind := AProvider;
  Result.Model := AModel;
  Result.Endpoint := AEndpoint;
  Result.Token := AToken;
  Result.Priority := APriority;
  Result.Local := FCapabilities.Supports(AProvider, aicLocal);
  FRoutes.Add(Result);
end;

function TAIModelRouter.RouteSupports(ARoute: TAIModelRoute;
  const ARequired: TAICapabilities): Boolean;
var
  C: TAICapability;
begin
  Result := Assigned(ARoute) and ARoute.Enabled;
  if not Result then
    Exit;
  for C := Low(TAICapability) to High(TAICapability) do
    if (C in ARequired) and
       (not FCapabilities.Supports(ARoute.ProviderKind, C)) then
      Exit(False);
end;

function TAIModelRouter.ScoreRoute(ARoute: TAIModelRoute): Integer;
begin
  Result := ARoute.Priority;
  if FPreferLocal and ARoute.Local then
    Dec(Result, 100000);
end;

function TAIModelRouter.Select(const ARequired: TAICapabilities): TAIModelRoute;
var
  I, BestScore, S: Integer;
  R: TAIModelRoute;
begin
  Result := nil;
  BestScore := MaxInt;
  for I := 0 to FRoutes.Count - 1 do
  begin
    R := GetRoute(I);
    if not RouteSupports(R, ARequired) then
      Continue;
    S := ScoreRoute(R);
    if (Result = nil) or (S < BestScore) then
    begin
      Result := R;
      BestScore := S;
    end;
  end;

  if Result = nil then
    SetError('Nenhuma rota LLM atende as capacidades solicitadas.')
  else
  begin
    ClearError;
    FLastResult := AILLMProviderKindName(Result.ProviderKind) + ':' + Result.Model;
  end;
end;

function TAIModelRouter.SelectProvider(const ARequired: TAICapabilities;
  out AProvider: TAILLMProviderKind; out AModel, AEndpoint, AToken: string): Boolean;
var
  R: TAIModelRoute;
begin
  R := Select(ARequired);
  Result := Assigned(R);
  if not Result then
    Exit;
  AProvider := R.ProviderKind;
  AModel := R.Model;
  AEndpoint := R.Endpoint;
  AToken := R.Token;
end;

initialization
  {$I aimodelrouter_icon.lrs}

end.
