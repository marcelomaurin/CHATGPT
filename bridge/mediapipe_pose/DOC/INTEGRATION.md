# Pascal Integration Guide

This document describes how to use the `mp_pose_bridge` unit and the `TAIHumanPoseDetector` component in your Lazarus/FPC applications.

## 1. Using the Low-level Binding (`mp_pose_bridge.pas`)

The `mp_pose_bridge` unit loads symbols dynamically in runtime. You don't need a hard link to the library:

```pascal
uses
  mp_pose_bridge;

var
  LInfo: tmp_pose_info;
  LCfg: tmp_pose_config;
  LHandle: mp_pose_handle;
  LImg: tmp_image_raw;
  LResult: Pmp_pose_result;
begin
  // Load DLL/SO dynamically
  if not LoadMpPoseBridge('caminho/para/pasta/contendo/dll') then
  begin
    WriteLn('Failed to load library.');
    Exit;
  end;

  // Retrieve version and ABI info
  LInfo.struct_size := SizeOf(LInfo);
  if mp_pose_get_info(@LInfo) = MP_OK then
  begin
    WriteLn('Loaded version: ', LInfo.bridge_version);
  end;

  // Setup configuration
  FillChar(LCfg, SizeOf(LCfg), 0);
  LCfg.struct_size := SizeOf(LCfg);
  LCfg.model_path := 'models/pose_landmarker_full.task';
  LCfg.running_mode := 0; // IMAGE

  if mp_pose_create(@LCfg, @LHandle) = MP_OK then
  begin
    // Run detection
    FillChar(LImg, SizeOf(LImg), 0);
    LImg.struct_size := SizeOf(LImg);
    LImg.data := PixelBuffer;
    LImg.width := 640;
    LImg.height := 480;
    LImg.channels := 3;
    LImg.stride := 640 * 3;

    if mp_pose_detect(LHandle, @LImg, @LResult) = MP_OK then
    begin
      WriteLn('Detected poses: ', LResult^.pose_count);
      
      // ALWAYS free result structures inside the DLL heap context
      mp_pose_free_result(LResult);
    end;

    mp_pose_destroy(LHandle);
  end;

  UnloadMpPoseBridge;
end;
```

## 2. Using the High-level Component (`TAIHumanPoseDetector`)

Place the component on a form or construct it dynamically:

```pascal
var
  FDetector: TAIHumanPoseDetector;
begin
  FDetector := TAIHumanPoseDetector.Create(Self);
  try
    FDetector.LoadMode := mplmAuto; // Auto-resolves runtime folder paths
    FDetector.ModelVariant := hpmFull;

    if FDetector.Initialize then
    begin
      if FDetector.DetectImageFile('path/to/test.jpg') then
      begin
        // Draw bones skeleton on a PaintBox Canvas
        FDetector.DrawResult(MyPaintBox.Canvas, MyPaintBox.ClientRect);
      end;
    end
    else
    begin
      ShowMessage('Error: ' + FDetector.LastError);
    end;
  finally
    FDetector.Free;
  end;
end;
```

## 3. ABI Version Check and Available Property
The component exposes an `Available` boolean property. This property does the following checks automatically:
1. Verifies that the platform is 64-bit (`CPU64` directive).
2. Attempts to load the dynamic library bridge.
3. Invokes `mp_pose_get_info` to assert that `abi_version == MP_POSE_ABI_VERSION` (currently `1`) and the architecture matches `x86_64`.
If any of these validations fail, `Available` returns `False`, permitting the application to degrade gracefully (e.g. disable pose detection features) without crashing the Lazarus IDE or target application.
