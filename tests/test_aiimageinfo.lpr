program test_aiimageinfo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Classes, SysUtils, Graphics, aiimageinfo, aibase;

procedure TestImageInfo;
var
  Info: TAIImageInfo;
  Bmp: TBitmap;
begin
  WriteLn('Testing TAIImageInfo...');
  Info := TAIImageInfo.Create(nil);
  Bmp := TBitmap.Create;
  try
    Bmp.Width := 24;
    Bmp.Height := 32;

    if Info.Width <> 0 then
      raise Exception.Create('Default Width should be 0');
    if Info.Height <> 0 then
      raise Exception.Create('Default Height should be 0');
    if Info.PixelCount <> 0 then
      raise Exception.Create('Default PixelCount should be 0');

    if not Info.LoadInfoFromBitmap(Bmp) then
      raise Exception.Create('Failed to load info from bitmap: ' + Info.LastError);

    if Info.Width <> 24 then
      raise Exception.Create('Loaded Width should be 24');
    if Info.Height <> 32 then
      raise Exception.Create('Loaded Height should be 32');
    if Info.PixelCount <> 768 then
      raise Exception.Create('Loaded PixelCount should be 768');

    // Test text representation
    if Pos('Width: 24', Info.AsText) = 0 then
      raise Exception.Create('AsText formatting check failed');

    // Test file loader
    Bmp.SaveToFile('temp_test_info.bmp');
    try
      if not Info.LoadInfoFromFile('temp_test_info.bmp') then
        raise Exception.Create('Failed to load info from file: ' + Info.LastError);

      if Info.Width <> 24 then
        raise Exception.Create('File Width should be 24');
      if Info.FileName <> 'temp_test_info.bmp' then
        raise Exception.Create('File name record mismatch');
    finally
      SysUtils.DeleteFile('temp_test_info.bmp');
    end;

    WriteLn('TAIImageInfo tests passed.');
  finally
    Bmp.Free;
    Info.Free;
  end;
end;

begin
  try
    TestImageInfo;
    WriteLn('test_aiimageinfo COMPLETED SUCCESSFULLY.');
  except
    on E: Exception do
    begin
      WriteLn('TEST FAILED: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
