unit aisipvoiceaudio;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, aisip_types;

function SIPVoiceWAV(const Samples: TAISIPAudioSamples;
  SampleRate: Integer = 8000): RawByteString;
function SIPVoiceReadWAV(const Data: RawByteString): TAISIPAudioSamples;
function SIPVoiceRealTranscript(const Text: string): Boolean;

implementation

procedure Put16(var S: RawByteString; P: Integer; V: Word);
begin
  S[P] := AnsiChar(V and 255); S[P+1] := AnsiChar(V shr 8);
end;

procedure Put32(var S: RawByteString; P: Integer; V: LongWord);
begin
  Put16(S, P, V and 65535); Put16(S, P+2, V shr 16);
end;

function U16(const S: RawByteString; P: Integer): Word;
begin Result := Byte(S[P]) or (Word(Byte(S[P+1])) shl 8); end;

function U32(const S: RawByteString; P: Integer): LongWord;
begin Result := U16(S, P) or (LongWord(U16(S, P+2)) shl 16); end;

function SIPVoiceWAV(const Samples: TAISIPAudioSamples;
  SampleRate: Integer): RawByteString;
var I: Integer;
begin
  if (SampleRate < 8000) or (SampleRate > 96000) or
    (Length(Samples) > SampleRate * 120) then
    raise Exception.Create('Invalid voice PCM size or rate');
  SetLength(Result, 44 + Length(Samples)*2);
  FillChar(Result[1], Length(Result), 0);
  Move('RIFF'[1], Result[1], 4); Put32(Result, 5, Length(Result)-8);
  Move('WAVEfmt '[1], Result[9], 8); Put32(Result, 17, 16);
  Put16(Result, 21, 1); Put16(Result, 23, 1);
  Put32(Result, 25, SampleRate); Put32(Result, 29, SampleRate*2);
  Put16(Result, 33, 2); Put16(Result, 35, 16);
  Move('data'[1], Result[37], 4); Put32(Result, 41, Length(Samples)*2);
  for I := 0 to High(Samples) do Put16(Result, 45+I*2, Word(Samples[I]));
end;

function SIPVoiceReadWAV(const Data: RawByteString): TAISIPAudioSamples;
var P, ChunkSize, Rate, Channels, Bits, FormatCode, Alignment: Integer;
    DataPos, DataSize, Frames, I, J, Index, V, A, B: Integer;
    Position, Fraction: Double;
    Mono: TAISIPAudioSamples;

  function Frame(N: Integer): SmallInt;
  var C, Sample, Sum: Integer;
  begin
    Sum := 0;
    for C := 0 to Channels-1 do
    begin
      J := DataPos + (N*Channels+C)*(Bits div 8);
      if Bits = 8 then Sample := (Integer(Byte(Data[J]))-128)*256
      else begin
        Sample := U16(Data, J);
        if Sample >= 32768 then Dec(Sample, 65536);
      end;
      Inc(Sum, Sample);
    end;
    Result := Sum div Channels;
  end;

begin
  Result := nil;
  if (Length(Data) < 44) or (Length(Data) > 8*1024*1024) or
    (Copy(Data, 1, 4) <> 'RIFF') or (Copy(Data, 9, 4) <> 'WAVE') then
    raise Exception.Create('TTS must return a RIFF/WAVE file');
  if Int64(U32(Data, 5))+8 <> Length(Data) then
    raise Exception.Create('Truncated or inconsistent WAV size');
  Rate := 0; Channels := 0; Bits := 0; FormatCode := 0; Alignment := 0;
  DataPos := 0; DataSize := 0; P := 13;
  while P+7 <= Length(Data) do
  begin
    if Int64(U32(Data, P+4)) > Length(Data)-P-7 then
      raise Exception.Create('Truncated WAV chunk');
    ChunkSize := U32(Data, P+4);
    if Copy(Data, P, 4) = 'fmt ' then
    begin
      if ChunkSize < 16 then raise Exception.Create('Invalid WAV format chunk');
      FormatCode := U16(Data, P+8); Channels := U16(Data, P+10);
      if U32(Data, P+12) > 96000 then raise Exception.Create('Invalid WAV rate');
      Rate := U32(Data, P+12); Alignment := U16(Data, P+20);
      Bits := U16(Data, P+22);
    end;
    if (Copy(Data, P, 4) = 'data') and (DataPos = 0) then
    begin DataPos := P+8; DataSize := ChunkSize; end;
    Inc(P, 8+ChunkSize+(ChunkSize mod 2));
  end;
  if (FormatCode <> 1) or not (Channels in [1, 2]) or
    not (Bits in [8, 16]) or (Rate < 8000) or (Rate > 96000) or
    (Alignment <> Channels*(Bits div 8)) or (DataPos = 0) or
    (DataSize = 0) then raise Exception.Create('Unsupported WAV: use 8/16-bit PCM, mono/stereo, 8..96 kHz');
  if (DataSize mod Alignment <> 0) or (DataSize div Alignment > Rate*120) then
    raise Exception.Create('Invalid or oversized WAV audio');
  Frames := DataSize div Alignment;
  SetLength(Mono, Frames);
  for I := 0 to Frames-1 do Mono[I] := Frame(I);
  { A low-pass filter before decimation reduces high-frequency aliasing.
    This keeps the service independent of a sound device or external process. }
  if Rate > 8000 then
  begin
    V := Mono[0];
    for I := 1 to Frames-1 do
    begin
      V := V + Round((Mono[I]-V) * (8000.0 / Rate)); Mono[I] := V;
    end;
  end;
  SetLength(Result, Int64(Frames)*8000 div Rate);
  for I := 0 to High(Result) do
  begin
    Position := I * (Rate / 8000.0); Index := Trunc(Position);
    Fraction := Position-Index; A := Mono[Index]; B := A;
    if Index+1 < Frames then B := Mono[Index+1];
    Result[I] := Round(A+(B-A)*Fraction);
  end;
end;

function SIPVoiceRealTranscript(const Text: string): Boolean;
var S: string;
begin
  S := LowerCase(Trim(Text));
  Result := (S <> '') and (Length(S) <= 16000) and
    (Pos('udio recebido e processado pelo parakeet stt', S) = 0);
end;

end.
