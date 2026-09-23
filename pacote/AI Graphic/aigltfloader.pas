unit aigltfloader;

{ ============================================================================
  Maurinsoft CHATGPT - AI Graphic / 3D Avatar Subsystem
  Carregador e Parser de Modelos glTF 2.0 e GLB (Tarefas 11 a 27)
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, fpjson, jsonparser, base64, aiavatartypes;

type
  { Representacao de Face simples (compativel com TFace3D do aimodel3d) }
  TGLTFFace = record
    V1, V2, V3: TVector3D;
    Normal: TVector3D;
    UV1, UV2, UV3: TVector2D;
    VIdx1, VIdx2, VIdx3: Integer;
    MaterialIndex: Integer;
  end;
  TGLTFFaceArray = array of TGLTFFace;

  { No da cena glTF (Tarefa 11, 24, 25) }
  TGLTFNode = record
    Name: string;
    MeshIndex: Integer;
    SkinIndex: Integer;
    Translation: TVector3D;
    Rotation: TQuaternion;
    Scale: TVector3D;
    HasMatrix: Boolean;
    Matrix: TMatrix4x4;
    ParentIndex: Integer;
    Children: array of Integer;
    LocalTransform: TMatrix4x4;
    GlobalTransform: TMatrix4x4;
  end;
  TGLTFNodeArray = array of TGLTFNode;

  { Classe especializada no carregamento e parsing de glTF 2.0 e GLB }
  TGLTFLoader = class
  private
    FBuffers: array of TBytes;
    FNodes: TGLTFNodeArray;
    FJSONDoc: TJSONObject;
    FLastError: string;
    
    function ParseJSON(const AJSONText: string): Boolean;
    procedure LoadGLBBuffers(AStream: TStream; ABINLength: UInt32);
    procedure LoadGLTFBuffers(const ABasePath: string);
    
    // Acessores e buffers
    function GetComponentByteSize(ACompType: Integer): Integer;
    function GetTypeNumComponents(const ATypeStr: string): Integer;
    function ReadAccessorFloat(AAccessorIdx, AElemIdx, ACompIdx: Integer): Single;
    function ReadAccessorInt(AAccessorIdx, AElemIdx, ACompIdx: Integer): Integer;
    function GetAccessorVec2(AAccessorIdx, AElemIdx: Integer): TVector2D;
    function GetAccessorVec3(AAccessorIdx, AElemIdx: Integer): TVector3D;
    function GetAccessorVec4(AAccessorIdx, AElemIdx: Integer): TVector4D;
    function GetAccessorVec4I(AAccessorIdx, AElemIdx: Integer): TVector4I;
    function GetAccessorMat4(AAccessorIdx, AElemIdx: Integer): TMatrix4x4;
    
    // Extracao de entidades
    procedure ParseNodes;
    procedure ComputeGlobalTransforms;
    procedure ParseMaterials(out AMaterials: TAIAvatarMaterialArray);
    procedure ParseTextures(const ABasePath: string; out ATextures: TAIAvatarTextureArray);
    procedure ParseSkins(out ASkins: TAIAvatarSkinArray);
    procedure ParseMeshes(out AVertices: TAIAvatarVertexArray; out AFaces: TGLTFFaceArray);
  public
    constructor Create;
    destructor Destroy; override;
    
    function LoadFromFile(const AFileName: string;
      out AVertices: TAIAvatarVertexArray;
      out AFaces: TGLTFFaceArray;
      out AMaterials: TAIAvatarMaterialArray;
      out ATextures: TAIAvatarTextureArray;
      out ASkins: TAIAvatarSkinArray;
      out ANodes: TGLTFNodeArray): Boolean;
      
    function LoadFromStream(AStream: TStream; const ABasePath: string;
      out AVertices: TAIAvatarVertexArray;
      out AFaces: TGLTFFaceArray;
      out AMaterials: TAIAvatarMaterialArray;
      out ATextures: TAIAvatarTextureArray;
      out ASkins: TAIAvatarSkinArray;
      out ANodes: TGLTFNodeArray): Boolean;

    property LastError: string read FLastError;
    property Nodes: TGLTFNodeArray read FNodes;
  end;

implementation

{ TGLTFLoader }

constructor TGLTFLoader.Create;
begin
  inherited Create;
  FJSONDoc := nil;
  FLastError := '';
  SetLength(FBuffers, 0);
  SetLength(FNodes, 0);
end;

destructor TGLTFLoader.Destroy;
begin
  if Assigned(FJSONDoc) then
    FJSONDoc.Free;
  inherited Destroy;
end;

function TGLTFLoader.GetComponentByteSize(ACompType: Integer): Integer;
begin
  case ACompType of
    5120, 5121: Result := 1; // BYTE, UNSIGNED_BYTE
    5122, 5123: Result := 2; // SHORT, UNSIGNED_SHORT
    5125, 5126: Result := 4; // UNSIGNED_INT, FLOAT
  else
    Result := 4;
  end;
end;

function TGLTFLoader.GetTypeNumComponents(const ATypeStr: string): Integer;
begin
  if ATypeStr = 'SCALAR' then Result := 1
  else if ATypeStr = 'VEC2' then Result := 2
  else if ATypeStr = 'VEC3' then Result := 3
  else if ATypeStr = 'VEC4' then Result := 4
  else if ATypeStr = 'MAT2' then Result := 4
  else if ATypeStr = 'MAT3' then Result := 9
  else if ATypeStr = 'MAT4' then Result := 16
  else Result := 1;
end;

function TGLTFLoader.ParseJSON(const AJSONText: string): Boolean;
var
  Parser: TJSONParser;
  Data: TJSONData;
begin
  Result := False;
  if Assigned(FJSONDoc) then
  begin
    FJSONDoc.Free;
    FJSONDoc := nil;
  end;
  
  try
    Parser := TJSONParser.Create(AJSONText);
    try
      Data := Parser.Parse;
      if (Data <> nil) and (Data is TJSONObject) then
      begin
        FJSONDoc := TJSONObject(Data);
        Result := True;
      end
      else
      begin
        FLastError := 'glTF JSON root must be an object';
        if Assigned(Data) then Data.Free;
      end;
    finally
      Parser.Free;
    end;
  except
    on E: Exception do
      FLastError := 'Error parsing glTF JSON: ' + E.Message;
  end;
end;

procedure TGLTFLoader.LoadGLBBuffers(AStream: TStream; ABINLength: UInt32);
begin
  if ABINLength > 0 then
  begin
    SetLength(FBuffers, 1);
    SetLength(FBuffers[0], ABINLength);
    AStream.ReadBuffer(FBuffers[0][0], ABINLength);
  end;
end;

procedure TGLTFLoader.LoadGLTFBuffers(const ABasePath: string);
var
  BuffersArr: TJSONArray;
  I: Integer;
  BufObj: TJSONObject;
  URI: string;
  ByteLength: Integer;
  FilePath: string;
  FS: TFileStream;
  PrefixData: string;
  Base64Data: string;
  DecodedStr: string;
begin
  if FJSONDoc = nil then Exit;
  BuffersArr := FJSONDoc.Get('buffers', TJSONArray(nil));
  if BuffersArr = nil then Exit;

  SetLength(FBuffers, BuffersArr.Count);
  for I := 0 to BuffersArr.Count - 1 do
  begin
    BufObj := BuffersArr.Objects[I];
    ByteLength := BufObj.Get('byteLength', 0);
    URI := BufObj.Get('uri', '');

    if URI = '' then
    begin
      // Ja preenchido (ex: chunk BIN de GLB)
      Continue;
    end;

    PrefixData := 'data:application/octet-stream;base64,';
    if Copy(URI, 1, Length(PrefixData)) = PrefixData then
    begin
      Base64Data := Copy(URI, Length(PrefixData) + 1, Length(URI));
      DecodedStr := DecodeStringBase64(Base64Data);
      SetLength(FBuffers[I], Length(DecodedStr));
      if Length(DecodedStr) > 0 then
        Move(DecodedStr[1], FBuffers[I][0], Length(DecodedStr));
    end
    else
    begin
      // Arquivo externo relativo
      FilePath := ABasePath + URI;
      if FileExists(FilePath) then
      begin
        FS := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
        try
          SetLength(FBuffers[I], FS.Size);
          if FS.Size > 0 then
            FS.ReadBuffer(FBuffers[I][0], FS.Size);
        finally
          FS.Free;
        end;
      end;
    end;
  end;
end;

function TGLTFLoader.ReadAccessorFloat(AAccessorIdx, AElemIdx, ACompIdx: Integer): Single;
var
  AccessorsArr, BufferViewsArr: TJSONArray;
  AccObj, BVObj: TJSONObject;
  BVIdx, AccOffset, BVOffset, Stride, CompType, TotalOffset: Integer;
  BufIdx: Integer;
  TypeStr: string;
  NumComp, CompSize: Integer;
  P: PByte;
  U8Val: UInt8;
  U16Val: UInt16;
  I16Val: Int16;
  U32Val: UInt32;
begin
  Result := 0.0;
  if FJSONDoc = nil then Exit;
  AccessorsArr := FJSONDoc.Get('accessors', TJSONArray(nil));
  if (AccessorsArr = nil) or (AAccessorIdx < 0) or (AAccessorIdx >= AccessorsArr.Count) then Exit;
  AccObj := AccessorsArr.Objects[AAccessorIdx];

  BVIdx := AccObj.Get('bufferView', -1);
  AccOffset := AccObj.Get('byteOffset', 0);
  CompType := AccObj.Get('componentType', 5126);
  TypeStr := AccObj.Get('type', 'SCALAR');
  NumComp := GetTypeNumComponents(TypeStr);
  CompSize := GetComponentByteSize(CompType);

  BufferViewsArr := FJSONDoc.Get('bufferViews', TJSONArray(nil));
  if (BufferViewsArr = nil) or (BVIdx < 0) or (BVIdx >= BufferViewsArr.Count) then Exit;
  BVObj := BufferViewsArr.Objects[BVIdx];

  BufIdx := BVObj.Get('buffer', 0);
  BVOffset := BVObj.Get('byteOffset', 0);
  Stride := BVObj.Get('byteStride', 0);
  if Stride = 0 then
    Stride := NumComp * CompSize;

  TotalOffset := BVOffset + AccOffset + (AElemIdx * Stride) + (ACompIdx * CompSize);
  if (BufIdx < 0) or (BufIdx >= Length(FBuffers)) then Exit;
  if TotalOffset + CompSize > Length(FBuffers[BufIdx]) then Exit;

  P := @FBuffers[BufIdx][TotalOffset];
  case CompType of
    5120: Result := PShortInt(P)^;
    5121: begin Move(P^, U8Val, 1); Result := U8Val; end;
    5122: begin Move(P^, I16Val, 2); Result := I16Val; end;
    5123: begin Move(P^, U16Val, 2); Result := U16Val; end;
    5125: begin Move(P^, U32Val, 4); Result := U32Val; end;
    5126: begin Move(P^, Result, 4); end;
  end;
end;

function TGLTFLoader.ReadAccessorInt(AAccessorIdx, AElemIdx, ACompIdx: Integer): Integer;
begin
  Result := Round(ReadAccessorFloat(AAccessorIdx, AElemIdx, ACompIdx));
end;

function TGLTFLoader.GetAccessorVec2(AAccessorIdx, AElemIdx: Integer): TVector2D;
begin
  Result.X := ReadAccessorFloat(AAccessorIdx, AElemIdx, 0);
  Result.Y := ReadAccessorFloat(AAccessorIdx, AElemIdx, 1);
end;

function TGLTFLoader.GetAccessorVec3(AAccessorIdx, AElemIdx: Integer): TVector3D;
begin
  Result.X := ReadAccessorFloat(AAccessorIdx, AElemIdx, 0);
  Result.Y := ReadAccessorFloat(AAccessorIdx, AElemIdx, 1);
  Result.Z := ReadAccessorFloat(AAccessorIdx, AElemIdx, 2);
end;

function TGLTFLoader.GetAccessorVec4(AAccessorIdx, AElemIdx: Integer): TVector4D;
begin
  Result.X := ReadAccessorFloat(AAccessorIdx, AElemIdx, 0);
  Result.Y := ReadAccessorFloat(AAccessorIdx, AElemIdx, 1);
  Result.Z := ReadAccessorFloat(AAccessorIdx, AElemIdx, 2);
  Result.W := ReadAccessorFloat(AAccessorIdx, AElemIdx, 3);
end;

function TGLTFLoader.GetAccessorVec4I(AAccessorIdx, AElemIdx: Integer): TVector4I;
begin
  Result.X := ReadAccessorInt(AAccessorIdx, AElemIdx, 0);
  Result.Y := ReadAccessorInt(AAccessorIdx, AElemIdx, 1);
  Result.Z := ReadAccessorInt(AAccessorIdx, AElemIdx, 2);
  Result.W := ReadAccessorInt(AAccessorIdx, AElemIdx, 3);
end;

function TGLTFLoader.GetAccessorMat4(AAccessorIdx, AElemIdx: Integer): TMatrix4x4;
var
  C, R: Integer;
begin
  for C := 0 to 3 do
    for R := 0 to 3 do
      Result[C, R] := ReadAccessorFloat(AAccessorIdx, AElemIdx, C * 4 + R);
end;

procedure TGLTFLoader.ParseNodes;
var
  NodesArr, ChildArr, MatArr, TArr, RArr, SArr: TJSONArray;
  I, J: Integer;
  NodeObj: TJSONObject;
  Col, Row: Integer;
begin
  if FJSONDoc = nil then Exit;
  NodesArr := FJSONDoc.Get('nodes', TJSONArray(nil));
  if NodesArr = nil then Exit;

  SetLength(FNodes, NodesArr.Count);
  for I := 0 to NodesArr.Count - 1 do
  begin
    NodeObj := NodesArr.Objects[I];
    FNodes[I].Name := NodeObj.Get('name', 'Node_' + IntToStr(I));
    FNodes[I].MeshIndex := NodeObj.Get('mesh', -1);
    FNodes[I].SkinIndex := NodeObj.Get('skin', -1);
    FNodes[I].ParentIndex := -1;
    FNodes[I].HasMatrix := False;
    FNodes[I].Translation := Vector3D(0, 0, 0);
    FNodes[I].Rotation := Quaternion(0, 0, 0, 1);
    FNodes[I].Scale := Vector3D(1, 1, 1);
    FNodes[I].LocalTransform := IdentityMatrix;
    FNodes[I].GlobalTransform := IdentityMatrix;

    // Translation
    TArr := NodeObj.Get('translation', TJSONArray(nil));
    if (TArr <> nil) and (TArr.Count >= 3) then
      FNodes[I].Translation := Vector3D(TArr.Floats[0], TArr.Floats[1], TArr.Floats[2]);

    // Rotation
    RArr := NodeObj.Get('rotation', TJSONArray(nil));
    if (RArr <> nil) and (RArr.Count >= 4) then
      FNodes[I].Rotation := Quaternion(RArr.Floats[0], RArr.Floats[1], RArr.Floats[2], RArr.Floats[3]);

    // Scale
    SArr := NodeObj.Get('scale', TJSONArray(nil));
    if (SArr <> nil) and (SArr.Count >= 3) then
      FNodes[I].Scale := Vector3D(SArr.Floats[0], SArr.Floats[1], SArr.Floats[2]);

    // Matrix (se houver, sobrepoe TRS)
    MatArr := NodeObj.Get('matrix', TJSONArray(nil));
    if (MatArr <> nil) and (MatArr.Count >= 16) then
    begin
      FNodes[I].HasMatrix := True;
      for Col := 0 to 3 do
        for Row := 0 to 3 do
          FNodes[I].Matrix[Col, Row] := MatArr.Floats[Col * 4 + Row];
      FNodes[I].LocalTransform := FNodes[I].Matrix;
    end
    else
    begin
      FNodes[I].LocalTransform := MatrixFromTRS(FNodes[I].Translation, FNodes[I].Rotation, FNodes[I].Scale);
    end;

    // Children
    ChildArr := NodeObj.Get('children', TJSONArray(nil));
    if ChildArr <> nil then
    begin
      SetLength(FNodes[I].Children, ChildArr.Count);
      for J := 0 to ChildArr.Count - 1 do
        FNodes[I].Children[J] := ChildArr.Integers[J];
    end
    else
      SetLength(FNodes[I].Children, 0);
  end;

  // Estabelecer indice de pai (ParentIndex)
  for I := 0 to High(FNodes) do
  begin
    for J := 0 to High(FNodes[I].Children) do
    begin
      if (FNodes[I].Children[J] >= 0) and (FNodes[I].Children[J] <= High(FNodes)) then
        FNodes[FNodes[I].Children[J]].ParentIndex := I;
    end;
  end;
end;

procedure TGLTFLoader.ComputeGlobalTransforms;
var
  Visited: array of Boolean;

  procedure Traverse(ANodeIdx: Integer);
  var
    PIdx, J: Integer;
  begin
    if Visited[ANodeIdx] then Exit;
    PIdx := FNodes[ANodeIdx].ParentIndex;
    if (PIdx >= 0) and (not Visited[PIdx]) then
      Traverse(PIdx);

    if PIdx >= 0 then
      FNodes[ANodeIdx].GlobalTransform := MatrixMultiply(FNodes[PIdx].GlobalTransform, FNodes[ANodeIdx].LocalTransform)
    else
      FNodes[ANodeIdx].GlobalTransform := FNodes[ANodeIdx].LocalTransform;

    Visited[ANodeIdx] := True;
    for J := 0 to High(FNodes[ANodeIdx].Children) do
      Traverse(FNodes[ANodeIdx].Children[J]);
  end;

var
  I: Integer;
begin
  SetLength(Visited, Length(FNodes));
  for I := 0 to High(Visited) do Visited[I] := False;
  for I := 0 to High(FNodes) do
    if not Visited[I] then Traverse(I);
end;

procedure TGLTFLoader.ParseMaterials(out AMaterials: TAIAvatarMaterialArray);
var
  MatArr, ColorArr: TJSONArray;
  I: Integer;
  MatObj, PbrObj, TexObj: TJSONObject;
begin
  SetLength(AMaterials, 0);
  if FJSONDoc = nil then Exit;
  MatArr := FJSONDoc.Get('materials', TJSONArray(nil));
  if MatArr = nil then Exit;

  SetLength(AMaterials, MatArr.Count);
  for I := 0 to MatArr.Count - 1 do
  begin
    MatObj := MatArr.Objects[I];
    AMaterials[I].Name := MatObj.Get('name', 'Material_' + IntToStr(I));
    AMaterials[I].BaseColorFactor := Vector4D(1.0, 1.0, 1.0, 1.0);
    AMaterials[I].MetallicFactor := 1.0;
    AMaterials[I].RoughnessFactor := 1.0;
    AMaterials[I].TextureIndex := -1;

    PbrObj := MatObj.Get('pbrMetallicRoughness', TJSONObject(nil));
    if PbrObj <> nil then
    begin
      ColorArr := PbrObj.Get('baseColorFactor', TJSONArray(nil));
      if (ColorArr <> nil) and (ColorArr.Count >= 4) then
        AMaterials[I].BaseColorFactor := Vector4D(ColorArr.Floats[0], ColorArr.Floats[1], ColorArr.Floats[2], ColorArr.Floats[3]);

      AMaterials[I].MetallicFactor := PbrObj.Get('metallicFactor', 1.0);
      AMaterials[I].RoughnessFactor := PbrObj.Get('roughnessFactor', 1.0);

      TexObj := PbrObj.Get('baseColorTexture', TJSONObject(nil));
      if TexObj <> nil then
        AMaterials[I].TextureIndex := TexObj.Get('index', -1);
    end;
  end;
end;

procedure TGLTFLoader.ParseTextures(const ABasePath: string; out ATextures: TAIAvatarTextureArray);
var
  TexArr, ImgArr, BVArr: TJSONArray;
  I, ImgIdx, BVIdx, Offset, Len, BufIdx: Integer;
  TexObj, ImgObj, BVObj: TJSONObject;
  URI, FilePath: string;
  FS: TFileStream;
begin
  SetLength(ATextures, 0);
  if FJSONDoc = nil then Exit;
  TexArr := FJSONDoc.Get('textures', TJSONArray(nil));
  ImgArr := FJSONDoc.Get('images', TJSONArray(nil));
  if (TexArr = nil) or (ImgArr = nil) then Exit;

  SetLength(ATextures, TexArr.Count);
  for I := 0 to TexArr.Count - 1 do
  begin
    TexObj := TexArr.Objects[I];
    ImgIdx := TexObj.Get('source', -1);
    ATextures[I].Name := TexObj.Get('name', 'Texture_' + IntToStr(I));
    ATextures[I].MimeType := 'image/png';
    SetLength(ATextures[I].Data, 0);

    if (ImgIdx >= 0) and (ImgIdx < ImgArr.Count) then
    begin
      ImgObj := ImgArr.Objects[ImgIdx];
      ATextures[I].MimeType := ImgObj.Get('mimeType', 'image/png');

      BVIdx := ImgObj.Get('bufferView', -1);
      if BVIdx >= 0 then
      begin
        // Imagem embutida em bufferView
        BVArr := FJSONDoc.Get('bufferViews', TJSONArray(nil));
        if (BVArr <> nil) and (BVIdx < BVArr.Count) then
        begin
          BVObj := BVArr.Objects[BVIdx];
          BufIdx := BVObj.Get('buffer', 0);
          Offset := BVObj.Get('byteOffset', 0);
          Len := BVObj.Get('byteLength', 0);
          if (BufIdx >= 0) and (BufIdx < Length(FBuffers)) and (Offset + Len <= Length(FBuffers[BufIdx])) then
          begin
            SetLength(ATextures[I].Data, Len);
            Move(FBuffers[BufIdx][Offset], ATextures[I].Data[0], Len);
          end;
        end;
      end
      else
      begin
        // Imagem externa
        URI := ImgObj.Get('uri', '');
        if URI <> '' then
        begin
          FilePath := ABasePath + URI;
          if FileExists(FilePath) then
          begin
            FS := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
            try
              SetLength(ATextures[I].Data, FS.Size);
              if FS.Size > 0 then
                FS.ReadBuffer(ATextures[I].Data[0], FS.Size);
            finally
              FS.Free;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TGLTFLoader.ParseSkins(out ASkins: TAIAvatarSkinArray);
var
  SkinsArr, JointsArr, AccessorsArr: TJSONArray;
  I, J, InvMatIdx, JointNodeIdx, JointCount: Integer;
  SkinObj: TJSONObject;
begin
  SetLength(ASkins, 0);
  if FJSONDoc = nil then Exit;
  SkinsArr := FJSONDoc.Get('skins', TJSONArray(nil));
  if SkinsArr = nil then Exit;

  SetLength(ASkins, SkinsArr.Count);
  for I := 0 to SkinsArr.Count - 1 do
  begin
    SkinObj := SkinsArr.Objects[I];
    ASkins[I].Name := SkinObj.Get('name', 'Skin_' + IntToStr(I));
    ASkins[I].SkeletonRootNode := SkinObj.Get('skeleton', -1);
    InvMatIdx := SkinObj.Get('inverseBindMatrices', -1);

    JointsArr := SkinObj.Get('joints', TJSONArray(nil));
    if JointsArr <> nil then
    begin
      JointCount := JointsArr.Count;
      SetLength(ASkins[I].Joints, JointCount);
      for J := 0 to JointCount - 1 do
      begin
        JointNodeIdx := JointsArr.Integers[J];
        ASkins[I].Joints[J].NodeIndex := JointNodeIdx;
        ASkins[I].Joints[J].ParentJointIndex := -1;
        if (JointNodeIdx >= 0) and (JointNodeIdx <= High(FNodes)) then
        begin
          ASkins[I].Joints[J].Name := FNodes[JointNodeIdx].Name;
          ASkins[I].Joints[J].HumanoidBone := StringToHumanoidBone(FNodes[JointNodeIdx].Name);
          ASkins[I].Joints[J].LocalMatrix := FNodes[JointNodeIdx].LocalTransform;
          ASkins[I].Joints[J].GlobalMatrix := FNodes[JointNodeIdx].GlobalTransform;
        end
        else
        begin
          ASkins[I].Joints[J].Name := 'Joint_' + IntToStr(J);
          ASkins[I].Joints[J].HumanoidBone := hbNone;
          ASkins[I].Joints[J].LocalMatrix := IdentityMatrix;
          ASkins[I].Joints[J].GlobalMatrix := IdentityMatrix;
        end;

        if InvMatIdx >= 0 then
          ASkins[I].Joints[J].InverseBindMatrix := GetAccessorMat4(InvMatIdx, J)
        else
          ASkins[I].Joints[J].InverseBindMatrix := IdentityMatrix;

        ASkins[I].Joints[J].FinalBoneMatrix := MatrixMultiply(ASkins[I].Joints[J].GlobalMatrix, ASkins[I].Joints[J].InverseBindMatrix);
      end;
    end
    else
      SetLength(ASkins[I].Joints, 0);
  end;
end;

procedure TGLTFLoader.ParseMeshes(out AVertices: TAIAvatarVertexArray; out AFaces: TGLTFFaceArray);
var
  MeshesArr, PrimsArr, AccessorsArr: TJSONArray;
  MeshIdx, PrimIdx, I, J, K: Integer;
  MeshObj, PrimObj, AttrObj: TJSONObject;
  PosAccIdx, NormAccIdx, UVAccIdx, JointAccIdx, WeightAccIdx, IndAccIdx: Integer;
  VCount, IndCount, BaseVIdx, FaceBaseIdx: Integer;
  WeightSum: Single;
  Face: TGLTFFace;
  V1, V2, V3: TVector3D;
  Edge1, Edge2, Normal: TVector3D;
  LenNorm: Single;
  I1, I2, I3: Integer;
begin
  SetLength(AVertices, 0);
  SetLength(AFaces, 0);
  if FJSONDoc = nil then Exit;
  MeshesArr := FJSONDoc.Get('meshes', TJSONArray(nil));
  AccessorsArr := FJSONDoc.Get('accessors', TJSONArray(nil));
  if (MeshesArr = nil) or (AccessorsArr = nil) then Exit;

  BaseVIdx := 0;
  FaceBaseIdx := 0;

  for MeshIdx := 0 to MeshesArr.Count - 1 do
  begin
    MeshObj := MeshesArr.Objects[MeshIdx];
    PrimsArr := MeshObj.Get('primitives', TJSONArray(nil));
    if PrimsArr = nil then Continue;

    for PrimIdx := 0 to PrimsArr.Count - 1 do
    begin
      PrimObj := PrimsArr.Objects[PrimIdx];
      AttrObj := PrimObj.Get('attributes', TJSONObject(nil));
      if AttrObj = nil then Continue;

      PosAccIdx := AttrObj.Get('POSITION', -1);
      if (PosAccIdx < 0) or (PosAccIdx >= AccessorsArr.Count) then Continue;

      NormAccIdx := AttrObj.Get('NORMAL', -1);
      UVAccIdx := AttrObj.Get('TEXCOORD_0', -1);
      JointAccIdx := AttrObj.Get('JOINTS_0', -1);
      WeightAccIdx := AttrObj.Get('WEIGHTS_0', -1);
      IndAccIdx := PrimObj.Get('indices', -1);

      VCount := AccessorsArr.Objects[PosAccIdx].Get('count', 0);
      if VCount <= 0 then Continue;

      SetLength(AVertices, BaseVIdx + VCount);

      // Ler Vertices
      for I := 0 to VCount - 1 do
      begin
        AVertices[BaseVIdx + I].Position := GetAccessorVec3(PosAccIdx, I);

        if NormAccIdx >= 0 then
          AVertices[BaseVIdx + I].Normal := GetAccessorVec3(NormAccIdx, I)
        else
          AVertices[BaseVIdx + I].Normal := Vector3D(0, 1, 0);

        if UVAccIdx >= 0 then
          AVertices[BaseVIdx + I].UV := GetAccessorVec2(UVAccIdx, I)
        else
          AVertices[BaseVIdx + I].UV := Vector2D(0, 0);

        if JointAccIdx >= 0 then
          AVertices[BaseVIdx + I].Joints := GetAccessorVec4I(JointAccIdx, I)
        else
          AVertices[BaseVIdx + I].Joints := Vector4I(0, 0, 0, 0);

        if WeightAccIdx >= 0 then
        begin
          AVertices[BaseVIdx + I].Weights := GetAccessorVec4(WeightAccIdx, I);
          WeightSum := AVertices[BaseVIdx + I].Weights.X + AVertices[BaseVIdx + I].Weights.Y +
                       AVertices[BaseVIdx + I].Weights.Z + AVertices[BaseVIdx + I].Weights.W;
          if WeightSum > 0.0001 then
          begin
            AVertices[BaseVIdx + I].Weights.X := AVertices[BaseVIdx + I].Weights.X / WeightSum;
            AVertices[BaseVIdx + I].Weights.Y := AVertices[BaseVIdx + I].Weights.Y / WeightSum;
            AVertices[BaseVIdx + I].Weights.Z := AVertices[BaseVIdx + I].Weights.Z / WeightSum;
            AVertices[BaseVIdx + I].Weights.W := AVertices[BaseVIdx + I].Weights.W / WeightSum;
          end;
        end
        else
          AVertices[BaseVIdx + I].Weights := Vector4D(0, 0, 0, 0);
      end;

      // Montar Faces
      if IndAccIdx >= 0 then
      begin
        IndCount := AccessorsArr.Objects[IndAccIdx].Get('count', 0);
        SetLength(AFaces, FaceBaseIdx + (IndCount div 3));
        for I := 0 to (IndCount div 3) - 1 do
        begin
          I1 := BaseVIdx + ReadAccessorInt(IndAccIdx, I * 3 + 0, 0);
          I2 := BaseVIdx + ReadAccessorInt(IndAccIdx, I * 3 + 1, 0);
          I3 := BaseVIdx + ReadAccessorInt(IndAccIdx, I * 3 + 2, 0);

          if (I1 >= 0) and (I1 < Length(AVertices)) and
             (I2 >= 0) and (I2 < Length(AVertices)) and
             (I3 >= 0) and (I3 < Length(AVertices)) then
          begin
            Face.V1 := AVertices[I1].Position;
            Face.V2 := AVertices[I2].Position;
            Face.V3 := AVertices[I3].Position;
            Face.UV1 := AVertices[I1].UV;
            Face.UV2 := AVertices[I2].UV;
            Face.UV3 := AVertices[I3].UV;
            Face.VIdx1 := I1;
            Face.VIdx2 := I2;
            Face.VIdx3 := I3;
            Face.MaterialIndex := PrimObj.Get('material', 0);

            // Calcular normal se ausente
            if NormAccIdx < 0 then
            begin
              Edge1.X := Face.V2.X - Face.V1.X;
              Edge1.Y := Face.V2.Y - Face.V1.Y;
              Edge1.Z := Face.V2.Z - Face.V1.Z;
              Edge2.X := Face.V3.X - Face.V1.X;
              Edge2.Y := Face.V3.Y - Face.V1.Y;
              Edge2.Z := Face.V3.Z - Face.V1.Z;
              Normal.X := Edge1.Y * Edge2.Z - Edge1.Z * Edge2.Y;
              Normal.Y := Edge1.Z * Edge2.X - Edge1.X * Edge2.Z;
              Normal.Z := Edge1.X * Edge2.Y - Edge1.Y * Edge2.X;
              LenNorm := Sqrt(Normal.X * Normal.X + Normal.Y * Normal.Y + Normal.Z * Normal.Z);
              if LenNorm > 0.00001 then
              begin
                Normal.X := Normal.X / LenNorm;
                Normal.Y := Normal.Y / LenNorm;
                Normal.Z := Normal.Z / LenNorm;
              end;
              Face.Normal := Normal;
            end
            else
            begin
              Face.Normal.X := (AVertices[I1].Normal.X + AVertices[I2].Normal.X + AVertices[I3].Normal.X) / 3.0;
              Face.Normal.Y := (AVertices[I1].Normal.Y + AVertices[I2].Normal.Y + AVertices[I3].Normal.Y) / 3.0;
              Face.Normal.Z := (AVertices[I1].Normal.Z + AVertices[I2].Normal.Z + AVertices[I3].Normal.Z) / 3.0;
            end;

            AFaces[FaceBaseIdx + I] := Face;
          end;
        end;
        FaceBaseIdx := FaceBaseIdx + (IndCount div 3);
      end
      else
      begin
        // Sem indices: agrupar 3 a 3
        SetLength(AFaces, FaceBaseIdx + (VCount div 3));
        for I := 0 to (VCount div 3) - 1 do
        begin
          I1 := BaseVIdx + I * 3 + 0;
          I2 := BaseVIdx + I * 3 + 1;
          I3 := BaseVIdx + I * 3 + 2;

          Face.V1 := AVertices[I1].Position;
          Face.V2 := AVertices[I2].Position;
          Face.V3 := AVertices[I3].Position;
          Face.UV1 := AVertices[I1].UV;
          Face.UV2 := AVertices[I2].UV;
          Face.UV3 := AVertices[I3].UV;
          Face.VIdx1 := I1;
          Face.VIdx2 := I2;
          Face.VIdx3 := I3;
          Face.MaterialIndex := PrimObj.Get('material', 0);
          Face.Normal := AVertices[I1].Normal;
          AFaces[FaceBaseIdx + I] := Face;
        end;
        FaceBaseIdx := FaceBaseIdx + (VCount div 3);
      end;

      BaseVIdx := BaseVIdx + VCount;
    end;
  end;
end;

function TGLTFLoader.LoadFromFile(const AFileName: string;
  out AVertices: TAIAvatarVertexArray;
  out AFaces: TGLTFFaceArray;
  out AMaterials: TAIAvatarMaterialArray;
  out ATextures: TAIAvatarTextureArray;
  out ASkins: TAIAvatarSkinArray;
  out ANodes: TGLTFNodeArray): Boolean;
var
  FS: TFileStream;
begin
  Result := False;
  if not FileExists(AFileName) then
  begin
    FLastError := 'File not found: ' + AFileName;
    Exit;
  end;

  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := LoadFromStream(FS, ExtractFilePath(AFileName), AVertices, AFaces, AMaterials, ATextures, ASkins, ANodes);
  finally
    FS.Free;
  end;
end;

function TGLTFLoader.LoadFromStream(AStream: TStream; const ABasePath: string;
  out AVertices: TAIAvatarVertexArray;
  out AFaces: TGLTFFaceArray;
  out AMaterials: TAIAvatarMaterialArray;
  out ATextures: TAIAvatarTextureArray;
  out ASkins: TAIAvatarSkinArray;
  out ANodes: TGLTFNodeArray): Boolean;
var
  Magic: array[0..3] of AnsiChar;
  Version, FileLength: UInt32;
  ChunkLength, ChunkType: UInt32;
  JSONBytes: TBytes;
  JSONStr: string;
  IsGLB: Boolean;
  BinLength: UInt32;
  BinType: UInt32;
  SL: TStringList;
begin
  Result := False;
  FLastError := '';
  IsGLB := False;
  BinLength := 0;

  SetLength(AVertices, 0);
  SetLength(AFaces, 0);
  SetLength(AMaterials, 0);
  SetLength(ATextures, 0);
  SetLength(ASkins, 0);
  SetLength(ANodes, 0);

  if AStream.Size < 12 then
  begin
    FLastError := 'Stream too small to be a valid glTF or GLB';
    Exit;
  end;

  // Checar se eh GLB pelo Header
  AStream.Position := 0;
  AStream.ReadBuffer(Magic[0], 4);
  if Magic = 'glTF' then
  begin
    IsGLB := True;
    AStream.ReadBuffer(Version, 4);
    AStream.ReadBuffer(FileLength, 4);

    // Chunk 0: JSON
    AStream.ReadBuffer(ChunkLength, 4);
    AStream.ReadBuffer(ChunkType, 4);

    SetLength(JSONBytes, ChunkLength);
    if ChunkLength > 0 then
      AStream.ReadBuffer(JSONBytes[0], ChunkLength);
    SetString(JSONStr, PAnsiChar(@JSONBytes[0]), ChunkLength);

    // Chunk 1: BIN (opcional)
    if AStream.Position + 8 <= AStream.Size then
    begin
      AStream.ReadBuffer(BinLength, 4);
      AStream.ReadBuffer(BinType, 4);
      LoadGLBBuffers(AStream, BinLength);
    end;
  end
  else
  begin
    // Eh glTF em texto puro
    AStream.Position := 0;
    SL := TStringList.Create;
    try
      SL.LoadFromStream(AStream);
      JSONStr := SL.Text;
    finally
      SL.Free;
    end;
  end;

  if not ParseJSON(JSONStr) then Exit;

  if not IsGLB then
    LoadGLTFBuffers(ABasePath);

  ParseNodes;
  ComputeGlobalTransforms;
  ParseMaterials(AMaterials);
  ParseTextures(ABasePath, ATextures);
  ParseSkins(ASkins);
  ParseMeshes(AVertices, AFaces);

  ANodes := FNodes;
  Result := True;
end;

end.
