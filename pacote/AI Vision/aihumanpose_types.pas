unit aihumanpose_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAIHumanPoseLandmarkIndex = (
    hplNose = 0,
    hplLeftEyeInner = 1,
    hplLeftEye = 2,
    hplLeftEyeOuter = 3,
    hplRightEyeInner = 4,
    hplRightEye = 5,
    hplRightEyeOuter = 6,
    hplLeftEar = 7,
    hplRightEar = 8,
    hplMouthLeft = 9,
    hplMouthRight = 10,
    hplLeftShoulder = 11,
    hplRightShoulder = 12,
    hplLeftElbow = 13,
    hplRightElbow = 14,
    hplLeftWrist = 15,
    hplRightWrist = 16,
    hplLeftPinky = 17,
    hplRightPinky = 18,
    hplLeftIndex = 19,
    hplRightIndex = 20,
    hplLeftThumb = 21,
    hplRightThumb = 22,
    hplLeftHip = 23,
    hplRightHip = 24,
    hplLeftKnee = 25,
    hplRightKnee = 26,
    hplLeftAnkle = 27,
    hplRightAnkle = 28,
    hplLeftHeel = 29,
    hplRightHeel = 30,
    hplLeftFootIndex = 31,
    hplRightFootIndex = 32
  );

  TAIHumanPoseLandmark = record
    Index: Integer;
    X: Single;
    Y: Single;
    Z: Single;
    Visibility: Single;
    Presence: Single;
    Name: string;
  end;

  TAIHumanPoseLandmarks = array[0..32] of TAIHumanPoseLandmark;

  TAIHumanPoseDetectionResult = record
    Landmarks: TAIHumanPoseLandmarks;
    HasPose: Boolean;
    Score: Single;
  end;

  TMPLoadMode = (mplmAuto, mplmManualPath);
  TMPExecutionMode = (mpemDLL, mpemProcess);
  TMPRunningMode = (hprImage, hprVideo, hprLiveStream);
  TMPModelVariant = (hpmLite, hpmFull, hpmHeavy, hpmCustom);
  TMPInputColorFormat = (hpcRGB, hpcBGR, hpcRGBA, hpcBGRA);

  TAIHumanBodyPartGroup = (
    hpgFace,
    hpgShoulders,
    hpgLeftArm,
    hpgRightArm,
    hpgTorso,
    hpgLeftLeg,
    hpgRightLeg
  );
  TAIHumanBodyPartGroups = set of TAIHumanBodyPartGroup;

implementation

end.
