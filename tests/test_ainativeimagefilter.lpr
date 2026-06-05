program test_ainativeimagefilter;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Classes, SysUtils, Graphics, FPimage, IntfGraphics, ainativeimagefilter, aibase;

procedure TestFilters;
var
  Filter: TAINativeImageFilter;
  Bmp: TBitmap;
  Intf: TLazIntfImage;
  C: TFPColor;
begin
  WriteLn('Testing TAINativeImageFilter...');
  Filter := TAINativeImageFilter.Create(nil);
  Bmp := TBitmap.Create;
  Intf := TLazIntfImage.Create(0, 0);
  try
    // Initialize a 10x10 red bitmap
    Bmp.Width := 10;
    Bmp.Height := 10;
    
    // Draw on bitmap canvas
    Bmp.Canvas.Brush.Color := clRed;
    Bmp.Canvas.FillRect(0, 0, 10, 10);

    // Verify initial state is red
    Intf.LoadFromBitmap(Bmp.Handle, Bmp.MaskHandle);
    C := Intf.Colors[0, 0];
    if (C.Red = 0) then
      raise Exception.Create('Test setup failed: Pixel is not red');

    // 1. Test Invert Filter
    Filter.FilterType := niftInvert;
    if not Filter.ApplyToBitmap(Bmp) then
      raise Exception.Create('Invert filter failed: ' + Filter.LastError);
      
    Intf.LoadFromBitmap(Bmp.Handle, Bmp.MaskHandle);
    C := Intf.Colors[0, 0];
    if (C.Red > 1000) or (C.Green < 60000) or (C.Blue < 60000) then
      raise Exception.Create('Invert filter validation failed: expected Cyan, got R=' + 
        IntToStr(C.Red) + ' G=' + IntToStr(C.Green) + ' B=' + IntToStr(C.Blue));
    WriteLn('  niftInvert passed.');

    // Reset to red
    Bmp.Canvas.Brush.Color := clRed;
    Bmp.Canvas.FillRect(0, 0, 10, 10);

    // 2. Test Grayscale Filter
    Filter.FilterType := niftGray;
    if not Filter.ApplyToBitmap(Bmp) then
      raise Exception.Create('Grayscale filter failed: ' + Filter.LastError);
      
    Intf.LoadFromBitmap(Bmp.Handle, Bmp.MaskHandle);
    C := Intf.Colors[0, 0];
    // Grayscale: Red/Green/Blue channels must be equal
    if (C.Red <> C.Green) or (C.Green <> C.Blue) then
      raise Exception.Create('Grayscale validation failed: channels are not equal');
    WriteLn('  niftGray passed.');

    // Reset to red
    Bmp.Canvas.Brush.Color := clRed;
    Bmp.Canvas.FillRect(0, 0, 10, 10);

    // 3. Test Threshold (Binarization) Filter
    Filter.FilterType := niftThreshold;
    Filter.ThresholdValue := 100;
    // Red color luminance is ~299/1000 * 65535 = 19594 (which is ~76/255).
    // Threshold is 100/255. So it should become black.
    if not Filter.ApplyToBitmap(Bmp) then
      raise Exception.Create('Threshold filter failed: ' + Filter.LastError);
      
    Intf.LoadFromBitmap(Bmp.Handle, Bmp.MaskHandle);
    C := Intf.Colors[0, 0];
    if (C.Red <> 0) or (C.Green <> 0) or (C.Blue <> 0) then
      raise Exception.Create('Threshold validation failed: expected black, got R=' + 
        IntToStr(C.Red) + ' G=' + IntToStr(C.Green) + ' B=' + IntToStr(C.Blue));
    WriteLn('  niftThreshold passed.');

    // 4. Test Resize Filter
    // Reset to red
    Bmp.Canvas.Brush.Color := clRed;
    Bmp.Canvas.FillRect(0, 0, 10, 10);
    Filter.FilterType := niftResize;
    Filter.ResizeWidth := 5;
    Filter.ResizeHeight := 5;
    if not Filter.ApplyToBitmap(Bmp) then
      raise Exception.Create('Resize filter failed: ' + Filter.LastError);
    if (Bmp.Width <> 5) or (Bmp.Height <> 5) then
      raise Exception.Create(Format('Resize validation failed: expected 5x5, got %dx%d', [Bmp.Width, Bmp.Height]));
    WriteLn('  niftResize passed.');

    // 5. Test Blur Filter
    // Reset to red
    Bmp.Width := 10;
    Bmp.Height := 10;
    Bmp.Canvas.Brush.Color := clRed;
    Bmp.Canvas.FillRect(0, 0, 10, 10);
    Filter.FilterType := niftBlurBox;
    if not Filter.ApplyToBitmap(Bmp) then
      raise Exception.Create('Blur filter failed: ' + Filter.LastError);
    WriteLn('  niftBlurBox passed.');

    // 6. Test File Processing
    Bmp.SaveToFile('temp_test_in.bmp');
    if not Filter.ApplyFile('temp_test_in.bmp', 'temp_test_out.bmp') then
      raise Exception.Create('ApplyFile failed: ' + Filter.LastError);
    if not FileExists('temp_test_out.bmp') then
      raise Exception.Create('ApplyFile did not write output file');
    
    SysUtils.DeleteFile('temp_test_in.bmp');
    SysUtils.DeleteFile('temp_test_out.bmp');
    WriteLn('  ApplyFile passed.');

  finally
    Intf.Free;
    Bmp.Free;
    Filter.Free;
  end;
end;

begin
  try
    TestFilters;
    WriteLn('test_ainativeimagefilter COMPLETED SUCCESSFULLY.');
  except
    on E: Exception do
    begin
      WriteLn('TEST FAILED: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
