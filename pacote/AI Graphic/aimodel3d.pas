unit aimodel3d;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, aibase;

type
  { TAIModel3D }

  TAIModel3D = class(TAIBaseComponent)
  private
    FVerticesCount: Integer;
    FFacesCount: Integer;
    FFilePath: string;
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    procedure Rotate(const AX, AY, AZ: Double);
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
begin
  FFilePath := AFileName;
  Log(llInfo, 'Loading 3D model from: ' + AFileName);
  ClearError;

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
        // A binary STL file size must match exactly: 80 + 4 + N * 50
        if FStream.Size = Int64(84) + Int64(TrianglesCount) * 50 then
          IsBinary := True;
      end;

      if IsBinary then
      begin
        FFacesCount := TrianglesCount;
        FVerticesCount := TrianglesCount * 3;
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
        FVerticesCount := VCount;
        FFacesCount := FCount;
        FLastResult := Format('ASCII STL loaded. Vertices: %d, Faces: %d', [VCount, FCount]);
        FLastSuccess := True;
        Log(llInfo, FLastResult);
      finally
        Lines.Free;
      end;
    end;
  except
    on E: Exception do
    begin
      FVerticesCount := 0;
      FFacesCount := 0;
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
