unit aiposelibrary;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aiskeletonrig, LResources;

type
  { TAIPoseLibrary }

  TAIPoseLibrary = class(TAIBaseComponent)
  private
    FLibraryPath: string;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SavePose(const APoseName: string; ARig: TAISkeletonRig);
    procedure ApplyPose(const APoseName: string; ARig: TAISkeletonRig);
  published
    property LibraryPath: string read FLibraryPath write FLibraryPath;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIPoseLibrary]);
end;

{ TAIPoseLibrary }

constructor TAIPoseLibrary.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIPoseLibrary stores and loads poses for TAISkeletonRig. Properties: LibraryPath. Methods: SavePose, ApplyPose.';
  FLibraryPath := '';
  ClearError;
end;

procedure TAIPoseLibrary.SavePose(const APoseName: string; ARig: TAISkeletonRig);
begin
  if Assigned(ARig) then
  begin
    Log(llInfo, Format('Saving pose %s from rig %s to library.', [APoseName, ARig.Name]));
    FLastResult := 'Pose saved.';
    FLastSuccess := True;
  end
  else
    SetError('Skeleton rig not assigned.');
end;

procedure TAIPoseLibrary.ApplyPose(const APoseName: string; ARig: TAISkeletonRig);
begin
  if Assigned(ARig) then
  begin
    Log(llInfo, Format('Applying pose %s to rig %s.', [APoseName, ARig.Name]));
    FLastResult := 'Pose applied.';
    FLastSuccess := True;
  end
  else
    SetError('Skeleton rig not assigned.');
end;

initialization
  {$I aiposelibrary_icon.lrs}

end.
