unit ubotplanner;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ubottasks;

type
  { TBotPlanner }

  TBotPlanner = class
  public
    function Plan(const AGoal: string; ATasks: TList): Boolean; virtual; abstract;
  end;

function NewTask(const AId: string; AOrder: Integer; const AAction, ADescription, ADependsOn: string; AParams: TStrings = nil): TBotTask;

implementation

function NewTask(const AId: string; AOrder: Integer; const AAction, ADescription, ADependsOn: string; AParams: TStrings = nil): TBotTask;
begin
  Result := TBotTask.Create;
  Result.Id := AId;
  Result.Order := AOrder;
  Result.Action := AAction;
  Result.Description := ADescription;
  Result.DependsOn := ADependsOn;
  if Assigned(AParams) then
    Result.Params.Assign(AParams);
end;

end.
