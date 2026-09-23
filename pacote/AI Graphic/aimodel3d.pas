unit aimodel3d;

{ ============================================================================
  Maurinsoft CHATGPT - AI Graphic / 3D Avatar Subsystem
  TAIModel3D: Suporte a STL, glTF 2.0 e GLB com Skinning (Tarefas 11 a 27)
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Math, aibase, aiavatartypes, aigltfloader, LResources;

type
  TVertex3D = record
    X, Y, Z: Single;
  end;

  TFace3D = record
    V1, V2, V3: TVertex3D;
    Normal: TVertex3D;
  end;

  TFaceArray = array of TFace3D;

  { Forward declaration para permitir referencia mutua com aiskeletonrig }
  TAISkeletonRig = class;

  { TAIModel3D }

  TAIModel3D = class(TAIBaseComponent)
  private
    FVerticesCount: Integer;
    FFacesCount: Integer;
    FFilePath: string;
    FFaces: TFaceArray;
    FGLTFFaces: TGLTFFaceArray;
    FMinX, FMaxX, FMinY, FMaxY, FMinZ, FMaxZ: Single;
    FMidX, FMidY, FMidZ: Single;
    FModelRadius: Single;

    // Estruturas glTF e Skinning (Tarefas 14-27)
    FBaseVertices: TAIAvatarVertexArray;
    FSkinnedVertices: TAIAvatarVertexArray;
    FMaterials: TAIAvatarMaterialArray;
    FTextures: TAIAvatarTextureArray;
    FSkins: TAIAvatarSkinArray;
    FNodes: TGLTFNodeArray;
    FAnimations: TAIAvatarAnimationArray;
    FHasSkinning: Boolean;

    procedure CalcBoundingBox;
    function LoadSTL(const AFileName: string): Boolean;
    function LoadGLTFOrGLB(const AFileName: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    procedure Rotate(const AX, AY, AZ: Double);

    // Skinning e Deformacao Esqueletal (Tarefas 24 a 27)
    procedure ApplySkinning; overload;
    procedure ApplySkinning(ASkeleton: TComponent); overload;
    procedure ResetSkinning;

    property Faces: TFaceArray read FFaces;
    property GLTFFaces: TGLTFFaceArray read FGLTFFaces;
    property BaseVertices: TAIAvatarVertexArray read FBaseVertices;
    property SkinnedVertices: TAIAvatarVertexArray read FSkinnedVertices;
    property Materials: TAIAvatarMaterialArray read FMaterials;
    property Textures: TAIAvatarTextureArray read FTextures;
    property Skins: TAIAvatarSkinArray read FSkins;
    property Nodes: TGLTFNodeArray read FNodes;
    property Animations: TAIAvatarAnimationArray read FAnimations;
    property HasSkinning: Boolean read FHasSkinning;
    function GetAnimationCount: Integer;
    function FindAnimation(const AName: string; out AAnim: TAIAvatarAnimation): Boolean;

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

  { Declaracao parcial de classe para consumo de TAISkeletonRig }
  TAISkeletonRig = class(TAIBaseComponent)
  public
    function GetJointCount: Integer; virtual; abstract;
    function HasHumanoidBone(AHumanoidBone: TAIHumanoidBone): Boolean; virtual; abstract;
    function FindHumanoidBone(AHumanoidBone: TAIHumanoidBone; out AJointIndex: Integer): Boolean; virtual; abstract;
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
  FPrompt := 'Component TAIModel3D stores 3D model mesh data (vertices, faces, materials, skins). Supports STL, glTF 2.0 and GLB with skeletal skinning deformation. Properties: VerticesCount, FacesCount, FilePath, HasSkinning. Methods: LoadFromFile, ApplySkinning, Rotate.';
  FVerticesCount := 0;
  FFacesCount := 0;
  FFilePath := '';
  SetLength(FFaces, 0);
  SetLength(FGLTFFaces, 0);
  SetLength(FBaseVertices, 0);
  SetLength(FSkinnedVertices, 0);
  SetLength(FMaterials, 0);
  SetLength(FTextures, 0);
  SetLength(FSkins, 0);
  SetLength(FNodes, 0);
  SetLength(FAnimations, 0);
  FHasSkinning := False;
  FMinX := 0; FMaxX := 0; FMinY := 0; FMaxY := 0; FMinZ := 0; FMaxZ := 0;
  FMidX := 0; FMidY := 0; FMidZ := 0;
  FModelRadius := 1.0;
  ClearError;
end;

procedure TAIModel3D.CalcBoundingBox;
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

function TAIModel3D.LoadGLTFOrGLB(const AFileName: string): Boolean;
var
  Loader: TGLTFLoader;
  I: Integer;
begin
  Result := False;
  Loader := TGLTFLoader.Create;
  try
    if Loader.LoadFromFile(AFileName, FBaseVertices, FGLTFFaces, FMaterials, FTextures, FSkins, FNodes, FAnimations) then
    begin
      FSkinnedVertices := Copy(FBaseVertices);
      FHasSkinning := (Length(FSkins) > 0) and (Length(FSkins[0].Joints) > 0);
      FVerticesCount := Length(FBaseVertices);
      FFacesCount := Length(FGLTFFaces);

      SetLength(FFaces, FFacesCount);
      for I := 0 to FFacesCount - 1 do
      begin
        FFaces[I].V1.X := FGLTFFaces[I].V1.X;
        FFaces[I].V1.Y := FGLTFFaces[I].V1.Y;
        FFaces[I].V1.Z := FGLTFFaces[I].V1.Z;

        FFaces[I].V2.X := FGLTFFaces[I].V2.X;
        FFaces[I].V2.Y := FGLTFFaces[I].V2.Y;
        FFaces[I].V2.Z := FGLTFFaces[I].V2.Z;

        FFaces[I].V3.X := FGLTFFaces[I].V3.X;
        FFaces[I].V3.Y := FGLTFFaces[I].V3.Y;
        FFaces[I].V3.Z := FGLTFFaces[I].V3.Z;

        FFaces[I].Normal.X := FGLTFFaces[I].Normal.X;
        FFaces[I].Normal.Y := FGLTFFaces[I].Normal.Y;
        FFaces[I].Normal.Z := FGLTFFaces[I].Normal.Z;
      end;

      CalcBoundingBox;
      FLastResult := Format('glTF/GLB loaded. Vertices: %d, Faces: %d, Materials: %d, Skins: %d',
        [FVerticesCount, FFacesCount, Length(FMaterials), Length(FSkins)]);
      FLastSuccess := True;
      Log(llInfo, FLastResult);
      Result := True;
    end
    else
    begin
      FLastResult := 'Error loading glTF/GLB: ' + Loader.LastError;
      FLastSuccess := False;
      Log(llError, FLastResult);
    end;
  finally
    Loader.Free;
  end;
end;

function TAIModel3D.LoadSTL(const AFileName: string): Boolean;
var
  FStream: TFileStream;
  Header: array[0..79] of Byte;
  TrianglesCount: UInt32;
  IsBinary: Boolean;
  Lines, Tokens: TStringList;
  I, VCount, FCount, VIdx: Integer;
  Face: TFace3D;
  Line: string;

  function ParseFloat(const S: string): Single;
  var
    FS: TFormatSettings;
  begin
    FS := DefaultFormatSettings;
    if Pos('.', S) > 0 then FS.DecimalSeparator := '.'
    else if Pos(',', S) > 0 then FS.DecimalSeparator := ',';
    Result := StrToFloatDef(Trim(S), 0.0, FS);
  end;

begin
  Result := False;
  IsBinary := False;
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
      CalcBoundingBox;
      FLastResult := Format('Binary STL loaded. Vertices: %d, Faces: %d', [FVerticesCount, FFacesCount]);
      FLastSuccess := True;
      Log(llInfo, FLastResult);
      Result := True;
      Exit;
    end;
  finally
    FStream.Free;
  end;

  // ASCII STL
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
      if StartsText('facet', Line) then Inc(FCount);
      if StartsText('vertex', Line) then Inc(VCount);
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
          Face.V1.X := ParseFloat(Tokens[1]); Face.V1.Y := ParseFloat(Tokens[2]); Face.V1.Z := ParseFloat(Tokens[3]);
          Inc(VIdx);
        end
        else if VIdx = 1 then
        begin
          Face.V2.X := ParseFloat(Tokens[1]); Face.V2.Y := ParseFloat(Tokens[2]); Face.V2.Z := ParseFloat(Tokens[3]);
          Inc(VIdx);
        end
        else if VIdx = 2 then
        begin
          Face.V3.X := ParseFloat(Tokens[1]); Face.V3.Y := ParseFloat(Tokens[2]); Face.V3.Z := ParseFloat(Tokens[3]);
          Inc(VIdx);
          if FCount < Length(FFaces) then
          begin
            FFaces[FCount] := Face;
            Inc(FCount);
          end;
        end;
      end;
    end;
    CalcBoundingBox;
    FLastResult := Format('ASCII STL loaded. Vertices: %d, Faces: %d', [VCount, FCount]);
    FLastSuccess := True;
    Log(llInfo, FLastResult);
    Result := True;
  finally
    Tokens.Free;
    Lines.Free;
  end;
end;

procedure TAIModel3D.LoadFromFile(const AFileName: string);
var
  Ext: string;
  FS: TFileStream;
  Magic: array[0..3] of AnsiChar;
  IsGLB: Boolean;
begin
  FFilePath := AFileName;
  Log(llInfo, 'Loading 3D model from: ' + AFileName);
  ClearError;
  SetLength(FFaces, 0);
  SetLength(FGLTFFaces, 0);
  SetLength(FBaseVertices, 0);
  SetLength(FSkinnedVertices, 0);
  SetLength(FMaterials, 0);
  SetLength(FTextures, 0);
  SetLength(FSkins, 0);
  SetLength(FNodes, 0);
  SetLength(FAnimations, 0);
  FHasSkinning := False;
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

  Ext := LowerCase(ExtractFileExt(AFileName));
  IsGLB := False;

  if (Ext = '.glb') or (Ext = '.gltf') then
  begin
    LoadGLTFOrGLB(AFileName);
    Exit;
  end;

  // Checar se o arquivo comeca com magic 'glTF' independente da extensao
  try
    FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      if FS.Size >= 4 then
      begin
        FS.ReadBuffer(Magic[0], 4);
        if Magic = 'glTF' then
          IsGLB := True;
      end;
    finally
      FS.Free;
    end;
  except
    // Segue para fallback
  end;

  if IsGLB then
    LoadGLTFOrGLB(AFileName)
  else
    LoadSTL(AFileName);
end;

procedure TAIModel3D.ApplySkinning;
begin
  ApplySkinning(nil);
end;

procedure TAIModel3D.ApplySkinning(ASkeleton: TComponent);
var
  I, FIdx, JointCount: Integer;
  P, P0, P1, P2, P3: TVector3D;
  J: TVector4I;
  W: TVector4D;
  M0, M1, M2, M3: TMatrix4x4;
begin
  if not FHasSkinning then Exit;
  if (Length(FSkins) = 0) or (Length(FSkins[0].Joints) = 0) then Exit;
  JointCount := Length(FSkins[0].Joints);

  // Deformar cada vertice base aplicando as matrizes finais dos ossos (Tarefas 25 e 26)
  for I := 0 to High(FBaseVertices) do
  begin
    W := FBaseVertices[I].Weights;
    if (W.X + W.Y + W.Z + W.W) > 0.0001 then
    begin
      J := FBaseVertices[I].Joints;
      P := FBaseVertices[I].Position;

      if (J.X >= 0) and (J.X < JointCount) then M0 := FSkins[0].Joints[J.X].FinalBoneMatrix else M0 := IdentityMatrix;
      if (J.Y >= 0) and (J.Y < JointCount) then M1 := FSkins[0].Joints[J.Y].FinalBoneMatrix else M1 := IdentityMatrix;
      if (J.Z >= 0) and (J.Z < JointCount) then M2 := FSkins[0].Joints[J.Z].FinalBoneMatrix else M2 := IdentityMatrix;
      if (J.W >= 0) and (J.W < JointCount) then M3 := FSkins[0].Joints[J.W].FinalBoneMatrix else M3 := IdentityMatrix;

      P0 := MatrixTransformPoint(M0, P);
      P1 := MatrixTransformPoint(M1, P);
      P2 := MatrixTransformPoint(M2, P);
      P3 := MatrixTransformPoint(M3, P);

      FSkinnedVertices[I].Position.X := P0.X * W.X + P1.X * W.Y + P2.X * W.Z + P3.X * W.W;
      FSkinnedVertices[I].Position.Y := P0.Y * W.X + P1.Y * W.Y + P2.Y * W.Z + P3.Y * W.W;
      FSkinnedVertices[I].Position.Z := P0.Z * W.X + P1.Z * W.Y + P2.Z * W.Z + P3.Z * W.W;
    end
    else
    begin
      FSkinnedVertices[I].Position := FBaseVertices[I].Position;
    end;
  end;

  // Atualizar faces renderizaveis do visualizador com a nova geometria deformada
  if Length(FGLTFFaces) = Length(FFaces) then
  begin
    for FIdx := 0 to High(FGLTFFaces) do
    begin
      if (FGLTFFaces[FIdx].VIdx1 >= 0) and (FGLTFFaces[FIdx].VIdx1 < Length(FSkinnedVertices)) then
      begin
        FFaces[FIdx].V1.X := FSkinnedVertices[FGLTFFaces[FIdx].VIdx1].Position.X;
        FFaces[FIdx].V1.Y := FSkinnedVertices[FGLTFFaces[FIdx].VIdx1].Position.Y;
        FFaces[FIdx].V1.Z := FSkinnedVertices[FGLTFFaces[FIdx].VIdx1].Position.Z;
      end;

      if (FGLTFFaces[FIdx].VIdx2 >= 0) and (FGLTFFaces[FIdx].VIdx2 < Length(FSkinnedVertices)) then
      begin
        FFaces[FIdx].V2.X := FSkinnedVertices[FGLTFFaces[FIdx].VIdx2].Position.X;
        FFaces[FIdx].V2.Y := FSkinnedVertices[FGLTFFaces[FIdx].VIdx2].Position.Y;
        FFaces[FIdx].V2.Z := FSkinnedVertices[FGLTFFaces[FIdx].VIdx2].Position.Z;
      end;

      if (FGLTFFaces[FIdx].VIdx3 >= 0) and (FGLTFFaces[FIdx].VIdx3 < Length(FSkinnedVertices)) then
      begin
        FFaces[FIdx].V3.X := FSkinnedVertices[FGLTFFaces[FIdx].VIdx3].Position.X;
        FFaces[FIdx].V3.Y := FSkinnedVertices[FGLTFFaces[FIdx].VIdx3].Position.Y;
        FFaces[FIdx].V3.Z := FSkinnedVertices[FGLTFFaces[FIdx].VIdx3].Position.Z;
      end;
    end;
    CalcBoundingBox;
  end;
end;

procedure TAIModel3D.ResetSkinning;
var
  I, FIdx: Integer;
begin
  FSkinnedVertices := Copy(FBaseVertices);
  if Length(FGLTFFaces) = Length(FFaces) then
  begin
    for FIdx := 0 to High(FGLTFFaces) do
    begin
      FFaces[FIdx].V1.X := FGLTFFaces[FIdx].V1.X;
      FFaces[FIdx].V1.Y := FGLTFFaces[FIdx].V1.Y;
      FFaces[FIdx].V1.Z := FGLTFFaces[FIdx].V1.Z;

      FFaces[FIdx].V2.X := FGLTFFaces[FIdx].V2.X;
      FFaces[FIdx].V2.Y := FGLTFFaces[FIdx].V2.Y;
      FFaces[FIdx].V2.Z := FGLTFFaces[FIdx].V2.Z;

      FFaces[FIdx].V3.X := FGLTFFaces[FIdx].V3.X;
      FFaces[FIdx].V3.Y := FGLTFFaces[FIdx].V3.Y;
      FFaces[FIdx].V3.Z := FGLTFFaces[FIdx].V3.Z;
    end;
    CalcBoundingBox;
  end;
end;


function TAIModel3D.GetAnimationCount: Integer;
begin
  Result := Length(FAnimations);
end;

function TAIModel3D.FindAnimation(const AName: string; out AAnim: TAIAvatarAnimation): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(FAnimations) do
  begin
    if SameText(FAnimations[I].Name, AName) then
    begin
      AAnim := FAnimations[I];
      Result := True;
      Exit;
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

initialization
  {$I aimodel3d_icon.lrs}

end.
