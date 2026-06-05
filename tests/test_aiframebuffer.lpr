program test_aiframebuffer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Classes, SysUtils, Graphics, aiframebuffer, aiimageinfo, aibase;

procedure TestBufferAndInfo;
var
  Buffer: TAIFrameBuffer;
  Info: TAIImageInfo;
  Bmp1, Bmp2, Bmp3: TBitmap;
  ReturnedBmp: TBitmap;
begin
  WriteLn('Testing TAIFrameBuffer and TAIImageInfo...');
  Buffer := TAIFrameBuffer.Create(nil);
  Info := TAIImageInfo.Create(nil);
  
  Bmp1 := TBitmap.Create;
  Bmp2 := TBitmap.Create;
  Bmp3 := TBitmap.Create;
  try
    Bmp1.Width := 16; Bmp1.Height := 16;
    Bmp2.Width := 32; Bmp2.Height := 32;
    Bmp3.Width := 64; Bmp3.Height := 64;

    // --- 1. Test TAIImageInfo ---
    WriteLn('Checking TAIImageInfo...');
    if Info.Width <> 0 then raise Exception.Create('Info: default Width should be 0');
    if Info.Height <> 0 then raise Exception.Create('Info: default Height should be 0');

    if not Info.LoadInfoFromBitmap(Bmp1) then
      raise Exception.Create('Info: failed to load from Bmp1: ' + Info.LastError);
    if Info.Width <> 16 then raise Exception.Create('Info: Width should be 16');
    if Info.Height <> 16 then raise Exception.Create('Info: Height should be 16');
    if Info.PixelCount <> 256 then raise Exception.Create('Info: PixelCount should be 256');

    Bmp1.SaveToFile('temp_info.bmp');
    if not Info.LoadInfoFromFile('temp_info.bmp') then
      raise Exception.Create('Info: failed to load from file: ' + Info.LastError);
    if Info.FileName <> 'temp_info.bmp' then raise Exception.Create('Info: FileName wrong');
    if Info.Width <> 16 then raise Exception.Create('Info: Width from file wrong');
    SysUtils.DeleteFile('temp_info.bmp');
    WriteLn('  TAIImageInfo tests passed.');

    // --- 2. Test TAIFrameBuffer ---
    WriteLn('Checking TAIFrameBuffer...');
    if Buffer.MaxFrames <> 2 then raise Exception.Create('Buffer: default MaxFrames should be 2');
    if Buffer.Count <> 0 then raise Exception.Create('Buffer: default Count should be 0');

    // Add Frame 1
    if not Buffer.AddFrame(Bmp1) then
      raise Exception.Create('Buffer: AddFrame(Bmp1) failed: ' + Buffer.LastError);
    if Buffer.Count <> 1 then raise Exception.Create('Buffer: Count should be 1');
    
    ReturnedBmp := Buffer.GetLastFrame;
    if ReturnedBmp.Width <> 16 then raise Exception.Create('Buffer: Last frame Width should be 16');

    // Add Frame 2
    if not Buffer.AddFrame(Bmp2) then
      raise Exception.Create('Buffer: AddFrame(Bmp2) failed: ' + Buffer.LastError);
    if Buffer.Count <> 2 then raise Exception.Create('Buffer: Count should be 2');

    ReturnedBmp := Buffer.GetLastFrame;
    if ReturnedBmp.Width <> 32 then raise Exception.Create('Buffer: Last frame Width should be 32');
    ReturnedBmp := Buffer.GetPreviousFrame;
    if ReturnedBmp.Width <> 16 then raise Exception.Create('Buffer: Previous frame Width should be 16');

    // Add Frame 3 (Circular Buffer overflow)
    // MaxFrames is 2. Bmp1 should be deleted. Count remains 2.
    if not Buffer.AddFrame(Bmp3) then
      raise Exception.Create('Buffer: AddFrame(Bmp3) failed: ' + Buffer.LastError);
    if Buffer.Count <> 2 then raise Exception.Create('Buffer: Count should remain 2 due to circular bounds');

    ReturnedBmp := Buffer.GetLastFrame;
    if ReturnedBmp.Width <> 64 then raise Exception.Create('Buffer: Last frame Width should be 64');
    ReturnedBmp := Buffer.GetPreviousFrame;
    if ReturnedBmp.Width <> 32 then raise Exception.Create('Buffer: Previous frame Width should be 32');

    // Clear Buffer
    Buffer.Clear;
    if Buffer.Count <> 0 then raise Exception.Create('Buffer: Count should be 0 after Clear');
    WriteLn('  TAIFrameBuffer tests passed.');

  finally
    Bmp3.Free;
    Bmp2.Free;
    Bmp1.Free;
    Info.Free;
    Buffer.Free;
  end;
end;

begin
  try
    TestBufferAndInfo;
    WriteLn('test_aiframebuffer COMPLETED SUCCESSFULLY.');
  except
    on E: Exception do
    begin
      WriteLn('TEST FAILED: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
