unit aiskeletonrig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, StrUtils, aibase, DOM, XMLRead, fpjson, jsonparser, Process, LResources;

type
  TMatrix3x3 = array[0..2, 0..2] of Double;

  TBoneJoint = record
    Name: string;
    ParentIndex: Integer;
    OffsetX, OffsetY, OffsetZ: Double; // Relative offset from parent joint
    AngleX, AngleY, AngleZ: Double;     // Rotation angles in degrees
    StartX, StartY, StartZ: Double;     // Computed global start position
    EndX, EndY, EndZ: Double;           // Computed global end position
    GlobalRot: TMatrix3x3;              // Accumulated global rotation matrix
  end;

  { TAISkeletonRig }

  TAISkeletonRig = class(TAIBaseComponent)
  private
    FBonesList: TStrings;
    FJoints: array of TBoneJoint;
    procedure SetBonesList(AValue: TStrings);
    procedure InitializeRig;
    
    procedure LoadBVH(const AFileName: string);
    procedure LoadDAE(const AFileName: string);
    procedure LoadGLTF(const AFileName: string);
    procedure LoadGLB(const AFileName: string);
    procedure LoadBlend(const AFileName: string);
    procedure ParseGLTFJSON(const AJSONText: string);
    procedure AutoScaleRig;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RotateBone(const ABoneName: string; const Angle: Double);
    procedure SetBoneRotation(const ABoneName: string; const AX, AY, AZ: Double);
    procedure UpdateFK;
    procedure LoadRigFromFile(const AFileName: string);
    
    function GetJointCount: Integer;
    function GetJoint(Index: Integer): TBoneJoint;
  published
    property BonesList: TStrings read FBonesList write SetBonesList;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAISkeletonRig]);
end;

{ TAISkeletonRig }

constructor TAISkeletonRig.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAISkeletonRig manages rigging joints and bone hierarchies. Properties: BonesList. Methods: RotateBone, SetBoneRotation, UpdateFK, LoadRigFromFile.';
  FBonesList := TStringList.Create;
  InitializeRig;
  ClearError;
end;

destructor TAISkeletonRig.Destroy;
begin
  FBonesList.Free;
  inherited Destroy;
end;

procedure TAISkeletonRig.InitializeRig;
begin
  SetLength(FJoints, 12);
  
  // 0. Pelvis/Root
  FJoints[0].Name := 'pelvis';
  FJoints[0].ParentIndex := -1;
  FJoints[0].OffsetX := 0; FJoints[0].OffsetY := 0.2; FJoints[0].OffsetZ := 0;
  FJoints[0].AngleX := 0; FJoints[0].AngleY := 0; FJoints[0].AngleZ := 0;
  
  // 1. Spine (child of Pelvis)
  FJoints[1].Name := 'spine';
  FJoints[1].ParentIndex := 0;
  FJoints[1].OffsetX := 0; FJoints[1].OffsetY := 0.4; FJoints[1].OffsetZ := 0;
  FJoints[1].AngleX := 0; FJoints[1].AngleY := 0; FJoints[1].AngleZ := 0;
  
  // 2. Neck (child of Spine)
  FJoints[2].Name := 'neck';
  FJoints[2].ParentIndex := 1;
  FJoints[2].OffsetX := 0; FJoints[2].OffsetY := 0.1; FJoints[2].OffsetZ := 0;
  FJoints[2].AngleX := 0; FJoints[2].AngleY := 0; FJoints[2].AngleZ := 0;
  
  // 3. Head (child of Neck)
  FJoints[3].Name := 'head';
  FJoints[3].ParentIndex := 2;
  FJoints[3].OffsetX := 0; FJoints[3].OffsetY := 0.2; FJoints[3].OffsetZ := 0;
  FJoints[3].AngleX := 0; FJoints[3].AngleY := 0; FJoints[3].AngleZ := 0;
  
  // Left Arm
  // 4. Left Shoulder (child of Spine)
  FJoints[4].Name := 'left_shoulder';
  FJoints[4].ParentIndex := 1;
  FJoints[4].OffsetX := -0.3; FJoints[4].OffsetY := 0; FJoints[4].OffsetZ := 0;
  FJoints[4].AngleX := 0; FJoints[4].AngleY := 0; FJoints[4].AngleZ := 0;
  
  // 5. Left Elbow (child of Left Shoulder)
  FJoints[5].Name := 'left_elbow';
  FJoints[5].ParentIndex := 4;
  FJoints[5].OffsetX := -0.4; FJoints[5].OffsetY := 0; FJoints[5].OffsetZ := 0;
  FJoints[5].AngleX := 0; FJoints[5].AngleY := 0; FJoints[5].AngleZ := 0;
  
  // Right Arm
  // 6. Right Shoulder (child of Spine)
  FJoints[6].Name := 'right_shoulder';
  FJoints[6].ParentIndex := 1;
  FJoints[6].OffsetX := 0.3; FJoints[6].OffsetY := 0; FJoints[6].OffsetZ := 0;
  FJoints[6].AngleX := 0; FJoints[6].AngleY := 0; FJoints[6].AngleZ := 0;
  
  // 7. Right Elbow (child of Right Shoulder)
  FJoints[7].Name := 'right_elbow';
  FJoints[7].ParentIndex := 6;
  FJoints[7].OffsetX := 0.4; FJoints[7].OffsetY := 0; FJoints[7].OffsetZ := 0;
  FJoints[7].AngleX := 0; FJoints[7].AngleY := 0; FJoints[7].AngleZ := 0;
  
  // Left Leg
  // 8. Left Hip (child of Pelvis)
  FJoints[8].Name := 'left_hip';
  FJoints[8].ParentIndex := 0;
  FJoints[8].OffsetX := -0.15; FJoints[8].OffsetY := -0.5; FJoints[8].OffsetZ := 0;
  FJoints[8].AngleX := 0; FJoints[8].AngleY := 0; FJoints[8].AngleZ := 0;
  
  // 9. Left Knee (child of Left Hip)
  FJoints[9].Name := 'left_knee';
  FJoints[9].ParentIndex := 8;
  FJoints[9].OffsetX := 0; FJoints[9].OffsetY := -0.5; FJoints[9].OffsetZ := 0;
  FJoints[9].AngleX := 0; FJoints[9].AngleY := 0; FJoints[9].AngleZ := 0;
  
  // Right Leg
  // 10. Right Hip (child of Pelvis)
  FJoints[10].Name := 'right_hip';
  FJoints[10].ParentIndex := 0;
  FJoints[10].OffsetX := 0.15; FJoints[10].OffsetY := -0.5; FJoints[10].OffsetZ := 0;
  FJoints[10].AngleX := 0; FJoints[10].AngleY := 0; FJoints[10].AngleZ := 0;
  
  // 11. Right Knee (child of Right Hip)
  FJoints[11].Name := 'right_knee';
  FJoints[11].ParentIndex := 10;
  FJoints[11].OffsetX := 0; FJoints[11].OffsetY := -0.5; FJoints[11].OffsetZ := 0;
  FJoints[11].AngleX := 0; FJoints[11].AngleY := 0; FJoints[11].AngleZ := 0;
  
  FBonesList.Clear;
  FBonesList.Add('pelvis');
  FBonesList.Add('spine');
  FBonesList.Add('neck');
  FBonesList.Add('head');
  FBonesList.Add('left_shoulder');
  FBonesList.Add('left_elbow');
  FBonesList.Add('right_shoulder');
  FBonesList.Add('right_elbow');
  FBonesList.Add('left_hip');
  FBonesList.Add('left_knee');
  FBonesList.Add('right_hip');
  FBonesList.Add('right_knee');
  
  UpdateFK;
end;

procedure TAISkeletonRig.SetBonesList(AValue: TStrings);
begin
  FBonesList.Assign(AValue);
end;

procedure TAISkeletonRig.RotateBone(const ABoneName: string; const Angle: Double);
begin
  SetBoneRotation(ABoneName, 0, 0, Angle);
end;

procedure TAISkeletonRig.SetBoneRotation(const ABoneName: string; const AX, AY, AZ: Double);
var
  I: Integer;
begin
  for I := 0 to Length(FJoints) - 1 do
  begin
    if SameText(FJoints[I].Name, ABoneName) then
    begin
      FJoints[I].AngleX := AX;
      FJoints[I].AngleY := AY;
      FJoints[I].AngleZ := AZ;
      Log(llDebug, Format('Set joint %s rotation to (%.1f, %.1f, %.1f)', [ABoneName, AX, AY, AZ]));
      UpdateFK;
      Break;
    end;
  end;
end;

function IdentityMatrix: TMatrix3x3;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result[0, 0] := 1.0;
  Result[1, 1] := 1.0;
  Result[2, 2] := 1.0;
end;

function MultiplyMatrix(const A, B: TMatrix3x3): TMatrix3x3;
var
  R, C, K: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for R := 0 to 2 do
    for C := 0 to 2 do
      for K := 0 to 2 do
        Result[R, C] := Result[R, C] + A[R, K] * B[K, C];
end;

function RotationMatrix(AX, AY, AZ: Double): TMatrix3x3;
var
  rx, ry, rz: Double;
  cx, sx, cy, sy, cz, sz: Double;
  Mx, My, Mz, Mtmp: TMatrix3x3;
begin
  rx := AX * pi / 180.0;
  ry := AY * pi / 180.0;
  rz := AZ * pi / 180.0;
  
  cx := Cos(rx); sx := Sin(rx);
  cy := Cos(ry); sy := Sin(ry);
  cz := Cos(rz); sz := Sin(rz);
  
  Mx := IdentityMatrix;
  Mx[1, 1] := cx; Mx[1, 2] := -sx;
  Mx[2, 1] := sx; Mx[2, 2] := cx;
  
  My := IdentityMatrix;
  My[0, 0] := cy; My[0, 2] := sy;
  My[2, 0] := -sy; My[2, 2] := cy;
  
  Mz := IdentityMatrix;
  Mz[0, 0] := cz; Mz[0, 1] := -sz;
  Mz[1, 0] := sz; Mz[1, 1] := cz;
  
  Mtmp := MultiplyMatrix(Mz, My);
  Result := MultiplyMatrix(Mtmp, Mx);
end;

procedure TAISkeletonRig.UpdateFK;
var
  I: Integer;
  ParentIdx: Integer;
  Rot, LocalRot: TMatrix3x3;
  OffsetGlobalX, OffsetGlobalY, OffsetGlobalZ: Double;
begin
  for I := 0 to Length(FJoints) - 1 do
  begin
    ParentIdx := FJoints[I].ParentIndex;
    LocalRot := RotationMatrix(FJoints[I].AngleX, FJoints[I].AngleY, FJoints[I].AngleZ);
    
    if ParentIdx = -1 then
    begin
      FJoints[I].GlobalRot := LocalRot;
      FJoints[I].StartX := 0;
      FJoints[I].StartY := 0.2; // slight base elevation
      FJoints[I].StartZ := 0;
      
      OffsetGlobalX := LocalRot[0, 0] * FJoints[I].OffsetX + LocalRot[0, 1] * FJoints[I].OffsetY + LocalRot[0, 2] * FJoints[I].OffsetZ;
      OffsetGlobalY := LocalRot[1, 0] * FJoints[I].OffsetX + LocalRot[1, 1] * FJoints[I].OffsetY + LocalRot[1, 2] * FJoints[I].OffsetZ;
      OffsetGlobalZ := LocalRot[2, 0] * FJoints[I].OffsetX + LocalRot[2, 1] * FJoints[I].OffsetY + LocalRot[2, 2] * FJoints[I].OffsetZ;
      
      FJoints[I].EndX := FJoints[I].StartX + OffsetGlobalX;
      FJoints[I].EndY := FJoints[I].StartY + OffsetGlobalY;
      FJoints[I].EndZ := FJoints[I].StartZ + OffsetGlobalZ;
    end
    else
    begin
      Rot := FJoints[ParentIdx].GlobalRot;
      FJoints[I].GlobalRot := MultiplyMatrix(Rot, LocalRot);
      
      FJoints[I].StartX := FJoints[ParentIdx].EndX;
      FJoints[I].StartY := FJoints[ParentIdx].EndY;
      FJoints[I].StartZ := FJoints[ParentIdx].EndZ;
      
      // Rotated by parent accumulated global rotation
      OffsetGlobalX := Rot[0, 0] * FJoints[I].OffsetX + Rot[0, 1] * FJoints[I].OffsetY + Rot[0, 2] * FJoints[I].OffsetZ;
      OffsetGlobalY := Rot[1, 0] * FJoints[I].OffsetX + Rot[1, 1] * FJoints[I].OffsetY + Rot[1, 2] * FJoints[I].OffsetZ;
      OffsetGlobalZ := Rot[2, 0] * FJoints[I].OffsetX + Rot[2, 1] * FJoints[I].OffsetY + Rot[2, 2] * FJoints[I].OffsetZ;
      
      FJoints[I].EndX := FJoints[I].StartX + OffsetGlobalX;
      FJoints[I].EndY := FJoints[I].StartY + OffsetGlobalY;
      FJoints[I].EndZ := FJoints[I].StartZ + OffsetGlobalZ;
    end;
  end;
end;

procedure TAISkeletonRig.AutoScaleRig;
var
  MaxVal: Double;
  I: Integer;
  ScaleFactor: Double;
begin
  MaxVal := 0.0;
  for I := 0 to Length(FJoints) - 1 do
  begin
    MaxVal := Max(MaxVal, Abs(FJoints[I].OffsetX));
    MaxVal := Max(MaxVal, Abs(FJoints[I].OffsetY));
    MaxVal := Max(MaxVal, Abs(FJoints[I].OffsetZ));
  end;
  
  if MaxVal > 2.0 then
  begin
    ScaleFactor := 1.5 / MaxVal;
    Log(llInfo, Format('Auto-scaling rig offsets by factor %.6f (max offset was %.2f)', [ScaleFactor, MaxVal]));
    for I := 0 to Length(FJoints) - 1 do
    begin
      FJoints[I].OffsetX := FJoints[I].OffsetX * ScaleFactor;
      FJoints[I].OffsetY := FJoints[I].OffsetY * ScaleFactor;
      FJoints[I].OffsetZ := FJoints[I].OffsetZ * ScaleFactor;
    end;
  end;
end;

procedure TAISkeletonRig.LoadBVH(const AFileName: string);
var
  Lines: TStringList;
  Stack: array of Integer;
  StackCount: Integer;
  I: Integer;
  Line: string;
  Words: TStringList;
  W: string;
  JIdx: Integer;
  ParentIdx: Integer;
  FS: TFormatSettings;
  
  procedure PushStack(Val: Integer);
  begin
    if StackCount >= Length(Stack) then
      SetLength(Stack, StackCount + 10);
    Stack[StackCount] := Val;
    Inc(StackCount);
  end;
  
  function PopStack: Integer;
  begin
    if StackCount > 0 then
    begin
      Dec(StackCount);
      Result := Stack[StackCount];
    end
    else
      Result := -1;
  end;

  function GetStackTop: Integer;
  begin
    if StackCount > 0 then
      Result := Stack[StackCount - 1]
    else
      Result := -1;
  end;

  function ParseFloat(const S: string): Double;
  begin
    Result := StrToFloatDef(Trim(S), 0.0, FS);
  end;

begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  
  Log(llInfo, 'Parsing BVH file: ' + AFileName);
  Lines := TStringList.Create;
  Words := TStringList.Create;
  SetLength(Stack, 10);
  StackCount := 0;
  JIdx := 0;
  
  try
    Lines.LoadFromFile(AFileName);
    SetLength(FJoints, Lines.Count);
    FBonesList.Clear;
    
    I := 0;
    while I < Lines.Count do
    begin
      Line := Trim(Lines[I]);
      Inc(I);
      if (Line = '') or (StartsText('#', Line)) then Continue;
      
      Words.Clear;
      ExtractStrings([' ', #9], [], PChar(Line), Words);
      if Words.Count = 0 then Continue;
      
      W := UpperCase(Words[0]);
      if (W = 'ROOT') or (W = 'JOINT') then
      begin
        if Words.Count >= 2 then
        begin
          FJoints[JIdx].Name := Words[1];
          FJoints[JIdx].ParentIndex := GetStackTop;
          FJoints[JIdx].OffsetX := 0;
          FJoints[JIdx].OffsetY := 0;
          FJoints[JIdx].OffsetZ := 0;
          FJoints[JIdx].AngleX := 0;
          FJoints[JIdx].AngleY := 0;
          FJoints[JIdx].AngleZ := 0;
          
          FBonesList.Add(FJoints[JIdx].Name);
          PushStack(JIdx);
          Inc(JIdx);
        end;
      end
      else if W = 'OFFSET' then
      begin
        if (Words.Count >= 4) and (StackCount > 0) then
        begin
          ParentIdx := GetStackTop;
          FJoints[ParentIdx].OffsetX := ParseFloat(Words[1]);
          FJoints[ParentIdx].OffsetY := ParseFloat(Words[2]);
          FJoints[ParentIdx].OffsetZ := ParseFloat(Words[3]);
        end;
      end
      else if W = '}' then
      begin
        PopStack;
      end;
    end;
    
    SetLength(FJoints, JIdx);
    AutoScaleRig;
    UpdateFK;
    
    Log(llInfo, Format('BVH rig loaded successfully. %d joints imported.', [JIdx]));
  finally
    Words.Free;
    Lines.Free;
  end;
end;

procedure TAISkeletonRig.LoadDAE(const AFileName: string);
var
  XMLDoc: TXMLDocument;
  JIdx: Integer;
  FS: TFormatSettings;

  function ParseFloat(const S: string): Double;
  begin
    Result := StrToFloatDef(Trim(S), 0.0, FS);
  end;

  procedure ParseOffsets(ANode: TDOMNode; var OX, OY, OZ: Double);
  var
    Child: TDOMNode;
    Text: string;
    Vals: TStringList;
    M: array[0..15] of Double;
    K: Integer;
  begin
    OX := 0.0; OY := 0.0; OZ := 0.0;
    Child := ANode.FirstChild;
    while Child <> nil do
    begin
      if Child.NodeType = ELEMENT_NODE then
      begin
        if SameText(Child.NodeName, 'translate') then
        begin
          Text := Trim(Child.TextContent);
          Vals := TStringList.Create;
          try
            ExtractStrings([' ', #9, #10, #13], [], PChar(Text), Vals);
            if Vals.Count >= 3 then
            begin
              OX := ParseFloat(Vals[0]);
              OY := ParseFloat(Vals[1]);
              OZ := ParseFloat(Vals[2]);
            end;
          finally
            Vals.Free;
          end;
          Break;
        end
        else if SameText(Child.NodeName, 'matrix') then
        begin
          Text := Trim(Child.TextContent);
          Vals := TStringList.Create;
          try
            ExtractStrings([' ', #9, #10, #13], [], PChar(Text), Vals);
            if Vals.Count >= 16 then
            begin
              for K := 0 to 15 do
                M[K] := ParseFloat(Vals[K]);
              OX := M[3];
              OY := M[7];
              OZ := M[11];
            end;
          finally
            Vals.Free;
          end;
          Break;
        end;
      end;
      Child := Child.NextSibling;
    end;
  end;

  procedure TraverseNode(ANode: TDOMNode; AParentIdx: Integer);
  var
    LName: string;
    CurIdx: Integer;
    Child: TDOMNode;
    Attr: TDOMNode;
    IsJoint: Boolean;
    OX, OY, OZ: Double;
  begin
    if ANode.NodeType = ELEMENT_NODE then
    begin
      IsJoint := False;
      LName := '';
      
      Attr := ANode.Attributes.GetNamedItem('name');
      if Attr <> nil then LName := Attr.NodeValue;
      if LName = '' then
      begin
        Attr := ANode.Attributes.GetNamedItem('id');
        if Attr <> nil then LName := Attr.NodeValue;
      end;
      
      Attr := ANode.Attributes.GetNamedItem('type');
      if (Attr <> nil) and SameText(Attr.NodeValue, 'JOINT') then
        IsJoint := True;
        
      if SameText(ANode.NodeName, 'node') and IsJoint then
      begin
        SetLength(FJoints, JIdx + 1);
        FJoints[JIdx].Name := LName;
        FJoints[JIdx].ParentIndex := AParentIdx;
        
        ParseOffsets(ANode, OX, OY, OZ);
        FJoints[JIdx].OffsetX := OX;
        FJoints[JIdx].OffsetY := OY;
        FJoints[JIdx].OffsetZ := OZ;
        FJoints[JIdx].AngleX := 0;
        FJoints[JIdx].AngleY := 0;
        FJoints[JIdx].AngleZ := 0;
        
        FBonesList.Add(LName);
        CurIdx := JIdx;
        Inc(JIdx);
      end
      else
        CurIdx := AParentIdx;
        
      Child := ANode.FirstChild;
      while Child <> nil do
      begin
        TraverseNode(Child, CurIdx);
        Child := Child.NextSibling;
      end;
    end
    else
    begin
      Child := ANode.FirstChild;
      while Child <> nil do
      begin
        TraverseNode(Child, AParentIdx);
        Child := Child.NextSibling;
      end;
    end;
  end;

begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  
  Log(llInfo, 'Parsing Collada DAE XML file: ' + AFileName);
  
  JIdx := 0;
  SetLength(FJoints, 0);
  FBonesList.Clear;
  
  try
    ReadXMLFile(XMLDoc, AFileName);
    try
      TraverseNode(XMLDoc.DocumentElement, -1);
      
      AutoScaleRig;
      UpdateFK;
      
      Log(llInfo, Format('Collada DAE rig loaded successfully. %d joints imported.', [JIdx]));
    finally
      XMLDoc.Free;
    end;
  except
    on E: Exception do
      SetError('Error parsing DAE XML: ' + E.Message);
  end;
end;

procedure TAISkeletonRig.ParseGLTFJSON(const AJSONText: string);
var
  Parser: TJSONParser;
  RootObj, NodeObj: TJSONObject;
  NodesArray, ChildrenArray: TJSONArray;
  I, J, JIdx, ChildIdx: Integer;
  FS: TFormatSettings;
  LName: string;
  Translation: TJSONArray;
begin
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  
  Parser := TJSONParser.Create(AJSONText);
  try
    RootObj := Parser.Parse as TJSONObject;
    try
      NodesArray := nil;
      if RootObj.IndexOfName('nodes') >= 0 then
        NodesArray := RootObj.Arrays['nodes'];
        
      if NodesArray = nil then
      begin
        SetError('gltf file does not contain a "nodes" array.');
        Exit;
      end;
      
      JIdx := NodesArray.Count;
      SetLength(FJoints, JIdx);
      FBonesList.Clear;
      
      for I := 0 to JIdx - 1 do
      begin
        NodeObj := NodesArray.Objects[I];
        
        LName := '';
        if NodeObj.IndexOfName('name') >= 0 then
          LName := NodeObj.Strings['name'];
        if LName = '' then
          LName := 'node_' + IntToStr(I);
          
        FJoints[I].Name := LName;
        FJoints[I].ParentIndex := -2;
        FJoints[I].OffsetX := 0;
        FJoints[I].OffsetY := 0;
        FJoints[I].OffsetZ := 0;
        FJoints[I].AngleX := 0;
        FJoints[I].AngleY := 0;
        FJoints[I].AngleZ := 0;
        
        Translation := nil;
        if NodeObj.IndexOfName('translation') >= 0 then
          Translation := NodeObj.Arrays['translation'];
          
        if (Translation <> nil) and (Translation.Count >= 3) then
        begin
          FJoints[I].OffsetX := Translation.Items[0].AsFloat;
          FJoints[I].OffsetY := Translation.Items[1].AsFloat;
          FJoints[I].OffsetZ := Translation.Items[2].AsFloat;
        end;
        
        FBonesList.Add(LName);
      end;
      
      for I := 0 to JIdx - 1 do
      begin
        NodeObj := NodesArray.Objects[I];
        
        ChildrenArray := nil;
        if NodeObj.IndexOfName('children') >= 0 then
          ChildrenArray := NodeObj.Arrays['children'];
          
        if ChildrenArray <> nil then
        begin
          for J := 0 to ChildrenArray.Count - 1 do
          begin
            ChildIdx := ChildrenArray.Items[J].AsInteger;
            if (ChildIdx >= 0) and (ChildIdx < JIdx) then
              FJoints[ChildIdx].ParentIndex := I;
          end;
        end;
      end;
      
      for I := 0 to JIdx - 1 do
      begin
        if FJoints[I].ParentIndex = -2 then
          FJoints[I].ParentIndex := -1;
      end;
      
      AutoScaleRig;
      UpdateFK;
      
      Log(llInfo, Format('glTF/GLB rig loaded successfully. %d joints imported.', [JIdx]));
    finally
      RootObj.Free;
    end;
  except
    on E: Exception do
      SetError('Error parsing glTF JSON: ' + E.Message);
  end;
end;

procedure TAISkeletonRig.LoadGLTF(const AFileName: string);
var
  JSONString: string;
  JSONFile: TStringList;
begin
  Log(llInfo, 'Parsing glTF JSON file: ' + AFileName);
  ClearError;
  if not FileExists(AFileName) then
  begin
    SetError('glTF file not found: ' + AFileName);
    Exit;
  end;
  
  JSONFile := TStringList.Create;
  try
    JSONFile.LoadFromFile(AFileName);
    JSONString := JSONFile.Text;
    ParseGLTFJSON(JSONString);
  finally
    JSONFile.Free;
  end;
end;

procedure TAISkeletonRig.LoadGLB(const AFileName: string);
var
  FS: TFileStream;
  Magic: array[0..3] of Char;
  Version: LongWord;
  LengthVal: LongWord;
  ChunkLength: LongWord;
  ChunkType: array[0..3] of Char;
  JSONBytes: array of Byte;
  JSONString: string;
begin
  Log(llInfo, 'Parsing GLB binary file: ' + AFileName);
  ClearError;
  if not FileExists(AFileName) then
  begin
    SetError('GLB file not found: ' + AFileName);
    Exit;
  end;
  
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    if FS.Size < 20 then
    begin
      SetError('Invalid GLB file: file size too small.');
      Exit;
    end;
    
    FS.Read(Magic[0], 4);
    FS.Read(Version, 4);
    FS.Read(LengthVal, 4);
    
    if (Magic <> 'glTF') then
    begin
      SetError('Invalid GLB file: magic is not glTF.');
      Exit;
    end;
    
    FS.Read(ChunkLength, 4);
    FS.Read(ChunkType[0], 4);
    
    if (ChunkType <> 'JSON') then
    begin
      SetError('Invalid GLB file: first chunk is not JSON.');
      Exit;
    end;
    
    if ChunkLength > FS.Size - 20 then
    begin
      SetError('Invalid GLB file: chunk length exceeds file bounds.');
      Exit;
    end;
    
    SetLength(JSONBytes, ChunkLength);
    FS.Read(JSONBytes[0], ChunkLength);
    
    SetString(JSONString, PAnsiChar(@JSONBytes[0]), ChunkLength);
    ParseGLTFJSON(JSONString);
  finally
    FS.Free;
  end;
end;

procedure TAISkeletonRig.LoadBlend(const AFileName: string);
var
  BlenderPath: string;
  ScriptPath: string;
  TempOutPath: string;
  PyScript: TStringList;
  Process: TProcess;
  I: Integer;
  SearchPaths: array[0..5] of string;
  Found: Boolean;
begin
  Log(llInfo, 'Attempting to load Blender (.blend) file: ' + AFileName);
  ClearError;
  
  Found := False;
  BlenderPath := '';
  
  SearchPaths[0] := 'C:\Program Files\Blender Foundation\Blender 4.3\blender.exe';
  SearchPaths[1] := 'C:\Program Files\Blender Foundation\Blender 4.2\blender.exe';
  SearchPaths[2] := 'C:\Program Files\Blender Foundation\Blender 4.1\blender.exe';
  SearchPaths[3] := 'C:\Program Files\Blender Foundation\Blender 4.0\blender.exe';
  SearchPaths[4] := 'C:\Program Files\Blender Foundation\Blender 3.6\blender.exe';
  SearchPaths[5] := 'blender.exe';
  
  for I := 0 to 5 do
  begin
    if (I < 5) and FileExists(SearchPaths[I]) then
    begin
      BlenderPath := SearchPaths[I];
      Found := True;
      Break;
    end;
  end;
  
  if not Found then
    BlenderPath := 'blender.exe';
  
  TempOutPath := GetTempDir + 'temp_rig_export.gltf';
  ScriptPath := GetTempDir + 'temp_blender_export.py';
  
  if FileExists(TempOutPath) then DeleteFile(TempOutPath);
  if FileExists(ScriptPath) then DeleteFile(ScriptPath);
  
  PyScript := TStringList.Create;
  try
    PyScript.Add('import bpy, os');
    PyScript.Add('bpy.ops.object.select_all(action="DESELECT")');
    PyScript.Add('armature_obj = None');
    PyScript.Add('for obj in bpy.data.objects:');
    PyScript.Add('    if obj.type == "ARMATURE":');
    PyScript.Add('        armature_obj = obj');
    PyScript.Add('        obj.select_set(True)');
    PyScript.Add('        bpy.context.view_layer.objects.active = obj');
    PyScript.Add('        break');
    PyScript.Add('if armature_obj:');
    PyScript.Add('    bpy.ops.export_scene.gltf(filepath=r"' + TempOutPath + '", export_format="GLTF_SEPARATE", use_selection=True)');
    PyScript.Add('    print("EXPORT_SUCCESS")');
    PyScript.Add('else:');
    PyScript.Add('    print("NO_ARMATURE_FOUND")');
    
    PyScript.SaveToFile(ScriptPath);
  finally
    PyScript.Free;
  end;
  
  Process := TProcess.Create(nil);
  try
    Process.Executable := BlenderPath;
    Process.Parameters.Add('--background');
    Process.Parameters.Add(AFileName);
    Process.Parameters.Add('--python');
    Process.Parameters.Add(ScriptPath);
    Process.Options := [poWaitOnExit];
    
    try
      Process.Execute;
    except
      on E: Exception do
      begin
        SetError('Blender (.blend) loader requires Blender installed. ' +
                 'Please install Blender, add it to your PATH, or export the armature to .dae, .bvh, .gltf, or .glb first. ' +
                 'Error executing Blender CLI: ' + E.Message);
        Exit;
      end;
    end;
    
    if FileExists(TempOutPath) then
    begin
      LoadGLTF(TempOutPath);
      DeleteFile(TempOutPath);
    end
    else
    begin
      SetError('Failed to convert Blender armature. Please verify if the .blend file contains an Armature object.');
    end;
    
    if FileExists(ScriptPath) then DeleteFile(ScriptPath);
  finally
    Process.Free;
  end;
end;

procedure TAISkeletonRig.LoadRigFromFile(const AFileName: string);
var
  Lines: TStringList;
  Tokens: TStringList;
  ParentNames: TStringList;
  I, JIdx: Integer;
  Line: string;
  LName, LParentName: string;
  OX, OY, OZ: Double;
  Ext: string;
  
  function FindJointIndex(const AName: string): Integer;
  var
    K: Integer;
  begin
    Result := -1;
    for K := 0 to JIdx - 1 do
      if SameText(FJoints[K].Name, AName) then
      begin
        Result := K;
        Break;
      end;
  end;

  function ParseFloat(const S: string): Double;
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

begin
  Ext := LowerCase(ExtractFileExt(AFileName));
  if Ext = '.bvh' then
  begin
    LoadBVH(AFileName);
    Exit;
  end
  else if Ext = '.dae' then
  begin
    LoadDAE(AFileName);
    Exit;
  end
  else if (Ext = '.gltf') then
  begin
    LoadGLTF(AFileName);
    Exit;
  end
  else if (Ext = '.glb') then
  begin
    LoadGLB(AFileName);
    Exit;
  end
  else if (Ext = '.blend') then
  begin
    LoadBlend(AFileName);
    Exit;
  end;

  // Otherwise, default to original .rig parser
  Log(llInfo, 'Loading rig from: ' + AFileName);
  ClearError;
  if not FileExists(AFileName) then
  begin
    SetError('Rig file not found: ' + AFileName);
    Exit;
  end;

  Lines := TStringList.Create;
  Tokens := TStringList.Create;
  Tokens.Delimiter := '|';
  Tokens.StrictDelimiter := True;
  ParentNames := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFileName);
      
      // First pass: count valid lines to allocate joints array
      JIdx := 0;
      for I := 0 to Lines.Count - 1 do
      begin
        Line := Trim(Lines[I]);
        if (Line = '') or StartsText('#', Line) then Continue;
        Inc(JIdx);
      end;
      
      SetLength(FJoints, JIdx);
      FBonesList.Clear;
      
      // Second pass: read joints and populate
      JIdx := 0;
      for I := 0 to Lines.Count - 1 do
      begin
        Line := Trim(Lines[I]);
        if (Line = '') or StartsText('#', Line) then Continue;
        
        Tokens.DelimitedText := Line;
        if Tokens.Count >= 5 then
        begin
          LName := Trim(Tokens[0]);
          LParentName := Trim(Tokens[1]);
          OX := ParseFloat(Tokens[2]);
          OY := ParseFloat(Tokens[3]);
          OZ := ParseFloat(Tokens[4]);
          
          FJoints[JIdx].Name := LName;
          FJoints[JIdx].ParentIndex := -2;
          FJoints[JIdx].OffsetX := OX;
          FJoints[JIdx].OffsetY := OY;
          FJoints[JIdx].OffsetZ := OZ;
          FJoints[JIdx].AngleX := 0;
          FJoints[JIdx].AngleY := 0;
          FJoints[JIdx].AngleZ := 0;
          
          ParentNames.Add(LParentName);
          FBonesList.Add(LName);
          Inc(JIdx);
        end;
      end;
      
      // Third pass: resolve parent indices
      for I := 0 to JIdx - 1 do
      begin
        LParentName := ParentNames[I];
        if (LParentName = '') or (LParentName = '-1') then
          FJoints[I].ParentIndex := -1
        else
          FJoints[I].ParentIndex := FindJointIndex(LParentName);
      end;
      
      UpdateFK;
      FLastResult := Format('Rig loaded successfully. Joints count: %d', [JIdx]);
      FLastSuccess := True;
      Log(llInfo, FLastResult);
    except
      on E: Exception do
      begin
        SetError('Error loading rig: ' + E.Message);
      end;
    end;
  finally
    ParentNames.Free;
    Tokens.Free;
    Lines.Free;
  end;
end;

function TAISkeletonRig.GetJointCount: Integer;
begin
  Result := Length(FJoints);
end;

function TAISkeletonRig.GetJoint(Index: Integer): TBoneJoint;
begin
  if (Index >= 0) and (Index < Length(FJoints)) then
    Result := FJoints[Index]
  else
    FillChar(Result, SizeOf(Result), 0);
end;

initialization
  {$I aiskeletonrig_icon.lrs}

end.
