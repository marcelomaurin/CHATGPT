unit kinect_retarget;
{$mode objfpc}{$H+}
interface
uses SysUtils, Math, aikinect_types, movement_timeline;
function Aim(const A,B:TMVector):TMQuaternion;
function Retarget(Rig:TMovementRuntime;const Previous:TMPoseArray;
  const Body:TAIKinectBody;Alpha:Double):TMPoseArray;
implementation
function Sub(const A,B:TMVector):TMVector;
begin Result:=MVector(A[0]-B[0],A[1]-B[1],A[2]-B[2]);end;
function Aim(const A,B:TMVector):TMQuaternion;
var U,V,C:TMVector;L,N,D:Double;I:Integer;
begin
  Result:=MQuaternion(0,0,0);U:=A;V:=B;
  L:=Sqrt(Sqr(U[0])+Sqr(U[1])+Sqr(U[2]));
  N:=Sqrt(Sqr(V[0])+Sqr(V[1])+Sqr(V[2]));
  if (L<1E-8) or (N<1E-8) then Exit;
  for I:=0 to 2 do begin U[I]:=U[I]/L;V[I]:=V[I]/N;end;
  D:=EnsureRange(U[0]*V[0]+U[1]*V[1]+U[2]*V[2],-1.0,1.0);
  C:=MVector(U[1]*V[2]-U[2]*V[1],U[2]*V[0]-U[0]*V[2],U[0]*V[1]-U[1]*V[0]);
  if D< -0.999999 then begin
    if Abs(U[0])<0.8 then C:=MVector(0,U[2],-U[1])
    else C:=MVector(-U[2],0,U[0]);
    Exit(MAxisAngle(C[0],C[1],C[2],Pi));
  end;
  N:=Sqrt(2*(1+D));
  for I:=0 to 2 do Result[I]:=C[I]/N;Result[3]:=N/2;
end;
function Retarget(Rig:TMovementRuntime;const Previous:TMPoseArray;
  const Body:TAIKinectBody;Alpha:Double):TMPoseArray;
var Rest:TMPoseArray;W:TMWorldArray;
  procedure Bone(const Name,Tip:string;A,B:TAIKinectJointType);
  var I,J,P:Integer;V,D:TMVector;Q:TMQuaternion;K:Integer;
  begin
    I:=Rig.NodeIndex(Name);J:=Rig.NodeIndex(Tip);
    if (I<0) or (J<0) or (Body.Joints[A].State<>ktTracked) or
      (Body.Joints[B].State<>ktTracked) then Exit;
    V:=Sub(W[J].Position,W[I].Position);
    // Kinect X points to the sensor's left; avatar anatomical left is +X.
    D:=MVector(-(Body.Joints[B].X-Body.Joints[A].X),
      Body.Joints[B].Y-Body.Joints[A].Y,-(Body.Joints[B].Z-Body.Joints[A].Z));
    for K:=0 to 2 do if IsNan(D[K]) or IsInfinite(D[K]) then Exit;
    if Sqr(D[0])+Sqr(D[1])+Sqr(D[2])<1E-8 then Exit;
    Q:=QMul(Aim(V,D),W[I].Rotation);P:=Rig.NodeParent(I);
    if P>=0 then Q:=QMul(MInverse(W[P].Rotation),Q);
    Result[I].Rotation:=MInterpolate(Previous[I].Rotation,Q,EnsureRange(Alpha,0.0,1.0));
    W:=Rig.Worlds(Result);
  end;
begin
  Result:=Copy(Previous);if not Body.Tracked then Exit;
  Rest:=Rig.RestPose;
  if Length(Result)<>Length(Rest) then Exit;
  W:=Rig.Worlds(Result);
  Bone('spine01','neck01',kjHipCenter,kjShoulderCenter);
  Bone('neck01','head',kjShoulderCenter,kjHead);
  Bone('upperarm01.L','lowerarm01.L',kjShoulderLeft,kjElbowLeft);
  Bone('lowerarm01.L','wrist.L',kjElbowLeft,kjWristLeft);
  Bone('upperarm01.R','lowerarm01.R',kjShoulderRight,kjElbowRight);
  Bone('lowerarm01.R','wrist.R',kjElbowRight,kjWristRight);
  Bone('upperleg01.L','lowerleg01.L',kjHipLeft,kjKneeLeft);
  Bone('lowerleg01.L','foot.L',kjKneeLeft,kjAnkleLeft);
  Bone('upperleg01.R','lowerleg01.R',kjHipRight,kjKneeRight);
  Bone('lowerleg01.R','foot.R',kjKneeRight,kjAnkleRight);
end;
end.
