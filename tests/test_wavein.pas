program test_wavein;
{ objfpc}{+}
uses
  Windows, MMSystem, SysUtils;
var
  hIn: HWAVEIN;
  wfx: WAVEFORMATEX;
  hdr: WAVEHDR;
begin
  wfx.wFormatTag := WAVE_FORMAT_PCM;
  wfx.nChannels := 1;
  wfx.nSamplesPerSec := 16000;
  wfx.wBitsPerSample := 16;
  wfx.nBlockAlign := 2;
  wfx.nAvgBytesPerSec := 32000;
  wfx.cbSize := 0;
  Writeln('WAVEFORMATEX initialized');
end.
