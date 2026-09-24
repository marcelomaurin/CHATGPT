program test_wavein_event;
{ objfpc}{+}
uses
  Windows, MMSystem, SysUtils;
var
  hIn: HWAVEIN;
  wfx: WAVEFORMATEX;
  hEvt: THandle;
  mmRes: MMRESULT;
begin
  hEvt := CreateEvent(nil, False, False, nil);
  wfx.wFormatTag := WAVE_FORMAT_PCM;
  wfx.nChannels := 1;
  wfx.nSamplesPerSec := 16000;
  wfx.wBitsPerSample := 16;
  wfx.nBlockAlign := 2;
  wfx.nAvgBytesPerSec := 32000;
  wfx.cbSize := 0;
  
  // Test waveInGetNumDevs
  if waveInGetNumDevs > 0 then
  begin
    mmRes := waveInOpen(@hIn, WAVE_MAPPER, @wfx, DWORD_PTR(hEvt), 0, CALLBACK_EVENT);
    if mmRes = MMSYSERR_NOERROR then
    begin
      Writeln('waveInOpen succeeded with CALLBACK_EVENT');
      waveInClose(hIn);
    end
    else
      Writeln('waveInOpen returned: ', mmRes);
  end
  else
    Writeln('No waveIn devices');
  CloseHandle(hEvt);
end.
