program test_aimotiontracker;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Classes, SysUtils, Graphics, FPimage, IntfGraphics, aimotiontracker, aiframediff, aibase;

procedure TestMotionAndDiff;
var
  Tracker: TAIMotionTracker;
  DiffGen: TAIFrameDiff;
  Bmp1, Bmp2, BmpDiff: TBitmap;
  Intf: TLazIntfImage;
  C: TFPColor;
begin
  WriteLn('Testing TAIMotionTracker and TAIFrameDiff...');
  Tracker := TAIMotionTracker.Create(nil);
  DiffGen := TAIFrameDiff.Create(nil);
  Bmp1 := TBitmap.Create;
  Bmp2 := TBitmap.Create;
  BmpDiff := TBitmap.Create;
  Intf := TLazIntfImage.Create(0, 0);
  try
    // Set 10x10 dimensions
    Bmp1.Width := 10;
    Bmp1.Height := 10;
    Bmp2.Width := 10;
    Bmp2.Height := 10;

    // 1. Identical Frames (No motion)
    Bmp1.Canvas.Brush.Color := clBlack;
    Bmp1.Canvas.FillRect(0, 0, 10, 10);
    Bmp2.Canvas.Brush.Color := clBlack;
    Bmp2.Canvas.FillRect(0, 0, 10, 10);

    Tracker.Threshold := 10;
    Tracker.MinMotionPercent := 1.0;
    
    if Tracker.DetectMotion(Bmp1, Bmp2) then
      raise Exception.Create('Motion detected on identical black frames');
    if Tracker.MotionPercent <> 0.0 then
      raise Exception.Create('MotionPercent should be 0.0 for identical frames');
    WriteLn('  No motion test passed.');

    // 2. Completely Different Frames (Full motion)
    Bmp2.Canvas.Brush.Color := clWhite;
    Bmp2.Canvas.FillRect(0, 0, 10, 10);

    if not Tracker.DetectMotion(Bmp1, Bmp2) then
      raise Exception.Create('Failed to detect motion on completely different frames');
    if Tracker.MotionPercent <> 100.0 then
      raise Exception.Create('MotionPercent should be 100.0 for completely opposite black/white frames');
    WriteLn('  Full motion test passed.');

    // 3. Partial Motion (20% change)
    // Create a 2x10 slice of white on Bmp2 (which is 20 pixels out of 100)
    Bmp2.Canvas.Brush.Color := clBlack;
    Bmp2.Canvas.FillRect(0, 0, 10, 10);
    Bmp2.Canvas.Brush.Color := clWhite;
    Bmp2.Canvas.FillRect(0, 0, 2, 10); // columns 0 and 1 are white (20%)

    if not Tracker.DetectMotion(Bmp1, Bmp2) then
      raise Exception.Create('Failed to detect partial motion');
    if (Tracker.MotionPercent < 19.9) or (Tracker.MotionPercent > 20.1) then
      raise Exception.Create('Expected ~20% motion, got: ' + FloatToStr(Tracker.MotionPercent));
    WriteLn('  Partial motion test passed.');

    // 4. Test TAIFrameDiff Generation
    if not DiffGen.GenerateDiffBitmap(Bmp1, Bmp2, BmpDiff) then
      raise Exception.Create('Failed to generate difference bitmap: ' + DiffGen.LastError);

    if (BmpDiff.Width <> 10) or (BmpDiff.Height <> 10) then
      raise Exception.Create('Difference bitmap dimensions are wrong');

    Intf.LoadFromBitmap(BmpDiff.Handle, BmpDiff.MaskHandle);
    // Columns 0, 1 in BmpDiff should be white, other columns should be black
    C := Intf.Colors[0, 0];
    if (C.Red = 0) then
      raise Exception.Create('Difference pixel at index 0,0 should not be black');
    
    C := Intf.Colors[5, 5];
    if (C.Red <> 0) or (C.Green <> 0) or (C.Blue <> 0) then
      raise Exception.Create('Difference pixel at index 5,5 should be black');
    WriteLn('  Frame difference generation test passed.');

    // 5. Test File Processing
    Bmp1.SaveToFile('temp_track1.bmp');
    Bmp2.SaveToFile('temp_track2.bmp');

    if not Tracker.DetectMotionFromFiles('temp_track1.bmp', 'temp_track2.bmp') then
      raise Exception.Create('DetectMotionFromFiles failed: ' + Tracker.LastError);
    if (Tracker.MotionPercent < 19.9) or (Tracker.MotionPercent > 20.1) then
      raise Exception.Create('File motion detection percentage discrepancy');

    if not DiffGen.GenerateDiffFile('temp_track1.bmp', 'temp_track2.bmp', 'temp_diff.bmp') then
      raise Exception.Create('GenerateDiffFile failed: ' + DiffGen.LastError);
    if not FileExists('temp_diff.bmp') then
      raise Exception.Create('Difference file temp_diff.bmp was not created');

    SysUtils.DeleteFile('temp_track1.bmp');
    SysUtils.DeleteFile('temp_track2.bmp');
    SysUtils.DeleteFile('temp_diff.bmp');
    WriteLn('  File checks passed.');

  finally
    Intf.Free;
    BmpDiff.Free;
    Bmp2.Free;
    Bmp1.Free;
    DiffGen.Free;
    Tracker.Free;
  end;
end;

begin
  try
    TestMotionAndDiff;
    WriteLn('test_aimotiontracker COMPLETED SUCCESSFULLY.');
  except
    on E: Exception do
    begin
      WriteLn('TEST FAILED: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
