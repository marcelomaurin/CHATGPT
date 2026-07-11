unit aiprinter_transport_spooler;

{-------------------------------------------------------------------------------
  Transporte: impressora instalada no SO, em modo RAW.

  E o caminho para qualquer impressora conectada por USB, que o SO ja instalou
  como fila de impressao. Os bytes vao CRUS: o driver nao interpreta, nao
  rasteriza, nao "melhora". E o que voce quer para ESC/POS, ZPL, TSPL e EPL.

    Windows : winspool.drv  -> pDatatype = 'RAW'   <<< o ponto critico
    Linux   : CUPS          -> lp -o raw
    macOS   : CUPS          -> idem

  Esta unit tambem EXPOE A ENUMERACAO das filas (ListSystemPrinters /
  DefaultSystemPrinter). Quem sabe abrir uma fila sabe lista-las; separar isso
  em outra unit so' cria uma dependencia a mais para dar errado.

  ---------------------------------------------------------------------------
  CORRECOES em relacao a versao anterior desta unit:

  [C1] Windows: o FBuffer era alimentado a cada WriteAll mas NUNCA usado
       (no Windows escrevemos direto via WritePrinter). Resultado: o job
       inteiro era duplicado em memoria a toa, e nunca liberado no Close.
       -> FBuffer agora so' existe no ramo Unix.

  [C2] Windows: WritePrinter nao verificava se escreveu TUDO. Escrita parcial
       passava como sucesso e o cupom saia truncado.
       -> agora compara Written com o tamanho pedido.

  [C3] Linux: o resultado do `lp` era ignorado. Se a fila nao existisse ou o
       CUPS estivesse parado, Close() nao reclamava e o usuario achava que
       tinha impresso.
       -> agora captura stdout/stderr e checa ExitStatus.

  [C4] Linux: se WriteAll fosse chamado sem bytes, o temp file ficava orfao.
       -> Close sempre limpa o temporario.

  [C5] Open() no Windows nao inicializava Result antes dos Exits.

  [C6] Faltava validar nome vazio de impressora -> OpenPrinter falhava com
       um erro criptico do Windows em vez de uma mensagem util.
  ---------------------------------------------------------------------------
-------------------------------------------------------------------------------}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiprinter_transport
  {$IFDEF MSWINDOWS}, Windows {$ENDIF}
  {$IFDEF UNIX}, Process {$ENDIF};

type
  { TAIPrinterSpoolerTransport }

  TAIPrinterSpoolerTransport = class(TInterfacedObject, IAIPrinterTransport)
  private
    FPrinterName: string;
    FDocName: string;
    FTimeoutMs: Integer;
    FLastError: string;
    FIsOpen: Boolean;
    {$IFDEF MSWINDOWS}
    FPrinterHandle: THandle;
    FDocId: DWORD;
    FPageStarted: Boolean;
    {$ELSE}
    FBuffer: TBytes;      { [C1] so' o ramo Unix precisa acumular }
    FTempFile: string;
    {$ENDIF}
  public
    constructor Create(const APrinterName: string;
                       const ADocName: string = 'AI Output');
    destructor Destroy; override;

    function Open: Boolean;
    procedure Close;
    function WriteAll(const ABytes: TBytes): Boolean;
    function IsOpen: Boolean;
    function LastError: string;
    procedure SetTimeoutMs(AValue: Integer);
    function GetTimeoutMs: Integer;

    property PrinterName: string read FPrinterName write FPrinterName;
    property DocName: string read FDocName write FDocName;
  end;

{ ---------------------------------------------------------------------------
  ENUMERACAO DAS FILAS DO SO
  E isto que alimenta o combo "Fila do SO" do sample.
  --------------------------------------------------------------------------- }

{ Preenche AList com os nomes das impressoras instaladas.
  Retorna a quantidade encontrada. Nunca levanta excecao: em caso de falha,
  devolve 0 e preenche AError. }
function ListSystemPrinters(AList: TStrings; out AError: string): Integer;

{ Nome da impressora padrao do SO. String vazia se nao houver. }
function DefaultSystemPrinter: string;

implementation

{$IFDEF MSWINDOWS}
const
  PRINTER_ENUM_LOCAL       = $00000002;
  PRINTER_ENUM_CONNECTIONS = $00000004;

type
  TDocInfo1 = record
    pDocName: PChar;
    pOutputFile: PChar;
    pDatatype: PChar;
  end;

  TPrinterInfo2 = record
    pServerName: PChar;
    pPrinterName: PChar;
    pShareName: PChar;
    pPortName: PChar;
    pDriverName: PChar;
    pComment: PChar;
    pLocation: PChar;
    pDevMode: Pointer;
    pSepFile: PChar;
    pPrintProcessor: PChar;
    pDatatype: PChar;
    pParameters: PChar;
    pSecurityDescriptor: Pointer;
    Attributes: DWORD;
    Priority: DWORD;
    DefaultPriority: DWORD;
    StartTime: DWORD;
    UntilTime: DWORD;
    Status: DWORD;
    cJobs: DWORD;
    AveragePPM: DWORD;
  end;
  PPrinterInfo2 = ^TPrinterInfo2;

function OpenPrinterA(pPrinterName: PChar; var phPrinter: THandle;
  pDefault: Pointer): BOOL; stdcall; external 'winspool.drv' name 'OpenPrinterA';
function ClosePrinter(hPrinter: THandle): BOOL; stdcall;
  external 'winspool.drv';
  
function StartDocPrinterA(hPrinter: THandle; Level: DWORD;
  pDocInfo: Pointer): DWORD; stdcall; external 'winspool.drv' name 'StartDocPrinterA';
function EndDocPrinter(hPrinter: THandle): BOOL; stdcall;
  external 'winspool.drv';
function StartPagePrinter(hPrinter: THandle): BOOL; stdcall;
  external 'winspool.drv';
function EndPagePrinter(hPrinter: THandle): BOOL; stdcall;
  external 'winspool.drv';
function WritePrinter(hPrinter: THandle; pBuf: Pointer; cbBuf: DWORD;
  var pcWritten: DWORD): BOOL; stdcall; external 'winspool.drv';
function EnumPrintersA(Flags: DWORD; Name: PChar; Level: DWORD; pPrinterEnum: Pointer;
  cbBuf: DWORD; var pcbNeeded: DWORD; var pcReturned: DWORD): BOOL; stdcall;
  external 'winspool.drv' name 'EnumPrintersA';
function GetDefaultPrinterA(pszBuffer: PChar; var pcchBuffer: DWORD): BOOL;
  stdcall; external 'winspool.drv' name 'GetDefaultPrinterA';
{$ENDIF}

{$IFDEF UNIX}
{ Executa um binario e captura a saida. Retorna True se ExitStatus = 0. }
function RunAndCapture(const AExe: string; const AArgs: array of string;
  out AOutput: string): Boolean;
var
  P: TProcess;
  S: TStringStream;
  Buf: array[0..4095] of Byte;
  n, i: Integer;
begin
  Result := False;
  AOutput := '';
  P := TProcess.Create(nil);
  S := TStringStream.Create('');
  try
    P.Executable := AExe;
    for i := Low(AArgs) to High(AArgs) do
      P.Parameters.Add(AArgs[i]);
    { poStderrToOutPut e' essencial: e' no stderr que o lp reclama }
    P.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    try
      P.Execute;
    except
      on E: Exception do
      begin
        AOutput := E.Message;
        Exit;   { binario ausente: chamador degrada }
      end;
    end;

    repeat
      n := P.Output.Read(Buf, SizeOf(Buf));
      if n > 0 then S.Write(Buf, n);
    until n <= 0;

    P.WaitOnExit;
    AOutput := S.DataString;
    Result := P.ExitStatus = 0;
  finally
    S.Free;
    P.Free;
  end;
end;
{$ENDIF}

{============================ ENUMERACAO ======================================}

function DefaultSystemPrinter: string;
{$IFDEF MSWINDOWS}
var
  Buf: array[0..511] of Char;
  Len: DWORD;
begin
  Result := '';
  Len := SizeOf(Buf);
  if GetDefaultPrinterA(@Buf[0], Len) then
    Result := StrPas(PChar(@Buf[0]));
end;
{$ELSE}
var
  Saida: string;
  p: Integer;
begin
  Result := '';
  { "system default destination: NOME" }
  if RunAndCapture('lpstat', ['-d'], Saida) then
  begin
    p := Pos(':', Saida);
    if p > 0 then
      Result := Trim(Copy(Saida, p + 1, MaxInt));
    Result := Trim(StringReplace(Result, LineEnding, '', [rfReplaceAll]));
  end;
end;
{$ENDIF}

function ListSystemPrinters(AList: TStrings; out AError: string): Integer;
{$IFDEF MSWINDOWS}
var
  Needed, Returned, i: DWORD;
  Buf: PByte;
  Info: PPrinterInfo2;
  Nome: string;
begin
  Result := 0;
  AError := '';
  if AList = nil then Exit;
  AList.Clear;

  Needed := 0;
  Returned := 0;
  { 1a chamada: descobre o tamanho do buffer. Sempre retorna False. }
  EnumPrintersA(PRINTER_ENUM_LOCAL or PRINTER_ENUM_CONNECTIONS, nil, 2,
                nil, 0, Needed, Returned);
  if Needed = 0 then
  begin
    AError := 'Nenhuma impressora instalada no Windows.';
    Exit;
  end;

  GetMem(Buf, Needed);
  try
    if not EnumPrintersA(PRINTER_ENUM_LOCAL or PRINTER_ENUM_CONNECTIONS, nil, 2,
                         Buf, Needed, Needed, Returned) then
    begin
      AError := 'EnumPrinters falhou (erro ' + IntToStr(GetLastError) + ').';
      Exit;
    end;

    Info := PPrinterInfo2(Buf);
    for i := 0 to Returned - 1 do
    begin
      Nome := StrPas(Info^.pPrinterName);
      if Nome <> '' then
        AList.Add(Nome);
      Inc(Info);
    end;
    Result := AList.Count;
  finally
    FreeMem(Buf);
  end;
end;
{$ELSE}
var
  Saida, Ln, Nome: string;
  L: TStringList;
  i, p: Integer;
begin
  Result := 0;
  AError := '';
  if AList = nil then Exit;
  AList.Clear;

  { "lpstat -a" -> "NOME accepting requests since ..."
    Se -a falhar, tenta -p -> "printer NOME is idle." }
  if not RunAndCapture('lpstat', ['-a'], Saida) then
    if not RunAndCapture('lpstat', ['-p'], Saida) then
    begin
      AError := 'CUPS nao respondeu (lpstat ausente ou servico parado). ' +
                'Instale/inicie o cups.';
      Exit;
    end;

  L := TStringList.Create;
  try
    L.Text := Saida;
    for i := 0 to L.Count - 1 do
    begin
      Ln := Trim(L[i]);
      if Ln = '' then Continue;

      { formato do "-p": "printer NOME is idle." }
      if Copy(Ln, 1, 8) = 'printer ' then
        Ln := Trim(Copy(Ln, 9, MaxInt));

      p := Pos(' ', Ln);
      if p > 0 then Nome := Copy(Ln, 1, p - 1) else Nome := Ln;
      if Nome = '' then Continue;
      if AList.IndexOf(Nome) >= 0 then Continue;   { dedup entre -a e -p }

      AList.Add(Nome);
    end;
    Result := AList.Count;
  finally
    L.Free;
  end;

  if Result = 0 then
    AError := 'Nenhuma fila de impressao encontrada no CUPS.';
end;
{$ENDIF}

{========================== TAIPrinterSpoolerTransport ========================}

constructor TAIPrinterSpoolerTransport.Create(const APrinterName: string;
  const ADocName: string);
begin
  inherited Create;
  FPrinterName := APrinterName;
  FDocName := ADocName;
  FTimeoutMs := 5000;
  FLastError := '';
  FIsOpen := False;
  {$IFDEF MSWINDOWS}
  FPrinterHandle := 0;
  FDocId := 0;
  FPageStarted := False;
  {$ELSE}
  SetLength(FBuffer, 0);
  FTempFile := '';
  {$ENDIF}
end;

destructor TAIPrinterSpoolerTransport.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TAIPrinterSpoolerTransport.Open: Boolean;
begin
  Result := False;             { [C5] antes ficava indefinido em alguns caminhos }
  FLastError := '';

  { [C6] antes, nome vazio chegava no OpenPrinter e voltava um erro criptico }
  if Trim(FPrinterName) = '' then
  begin
    FLastError := 'Nenhuma impressora do SO selecionada.';
    Exit;
  end;

  if FIsOpen then Exit(True);

  {$IFDEF MSWINDOWS}
  if not OpenPrinterA(PChar(FPrinterName), FPrinterHandle, nil) then
  begin
    FLastError := Format('Nao foi possivel abrir a impressora "%s" ' +
      '(erro %d). Verifique se o nome confere exatamente com o que aparece ' +
      'em Dispositivos e Impressoras.', [FPrinterName, GetLastError]);
    FPrinterHandle := 0;
    Exit;
  end;
  FIsOpen := True;
  Result := True;
  {$ELSE}
  SetLength(FBuffer, 0);
  FTempFile := GetTempFileName(GetTempDir, 'airaw');
  FIsOpen := True;
  Result := True;
  {$ENDIF}
end;

function TAIPrinterSpoolerTransport.WriteAll(const ABytes: TBytes): Boolean;
{$IFDEF MSWINDOWS}
var
  DocInfo: TDocInfo1;
  Written: DWORD;
  Total: DWORD;
begin
  Result := False;
  if not FIsOpen then
  begin
    FLastError := 'Transporte nao esta aberto.';
    Exit;
  end;

  Total := Length(ABytes);
  if Total = 0 then Exit(True);

  { Abre o documento na primeira escrita. Assim, se o job estiver vazio,
    nao criamos um job fantasma no spooler. }
  if FDocId = 0 then
  begin
    DocInfo.pDocName    := PChar(FDocName);
    DocInfo.pOutputFile := nil;
    DocInfo.pDatatype   := PChar('RAW');
    { <<< 'RAW' e o ponto critico desta unit inteira.
          Sem ele, o driver INTERPRETA os bytes: seu ESC/POS ou TSPL vira
          uma pagina de texto rasterizada, ou lixo. >>> }

    FDocId := StartDocPrinterA(FPrinterHandle, 1, @DocInfo);
    if FDocId = 0 then
    begin
      FLastError := Format('StartDocPrinter falhou (erro %d).', [GetLastError]);
      Exit;
    end;

    if not StartPagePrinter(FPrinterHandle) then
    begin
      FLastError := Format('StartPagePrinter falhou (erro %d).', [GetLastError]);
      Exit;
    end;
    FPageStarted := True;
  end;

  Written := 0;
  if not WritePrinter(FPrinterHandle, @ABytes[0], Total, Written) then
  begin
    FLastError := Format('WritePrinter falhou (erro %d).', [GetLastError]);
    Exit;
  end;

  { [C2] antes nao se verificava isto: escrita PARCIAL passava como sucesso
    e o cupom saia truncado sem nenhum aviso. }
  if Written <> Total then
  begin
    FLastError := Format('Escrita parcial no spooler: %d de %d bytes.',
      [Written, Total]);
    Exit;
  end;

  Result := True;
end;
{$ELSE}
var
  OldLen, AddedLen: Integer;
begin
  Result := False;
  if not FIsOpen then
  begin
    FLastError := 'Transporte nao esta aberto.';
    Exit;
  end;

  AddedLen := Length(ABytes);
  if AddedLen = 0 then Exit(True);

  { No Unix acumulamos e mandamos tudo de uma vez no Close, via `lp`.
    Um `lp` por WriteAll geraria N jobs no CUPS. }
  OldLen := Length(FBuffer);
  SetLength(FBuffer, OldLen + AddedLen);
  Move(ABytes[0], FBuffer[OldLen], AddedLen);
  Result := True;
end;
{$ENDIF}

procedure TAIPrinterSpoolerTransport.Close;
{$IFDEF MSWINDOWS}
begin
  if not FIsOpen then Exit;
  FIsOpen := False;

  if FDocId <> 0 then
  begin
    if FPageStarted then
    begin
      EndPagePrinter(FPrinterHandle);
      FPageStarted := False;
    end;
    EndDocPrinter(FPrinterHandle);   { <-- e' aqui que o job entra na fila }
    FDocId := 0;
  end;

  if FPrinterHandle <> 0 then
  begin
    ClosePrinter(FPrinterHandle);
    FPrinterHandle := 0;
  end;
end;
{$ELSE}
var
  FS: TFileStream;
  Saida: string;
  Ok: Boolean;
begin
  if not FIsOpen then Exit;
  FIsOpen := False;

  try
    if (FTempFile <> '') and (Length(FBuffer) > 0) then
    begin
      FS := TFileStream.Create(FTempFile, fmCreate);
      try
        FS.WriteBuffer(FBuffer[0], Length(FBuffer));
      finally
        FS.Free;
      end;

      { -o raw : impede o filtro do CUPS de mexer nos bytes. }
      Ok := RunAndCapture('lp',
              ['-d', FPrinterName, '-o', 'raw', FTempFile], Saida);

      { [C3] antes o resultado do lp era ignorado: fila inexistente ou CUPS
        parado passavam em silencio e o usuario achava que tinha impresso. }
      if not Ok then
        FLastError := Format('Falha ao enviar para a fila "%s": %s',
          [FPrinterName, Trim(Saida)]);
    end;
  except
    on E: Exception do
      FLastError := E.Message;
  end;

  { [C4] o temporario e' removido SEMPRE, mesmo se o buffer estava vazio
    ou se o lp explodiu. Antes ficava orfao em /tmp. }
  if (FTempFile <> '') and FileExists(FTempFile) then
    DeleteFile(FTempFile);
  FTempFile := '';
  SetLength(FBuffer, 0);
end;
{$ENDIF}

function TAIPrinterSpoolerTransport.IsOpen: Boolean;
begin
  Result := FIsOpen;
end;

function TAIPrinterSpoolerTransport.LastError: string;
begin
  Result := FLastError;
end;

procedure TAIPrinterSpoolerTransport.SetTimeoutMs(AValue: Integer);
begin
  FTimeoutMs := AValue;
end;

function TAIPrinterSpoolerTransport.GetTimeoutMs: Integer;
begin
  Result := FTimeoutMs;
end;

end.
