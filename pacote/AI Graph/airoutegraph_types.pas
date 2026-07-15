unit airoutegraph_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAIGeoPoint = record
    Latitude: Double;
    Longitude: Double;
  end;

  TAIGeoPointArray = array of TAIGeoPoint;

  TAIRoadType = (
    rtUnknown,
    rtMotorway,
    rtTrunk,
    rtPrimary,
    rtSecondary,
    rtTertiary,
    rtUnclassified,
    rtResidential,
    rtService,
    rtTrack
  );

  TAIRouteNode = record
    ExternalId: Int64;
    Latitude: Double;
    Longitude: Double;
    FirstOutgoingEdge: Integer;
    OutgoingEdgeCount: Integer;
  end;

  TAIRouteEdge = record
    ExternalId: Int64;
    FromNodeIndex: Integer;
    ToNodeIndex: Integer;
    DistanceMeters: Double;
    EstimatedSpeedKmH: Double;
    TravelTimeSeconds: Double;
    RoadName: string;
    RoadReference: string;
    HighwayType: TAIRoadType;
    OneWay: Boolean;
    Toll: Boolean;
    GeometryStart: Integer;
    GeometryCount: Integer;
    Geometry: TAIGeoPointArray;
  end;

  TAIRouteEdgeArray = array of TAIRouteEdge;
  TAIRouteNodeArray = array of TAIRouteNode;

  TAIRouteResult = class
  public
    Found: Boolean;
    OriginNodeIndex: Integer;
    DestinationNodeIndex: Integer;
    EdgeIndexes: array of Integer;
    Geometry: TAIGeoPointArray;
    TotalDistanceMeters: Double;
    TotalTravelTimeSeconds: Double;
    CalculationTimeMilliseconds: Int64;
    ErrorMessage: string;
    procedure Clear;
  end;

  TAIRouteCity = class
  public
    IBGECode: string;
    Name: string;
    NormalizedName: string;
    Latitude: Double;
    Longitude: Double;
    NearestNodeIndex: Integer;
  end;

  TAIImportProgressEvent = procedure(
    Sender: TObject;
    const AMessage: string;
    const APercent: Integer
  ) of object;

implementation

procedure TAIRouteResult.Clear;
begin
  Found := False;
  OriginNodeIndex := -1;
  DestinationNodeIndex := -1;
  SetLength(EdgeIndexes, 0);
  SetLength(Geometry, 0);
  TotalDistanceMeters := 0;
  TotalTravelTimeSeconds := 0;
  CalculationTimeMilliseconds := 0;
  ErrorMessage := '';
end;

end.
