unit aisensorvirtual;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase;

type
  TSensorType = (stDistance, stCollision, stTarget);

  { TAISensorVirtual }

  TAISensorVirtual = class(TAIBaseComponent)
  private
    FSensorType: TSensorType;
    FRange: Double;
    FParentObjectID: string;
  public
    constructor Create(AOwner: TComponent); override;
    function ReadDistance: Double;
    function IsColliding: Boolean;
  published
    property SensorType: TSensorType read FSensorType write FSensorType default stDistance;
    property Range: Double read FRange write FRange;
    property ParentObjectID: string read FParentObjectID write FParentObjectID;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAISensorVirtual]);
end;

{ TAISensorVirtual }

constructor TAISensorVirtual.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAISensorVirtual simulates virtual sensors (distance, collision, target) inside a scene. Properties: SensorType, Range, ParentObjectID. Methods: ReadDistance, IsColliding.';
  FSensorType := stDistance;
  FRange := 10.0;
  FParentObjectID := '';
  ClearError;
end;

function TAISensorVirtual.ReadDistance: Double;
begin
  Result := 0.0;
  Log(llDebug, 'Reading distance sensor.');
end;

function TAISensorVirtual.IsColliding: Boolean;
begin
  Result := False;
  Log(llDebug, 'Reading collision sensor.');
end;

end.
