unit airag_textutils;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Math, LazUTF8;

type
  TAIRAGChunkMetadata = record
    Source: string;
    ChunkIndex: Integer;
    StartOffset: Integer;
    EndOffset: Integer;
    Page: Integer;
    Section: string;
  end;

function AIRAGTokenizeUnicode(const AText: string): TStringList;
procedure AIRAGSemanticChunks(const AText: string; AChunkSize, AOverlap: Integer;
  AChunks: TStrings);
function AIRAGEstimateTokens(const AText: string): Integer;

implementation

function IsWordCodePoint(C: WideChar): Boolean;
var
  V: Word;
begin
  V := Ord(C);
  Result :=
    ((C >= 'a') and (C <= 'z')) or
    ((C >= 'A') and (C <= 'Z')) or
    ((C >= '0') and (C <= '9')) or
    (C = '_') or
    ((V >= $00C0) and (V <= $02AF)) or
    ((V >= $0370) and (V <= $052F)) or
    ((V >= $1E00) and (V <= $1EFF));
end;

function AIRAGTokenizeUnicode(const AText: string): TStringList;
var
  W: UnicodeString;
  Token: UnicodeString;
  I: Integer;
  Encoded: string;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  W := UTF8Decode(AText);
  Token := '';
  for I := 1 to Length(W) do
  begin
    if IsWordCodePoint(W[I]) then
      Token := Token + W[I]
    else if Token <> '' then
    begin
      Encoded := UTF8LowerCase(UTF8Encode(Token));
      Result.Add(Encoded);
      Token := '';
    end;
  end;
  if Token <> '' then
    Result.Add(UTF8LowerCase(UTF8Encode(Token)));
end;

function NormalizeBreaks(const S: string): string;
begin
  Result := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
end;

function BestBoundary(const S: string; AMaximum: Integer): Integer;
var
  I, Minimum: Integer;
begin
  if Length(S) <= AMaximum then Exit(Length(S));
  Minimum := Max(1, AMaximum div 2);
  for I := AMaximum downto Minimum do
    if S[I] in [#10, '.', '!', '?', ';', ':'] then Exit(I);
  for I := AMaximum downto Minimum do
    if S[I] in [' ', #9] then Exit(I);
  Result := AMaximum;
end;

function OverlapTail(const S: string; AOverlap: Integer): string;
var
  P, I: Integer;
begin
  Result := '';
  if (AOverlap <= 0) or (S = '') then Exit;
  P := Max(1, Length(S) - AOverlap + 1);
  for I := P to Length(S) do
    if S[I] in [' ', #9, #10, '.', '!', '?', ';', ':'] then
    begin
      P := I + 1;
      Break;
    end;
  if P <= Length(S) then Result := Copy(S, P, MaxInt);
end;

procedure AIRAGSemanticChunks(const AText: string; AChunkSize, AOverlap: Integer;
  AChunks: TStrings);
var
  Remaining, Chunk, Tail: string;
  CutAt: Integer;
begin
  if AChunks = nil then Exit;
  AChunks.Clear;
  AChunkSize := Max(50, AChunkSize);
  AOverlap := Max(0, Min(AOverlap, AChunkSize div 2));
  Remaining := Trim(NormalizeBreaks(AText));

  while Remaining <> '' do
  begin
    CutAt := BestBoundary(Remaining, AChunkSize);
    Chunk := Trim(Copy(Remaining, 1, CutAt));
    if Chunk = '' then
    begin
      Delete(Remaining, 1, Max(1, CutAt));
      Remaining := TrimLeft(Remaining);
      Continue;
    end;

    AChunks.Add(Chunk);
    Delete(Remaining, 1, CutAt);
    Remaining := TrimLeft(Remaining);

    if Remaining <> '' then
    begin
      Tail := OverlapTail(Chunk, AOverlap);
      if Tail <> '' then Remaining := Tail + LineEnding + Remaining;
    end;
  end;
end;

function AIRAGEstimateTokens(const AText: string): Integer;
var
  Tokens: TStringList;
begin
  Tokens := AIRAGTokenizeUnicode(AText);
  try
    Result := Max(1, Tokens.Count);
  finally
    Tokens.Free;
  end;
end;

end.
