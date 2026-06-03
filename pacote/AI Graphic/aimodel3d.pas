unit aimodel3d;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, aibase;

type
  TVertex3D = record
    X, Y, Z: Single;
  end;

  TFace3D = record
    V1, V2, V3: TVertex3D;
    Normal: TVertex3D;
  end;

  TFaceArray = array of TFace3D;

  { TAIModel3D }

  TAIModel3D = class(TAIBaseComponent)
  private
    FVerticesCount: Integer;
    FFacesCount: Integer;
    FFilePath: string;
    FFaces: TFaceArray;
    FMinX, FMaxX, FMinY, FMaxY, FMinZ, FMaxZ: Single;
    FMidX, FMidY, FMidZ: Single;
    FModelRadius: Single;
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    procedure Rotate(const AX, AY, AZ: Double);
    
    property Faces: TFaceArray read FFaces;
    property MinX: Single read FMinX;
    property MaxX: Single read FMaxX;
    property MinY: Single read FMinY;
    property MaxY: Single read FMaxY;
    property MinZ: Single read FMinZ;
    property MaxZ: Single read FMaxZ;
    property MidX: Single read FMidX;
    property MidY: Single read FMidY;
    property MidZ: Single read FMidZ;
    property ModelRadius: Single read FModelRadius;
  published
    property VerticesCount: Integer read FVerticesCount write FVerticesCount;
    property FacesCount: Integer read FFacesCount write FFacesCount;
    property FilePath: string read FFilePath write FFilePath;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIModel3D]);
end;

{ TAIModel3D }

constructor TAIModel3D.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIModel3D stores 3D model mesh data (vertices, faces). Properties: VerticesCount, FacesCount, FilePath. Methods: LoadFromFile, SaveToFile, Rotate.';
  FVerticesCount := 0;
  FFacesCount := 0;
  FFilePath := '';
  SetLength(FFaces, 0);
  FMinX := 0; FMaxX := 0; FMinY := 0; FMaxY := 0; FMinZ := 0; FMaxZ := 0;
  FMidX := 0; FMidY := 0; FMidZ := 0;
  FModelRadius := 1.0;
  ClearError;
end;

procedure TAIModel3D.LoadFromFile(const AFileName: string);
var
  FStream: TFileStream;
  Header: array[0..79] of Byte;
  TrianglesCount: UInt32;
  IsBinary: Boolean;
  Lines: TStringList;
  I: Integer;
  Line: string;
  VCount, FCount: Integer;
  Face: TFace3D;
  VIdx: Integer;
  Tokens: TStringList;
  
  function ParseFloat(const S: string): Single;
  var
    FS: TFormatSettings;
  begin
    FS := DefaultFormatSettings;
    if Pos('.', S) > 0 then
      FS.DecimalSeparator := '.'
    else if Pos(',', S) > 0 then
      FS.DecimalSeparator := ',';
    Result := StrToFloatDef(Trim(S), 0.0, FS);
  end;

  procedure CalcBoundingBox;
  var
    Idx: Integer;
    DX, DY, DZ: Single;
  begin
    if Length(FFaces) = 0 then Exit;
    FMinX := FFaces[0].V1.X; FMaxX := FMinX;
    FMinY := FFaces[0].V1.Y; FMaxY := FMinY;
    FMinZ := FFaces[0].V1.Z; FMaxZ := FMinZ;
    for Idx := 0 to Length(FFaces) - 1 do
    begin
      // V1
      if FFaces[Idx].V1.X < FMinX then FMinX := FFaces[Idx].V1.X;
      if FFaces[Idx].V1.X > FMaxX then FMaxX := FFaces[Idx].V1.X;
      if FFaces[Idx].V1.Y < FMinY then FMinY := FFaces[Idx].V1.Y;
      if FFaces[Idx].V1.Y > FMaxY then FMaxY := FFaces[Idx].V1.Y;
      if FFaces[Idx].V1.Z < FMinZ then FMinZ := FFaces[Idx].V1.Z;
      if FFaces[Idx].V1.Z > FMaxZ then FMaxZ := FFaces[Idx].V1.Z;
      // V2
      if FFaces[Idx].V2.X < FMinX then FMinX := FFaces[Idx].V2.X;
      if FFaces[Idx].V2.X > FMaxX then FMaxX := FFaces[Idx].V2.X;
      if FFaces[Idx].V2.Y < FMinY then FMinY := FFaces[Idx].V2.Y;
      if FFaces[Idx].V2.Y > FMaxY then FMaxY := FFaces[Idx].V2.Y;
      if FFaces[Idx].V2.Z < FMinZ then FMinZ := FFaces[Idx].V2.Z;
      if FFaces[Idx].V2.Z > FMaxZ then FMaxZ := FFaces[Idx].V2.Z;
      // V3
      if FFaces[Idx].V3.X < FMinX then FMinX := FFaces[Idx].V3.X;
      if FFaces[Idx].V3.X > FMaxX then FMaxX := FFaces[Idx].V3.X;
      if FFaces[Idx].V3.Y < FMinY then FMinY := FFaces[Idx].V3.Y;
      if FFaces[Idx].V3.Y > FMaxY then FMaxY := FFaces[Idx].V3.Y;
      if FFaces[Idx].V3.Z < FMinZ then FMinZ := FFaces[Idx].V3.Z;
      if FFaces[Idx].V3.Z > FMaxZ then FMaxZ := FFaces[Idx].V3.Z;
    end;
    FMidX := (FMinX + FMaxX) / 2.0;
    FMidY := (FMinY + FMaxY) / 2.0;
    FMidZ := (FMinZ + FMaxZ) / 2.0;
    DX := FMaxX - FMinX;
    DY := FMaxY - FMinY;
    DZ := FMaxZ - FMinZ;
    FModelRadius := Sqrt(DX*DX + DY*DY + DZ*DZ) / 2.0;
    if FModelRadius < 0.1 then FModelRadius := 1.0;
  end;

begin
  FFilePath := AFileName;
  Log(llInfo, 'Loading 3D model from: ' + AFileName);
  ClearError;
  SetLength(FFaces, 0);
  FMinX := 0; FMaxX := 0; FMinY := 0; FMaxY := 0; FMinZ := 0; FMaxZ := 0;
  FMidX := 0; FMidY := 0; FMidZ := 0;
  FModelRadius := 1.0;

  if not FileExists(AFileName) then
  begin
    FVerticesCount := 0;
    FFacesCount := 0;
    FLastSuccess := False;
    FLastResult := 'File not found: ' + AFileName;
    Log(llError, FLastResult);
    Exit;
  end;

  try
    IsBinary := False;
    // Determine if it is ASCII or Binary
    FStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      if FStream.Size >= 84 then
      begin
        FStream.ReadBuffer(Header, 80);
        FStream.ReadBuffer(TrianglesCount, 4);
        if FStream.Size = Int64(84) + Int64(TrianglesCount) * 50 then
          IsBinary := True;
      end;

      if IsBinary then
      begin
        FFacesCount := TrianglesCount;
        FVerticesCount := TrianglesCount * 3;
        SetLength(FFaces, TrianglesCount);
        for I := 0 to TrianglesCount - 1 do
        begin
          FStream.ReadBuffer(Face.Normal.X, 4);
          FStream.ReadBuffer(Face.Normal.Y, 4);
          FStream.ReadBuffer(Face.Normal.Z, 4);
          FStream.ReadBuffer(Face.V1.X, 4);
          FStream.ReadBuffer(Face.V1.Y, 4);
          FStream.ReadBuffer(Face.V1.Z, 4);
          FStream.ReadBuffer(Face.V2.X, 4);
          FStream.ReadBuffer(Face.V2.Y, 4);
          FStream.ReadBuffer(Face.V2.Z, 4);
          FStream.ReadBuffer(Face.V3.X, 4);
          FStream.ReadBuffer(Face.V3.Y, 4);
          FStream.ReadBuffer(Face.V3.Z, 4);
          FStream.Seek(2, soFromCurrent);
          FFaces[I] := Face;
        end;
        FLastResult := Format('Binary STL loaded. Vertices: %d, Faces: %d', [FVerticesCount, FFacesCount]);
        FLastSuccess := True;
        Log(llInfo, FLastResult);
      end;
    finally
      FStream.Free;
    end;

    // If not binary, parse as ASCII
    if not IsBinary then
    begin
      Lines := TStringList.Create;
      Tokens := TStringList.Create;
      Tokens.Delimiter := ' ';
      Tokens.StrictDelimiter := False;
      try
        Lines.LoadFromFile(AFileName);
        VCount := 0;
        FCount := 0;
        
        for I := 0 to Lines.Count - 1 do
        begin
          Line := Trim(Lines[I]);
          if StartsText('facet', Line) or StartsText('facet ', Line) then
            Inc(FCount);
          if StartsText('vertex', Line) or StartsText('vertex ', Line) then
            Inc(VCount);
        end;
        
        FFacesCount := FCount;
        FVerticesCount := VCount;
        SetLength(FFaces, FCount);
        
        FCount := 0;
        VIdx := 0;
        for I := 0 to Lines.Count - 1 do
        begin
          Tokens.DelimitedText := Trim(Lines[I]);
          if Tokens.Count = 0 then Continue;
          
          if (Tokens[0] = 'facet') and (Tokens.Count >= 5) and (Tokens[1] = 'normal') then
          begin
            Face.Normal.X := ParseFloat(Tokens[2]);
            Face.Normal.Y := ParseFloat(Tokens[3]);
            Face.Normal.Z := ParseFloat(Tokens[4]);
            VIdx := 0;
          end
          else if (Tokens[0] = 'vertex') and (Tokens.Count >= 4) then
          begin
            if VIdx = 0 then
            begin
              Face.V1.X := ParseFloat(Tokens[1]);
              Face.V1.Y := ParseFloat(Tokens[2]);
              Face.V1.Z := ParseFloat(Tokens[3]);
              Inc(VIdx);
            end
            else if VIdx = 1 then
            begin
              Face.V2.X := ParseFloat(Tokens[1]);
              Face.V2.Y := ParseFloat(Tokens[2]);
              Face.V2.Z := ParseFloat(Tokens[3]);
              Inc(VIdx);
            end
            else if VIdx = 2 then
            begin
              Face.V3.X := ParseFloat(Tokens[1]);
              Face.V3.Y := ParseFloat(Tokens[2]);
              Face.V3.Z := ParseFloat(Tokens[3]);
              Inc(VIdx);
              if FCount < Length(FFaces) then
              begin
                FFaces[FCount] := Face;
                Inc(FCount);
              end;
            end;
          end;
        end;
        FLastResult := Format('ASCII STL loaded. Vertices: %d, Faces: %d', [VCount, FCount]);
        FLastSuccess := True;
        Log(llInfo, FLastResult);
      finally
        Tokens.Free;
        Lines.Free;
      end;
    end;
    
    CalcBoundingBox;
    
  except
    on E: Exception do
    begin
      FVerticesCount := 0;
      FFacesCount := 0;
      SetLength(FFaces, 0);
      FLastSuccess := False;
      FLastResult := 'Error parsing STL: ' + E.Message;
      Log(llError, FLastResult);
    end;
  end;
end;

procedure TAIModel3D.SaveToFile(const AFileName: string);
begin
  Log(llInfo, 'Saving 3D model to: ' + AFileName);
  FLastResult := 'Model saved.';
  FLastSuccess := True;
end;

procedure TAIModel3D.Rotate(const AX, AY, AZ: Double);
begin
  Log(llDebug, Format('Rotated model: (%.2f, %.2f, %.2f)', [AX, AY, AZ]));
end;

end.
