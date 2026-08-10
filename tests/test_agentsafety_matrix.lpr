program test_agentsafety_matrix;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aiagentsafety;

var
  GPassCount: Integer = 0;
  GFailCount: Integer = 0;

procedure AssertResult(const ATestName: string; ASuccess: Boolean; const AExpected, AObtained, AMotivo: string);
begin
  if ASuccess then
  begin
    Inc(GPassCount);
    WriteLn('[PASS] ', ATestName);
  end
  else
  begin
    Inc(GFailCount);
    WriteLn('[FAIL] ', ATestName);
    WriteLn('       Esperado: ', AExpected);
    WriteLn('       Obtido:   ', AObtained);
    WriteLn('       Motivo:   ', AMotivo);
  end;
end;

procedure TestRealActionNames;
var
  Safety: TAIAgentSafety;
  Params: TStringList;
  Err: string;
  Allowed: Boolean;
begin
  WriteLn('=== Teste 1: Acoes Reais do Framework com Defaults Restritivos ===');
  Safety := TAIAgentSafety.Create(nil);
  Params := TStringList.Create;
  try
    Safety.Enabled := True;
    Safety.ReadOnlyMode := True;
    Safety.AllowFileWrite := False;
    Safety.AllowNetwork := False;
    Safety.AllowIndustrialWrite := False;
    Safety.AllowEmailSend := False;

    // BROWSER_NAVIGATE (esperado: BLOQUEADA por acesso a rede)
    Allowed := Safety.ValidateAction('BROWSER_NAVIGATE', Params, Err);
    AssertResult('BROWSER_NAVIGATE (AllowNetwork=False)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Acesso de rede com AllowNetwork=False');

    // BROWSER_CLICK (esperado: BLOQUEADA por mutacao remota em ReadOnlyMode)
    Allowed := Safety.ValidateAction('BROWSER_CLICK', Params, Err);
    AssertResult('BROWSER_CLICK (ReadOnlyMode=True)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Mutacao de estado remoto em ReadOnlyMode');

    // BROWSER_SET_VALUE (esperado: BLOQUEADA por escrita/mutacao)
    Allowed := Safety.ValidateAction('BROWSER_SET_VALUE', Params, Err);
    AssertResult('BROWSER_SET_VALUE (ReadOnlyMode=True)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Escrita em form em ReadOnlyMode');

    // BROWSER_SUBMIT_FORM (esperado: BLOQUEADA)
    Allowed := Safety.ValidateAction('BROWSER_SUBMIT_FORM', Params, Err);
    AssertResult('BROWSER_SUBMIT_FORM (ReadOnlyMode=True)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Submit de formulario em ReadOnlyMode');

    // BROWSER_SCREENSHOT (esperado: BLOQUEADA por gravar arquivo)
    Allowed := Safety.ValidateAction('BROWSER_SCREENSHOT', Params, Err);
    AssertResult('BROWSER_SCREENSHOT (AllowFileWrite=False)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Grava arquivo de imagem em disco');

    // BROWSER_PRESS_ENTER (esperado: BLOQUEADA)
    Allowed := Safety.ValidateAction('BROWSER_PRESS_ENTER', Params, Err);
    AssertResult('BROWSER_PRESS_ENTER (ReadOnlyMode=True)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Interacao de teclado em ReadOnlyMode');

    // CREATE_TEXT_DOCUMENT (esperado: BLOQUEADA por gravar arquivo)
    Allowed := Safety.ValidateAction('CREATE_TEXT_DOCUMENT', Params, Err);
    AssertResult('CREATE_TEXT_DOCUMENT (AllowFileWrite=False)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Criacao de documento em disco');

    // REGISTER_RESULT (esperado: BLOQUEADA)
    Allowed := Safety.ValidateAction('REGISTER_RESULT', Params, Err);
    AssertResult('REGISTER_RESULT (ReadOnlyMode=True)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Persistencia de resultado em ReadOnlyMode');

    // SEND_EMAIL (esperado: BLOQUEADA por envio de email)
    Allowed := Safety.ValidateAction('SEND_EMAIL', Params, Err);
    AssertResult('SEND_EMAIL (AllowEmailSend=False)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Envio de e-mail desabilitado');

    // BROWSER_READ_PAGE (esperado: BLOQUEADA com AllowNetwork=False)
    Allowed := Safety.ValidateAction('BROWSER_READ_PAGE', Params, Err);
    AssertResult('BROWSER_READ_PAGE (AllowNetwork=False)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Leitura web requer rede');

    // ACAO_DESCONHECIDA_XYZ (esperado: BLOQUEADA fail-closed)
    Allowed := Safety.ValidateAction('ACAO_DESCONHECIDA_XYZ', Params, Err);
    AssertResult('ACAO_DESCONHECIDA_XYZ (Fail-Closed)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Acao nao registrada deve ser bloqueada');
  finally
    Params.Free;
    Safety.Free;
  end;
end;

procedure TestFalsePositives;
var
  Safety: TAIAgentSafety;
  Params: TStringList;
  Err: string;
  Allowed: Boolean;
begin
  WriteLn;
  WriteLn('=== Teste 2: Falsos Positivos de Nomes de Acao ===');
  Safety := TAIAgentSafety.Create(nil);
  Params := TStringList.Create;
  try
    Safety.Enabled := True;
    Safety.ReadOnlyMode := False;
    Safety.AllowFileWrite := False;
    Safety.AllowNetwork := True;
    Safety.AllowAnyDomain := True;

    // READ_WORD_DOCUMENT (esperado: PERMITIDA, pois e leitura)
    Allowed := Safety.ValidateAction('READ_WORD_DOCUMENT', Params, Err);
    AssertResult('READ_WORD_DOCUMENT (Leitura de Documento)', Allowed, 'PERMITIDA', 'BLOQUEADA', 'Leitura nao deve ser bloqueada por conter WORD no nome');

    // LIST_PDF_FILES (esperado: PERMITIDA, pois e listagem)
    Allowed := Safety.ValidateAction('LIST_PDF_FILES', Params, Err);
    AssertResult('LIST_PDF_FILES (Listagem de PDF)', Allowed, 'PERMITIDA', 'BLOQUEADA', 'Listagem nao deve ser bloqueada por conter PDF no nome');
  finally
    Params.Free;
    Safety.Free;
  end;
end;

procedure TestPtBrParameters;
var
  Safety: TAIAgentSafety;
  Params: TStringList;
  Err: string;
  Allowed: Boolean;
begin
  WriteLn;
  WriteLn('=== Teste 3: Parametros em Portugues e Traversal ===');
  Safety := TAIAgentSafety.Create(nil);
  Params := TStringList.Create;
  try
    Safety.Enabled := True;
    Safety.ReadOnlyMode := False;
    Safety.AllowFileWrite := True;
    Safety.SafeBasePath := '/tmp/safe';

    Params.Clear;
    Params.Values['arquivo'] := '../../etc/passwd';
    Allowed := Safety.ValidateAction('CREATE_TEXT_DOCUMENT', Params, Err);
    AssertResult('Parametro "arquivo" com directory traversal', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Parametros em PT-BR devem ter caminhos validados');

    Params.Clear;
    Params.Values['caminho'] := '/etc/shadow';
    Allowed := Safety.ValidateAction('CREATE_TEXT_DOCUMENT', Params, Err);
    AssertResult('Parametro "caminho" fora de SafeBasePath', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Caminhos fora do SafeBasePath devem ser bloqueados');

    Params.Clear;
    Params.Values['destino'] := 'http://evil.tld/x';
    Safety.AllowNetwork := False;
    Allowed := Safety.ValidateAction('BROWSER_NAVIGATE', Params, Err);
    AssertResult('Parametro "destino" com URL remota e AllowNetwork=False', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'URLs em parametros em PT-BR devem ser validadas');
  finally
    Params.Free;
    Safety.Free;
  end;
end;

procedure TestURLParsing;
var
  Safety: TAIAgentSafety;
  Err: string;
  Allowed: Boolean;
begin
  WriteLn;
  WriteLn('=== Teste 4: Deteccao e Parser de URLs ===');
  Safety := TAIAgentSafety.Create(nil);
  try
    Safety.Enabled := True;
    Safety.AllowNetwork := True;
    Safety.AllowedDomains.Clear;
    Safety.AllowedDomains.Add('exemplo.com');

    // IPv6 literal com porta
    Allowed := Safety.ValidateURL('http://[::1]:8080/', Err);
    AssertResult('URL IPv6 Literal http://[::1]:8080/', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'IPv6 nao esta na lista de dominios permitidos');

    // Query sem barra antes
    Allowed := Safety.ValidateURL('https://exemplo.com?x=1', Err);
    AssertResult('URL com Query https://exemplo.com?x=1', Allowed, 'PERMITIDA', 'BLOQUEADA', 'Query string deve ser removida antes de validar o dominio');

    // Lista de dominios vazia (devia ser fail-closed)
    Safety.AllowedDomains.Clear;
    Allowed := Safety.ValidateURL('https://qualquer.tld/', Err);
    AssertResult('Lista AllowedDomains Vazia (Fail-Closed)', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Lista vazia de dominios deve proibir acessos');
  finally
    Safety.Free;
  end;
end;

procedure TestFilePathSecurity;
var
  Safety: TAIAgentSafety;
  Err: string;
  Allowed: Boolean;
begin
  WriteLn;
  WriteLn('=== Teste 5: Caminhos de Arquivo (Path Traversal & Boundaries) ===');
  Safety := TAIAgentSafety.Create(nil);
  try
    Safety.Enabled := True;
    Safety.AllowFileWrite := True;
    Safety.SafeBasePath := '/tmp/safe';

    // Nome legitimo contendo '..' no meio da string
    Allowed := Safety.ValidateFilePath('relatorio..v2.txt', Err);
    AssertResult('Path Legitimo "relatorio..v2.txt"', Allowed, 'PERMITIDA', 'BLOQUEADA', 'Pos(..) ingenuo nao pode bloquear nomes de arquivos validos');

    // Prefix match bypass (/tmp/safe_evil)
    Allowed := Safety.ValidateFilePath('/tmp/safe_evil/x.txt', Err);
    AssertResult('Boundary Bypass "/tmp/safe_evil/x.txt"', not Allowed, 'BLOQUEADA', 'PERMITIDA', 'Diretorio similar fora do boundary deve ser bloqueado');
  finally
    Safety.Free;
  end;
end;

begin
  WriteLn('Iniciando Execucao do Teste de Matriz do TAIAgentSafety (T-1.5)...');
  WriteLn;

  TestRealActionNames;
  TestFalsePositives;
  TestPtBrParameters;
  TestURLParsing;
  TestFilePathSecurity;

  WriteLn;
  WriteLn('==================================================');
  WriteLn(Format('Resumo dos Testes: %d PASS, %d FAIL', [GPassCount, GFailCount]));
  WriteLn('==================================================');

  if GFailCount > 0 then
  begin
    WriteLn('ATENCAO: Teste finalizado com FALHAS (comportamento esperado no T-1.5 antes da reescrita T-1.6).');
    Halt(1);
  end
  else
  begin
    WriteLn('SUCESSO: Todos os testes de matriz de seguranca passaram 100%!');
    Halt(0);
  end;
end.
