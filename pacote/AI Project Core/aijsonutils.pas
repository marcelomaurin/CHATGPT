unit aijsonutils;

{ Lazarus AI Suite - AI Project Core
  Utilitarios JSON para formatos de documento versionados (generico, sem LCL).

  - Leitura tipada com erro claro: AIJSONStr/Int64/Bool/Obj/Arr/Date levantam
    EAIJSONFormat quando o campo existe com tipo errado; ausente ou null usa
    o padrao.
  - AIJSONMergeKnown: grava um documento preservando campos que o programa
    nao conhece (de versoes mais novas ou de outras ferramentas), mantendo a
    ordem original das chaves e mesclando objetos aninhados.
  - Datas ISO 8601 locais sem fuso (AAAA-MM-DDTHH:MM:SS).
  - Gravacao atomica: grava em <arquivo>.tmp, valida e so entao substitui.

  Nenhuma funcao depende da configuracao regional (separador decimal). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

type
  EAIJSONFormat = class(Exception);

  { valida o texto gravado antes de substituir o arquivo; levante excecao se invalido }
  TAITextValidator = procedure(const AText: string) of object;

function AIJSONStr(O: TJSONObject; const K: string; const Def: string = ''): string;
function AIJSONInt64(O: TJSONObject; const K: string; Def: Int64): Int64;
function AIJSONBool(O: TJSONObject; const K: string; Def: Boolean): Boolean;
function AIJSONObj(O: TJSONObject; const K: string): TJSONObject;
function AIJSONArr(O: TJSONObject; const K: string): TJSONArray;
function AIJSONDate(O: TJSONObject; const K: string): TDateTime;
function AIJSONInt(V: Int64): TJSONData;

function AIJSONMergeKnown(Original, Known: TJSONObject): TJSONObject;
function AIJSONParseObject(const Text: string): TJSONObject;
function AIJSONFormat(O: TJSONData): string;

function AIDateToISO(D: TDateTime): string;
function AITryISOToDate(const S: string; out D: TDateTime): Boolean;

function AIReadTextFile(const FileName: string): string;
procedure AIWriteTextFile(const FileName, Text: string);
procedure AISaveTextFileAtomic(const FileName, Text: string; Validator: TAITextValidator);

implementation

{ ---------------- leitura tipada ---------------- }

function AIJSONStr(O: TJSONObject; const K: string; const Def: string): string;
var D: TJSONData;
begin
  D := O.Find(K);
  if (D = nil) or (D.JSONType = jtNull) then Exit(Def);
  if D.JSONType in [jtObject, jtArray] then
    raise EAIJSONFormat.CreateFmt('campo "%s" deveria ser texto', [K]);
  Result := D.AsString;
end;

function AIJSONInt64(O: TJSONObject; const K: string; Def: Int64): Int64;
var D: TJSONData;
begin
  D := O.Find(K);
  if (D = nil) or (D.JSONType = jtNull) then Exit(Def);
  if D.JSONType <> jtNumber then
    raise EAIJSONFormat.CreateFmt('campo "%s" deveria ser numero', [K]);
  Result := D.AsInt64;
end;

function AIJSONBool(O: TJSONObject; const K: string; Def: Boolean): Boolean;
var D: TJSONData;
begin
  D := O.Find(K);
  if (D = nil) or (D.JSONType = jtNull) then Exit(Def);
  if D.JSONType <> jtBoolean then
    raise EAIJSONFormat.CreateFmt('campo "%s" deveria ser verdadeiro/falso', [K]);
  Result := D.AsBoolean;
end;

function AIJSONObj(O: TJSONObject; const K: string): TJSONObject;
var D: TJSONData;
begin
  D := O.Find(K);
  if (D = nil) or (D.JSONType = jtNull) then Exit(nil);
  if D.JSONType <> jtObject then
    raise EAIJSONFormat.CreateFmt('campo "%s" deveria ser objeto', [K]);
  Result := TJSONObject(D);
end;

function AIJSONArr(O: TJSONObject; const K: string): TJSONArray;
var D: TJSONData;
begin
  D := O.Find(K);
  if (D = nil) or (D.JSONType = jtNull) then Exit(nil);
  if D.JSONType <> jtArray then
    raise EAIJSONFormat.CreateFmt('campo "%s" deveria ser lista', [K]);
  Result := TJSONArray(D);
end;

function AIJSONDate(O: TJSONObject; const K: string): TDateTime;
var S: string;
begin
  S := AIJSONStr(O, K);
  if not AITryISOToDate(S, Result) then
    raise EAIJSONFormat.CreateFmt('data invalida em "%s": "%s" (use AAAA-MM-DDTHH:MM:SS)', [K, S]);
end;

function AIJSONInt(V: Int64): TJSONData;
begin
  if (V >= Low(Integer)) and (V <= High(Integer)) then
    Result := TJSONIntegerNumber.Create(V)
  else
    Result := TJSONInt64Number.Create(V);
end;

{ ---------------- mescla ---------------- }

function AIJSONMergeKnown(Original, Known: TJSONObject): TJSONObject;
var
  I, K: Integer;
  Key: string;
  KV, OV: TJSONData;
begin
  { Known e consumido. Sem original, o resultado e o proprio Known. }
  if Original = nil then Exit(Known);
  Result := TJSONObject.Create;
  try
    for I := 0 to Original.Count - 1 do
    begin
      Key := Original.Names[I];
      OV := Original.Items[I];
      K := Known.IndexOfName(Key);
      if K < 0 then
        Result.Add(Key, OV.Clone)
      else
      begin
        KV := Known.Extract(K);
        if (KV.JSONType = jtObject) and (OV.JSONType = jtObject) then
          Result.Add(Key, AIJSONMergeKnown(TJSONObject(OV), TJSONObject(KV)))
        else
          Result.Add(Key, KV);
      end;
    end;
    while Known.Count > 0 do
    begin
      Key := Known.Names[0];
      Result.Add(Key, Known.Extract(0));
    end;
  finally
    Known.Free;
  end;
end;

function AIJSONParseObject(const Text: string): TJSONObject;
var D: TJSONData;
begin
  try
    D := GetJSON(Text, True);
  except
    on E: Exception do
      raise EAIJSONFormat.Create('JSON invalido: ' + E.Message);
  end;
  if (D = nil) or (D.JSONType <> jtObject) then
  begin
    D.Free;
    raise EAIJSONFormat.Create('o conteudo deve ser um objeto JSON');
  end;
  Result := TJSONObject(D);
end;

function AIJSONFormat(O: TJSONData): string;
begin
  Result := O.FormatJSON([], 2) + LineEnding;
end;

{ ---------------- datas ---------------- }

function AIDateToISO(D: TDateTime): string;
begin
  if D = 0 then Exit('');
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', D);
end;

function AITryISOToDate(const S: string; out D: TDateTime): Boolean;
var
  Y, M, Dd, H, N, Sec: Integer;
  T: string;
  DPart, TPart: TDateTime;
begin
  D := 0;
  T := Trim(S);
  if T = '' then Exit(True);
  Result := False;
  if (Length(T) < 10) or (T[5] <> '-') or (T[8] <> '-') then Exit;
  Y := StrToIntDef(Copy(T, 1, 4), -1);
  M := StrToIntDef(Copy(T, 6, 2), -1);
  Dd := StrToIntDef(Copy(T, 9, 2), -1);
  H := 0; N := 0; Sec := 0;
  if Length(T) > 10 then
  begin
    if not (T[11] in ['T', 't', ' ']) or (Length(T) < 16) or (T[14] <> ':') then Exit;
    H := StrToIntDef(Copy(T, 12, 2), -1);
    N := StrToIntDef(Copy(T, 15, 2), -1);
    if Length(T) >= 19 then
    begin
      if T[17] <> ':' then Exit;
      Sec := StrToIntDef(Copy(T, 18, 2), -1);
    end;
  end;
  if not TryEncodeDate(Y, M, Dd, DPart) then Exit;
  if not TryEncodeTime(H, N, Sec, 0, TPart) then Exit;
  D := DPart + TPart;
  Result := True;
end;

{ ---------------- arquivos ---------------- }

function AIReadTextFile(const FileName: string): string;
var F: TFileStream;
begin
  F := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, F.Size);
    if F.Size > 0 then F.ReadBuffer(Result[1], F.Size);
  finally
    F.Free;
  end;
end;

procedure AIWriteTextFile(const FileName, Text: string);
var F: TFileStream;
begin
  F := TFileStream.Create(FileName, fmCreate);
  try
    if Text <> '' then F.WriteBuffer(Text[1], Length(Text));
  finally
    F.Free;
  end;
end;

procedure AISaveTextFileAtomic(const FileName, Text: string; Validator: TAITextValidator);
var Tmp, Bak: string;
begin
  Tmp := FileName + '.tmp';
  Bak := FileName + '.bak';
  AIWriteTextFile(Tmp, Text);
  if Assigned(Validator) then
    try
      Validator(AIReadTextFile(Tmp));
    except
      DeleteFile(Tmp);
      raise;
    end;
  if FileExists(Bak) then DeleteFile(Bak);
  { no Windows RenameFile nao substitui: guarda o atual como .bak primeiro }
  if FileExists(FileName) and not RenameFile(FileName, Bak) then
  begin
    DeleteFile(Tmp);
    raise EInOutError.CreateFmt('nao foi possivel substituir %s', [FileName]);
  end;
  if not RenameFile(Tmp, FileName) then
  begin
    if FileExists(Bak) then RenameFile(Bak, FileName);
    raise EInOutError.CreateFmt('nao foi possivel gravar %s', [FileName]);
  end;
  if FileExists(Bak) then DeleteFile(Bak);
end;

end.
