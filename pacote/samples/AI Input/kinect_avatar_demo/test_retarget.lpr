program test_retarget;
{$mode objfpc}{$H+}
uses SysUtils,Math,kinect_retarget,movement_timeline,aikinect_types;
var Q,R,V:TMQuaternion;I,J,K:Integer;Rig:TMovementRuntime;P,C:TMPoseArray;
 W:TMWorldArray;Body:TAIKinectBody;
procedure Joint(A:TAIKinectJointType;const Name:string);
var N:Integer;
begin
 N:=Rig.NodeIndex(Name);if N<0 then raise Exception.Create('Osso ausente: '+Name);
 Body.Joints[A].State:=ktTracked;Body.Joints[A].X:=-W[N].Position[0];
 Body.Joints[A].Y:=W[N].Position[1];Body.Joints[A].Z:=-W[N].Position[2];
end;
procedure Check(const A,B:TMVector);
var N,L:Double;
begin
 Q:=Aim(A,B);V[0]:=A[0];V[1]:=A[1];V[2]:=A[2];V[3]:=0;
 R:=QMul(QMul(Q,V),MInverse(Q));N:=0;L:=0;
 for I:=0 to 2 do begin N:=N+Sqr(A[I]);L:=L+Sqr(B[I]);end;
 for I:=0 to 2 do if Abs(R[I]/Sqrt(N)-B[I]/Sqrt(L))>1E-5 then
   raise Exception.Create('Direcao incorreta');
end;
begin
 Check(MVector(1,0,0),MVector(0,1,0));
 Check(MVector(0,1,0),MVector(0,-1,0));
 Check(MVector(1,2,3),MVector(-3,2,1));
 Q:=Aim(MVector(0,0,0),MVector(1,0,0));
 if Abs(Q[3]-1)>1E-8 then Halt(1);
 WriteLn('PASS: rotacao 90 graus, opostos, 3D e segmento nulo');
 Rig:=TMovementRuntime.Create;
 try
  Rig.LoadRig('C:\projetos\maurinsoft\Assistente\AVATARES\professor\modelo.gltf',
   'C:\projetos\maurinsoft\Assistente\AVATARES\colisoes.json',1.8);
  P:=Rig.RestPose;W:=Rig.Worlds(P);Body:=Default(TAIKinectBody);Body.Tracked:=True;
  Joint(kjShoulderRight,'upperarm01.R');Joint(kjElbowRight,'lowerarm01.R');Joint(kjWristRight,'wrist.R');
  C:=Retarget(Rig,P,Body,1);
  for J:=0 to High(P) do for K:=0 to 3 do
   if Abs(P[J].Rotation[K]-C[J].Rotation[K])>1E-4 then raise Exception.Create('Repouso alterado');
  Body.Joints[kjElbowRight].Y:=Body.Joints[kjShoulderRight].Y+1;
  Body.Joints[kjElbowRight].X:=Body.Joints[kjShoulderRight].X;
  C:=Retarget(Rig,P,Body,1);J:=Rig.NodeIndex('upperarm01.R');
  if Abs(C[J].Rotation[3]-P[J].Rotation[3])<1E-4 then raise Exception.Create('Braco nao se moveu');
  Body.Joints[kjElbowRight].State:=ktNotTracked;C:=Retarget(Rig,P,Body,1);
  for K:=0 to 3 do if Abs(C[J].Rotation[K]-P[J].Rotation[K])>1E-6 then raise Exception.Create('Junta ausente alterada');
  WriteLn('PASS: modelo real, repouso, braco levantado e junta ausente');
 finally Rig.Free;end;
end.
