unit ubotactions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ubottasks, Contnrs;

type
  TActionResult = (aoSuccess, aoFailed, aoBlocked);

  { TBotAction }

  TBotAction = class
  private
    FName: string;
  public
    constructor Create(const AName: string); virtual;
    property Name: string read FName;
    function Execute(ATask: TBotTask; AContext: TExecContext): TActionResult; virtual; abstract;
  end;

  { TActionRegistry }

  TActionRegistry = class
  private
    FList: TObjectList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(AAction: TBotAction);
    function Find(const AName: string): TBotAction;
  end;

function ActOk: TActionResult;
function ActFail: TActionResult;
function ActBlocked: TActionResult;

implementation

function ActOk: TActionResult;
begin
  Result := aoSuccess;
end;

function ActFail: TActionResult;
begin
  Result := aoFailed;
end;

function ActBlocked: TActionResult;
begin
  Result := aoBlocked;
end;

{ TBotAction }

constructor TBotAction.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ TActionRegistry }

constructor TActionRegistry.Create;
begin
  inherited Create;
  FList := TObjectList.Create(True);
end;

destructor TActionRegistry.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

procedure TActionRegistry.Add(AAction: TBotAction);
begin
  if Assigned(AAction) and (Find(AAction.Name) = nil) then
    FList.Add(AAction);
end;

function TActionRegistry.Find(const AName: string): TBotAction;
var
  i: Integer;
  Act: TBotAction;
begin
  Result := nil;
  for i := 0 to FList.Count - 1 do
  begin
    Act := TBotAction(FList[i]);
    if SameText(Act.Name, AName) then
    begin
      Result := Act;
      Exit;
    end;
  end;
end;

end.
