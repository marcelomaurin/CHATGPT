unit aiwifi;

{ TAIWifi
  -------
  Busca e conexão a redes Wi-Fi, para aplicações que falam com aparelhos que
  criam o próprio ponto de acesso (drones, câmeras, placas ESP32, impressoras).

    Wifi.Scan;                                   // varre e preenche Networks
    if Wifi.FindNetwork('FQ777*;MEUDRONE', Rede) then
      Wifi.Connect(Rede.SSID, '');               // '' = rede aberta
    Wifi.WaitForConnection(Rede.SSID, 15000);

  Windows: dispara uma varredura nova pela wlanapi.dll e usa o netsh para
  listar e conectar (cria um perfil com conexão MANUAL, para o Windows não
  voltar sozinho para a rede do aparelho depois).
  Linux: usa o nmcli (NetworkManager).

  A leitura da saída do netsh tolera Windows em português, inglês e espanhol.
  Durante as esperas, OnWait é chamado a cada ~100 ms (use para manter a
  interface respondendo). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process
  {$IFDEF WINDOWS}, Windows, DynLibs{$ENDIF};

type
  TAIWifiNetwork = record
    SSID: string;
    BSSID: string;
    Signal: Integer;     // 0..100 (%)
    Secured: Boolean;
    Security: string;
    Connected: Boolean;  // preenchido no Linux; no Windows use CurrentSSID
  end;
  TAIWifiNetworks = array of TAIWifiNetwork;

  { TAIWifi }

  TAIWifi = class(TComponent)
  private
    FNetworks: TAIWifiNetworks;
    FLastError: string;
    FInterfaceName: string;
    FOnWait: TNotifyEvent;
    FOnLog: TGetStrProc;
    procedure DoLog(const AMsg: string);
    procedure Wait(AMs: Integer);
    function Run(const AExe: string; const AArgs: array of string;
      out AOutput: string): Boolean;
    {$IFDEF WINDOWS}
    function TriggerWindowsScan: Boolean;
    {$ENDIF}
  public
    { Varre as redes ao alcance. ARefresh força uma varredura nova (leva
      alguns segundos). }
    function Scan(ARefresh: Boolean = True): Boolean;
    { SSID da rede conectada agora ('' se nenhuma). }
    function CurrentSSID: string;
    function IsConnectedTo(const ASSID: string): Boolean;
    { Conecta a uma rede. APassword vazio = rede aberta. }
    function Connect(const ASSID: string; const APassword: string = ''): Boolean;
    { Reconecta a uma rede cujo perfil já está salvo no sistema, sem alterar
      o perfil (use para voltar à rede anterior). Não espera a conexão. }
    function ConnectExisting(const ASSID: string): Boolean;
    { Espera até estar conectado a ASSID. }
    function WaitForConnection(const ASSID: string; ATimeoutMs: Integer): Boolean;
    { Rede de maior sinal em Networks que combine com APatterns. }
    function FindNetwork(const APatterns: string; out ANetwork: TAIWifiNetwork): Boolean;

    { Padrões separados por ';'. Com '*' ou '?' vale como máscara; sem
      curingas, basta o SSID conter o texto. Sem diferenciar maiúsculas. }
    class function MatchesPattern(const ASSID, APatterns: string): Boolean; static;
    class function ParseNetshNetworks(const AText: string): TAIWifiNetworks; static;
    class function ParseNetshCurrentSSID(const AText: string): string; static;
    class function ParseNmcliNetworks(const AText: string): TAIWifiNetworks; static;
    class function BuildWindowsProfileXml(const ASSID, APassword: string): string; static;

    property Networks: TAIWifiNetworks read FNetworks;
    property LastError: string read FLastError;
  published
    { Placa Wi-Fi a usar ('' = a padrão do sistema). }
    property InterfaceName: string read FInterfaceName write FInterfaceName;
    property OnWait: TNotifyEvent read FOnWait write FOnWait;
    property OnLog: TGetStrProc read FOnLog write FOnLog;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAIWifi]);
end;

{ ---------- auxiliares de texto ---------- }

function SplitKeyValue(const ALine: string; out AKey, AValue: string): Boolean;
var
  P: Integer;
begin
  P := Pos(':', ALine);
  Result := P > 0;
  if Result then
  begin
    AKey := Trim(Copy(ALine, 1, P - 1));
    AValue := Trim(Copy(ALine, P + 1, MaxInt));
  end
  else
  begin
    AKey := '';
    AValue := '';
  end;
end;

function KeyIsNumbered(const AKey, AWord: string): Boolean;
{ 'SSID 3' para AWord = 'SSID' }
var
  Rest: string;
  N: Integer;
begin
  Result := False;
  if not SameText(Copy(AKey, 1, Length(AWord) + 1), AWord + ' ') then
    Exit;
  Rest := Trim(Copy(AKey, Length(AWord) + 2, MaxInt));
  Result := TryStrToInt(Rest, N);
end;

function IsOpenAuth(const AValue: string): Boolean;
var
  V: string;
begin
  V := LowerCase(Trim(AValue));
  Result := (V = 'open') or (V = 'aberta') or (V = 'aberto') or (V = 'abierta') or
    (V = 'ouvert') or (V = 'offen') or (V = 'aperta') or (V = 'none') or (V = '');
end;

function WildMatch(const AText, AMask: string): Boolean;
var
  T, M, StarT, StarM: Integer;
begin
  T := 1; M := 1; StarT := 0; StarM := 0;
  while T <= Length(AText) do
  begin
    if (M <= Length(AMask)) and ((AMask[M] = '?') or (AMask[M] = AText[T])) then
    begin
      Inc(T); Inc(M);
    end
    else if (M <= Length(AMask)) and (AMask[M] = '*') then
    begin
      StarM := M; StarT := T; Inc(M);
    end
    else if StarM > 0 then
    begin
      M := StarM + 1; Inc(StarT); T := StarT;
    end
    else
      Exit(False);
  end;
  while (M <= Length(AMask)) and (AMask[M] = '*') do
    Inc(M);
  Result := M > Length(AMask);
end;

function XmlEscape(const S: string): string;
begin
  Result := StringReplace(S, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&apos;', [rfReplaceAll]);
end;

{ ---------- Windows: varredura pela wlanapi.dll ---------- }

{$IFDEF WINDOWS}
type
  TWlanOpenHandle = function(dwClientVersion: DWORD; pReserved: Pointer;
    out pdwNegotiatedVersion: DWORD; out phClientHandle: THandle): DWORD; stdcall;
  TWlanCloseHandle = function(hClientHandle: THandle; pReserved: Pointer): DWORD; stdcall;
  TWlanEnumInterfaces = function(hClientHandle: THandle; pReserved: Pointer;
    out ppInterfaceList: Pointer): DWORD; stdcall;
  TWlanScan = function(hClientHandle: THandle; pInterfaceGuid: PGUID;
    pDot11Ssid: Pointer; pIeData: Pointer; pReserved: Pointer): DWORD; stdcall;
  TWlanFreeMemory = procedure(pMemory: Pointer); stdcall;

const
  WLAN_INTERFACE_INFO_SIZE = 16 + 256 * 2 + 4; // GUID + descrição + estado

function TAIWifi.TriggerWindowsScan: Boolean;
var
  Lib: TLibHandle;
  OpenH: TWlanOpenHandle;
  CloseH: TWlanCloseHandle;
  Enum: TWlanEnumInterfaces;
  ScanF: TWlanScan;
  FreeM: TWlanFreeMemory;
  Ver: DWORD;
  H: THandle;
  List: Pointer;
  Count, I: DWORD;
  Guid: TGUID;
begin
  Result := False;
  Lib := DynLibs.LoadLibrary('wlanapi.dll');
  if Lib = NilHandle then
    Exit;
  try
    Pointer(OpenH) := DynLibs.GetProcedureAddress(Lib, 'WlanOpenHandle');
    Pointer(CloseH) := DynLibs.GetProcedureAddress(Lib, 'WlanCloseHandle');
    Pointer(Enum) := DynLibs.GetProcedureAddress(Lib, 'WlanEnumInterfaces');
    Pointer(ScanF) := DynLibs.GetProcedureAddress(Lib, 'WlanScan');
    Pointer(FreeM) := DynLibs.GetProcedureAddress(Lib, 'WlanFreeMemory');
    if not (Assigned(OpenH) and Assigned(CloseH) and Assigned(Enum) and
      Assigned(ScanF) and Assigned(FreeM)) then
      Exit;
    if OpenH(2, nil, Ver, H) <> 0 then
      Exit;
    try
      if Enum(H, nil, List) <> 0 then
        Exit;
      try
        Count := PDWORD(List)^;
        for I := 0 to Count - 1 do
        begin
          Move((PByte(List) + 8 + I * WLAN_INTERFACE_INFO_SIZE)^, Guid, SizeOf(Guid));
          if ScanF(H, @Guid, nil, nil, nil) = 0 then
            Result := True;
        end;
      finally
        FreeM(List);
      end;
    finally
      CloseH(H, nil);
    end;
  finally
    DynLibs.UnloadLibrary(Lib);
  end;
end;
{$ENDIF}

{ TAIWifi }

procedure TAIWifi.DoLog(const AMsg: string);
begin
  if Assigned(FOnLog) then
    FOnLog(AMsg);
end;

procedure TAIWifi.Wait(AMs: Integer);
var
  T: QWord;
begin
  T := GetTickCount64 + QWord(AMs);
  repeat
    if Assigned(FOnWait) then
      FOnWait(Self);
    Sleep(100);
  until GetTickCount64 >= T;
end;

function TAIWifi.Run(const AExe: string; const AArgs: array of string;
  out AOutput: string): Boolean;
begin
  AOutput := '';
  try
    Result := RunCommand(AExe, AArgs, AOutput, [poNoConsole], swoHIDE);
  except
    on E: Exception do
    begin
      FLastError := AExe + ': ' + E.Message;
      Result := False;
    end;
  end;
end;

function TAIWifi.Scan(ARefresh: Boolean): Boolean;
var
  Output: string;
begin
  FLastError := '';
  SetLength(FNetworks, 0);
{$IFDEF WINDOWS}
  if ARefresh and TriggerWindowsScan then
  begin
    DoLog('Procurando redes Wi-Fi...');
    Wait(4000); // o Windows conclui a varredura em até 4 s
  end;
  if FInterfaceName <> '' then
    Result := Run('netsh', ['wlan', 'show', 'networks', 'mode=bssid',
      'interface=' + FInterfaceName], Output)
  else
    Result := Run('netsh', ['wlan', 'show', 'networks', 'mode=bssid'], Output);
  if Result then
    FNetworks := ParseNetshNetworks(Output)
  else if FLastError = '' then
    FLastError := 'Não foi possível listar as redes (netsh). O serviço de ' +
      'Wi-Fi (WLAN AutoConfig) está ativo e há placa Wi-Fi?';
{$ELSE}
  if ARefresh then
    DoLog('Procurando redes Wi-Fi...');
  if ARefresh then
    Result := Run('nmcli', ['-t', '-f', 'IN-USE,SSID,BSSID,SIGNAL,SECURITY',
      'device', 'wifi', 'list', '--rescan', 'yes'], Output)
  else
    Result := Run('nmcli', ['-t', '-f', 'IN-USE,SSID,BSSID,SIGNAL,SECURITY',
      'device', 'wifi', 'list', '--rescan', 'no'], Output);
  if Result then
    FNetworks := ParseNmcliNetworks(Output)
  else if FLastError = '' then
    FLastError := 'Não foi possível listar as redes (nmcli). O NetworkManager está instalado?';
{$ENDIF}
  if Result then
    DoLog(Format('%d rede(s) Wi-Fi encontrada(s).', [Length(FNetworks)]));
end;

function TAIWifi.CurrentSSID: string;
var
  Output: string;
{$IFNDEF WINDOWS}
  Nets: TAIWifiNetworks;
  I: Integer;
{$ENDIF}
begin
  Result := '';
{$IFDEF WINDOWS}
  if Run('netsh', ['wlan', 'show', 'interfaces'], Output) then
    Result := ParseNetshCurrentSSID(Output);
{$ELSE}
  if Run('nmcli', ['-t', '-f', 'IN-USE,SSID,BSSID,SIGNAL,SECURITY',
    'device', 'wifi', 'list', '--rescan', 'no'], Output) then
  begin
    Nets := ParseNmcliNetworks(Output);
    for I := 0 to High(Nets) do
      if Nets[I].Connected then
        Exit(Nets[I].SSID);
  end;
{$ENDIF}
end;

function TAIWifi.IsConnectedTo(const ASSID: string): Boolean;
begin
  Result := (ASSID <> '') and (CurrentSSID = ASSID);
end;

function TAIWifi.Connect(const ASSID: string; const APassword: string): Boolean;
var
  Output: string;
{$IFDEF WINDOWS}
  ProfileFile: string;
  SL: TStringList;
{$ENDIF}
begin
  FLastError := '';
  Result := False;
  if Trim(ASSID) = '' then
  begin
    FLastError := 'SSID vazio.';
    Exit;
  end;
  DoLog('Conectando à rede Wi-Fi "' + ASSID + '"...');
{$IFDEF WINDOWS}
  ProfileFile := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'aiwifi_profile.xml';
  SL := TStringList.Create;
  try
    SL.Text := BuildWindowsProfileXml(ASSID, APassword);
    SL.SaveToFile(ProfileFile);
  finally
    SL.Free;
  end;
  try
    if FInterfaceName <> '' then
      Run('netsh', ['wlan', 'add', 'profile', 'filename=' + ProfileFile,
        'interface=' + FInterfaceName, 'user=current'], Output)
    else
      Run('netsh', ['wlan', 'add', 'profile', 'filename=' + ProfileFile,
        'user=current'], Output);
  finally
    SysUtils.DeleteFile(ProfileFile); // o arquivo pode conter a senha
  end;
  Result := ConnectExisting(ASSID);
  Output := '';
{$ELSE}
  if APassword <> '' then
  begin
    if FInterfaceName <> '' then
      Result := Run('nmcli', ['device', 'wifi', 'connect', ASSID, 'password',
        APassword, 'ifname', FInterfaceName], Output)
    else
      Result := Run('nmcli', ['device', 'wifi', 'connect', ASSID, 'password',
        APassword], Output);
  end
  else
  begin
    if FInterfaceName <> '' then
      Result := Run('nmcli', ['device', 'wifi', 'connect', ASSID, 'ifname',
        FInterfaceName], Output)
    else
      Result := Run('nmcli', ['device', 'wifi', 'connect', ASSID], Output);
  end;
{$ENDIF}
  if not Result and (FLastError = '') then
    FLastError := 'Falha ao conectar em "' + ASSID + '": ' + Trim(Output);
end;

function TAIWifi.ConnectExisting(const ASSID: string): Boolean;
var
  Output: string;
begin
  Result := False;
  if Trim(ASSID) = '' then
    Exit;
{$IFDEF WINDOWS}
  if FInterfaceName <> '' then
    Result := Run('netsh', ['wlan', 'connect', 'name=' + ASSID, 'ssid=' + ASSID,
      'interface=' + FInterfaceName], Output)
  else
    Result := Run('netsh', ['wlan', 'connect', 'name=' + ASSID, 'ssid=' + ASSID],
      Output);
{$ELSE}
  Result := Run('nmcli', ['connection', 'up', 'id', ASSID], Output);
{$ENDIF}
  if not Result and (FLastError = '') then
    FLastError := 'Falha ao conectar em "' + ASSID + '": ' + Trim(Output);
end;

function TAIWifi.WaitForConnection(const ASSID: string; ATimeoutMs: Integer): Boolean;
var
  Limit: QWord;
begin
  Limit := GetTickCount64 + QWord(Abs(ATimeoutMs));
  repeat
    if IsConnectedTo(ASSID) then
      Exit(True);
    Wait(500);
  until GetTickCount64 >= Limit;
  Result := IsConnectedTo(ASSID);
  if not Result then
    FLastError := 'Tempo esgotado esperando a conexão com "' + ASSID + '".';
end;

function TAIWifi.FindNetwork(const APatterns: string;
  out ANetwork: TAIWifiNetwork): Boolean;
var
  I, Best: Integer;
begin
  ANetwork := Default(TAIWifiNetwork);
  Best := -1;
  for I := 0 to High(FNetworks) do
    if MatchesPattern(FNetworks[I].SSID, APatterns) then
      if (Best < 0) or (FNetworks[I].Signal > FNetworks[Best].Signal) then
        Best := I;
  Result := Best >= 0;
  if Result then
    ANetwork := FNetworks[Best];
end;

class function TAIWifi.MatchesPattern(const ASSID, APatterns: string): Boolean;
var
  Parts: TStringArray;
  P, S: string;
  I: Integer;
begin
  Result := False;
  if ASSID = '' then
    Exit;
  S := UpperCase(ASSID);
  Parts := APatterns.Split([';']);
  for I := 0 to High(Parts) do
  begin
    P := UpperCase(Trim(Parts[I]));
    if P = '' then
      Continue;
    if (Pos('*', P) > 0) or (Pos('?', P) > 0) then
    begin
      if WildMatch(S, P) then
        Exit(True);
    end
    else if Pos(P, S) > 0 then
      Exit(True);
  end;
end;

class function TAIWifi.ParseNetshNetworks(const AText: string): TAIWifiNetworks;
var
  Lines: TStringList;
  I, N, Sig: Integer;
  Key, Value, LKey: string;
  Cur: Integer;
begin
  Result := nil;
  Cur := -1;
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for I := 0 to Lines.Count - 1 do
    begin
      if not SplitKeyValue(Lines[I], Key, Value) then
        Continue;

      if KeyIsNumbered(Key, 'SSID') then
      begin
        if Value = '' then
        begin
          Cur := -1; // rede oculta: ignorada
          Continue;
        end;
        N := Length(Result);
        SetLength(Result, N + 1);
        Result[N] := Default(TAIWifiNetwork);
        Result[N].SSID := Value;
        Result[N].Signal := -1;
        Cur := N;
        Continue;
      end;

      if Cur < 0 then
        Continue;

      LKey := LowerCase(Key);
      if (Copy(LKey, 1, 4) = 'auth') or (Copy(LKey, 1, 9) = 'autentica') then
      begin
        Result[Cur].Security := Value;
        Result[Cur].Secured := not IsOpenAuth(Value);
      end
      else if KeyIsNumbered(Key, 'BSSID') then
      begin
        if Result[Cur].BSSID = '' then
          Result[Cur].BSSID := Value;
      end
      else if (Value <> '') and (Value[Length(Value)] = '%') then
      begin
        // 'Signal'/'Sinal'/'Señal' : 90%
        if TryStrToInt(Trim(Copy(Value, 1, Length(Value) - 1)), Sig) then
          if Sig > Result[Cur].Signal then
            Result[Cur].Signal := Sig;
      end;
    end;
  finally
    Lines.Free;
  end;
  for I := 0 to High(Result) do
    if Result[I].Signal < 0 then
      Result[I].Signal := 0;
end;

class function TAIWifi.ParseNetshCurrentSSID(const AText: string): string;
var
  Lines: TStringList;
  I: Integer;
  Key, Value: string;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for I := 0 to Lines.Count - 1 do
      if SplitKeyValue(Lines[I], Key, Value) and SameText(Key, 'SSID') then
        Exit(Value);
  finally
    Lines.Free;
  end;
end;

class function TAIWifi.ParseNmcliNetworks(const AText: string): TAIWifiNetworks;

  function SplitTerse(const ALine: string): TStringArray;
  var
    I, N: Integer;
    Cur: string;
  begin
    Result := nil;
    Cur := '';
    I := 1;
    while I <= Length(ALine) do
    begin
      if (ALine[I] = '\') and (I < Length(ALine)) then
      begin
        Cur := Cur + ALine[I + 1];
        Inc(I, 2);
        Continue;
      end;
      if ALine[I] = ':' then
      begin
        N := Length(Result);
        SetLength(Result, N + 1);
        Result[N] := Cur;
        Cur := '';
      end
      else
        Cur := Cur + ALine[I];
      Inc(I);
    end;
    N := Length(Result);
    SetLength(Result, N + 1);
    Result[N] := Cur;
  end;

var
  Lines: TStringList;
  I, J, N, Sig: Integer;
  F: TStringArray;
  Found: Boolean;
begin
  Result := nil;
  Lines := TStringList.Create;
  try
    Lines.Text := AText;
    for I := 0 to Lines.Count - 1 do
    begin
      F := SplitTerse(Lines[I]);
      if (Length(F) < 5) or (F[1] = '') then
        Continue;
      if not TryStrToInt(F[3], Sig) then
        Sig := 0;
      // Mesma rede em vários pontos de acesso: fica o de maior sinal.
      Found := False;
      for J := 0 to High(Result) do
        if Result[J].SSID = F[1] then
        begin
          Found := True;
          if Sig > Result[J].Signal then
          begin
            Result[J].Signal := Sig;
            Result[J].BSSID := F[2];
          end;
          if Trim(F[0]) = '*' then
            Result[J].Connected := True;
        end;
      if Found then
        Continue;
      N := Length(Result);
      SetLength(Result, N + 1);
      Result[N] := Default(TAIWifiNetwork);
      Result[N].Connected := Trim(F[0]) = '*';
      Result[N].SSID := F[1];
      Result[N].BSSID := F[2];
      Result[N].Signal := Sig;
      Result[N].Security := F[4];
      Result[N].Secured := (Trim(F[4]) <> '') and (Trim(F[4]) <> '--');
    end;
  finally
    Lines.Free;
  end;
end;

class function TAIWifi.BuildWindowsProfileXml(const ASSID, APassword: string): string;
var
  S, Sec: string;
begin
  S := XmlEscape(ASSID);
  if APassword = '' then
    Sec :=
      '      <authEncryption>' + LineEnding +
      '        <authentication>open</authentication>' + LineEnding +
      '        <encryption>none</encryption>' + LineEnding +
      '        <useOneX>false</useOneX>' + LineEnding +
      '      </authEncryption>' + LineEnding
  else
    Sec :=
      '      <authEncryption>' + LineEnding +
      '        <authentication>WPA2PSK</authentication>' + LineEnding +
      '        <encryption>AES</encryption>' + LineEnding +
      '        <useOneX>false</useOneX>' + LineEnding +
      '      </authEncryption>' + LineEnding +
      '      <sharedKey>' + LineEnding +
      '        <keyType>passPhrase</keyType>' + LineEnding +
      '        <protected>false</protected>' + LineEnding +
      '        <keyMaterial>' + XmlEscape(APassword) + '</keyMaterial>' + LineEnding +
      '      </sharedKey>' + LineEnding;

  Result :=
    '<?xml version="1.0"?>' + LineEnding +
    '<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">' + LineEnding +
    '  <name>' + S + '</name>' + LineEnding +
    '  <SSIDConfig><SSID><name>' + S + '</name></SSID></SSIDConfig>' + LineEnding +
    '  <connectionType>ESS</connectionType>' + LineEnding +
    '  <connectionMode>manual</connectionMode>' + LineEnding +
    '  <MSM>' + LineEnding +
    '    <security>' + LineEnding +
    Sec +
    '    </security>' + LineEnding +
    '  </MSM>' + LineEnding +
    '</WLANProfile>' + LineEnding;
end;

end.
