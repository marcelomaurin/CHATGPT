unit aiscene2d3d;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, fpjson, jsonparser, aibase;

type
  TSceneMode = (sm2D, sm3D);

  { TAIScene2D3D }

  TAIScene2D3D = class(TAIBaseComponent)
  private
    FTargetFPS: Integer;
    FGridVisible: Boolean;
    FAxesVisible: Boolean;
    FSceneMode: TSceneMode;
    FBackgroundColor: TColor;
    FObjectsList: TList;
    FOnCollision: TNotifyEvent;
    FOnStateGenerated: TNotifyEvent;
    FOnActionReceived: TNotifyEvent;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    procedure Pause;
    procedure Play;
    procedure AddObject(AObject: TObject);
    function ExportStateJSON: string;
  published
    property TargetFPS: Integer read FTargetFPS write FTargetFPS default 60;
    property GridVisible: Boolean read FGridVisible write FGridVisible default True;
    property AxesVisible: Boolean read FAxesVisible write FAxesVisible default True;
    property SceneMode: TSceneMode read FSceneMode write FSceneMode default sm3D;
    property BackgroundColor: TColor read FBackgroundColor write FBackgroundColor default clBlack;
    property ObjectsList: TList read FObjectsList;
    property OnCollision: TNotifyEvent read FOnCollision write FOnCollision;
    property OnStateGenerated: TNotifyEvent read FOnStateGenerated write FOnStateGenerated;
    property OnActionReceived: TNotifyEvent read FOnActionReceived write FOnActionReceived;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIScene2D3D]);
end;

{ TAIScene2D3D }

constructor TAIScene2D3D.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIScene2D3D manages the visual 2D/3D simulation environment. Properties: TargetFPS, GridVisible, AxesVisible, SceneMode, BackgroundColor. Methods: Clear, Pause, Play, AddObject, ExportStateJSON.';
  FTargetFPS := 60;
  FGridVisible := True;
  FAxesVisible := True;
  FSceneMode := sm3D;
  FBackgroundColor := clBlack;
  FObjectsList := TList.Create;
  ClearError;
end;

destructor TAIScene2D3D.Destroy;
begin
  FObjectsList.Free;
  inherited Destroy;
end;

procedure TAIScene2D3D.Clear;
begin
  FObjectsList.Clear;
  Log(llInfo, 'Scene cleared.');
end;

procedure TAIScene2D3D.Pause;
begin
  Log(llInfo, 'Scene simulation paused.');
end;

procedure TAIScene2D3D.Play;
begin
  Log(llInfo, 'Scene simulation started.');
end;

procedure TAIScene2D3D.AddObject(AObject: TObject);
begin
  if Assigned(AObject) and (FObjectsList.IndexOf(AObject) < 0) then
  begin
    FObjectsList.Add(AObject);
    Log(llDebug, 'Object added to scene.');
  end;
end;

function TAIScene2D3D.ExportStateJSON: string;
var
  JSONObj: TJSONObject;
begin
  JSONObj := TJSONObject.Create;
  try
    JSONObj.Add('fps', FTargetFPS);
    JSONObj.Add('objectsCount', FObjectsList.Count);
    JSONObj.Add('sceneMode', Ord(FSceneMode));
    Result := JSONObj.AsJSON;
  finally
    JSONObj.Free;
  end;
end;

end.
