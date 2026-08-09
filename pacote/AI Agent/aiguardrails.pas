unit aiguardrails;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aitools, LResources;

type
  TAIGuardrailTarget = (agtInput, agtOutput, agtTool);
  TAIGuardrailDecision = (agdAllow, agdMark, agdConfirm, agdBlock);

  IAIGuardrail = interface
    ['{024CE488-A05B-4849-A7A1-F5264F41C685}']
    function Evaluate(const AValue: string; out ADecision: TAIGuardrailDecision;
      out AReason: string): Boolean;
  end;

  TAIGuardrail = class(TAIBaseComponent, IAIGuardrail)
  private
    FEnabled: Boolean;
    FTarget: TAIGuardrailTarget;
  public
    constructor Create(AOwner: TComponent); override;
    function Evaluate(const AValue: string; out ADecision: TAIGuardrailDecision;
      out AReason: string): Boolean; virtual; abstract;
    function GetLastError: string;
  published
    property Enabled: Boolean read FEnabled write FEnabled default True;
    property Target: TAIGuardrailTarget read FTarget write FTarget default agtInput;
  end;

  TAITextGuardrail = class(TAIGuardrail)
  private
    FBlockedPatterns: TStringList;
    FMarkedPatterns: TStringList;
    FCaseSensitive: Boolean;
    FMaximumLength: Integer;
    function GetBlockedPatterns: TStrings;
    function GetMarkedPatterns: TStrings;
    procedure SetBlockedPatterns(AValue: TStrings);
    procedure SetMarkedPatterns(AValue: TStrings);
    function ContainsPattern(const AValue, APattern: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Evaluate(const AValue: string; out ADecision: TAIGuardrailDecision;
      out AReason: string): Boolean; override;
  published
    property BlockedPatterns: TStrings read GetBlockedPatterns write SetBlockedPatterns;
    property MarkedPatterns: TStrings read GetMarkedPatterns write SetMarkedPatterns;
    property CaseSensitive: Boolean read FCaseSensitive write FCaseSensitive default False;
    property MaximumLength: Integer read FMaximumLength write FMaximumLength default 0;
  end;

  TAIInputGuardrail = class(TAITextGuardrail)
  public constructor Create(AOwner: TComponent); override;
  end;

  TAIOutputGuardrail = class(TAITextGuardrail)
  public constructor Create(AOwner: TComponent); override;
  end;

  TAIToolGuardrail = class(TAIGuardrail, IAIToolGuardrail)
  private
    FPolicies: TStringList;
    FDefaultPolicy: TAIToolPolicy;
    function GetPolicies: TStrings;
    procedure SetPolicies(AValue: TStrings);
    function ParsePolicy(const AValue: string): TAIToolPolicy;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Evaluate(const AValue: string; out ADecision: TAIGuardrailDecision;
      out AReason: string): Boolean; override;
    function EvaluateTool(ATool: TAITool; ACall: TAIToolCall;
      out APolicy: TAIToolPolicy; out AReason: string): Boolean;
    procedure SetToolPolicy(const AToolName: string; APolicy: TAIToolPolicy);
    function GetToolPolicy(const AToolName: string): TAIToolPolicy;
  published
    property Policies: TStrings read GetPolicies write SetPolicies;
    property DefaultPolicy: TAIToolPolicy read FDefaultPolicy write FDefaultPolicy default toolPolicyInherit;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Agents', [TAIInputGuardrail, TAIOutputGuardrail,
    TAIToolGuardrail]);
end;

constructor TAIGuardrail.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccSafety;
  FEnabled := True;
  FTarget := agtInput;
end;

function TAIGuardrail.GetLastError: string;
begin Result := FLastError; end;

constructor TAITextGuardrail.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBlockedPatterns := TStringList.Create;
  FMarkedPatterns := TStringList.Create;
  FMaximumLength := 0;
end;

destructor TAITextGuardrail.Destroy;
begin
  FMarkedPatterns.Free;
  FBlockedPatterns.Free;
  inherited Destroy;
end;

procedure TAITextGuardrail.SetBlockedPatterns(AValue: TStrings);
begin FBlockedPatterns.Assign(AValue); end;

function TAITextGuardrail.GetBlockedPatterns: TStrings;
begin Result := FBlockedPatterns; end;

function TAITextGuardrail.GetMarkedPatterns: TStrings;
begin Result := FMarkedPatterns; end;

procedure TAITextGuardrail.SetMarkedPatterns(AValue: TStrings);
begin FMarkedPatterns.Assign(AValue); end;

function TAITextGuardrail.ContainsPattern(const AValue, APattern: string): Boolean;
begin
  if FCaseSensitive then Result := Pos(APattern, AValue) > 0
  else Result := Pos(LowerCase(APattern), LowerCase(AValue)) > 0;
end;

function TAITextGuardrail.Evaluate(const AValue: string;
  out ADecision: TAIGuardrailDecision; out AReason: string): Boolean;
var I: Integer;
begin
  ADecision := agdAllow;
  AReason := '';
  if not Enabled then Exit(True);
  if (FMaximumLength > 0) and (Length(AValue) > FMaximumLength) then
  begin
    ADecision := agdBlock;
    AReason := Format('Conteudo excede MaximumLength=%d.', [FMaximumLength]);
    Exit(False);
  end;
  for I := 0 to FBlockedPatterns.Count - 1 do
    if (FBlockedPatterns[I] <> '') and ContainsPattern(AValue, FBlockedPatterns[I]) then
    begin ADecision := agdBlock; AReason := 'Padrao bloqueado detectado: ' + FBlockedPatterns[I]; Exit(False); end;
  for I := 0 to FMarkedPatterns.Count - 1 do
    if (FMarkedPatterns[I] <> '') and ContainsPattern(AValue, FMarkedPatterns[I]) then
    begin ADecision := agdMark; AReason := 'Conteudo marcado por: ' + FMarkedPatterns[I]; Exit(True); end;
  Result := True;
end;

constructor TAIInputGuardrail.Create(AOwner: TComponent);
begin inherited Create(AOwner); Target := agtInput; end;

constructor TAIOutputGuardrail.Create(AOwner: TComponent);
begin inherited Create(AOwner); Target := agtOutput; end;

constructor TAIToolGuardrail.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Target := agtTool;
  FPolicies := TStringList.Create;
  FPolicies.CaseSensitive := False;
  FPolicies.NameValueSeparator := '=';
  FDefaultPolicy := toolPolicyInherit;
end;

destructor TAIToolGuardrail.Destroy;
begin FPolicies.Free; inherited Destroy; end;

procedure TAIToolGuardrail.SetPolicies(AValue: TStrings);
begin FPolicies.Assign(AValue); end;

function TAIToolGuardrail.GetPolicies: TStrings;
begin Result := FPolicies; end;

function TAIToolGuardrail.ParsePolicy(const AValue: string): TAIToolPolicy;
begin
  if SameText(AValue, 'allow') then Exit(toolPolicyAllow);
  if SameText(AValue, 'confirm') then Exit(toolPolicyConfirm);
  if SameText(AValue, 'block') then Exit(toolPolicyBlock);
  Result := toolPolicyInherit;
end;

procedure TAIToolGuardrail.SetToolPolicy(const AToolName: string;
  APolicy: TAIToolPolicy);
const Names: array[TAIToolPolicy] of string = ('Inherit', 'Allow', 'Confirm', 'Block');
begin FPolicies.Values[AToolName] := Names[APolicy]; end;

function TAIToolGuardrail.GetToolPolicy(const AToolName: string): TAIToolPolicy;
var S: string;
begin
  S := FPolicies.Values[AToolName];
  if S = '' then Result := FDefaultPolicy else Result := ParsePolicy(S);
end;

function TAIToolGuardrail.Evaluate(const AValue: string;
  out ADecision: TAIGuardrailDecision; out AReason: string): Boolean;
var P: TAIToolPolicy;
begin
  P := GetToolPolicy(AValue);
  case P of
    toolPolicyAllow, toolPolicyInherit: begin ADecision := agdAllow; AReason := ''; Result := True; end;
    toolPolicyConfirm: begin ADecision := agdConfirm; AReason := 'Tool exige confirmacao.'; Result := True; end;
    toolPolicyBlock: begin ADecision := agdBlock; AReason := 'Tool bloqueada por politica.'; Result := False; end;
  end;
end;

function TAIToolGuardrail.EvaluateTool(ATool: TAITool; ACall: TAIToolCall;
  out APolicy: TAIToolPolicy; out AReason: string): Boolean;
begin
  AReason := '';
  if not Enabled then begin APolicy := toolPolicyInherit; Exit(True); end;
  APolicy := GetToolPolicy(ATool.Name);
  Result := APolicy <> toolPolicyBlock;
  if not Result then AReason := 'Tool "' + ATool.Name + '" bloqueada pelo guardrail.'
  else if APolicy = toolPolicyConfirm then AReason := 'Tool "' + ATool.Name + '" exige confirmacao.';
end;

end.
