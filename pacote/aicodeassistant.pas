unit aicodeassistant;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, chatgpt;

type
  { TAICodeAssistant }

  TAICodeAssistant = class(TComponent)
  private
    FChatGPT: TCHATGPT;
  public
    constructor Create(AOwner: TComponent); override;

    // Métodos utilitários de IA de apoio à programação
    function OptimizeCode(const ACode: string): string;
    function FindBugs(const ACode: string): string;
    function DocumentCode(const ACode: string): string;
    
    // Gera testes unitários (ex: FPCUnit, DUnit)
    function GenerateUnitTests(const ACode: string; const ATestFramework: string = 'FPCUnit'): string;
    
    // Traduz código de uma linguagem para outra (ex: Pascal para C++, Java para Pascal)
    function TranslateCode(const ACode, ASourceLang, ATargetLang: string): string;

    // Explica o funcionamento de uma rotina ou trecho
    function ExplainCode(const ACode: string): string;

  published
    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA', [TAICodeAssistant]);
end;

constructor TAICodeAssistant.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChatGPT := nil;
end;

function TAICodeAssistant.OptimizeCode(const ACode: string): string;
var
  Prompt: WideString;
begin
  Result := '';
  if FChatGPT = nil then
    raise Exception.Create('Componente ChatGPT não associado. Defina a propriedade ChatGPT.');

  Prompt := 'Por favor, otimize o seguinte código para melhor desempenho e legibilidade. ' +
            'Mantenha as diretivas de compilador originais se houver. Retorne apenas o código otimizado ' +
            'sem explicações adicionais, delimitado por bloco de código markdown:' + #13#10 +
            ACode;

  if FChatGPT.SendQuestion(Prompt) then
    Result := FChatGPT.Response
  else
    Result := 'Erro ao otimizar código: ' + FChatGPT.Response;
end;

function TAICodeAssistant.FindBugs(const ACode: string): string;
var
  Prompt: WideString;
begin
  Result := '';
  if FChatGPT = nil then
    raise Exception.Create('Componente ChatGPT não associado. Defina a propriedade ChatGPT.');

  Prompt := 'Analise o seguinte código em busca de erros de lógica, vazamentos de memória, bugs latentes ' +
            'ou violações de boas práticas. Liste os problemas encontrados de forma sucinta e forneça correções recomendadas:' + #13#10 +
            ACode;

  if FChatGPT.SendQuestion(Prompt) then
    Result := FChatGPT.Response
  else
    Result := 'Erro ao analisar código: ' + FChatGPT.Response;
end;

function TAICodeAssistant.DocumentCode(const ACode: string): string;
var
  Prompt: WideString;
begin
  Result := '';
  if FChatGPT = nil then
    raise Exception.Create('Componente ChatGPT não associado. Defina a propriedade ChatGPT.');

  Prompt := 'Adicione comentários detalhados explicativos de cabeçalho e documentação em formato XML ou padrão Javadoc ' +
            'para cada rotina, parâmetro e classe no seguinte código. Retorne apenas o código documentado ' +
            'sem textos adicionais ao redor:' + #13#10 +
            ACode;

  if FChatGPT.SendQuestion(Prompt) then
    Result := FChatGPT.Response
  else
    Result := 'Erro ao documentar código: ' + FChatGPT.Response;
end;

function TAICodeAssistant.GenerateUnitTests(const ACode: string; const ATestFramework: string): string;
var
  Prompt: WideString;
begin
  Result := '';
  if FChatGPT = nil then
    raise Exception.Create('Componente ChatGPT não associado. Defina a propriedade ChatGPT.');

  Prompt := Format('Escreva testes unitários abrangentes para o seguinte código utilizando o framework "%s". ' +
            'Inclua casos de teste normais, limites e cenários de exceção. Retorne apenas o código do teste ' +
            'unitário em markdown:', [ATestFramework]) + #13#10 + ACode;

  if FChatGPT.SendQuestion(Prompt) then
    Result := FChatGPT.Response
  else
    Result := 'Erro ao gerar testes: ' + FChatGPT.Response;
end;

function TAICodeAssistant.TranslateCode(const ACode, ASourceLang, ATargetLang: string): string;
var
  Prompt: WideString;
begin
  Result := '';
  if FChatGPT = nil then
    raise Exception.Create('Componente ChatGPT não associado. Defina a propriedade ChatGPT.');

  Prompt := Format('Traduza o seguinte código escrito em "%s" para a linguagem "%s". ' +
            'Respeite as convenções idiomáticas e boas práticas da linguagem de destino. Retorne apenas o código ' +
            'traduzido em markdown sem explicações:', [ASourceLang, ATargetLang]) + #13#10 + ACode;

  if FChatGPT.SendQuestion(Prompt) then
    Result := FChatGPT.Response
  else
    Result := 'Erro ao traduzir código: ' + FChatGPT.Response;
end;

function TAICodeAssistant.ExplainCode(const ACode: string): string;
var
  Prompt: WideString;
begin
  Result := '';
  if FChatGPT = nil then
    raise Exception.Create('Componente ChatGPT não associado. Defina a propriedade ChatGPT.');

  Prompt := 'Explique detalhadamente o funcionamento e a lógica do seguinte código, passo a passo, ' +
            'descrevendo as entradas, saídas e a complexidade algorítmica aproximada:' + #13#10 +
            ACode;

  if FChatGPT.SendQuestion(Prompt) then
    Result := FChatGPT.Response
  else
    Result := 'Erro ao explicar código: ' + FChatGPT.Response;
end;

end.
