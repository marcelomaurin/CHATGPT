unit fgx_pascal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl;

type
  TPascalRef = class
  public
    Name: string;
    Line: Integer;
  end;

  TPascalClass = class
  public
    Name: string;
    Ancestor: string;
    Line: Integer;
  end;

  TComponentRegistration = class
  public
    Palette: string;
    ClassName: string;
    Line: Integer;
  end;

  TPascalRefList = specialize TFPGObjectList<TPascalRef>;
  TPascalClassList = specialize TFPGObjectList<TPascalClass>;
  TRegistrationList = specialize TFPGObjectList<TComponentRegistration>;

  TPascalUnitInfo = class
  public
    UnitName: string;
    InterfaceUses: TPascalRefList;
    ImplementationUses: TPascalRefList;
    PublicClasses: TPascalClassList;
    Registrations: TRegistrationList;
    ParseErrors: TStringList;
    constructor Create;
    destructor Destroy; override;
  end;

function ParsePascalUnit(const AFileName: string): TPascalUnitInfo;
function FileContainsIdentifier(const AFileName, AIdentifier: string;
                                out ALine: Integer): Boolean;

implementation

type
  TToken = class
  public
    Text: string;
    Line: Integer;
  end;
  TTokenList = specialize TFPGObjectList<TToken>;

constructor TPascalUnitInfo.Create;
begin
  inherited Create;
  InterfaceUses := TPascalRefList.Create(True);
  ImplementationUses := TPascalRefList.Create(True);
  PublicClasses := TPascalClassList.Create(True);
  Registrations := TRegistrationList.Create(True);
  ParseErrors := TStringList.Create;
end;

destructor TPascalUnitInfo.Destroy;
begin
  ParseErrors.Free;
  Registrations.Free;
  PublicClasses.Free;
  ImplementationUses.Free;
  InterfaceUses.Free;
  inherited Destroy;
end;

function IsIdentStart(C: Char): Boolean;
begin
  Result := (C = '_') or (C in ['A'..'Z', 'a'..'z']);
end;

function IsIdentChar(C: Char): Boolean;
begin
  Result := IsIdentStart(C) or (C in ['0'..'9']);
end;

procedure AddToken(AList: TTokenList; const S: string; ALine: Integer);
var
  T: TToken;
begin
  T := TToken.Create;
  T.Text := S;
  T.Line := ALine;
  AList.Add(T);
end;

{ Lexer pequeno: comentarios, strings e diretivas desaparecem, mas linhas sao
  preservadas. Assim palavras dentro deles nunca viram fatos. }
function Tokenize(const S: string): TTokenList;
var
  I, L, Line, Start: Integer;
  StrValue: string;
  C: Char;
begin
  Result := TTokenList.Create(True);
  I := 1;
  L := Length(S);
  Line := 1;
  while I <= L do
  begin
    C := S[I];
    if C in [#10, #13] then
    begin
      if (C = #10) then Inc(Line);
      Inc(I);
    end
    else if (C = '/') and (I < L) and (S[I + 1] = '/') then
    begin
      Inc(I, 2);
      while (I <= L) and not (S[I] in [#10, #13]) do Inc(I);
    end
    else if (C = '{') then
    begin
      Inc(I);
      while (I <= L) and (S[I] <> '}') do
      begin
        if S[I] = #10 then Inc(Line);
        Inc(I);
      end;
      if I <= L then Inc(I);
    end
    else if (C = '(') and (I < L) and (S[I + 1] = '*') then
    begin
      Inc(I, 2);
      while (I < L) and not ((S[I] = '*') and (S[I + 1] = ')')) do
      begin
        if S[I] = #10 then Inc(Line);
        Inc(I);
      end;
      if I < L then Inc(I, 2);
    end
    else if C = '''' then
    begin
      StrValue := '';
      Inc(I);
      while I <= L do
      begin
        if S[I] = #10 then Inc(Line);
        if S[I] = '''' then
        begin
          if (I < L) and (S[I + 1] = '''') then
          begin
            StrValue := StrValue + '''';
            Inc(I, 2);
          end
          else begin Inc(I); Break; end;
        end
        else begin StrValue := StrValue + S[I]; Inc(I); end;
      end;
      AddToken(Result, '@str:' + StrValue, Line);
    end
    else if IsIdentStart(C) then
    begin
      Start := I;
      Inc(I);
      while (I <= L) and IsIdentChar(S[I]) do Inc(I);
      AddToken(Result, Copy(S, Start, I - Start), Line);
    end
    else if C in [';', ',', ':', '=', '(', ')', '[', ']'] then
    begin
      AddToken(Result, C, Line);
      Inc(I);
    end
    else
      Inc(I);
  end;
end;

function SameToken(T: TToken; const S: string): Boolean;
begin
  Result := SameText(T.Text, S);
end;

procedure AddRef(AList: TPascalRefList; const AName: string; ALine: Integer);
var
  I: Integer;
  R: TPascalRef;
begin
  for I := 0 to AList.Count - 1 do
    if SameText(AList[I].Name, AName) then Exit;
  R := TPascalRef.Create;
  R.Name := AName;
  R.Line := ALine;
  AList.Add(R);
end;

procedure ParseUses(Tokens: TTokenList; AStart, AEnd: Integer;
                    AList: TPascalRefList);
var
  I: Integer;
  InUses, WantName: Boolean;
begin
  InUses := False;
  WantName := False;
  I := AStart;
  while I < AEnd do
  begin
    if SameToken(Tokens[I], 'uses') then
    begin
      InUses := True;
      WantName := True;
    end
    else if InUses and (Tokens[I].Text = ';') then
    begin
      InUses := False;
      WantName := False;
    end
    else if InUses and (Tokens[I].Text = ',') then
      WantName := True
    else if InUses and WantName and IsIdentStart(Tokens[I].Text[1]) then
    begin
      AddRef(AList, Tokens[I].Text, Tokens[I].Line);
      WantName := False;
    end;
    Inc(I);
  end;
end;

procedure ParseClasses(Tokens: TTokenList; AStart, AEnd: Integer;
                       AList: TPascalClassList);
var
  I: Integer;
  C: TPascalClass;
begin
  I := AStart;
  while I + 4 < AEnd do
  begin
    if IsIdentStart(Tokens[I].Text[1]) and (Tokens[I + 1].Text = '=') and
       SameToken(Tokens[I + 2], 'class') and (Tokens[I + 3].Text = '(') and
       IsIdentStart(Tokens[I + 4].Text[1]) then
    begin
      C := TPascalClass.Create;
      C.Name := Tokens[I].Text;
      C.Ancestor := Tokens[I + 4].Text;
      C.Line := Tokens[I].Line;
      AList.Add(C);
    end;
    Inc(I);
  end;
end;

procedure ParseRegistrations(Tokens: TTokenList; AList: TRegistrationList);
var
  I, J: Integer;
  Palette: string;
  R: TComponentRegistration;
begin
  I := 0;
  while I + 4 < Tokens.Count do
  begin
    if SameToken(Tokens[I], 'RegisterComponents') and
       (Tokens[I + 1].Text = '(') then
    begin
      Palette := '';
      J := I + 2;
      if (J < Tokens.Count) and (Copy(Tokens[J].Text, 1, 5) = '@str:') then
        Palette := Copy(Tokens[J].Text, 6, MaxInt);
      while (J < Tokens.Count) and (Tokens[J].Text <> '[') and
            (Tokens[J].Text <> ';') do Inc(J);
      if (J < Tokens.Count) and (Tokens[J].Text = '[') then
      begin
        Inc(J);
        while (J < Tokens.Count) and (Tokens[J].Text <> ']') do
        begin
          if IsIdentStart(Tokens[J].Text[1]) then
          begin
            R := TComponentRegistration.Create;
            R.Palette := Palette;
            R.ClassName := Tokens[J].Text;
            R.Line := Tokens[I].Line;
            AList.Add(R);
          end;
          Inc(J);
        end;
      end;
    end;
    Inc(I);
  end;
end;

function ParsePascalUnit(const AFileName: string): TPascalUnitInfo;
var
  SL: TStringList;
  Tokens: TTokenList;
  I, IntfAt, ImplAt: Integer;
begin
  Result := TPascalUnitInfo.Create;
  SL := TStringList.Create;
  Tokens := nil;
  try
    try
      SL.LoadFromFile(AFileName);
      Tokens := Tokenize(SL.Text);
      IntfAt := -1;
      ImplAt := Tokens.Count;
      for I := 0 to Tokens.Count - 1 do
      begin
        if SameToken(Tokens[I], 'unit') and (I + 1 < Tokens.Count) and
           (Result.UnitName = '') then Result.UnitName := Tokens[I + 1].Text;
        if SameToken(Tokens[I], 'interface') and (IntfAt < 0) then IntfAt := I;
        if SameToken(Tokens[I], 'implementation') then begin ImplAt := I; Break; end;
      end;
      if IntfAt < 0 then IntfAt := 0;
      ParseUses(Tokens, IntfAt, ImplAt, Result.InterfaceUses);
      ParseUses(Tokens, ImplAt, Tokens.Count, Result.ImplementationUses);
      ParseClasses(Tokens, IntfAt, ImplAt, Result.PublicClasses);
      ParseRegistrations(Tokens, Result.Registrations);
    except
      on E: Exception do Result.ParseErrors.Add(E.Message);
    end;
  finally
    Tokens.Free;
    SL.Free;
  end;
end;

function FileContainsIdentifier(const AFileName, AIdentifier: string;
                                out ALine: Integer): Boolean;
var
  SL: TStringList;
  Tokens: TTokenList;
  I: Integer;
begin
  Result := False;
  ALine := 0;
  SL := TStringList.Create;
  Tokens := nil;
  try
    try
      SL.LoadFromFile(AFileName);
      Tokens := Tokenize(SL.Text);
      for I := 0 to Tokens.Count - 1 do
        if SameText(Tokens[I].Text, AIdentifier) then
        begin
          ALine := Tokens[I].Line;
          Exit(True);
        end;
    except
      Exit(False);
    end;
  finally
    Tokens.Free;
    SL.Free;
  end;
end;

end.
