unit aihardwarelinux;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

var
  AIHardwareProcRoot: string;
  AIHardwareSysRoot: string;
  AIHardwareEtcRoot: string;

procedure ResetAIHardwareLinuxRoots;
function AIHardwareProcPath(const ARelativePath: string): string;
function AIHardwareSysPath(const ARelativePath: string): string;
function AIHardwareEtcPath(const ARelativePath: string): string;
function AIReadFirstLine(const AFileName: string; out AValue: string): Boolean;
function AITryReadQWord(const AFileName: string; out AValue: QWord): Boolean;
function AIUnquote(const AValue: string): string;
function AIDecodeMountPath(const AValue: string): string;
procedure AIAppendMessage(var AMessages: string; const AMessage: string);

implementation

function RootedPath(const ARoot, ARelativePath: string): string;
var
  RelativePath: string;
begin
  RelativePath := StringReplace(ARelativePath, '/', DirectorySeparator,
    [rfReplaceAll]);
  while (RelativePath <> '') and
    (RelativePath[1] in ['/', '\']) do
    Delete(RelativePath, 1, 1);
  Result := IncludeTrailingPathDelimiter(ARoot) + RelativePath;
end;

procedure ResetAIHardwareLinuxRoots;
begin
  AIHardwareProcRoot := '/proc';
  AIHardwareSysRoot := '/sys';
  AIHardwareEtcRoot := '/etc';
end;

function AIHardwareProcPath(const ARelativePath: string): string;
begin
  Result := RootedPath(AIHardwareProcRoot, ARelativePath);
end;

function AIHardwareSysPath(const ARelativePath: string): string;
begin
  Result := RootedPath(AIHardwareSysRoot, ARelativePath);
end;

function AIHardwareEtcPath(const ARelativePath: string): string;
begin
  Result := RootedPath(AIHardwareEtcRoot, ARelativePath);
end;

function AIReadFirstLine(const AFileName: string; out AValue: string): Boolean;
var
  Lines: TStringList;
begin
  AValue := '';
  Result := False;
  if not FileExists(AFileName) then
    Exit;

  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(AFileName);
      if Lines.Count = 0 then
        Exit;
      AValue := Trim(Lines[0]);
      Result := True;
    except
      Result := False;
    end;
  finally
    Lines.Free;
  end;
end;

function AITryReadQWord(const AFileName: string; out AValue: QWord): Boolean;
var
  TextValue: string;
begin
  AValue := 0;
  Result := AIReadFirstLine(AFileName, TextValue) and
    TryStrToQWord(Trim(TextValue), AValue);
end;

function AIUnquote(const AValue: string): string;
begin
  Result := Trim(AValue);
  if (Length(Result) >= 2) and
    (((Result[1] = '"') and (Result[Length(Result)] = '"')) or
     ((Result[1] = '''') and (Result[Length(Result)] = ''''))) then
    Result := Copy(Result, 2, Length(Result) - 2);
  Result := StringReplace(Result, '\"', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '\\', '\', [rfReplaceAll]);
end;

function AIDecodeMountPath(const AValue: string): string;
begin
  Result := StringReplace(AValue, '\040', ' ', [rfReplaceAll]);
  Result := StringReplace(Result, '\011', #9, [rfReplaceAll]);
  Result := StringReplace(Result, '\012', #10, [rfReplaceAll]);
  Result := StringReplace(Result, '\134', '\', [rfReplaceAll]);
end;

procedure AIAppendMessage(var AMessages: string; const AMessage: string);
begin
  if Trim(AMessage) = '' then
    Exit;
  if AMessages <> '' then
    AMessages := AMessages + '; ';
  AMessages := AMessages + AMessage;
end;

initialization
  ResetAIHardwareLinuxRoots;

end.
