unit aifacetracker;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase;

type
  { TAIFaceTracker }

  TAIFaceTracker = class(TAIBaseComponent)
  private
    FCascadeClassifierPath: string;
  public
    constructor Create(AOwner: TComponent); override;
    function TrackFace(AFrame: TObject; var AX, AY, AW, AH: Integer): Boolean;
  published
    property CascadeClassifierPath: string read FCascadeClassifierPath write FCascadeClassifierPath;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Vision', [TAIFaceTracker]);
end;

{ TAIFaceTracker }

constructor TAIFaceTracker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIFaceTracker detects and tracks faces using Cascade classifiers. Properties: CascadeClassifierPath. Methods: TrackFace.';
  FCascadeClassifierPath := '';
  ClearError;
end;

function TAIFaceTracker.TrackFace(AFrame: TObject; var AX, AY, AW, AH: Integer): Boolean;
begin
  Result := False;
  AX := 0;
  AY := 0;
  AW := 0;
  AH := 0;
  Log(llDebug, 'Tracking face in frame.');
end;

end.
