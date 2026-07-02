unit ubottasks;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TTaskStatus = (tsPending, tsRunning, tsCompleted, tsFailed, tsCanceled);

  { TBotTask }

  TBotTask = class
  private
    FId: string;
    FOrder: Integer;
    FAction: string;
    FDescription: string;
    FDependsOn: string;
    FParams: TStringList;
    FStatus: TTaskStatus;
    FResultMsg: string;
  public
    constructor Create;
    destructor Destroy; override;

    property Id: string read FId write FId;
    property Order: Integer read FOrder write FOrder;
    property Action: string read FAction write FAction;
    property Description: string read FDescription write FDescription;
    property DependsOn: string read FDependsOn write FDependsOn;
    property Params: TStringList read FParams;
    property Status: TTaskStatus read FStatus write FStatus;
    property ResultMsg: string read FResultMsg write FResultMsg;
  end;

  { TExecContext }

  TExecContext = class
  private
    FData: TStringList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure SetValue(const AKey, AValue: string);
    function GetValue(const AKey: string): string;
    function Has(const AKey: string): Boolean;
    function Render(const AText: string): string;
  end;

implementation

{ TBotTask }

constructor TBotTask.Create;
begin
  inherited Create;
  FParams := TStringList.Create;
  FStatus := tsPending;
end;

destructor TBotTask.Destroy;
begin
  FParams.Free;
  inherited Destroy;
end;

{ TExecContext }

constructor TExecContext.Create;
begin
  inherited Create;
  FData := TStringList.Create;
  FData.NameValueSeparator := '=';
end;

destructor TExecContext.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

procedure TExecContext.SetValue(const AKey, AValue: string);
begin
  FData.Values[AKey] := AValue;
end;

function TExecContext.GetValue(const AKey: string): string;
begin
  Result := FData.Values[AKey];
end;

function TExecContext.Has(const AKey: string): Boolean;
begin
  Result := FData.IndexOfName(AKey) >= 0;
end;

function TExecContext.Render(const AText: string): string;
var
  i: Integer;
  Key, Val, SearchStr: string;
begin
  Result := AText;
  for i := 0 to FData.Count - 1 do
  begin
    Key := FData.Names[i];
    Val := FData.ValueFromIndex[i];
    SearchStr := '{{' + Key + '}}';
    Result := StringReplace(Result, SearchStr, Val, [rfReplaceAll, rfIgnoreCase]);
  end;
end;

end.
