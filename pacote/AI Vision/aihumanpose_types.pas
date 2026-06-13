unit aihumanpose_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAIHumanPoseRunningMode = (
    hprImage,
    hprVideo,
    hprLiveStream
  );

  TAIHumanPoseModelVariant = (
    hpmLite,
    hpmFull,
    hpmHeavy,
    hpmCustom
  );

  TAIHumanPoseColorFormat = (
    hpcRGB,
    hpcBGR,
    hpcRGBA,
    hpcBGRA
  );

  TAIHumanPoseLoadMode = (
    mplmAuto,
    mplmManualPath
  );

  TAIHumanPoseExecutionMode = (
    mpemDLL,
    mpemProcess
  );

  TAIHumanPoseLandmarkId = (
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
    X: Single;
    Y: Single;
    Z: Single;
    Visibility: Single;
    Presence: Single;
  end;

  TAIHumanPose = record
    LandmarkCount: Integer;
    Landmarks: array[0..32] of TAIHumanPoseLandmark;
    WorldLandmarks: array[0..32] of TAIHumanPoseLandmark;
  end;

  TAIHumanPoseResult = record
    PoseCount: Integer;
    Poses: array[0..3] of TAIHumanPose;
  end;

const
  AI_HUMAN_POSE_LANDMARK_COUNT = 33;
  AI_HUMAN_POSE_MAX_POSES = 4;

implementation

end.
