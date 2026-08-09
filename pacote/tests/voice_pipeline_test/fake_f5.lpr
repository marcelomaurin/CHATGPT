program fake_f5;

{$mode objfpc}{$H+}

uses Classes, SysUtils;

procedure WriteWav(const AFileName: string);
var
  S: TFileStream;
  H: array[0..43] of Byte;
  RiffSize, DataSize, FmtSize, SampleRate, ByteRate: LongWord;
  AudioFormat, Channels, BlockAlign, Bits: Word;
  Z: array[0..319] of Byte;
begin
  FillChar(H, SizeOf(H), 0); FillChar(Z, SizeOf(Z), 0);
  Move('RIFF'[1], H[0], 4); Move('WAVE'[1], H[8], 4); Move('fmt '[1], H[12], 4);
  FmtSize := 16; AudioFormat := 1; Channels := 1; SampleRate := 16000;
  Bits := 16; BlockAlign := 2; ByteRate := 32000; DataSize := SizeOf(Z); RiffSize := 36 + DataSize;
  Move(RiffSize, H[4], 4); Move(FmtSize, H[16], 4); Move(AudioFormat, H[20], 2);
  Move(Channels, H[22], 2); Move(SampleRate, H[24], 4); Move(ByteRate, H[28], 4);
  Move(BlockAlign, H[32], 2); Move(Bits, H[34], 2); Move('data'[1], H[36], 4);
  Move(DataSize, H[40], 4);
  ForceDirectories(ExtractFileDir(ExpandFileName(AFileName)));
  S := TFileStream.Create(AFileName, fmCreate);
  try S.WriteBuffer(H, SizeOf(H)); S.WriteBuffer(Z, SizeOf(Z)); finally S.Free; end;
end;

var I: Integer; OutputFile: string;
begin
  OutputFile := '';
  for I := 1 to ParamCount - 1 do
    if ParamStr(I) = '--output_file' then OutputFile := ParamStr(I + 1);
  if OutputFile = '' then Halt(2);
  WriteWav(OutputFile);
  Writeln('generated=', OutputFile);
end.
