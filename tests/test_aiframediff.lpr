program test_aiframediff;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Classes, SysUtils, Graphics, FPimage, IntfGraphics, aiframediff, aibase;

procedure TestFrameDiff;
var
  DiffGen: TAIFrameDiff;
  Bmp1, Bmp2, BmpDiff: TBitmap;
  Intf: TLazIntfImage;
  C: TFPColor;
begin
  WriteLn('Testing TAIFrameDiff...');
  DiffGen := TAIFrameDiff.Create(nil);
  Bmp1 := TBitmap.Create;
  Bmp2 := TBitmap.Create;
  BmpDiff := TBitmap.Create;
  Intf := TLazIntfImage.Create(0, 0);
  try
    Bmp1.Width := 10; Bmp1.Height := 10;
    Bmp2.Width := 10; Bmp2.Height := 10;

    // Both black
    Bmp1.Canvas.Brush.Color := clBlack;
    Bmp1.Canvas.FillRect(0, 0, 10, 10);
    Bmp2.Canvas.Brush.Color := clBlack;
    Bmp2.Canvas.FillRect(0, 0, 10, 10);

    // Difference should be black
    if not DiffGen.GenerateDiffBitmap(Bmp1, Bmp2, BmpDiff) then
      raise Exception.Create('Failed to generate difference bitmap: ' + DiffGen.LastError);

    Intf.LoadFromBitmap(BmpDiff.Handle, BmpDiff.MaskHandle);
    C := Intf.Colors[0, 0];
    if (C.Red <> 0) or (C.Green <> 0) or (C.Blue <> 0) then
      raise Exception.Create('Identical black frames diff should be black, got R=' + IntToStr(C.Red));

    // One black, one white
    Bmp2.Canvas.Brush.Color := clWhite;
    Bmp2.Canvas.FillRect(0, 0, 10, 10);

    if not DiffGen.GenerateDiffBitmap(Bmp1, Bmp2, BmpDiff) then
      raise Exception.Create('Failed to generate difference bitmap: ' + DiffGen.LastError);

    Intf.LoadFromBitmap(BmpDiff.Handle, BmpDiff.MaskHandle);
    C := Intf.Colors[0, 0];
    if (C.Red < 60000) or (C.Green < 60000) or (C.Blue < 60000) then
      raise Exception.Create('Black/white frames diff should be white, got R=' + IntToStr(C.Red));

    // Test file-based diff
    Bmp1.SaveToFile('temp_diff1.bmp');
    Bmp2.SaveToFile('temp_diff2.bmp');
    try
      if not DiffGen.GenerateDiffFile('temp_diff1.bmp', 'temp_diff2.bmp', 'temp_diff_out.bmp') then
        raise Exception.Create('GenerateDiffFile failed: ' + DiffGen.LastError);

      if not FileExists('temp_diff_out.bmp') then
        raise Exception.Create('Difference output file was not created');
    finally
      SysUtils.DeleteFile('temp_diff1.bmp');
      SysUtils.DeleteFile('temp_diff2.bmp');
      SysUtils.DeleteFile('temp_diff_out.bmp');
    end;

    WriteLn('TAIFrameDiff tests passed.');
  finally
    Intf.Free;
    BmpDiff.Free;
    Bmp2.Free;
    Bmp1.Free;
    DiffGen.Free;
  end;
end;

begin
  try
    TestFrameDiff;
    WriteLn('test_aiframediff COMPLETED SUCCESSFULLY.');
  except
    on E: Exception do
    begin
      WriteLn('TEST FAILED: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
