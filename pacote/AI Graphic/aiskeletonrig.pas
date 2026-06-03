unit aiskeletonrig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, StrUtils, aibase;

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
  SetLength(FJoints, 11);
  
  // 0. Pelvis/Root
  FJoints[0].Name := 'pelvis';
  FJoints[0].ParentIndex := -1;
  FJoints[0].OffsetX := 0; FJoints[0].OffsetY := 0.2; FJoints[0].OffsetZ := 0;
  FJoints[0].AngleX := 0; FJoints[0].AngleY := 0; FJoints[0].AngleZ := 0;
  
  // 1. Spine (child of Pelvis)
  FJoints[1].Name := 'spine';
  FJoints[1].ParentIndex := 0;
  FJoints[1].OffsetX := 0; FJoints[1].OffsetY := 0.5; FJoints[1].OffsetZ := 0;
  FJoints[1].AngleX := 0; FJoints[1].AngleY := 0; FJoints[1].AngleZ := 0;
  
  // 2. Head (child of Spine)
  FJoints[2].Name := 'head';
  FJoints[2].ParentIndex := 1;
  FJoints[2].OffsetX := 0; FJoints[2].OffsetY := 0.3; FJoints[2].OffsetZ := 0;
  FJoints[2].AngleX := 0; FJoints[2].AngleY := 0; FJoints[2].AngleZ := 0;
  
  // Left Arm
  // 3. Left Shoulder (child of Spine)
  FJoints[3].Name := 'left_shoulder';
  FJoints[3].ParentIndex := 1;
  FJoints[3].OffsetX := -0.3; FJoints[3].OffsetY := 0; FJoints[3].OffsetZ := 0;
  FJoints[3].AngleX := 0; FJoints[3].AngleY := 0; FJoints[3].AngleZ := 0;
  
  // 4. Left Elbow (child of Left Shoulder)
  FJoints[4].Name := 'left_elbow';
  FJoints[4].ParentIndex := 3;
  FJoints[4].OffsetX := -0.4; FJoints[4].OffsetY := 0; FJoints[4].OffsetZ := 0;
  FJoints[4].AngleX := 0; FJoints[4].AngleY := 0; FJoints[4].AngleZ := 0;
  
  // Right Arm
  // 5. Right Shoulder (child of Spine)
  FJoints[5].Name := 'right_shoulder';
  FJoints[5].ParentIndex := 1;
  FJoints[5].OffsetX := 0.3; FJoints[5].OffsetY := 0; FJoints[5].OffsetZ := 0;
  FJoints[5].AngleX := 0; FJoints[5].AngleY := 0; FJoints[5].AngleZ := 0;
  
  // 6. Right Elbow (child of Right Shoulder)
  FJoints[6].Name := 'right_elbow';
  FJoints[6].ParentIndex := 5;
  FJoints[6].OffsetX := 0.4; FJoints[6].OffsetY := 0; FJoints[6].OffsetZ := 0;
  FJoints[6].AngleX := 0; FJoints[6].AngleY := 0; FJoints[6].AngleZ := 0;
  
  // Left Leg
  // 7. Left Hip (child of Pelvis)
  FJoints[7].Name := 'left_hip';
  FJoints[7].ParentIndex := 0;
  FJoints[7].OffsetX := -0.15; FJoints[7].OffsetY := -0.5; FJoints[7].OffsetZ := 0;
  FJoints[7].AngleX := 0; FJoints[7].AngleY := 0; FJoints[7].AngleZ := 0;
  
  // 8. Left Knee (child of Left Hip)
  FJoints[8].Name := 'left_knee';
  FJoints[8].ParentIndex := 7;
  FJoints[8].OffsetX := 0; FJoints[8].OffsetY := -0.5; FJoints[8].OffsetZ := 0;
  FJoints[8].AngleX := 0; FJoints[8].AngleY := 0; FJoints[8].AngleZ := 0;
  
  // Right Leg
  // 9. Right Hip (child of Pelvis)
  FJoints[9].Name := 'right_hip';
  FJoints[9].ParentIndex := 0;
  FJoints[9].OffsetX := 0.15; FJoints[9].OffsetY := -0.5; FJoints[9].OffsetZ := 0;
  FJoints[9].AngleX := 0; FJoints[9].AngleY := 0; FJoints[9].AngleZ := 0;
  
  // 10. Right Knee (child of Right Hip)
  FJoints[10].Name := 'right_knee';
  FJoints[10].ParentIndex := 9;
  FJoints[10].OffsetX := 0; FJoints[10].OffsetY := -0.5; FJoints[10].OffsetZ := 0;
  FJoints[10].AngleX := 0; FJoints[10].AngleY := 0; FJoints[10].AngleZ := 0;
  
  FBonesList.Clear;
  FBonesList.Add('pelvis');
  FBonesList.Add('spine');
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

procedure TAISkeletonRig.LoadRigFromFile(const AFileName: string);
var
  Lines: TStringList;
  Tokens: TStringList;
  ParentNames: TStringList;
  I, JIdx: Integer;
  Line: string;
  LName, LParentName: string;
  OX, OY, OZ: Double;
  
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

end.
