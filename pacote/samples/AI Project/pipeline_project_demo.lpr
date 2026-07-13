program pipeline_project_demo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces,
  Classes, SysUtils,
  chatgpt, NeuralNetwork, aiinput, aioutput, aioutput_docs, aipipeline, aiproject, aipromptbuilder;

var
  LContainer: TComponent;
  LProject: TAIProject;
  LPipeline: TAIPipeline;
  LChat: TCHATGPT;
  LNet: TNeuralNetwork;
  LInput: TAIInputData;
  LOutput: TAIOutputData;
  LDocs: TAIOutputDocs;
  LPromptBuilder: TAIPromptBuilder;
  SystemPrompt: string;
  
begin
  WriteLn('=== Lazarus AI Suite — Pipeline & Project Demo ===');
  WriteLn;

  // 1. Instanciar container e componentes
  LContainer := TComponent.Create(nil);
  LProject := TAIProject.Create(LContainer);
  LProject.Name := 'Project1';
  
  LPipeline := TAIPipeline.Create(LContainer);
  LPipeline.Name := 'Pipeline1';
  
  LChat := TCHATGPT.Create(LContainer);
  LChat.Name := 'ChatGPT1';
  
  LNet := TNeuralNetwork.Create(LContainer);
  LNet.Name := 'Net1';
  
  LInput := TAIInputData.Create(LContainer);
  LInput.Name := 'Input1';
  
  LOutput := TAIOutputData.Create(LContainer);
  LOutput.Name := 'Output1';
  
  LDocs := TAIOutputDocs.Create(LContainer);
  LDocs.Name := 'Docs1';
  
  LPromptBuilder := TAIPromptBuilder.Create(LContainer);
  LPromptBuilder.Name := 'PromptBuilder1';

  try
    // 2. Configurar metadados do projeto
    LProject.ProjectName := 'Demo Pipeline Project';
    LProject.Description := 'Demonstracao do uso integrado do TAIProject e TAIPipeline.';
    LProject.SimulationMode := True; // Ativa modo simulado para testes sem API Key

    // 3. Vincular componentes ao Pipeline
    LPipeline.ChatGPT := LChat;
    LPipeline.NeuralNetwork := LNet;
    LPipeline.InputData := LInput;
    LPipeline.OutputData := LOutput;
    LPipeline.OutputDocs := LDocs;

    // 4. Vincular componentes ao Projeto
    LProject.ChatGPT := LChat;
    LProject.Pipeline := LPipeline;

    WriteLn('Projeto: ' + LProject.ProjectName);
    WriteLn('Descricao: ' + LProject.Description);
    WriteLn('Modo Simulacao: ' + BoolToStr(LProject.SimulationMode, True));
    WriteLn;

    // 5. Testar Fluxo de NLP Textual
    WriteLn('1. Testando Fluxo de Texto (pmTextLLM)...');
    LPipeline.Mode := pmTextLLM;
    LPipeline.InputText := 'Como funciona o compilador FPC?';
    
    if LProject.Execute then
      WriteLn('  Resultado do Texto: ' + LProject.LastResult)
    else
      WriteLn('  Erro no Texto: ' + LProject.LastError);
    WriteLn;

    // 6. Testar Fluxo de Classificação Numérica (pmNumericML)
    WriteLn('2. Testando Fluxo de Machine Learning (pmNumericML)...');
    
    // Inicializar rede neural de teste local (1 entrada, 3 ocultos, 2 saídas)
    LNet.Initialize(1, 3, 2, 0.1);
    
    // Carregar dados de telemetria brutos e configurar normalização
    LInput.LoadFromString('12.5, 45.3, 78.9', ',');
    LInput.MinRange := 0.0;
    LInput.MaxRange := 1.0;
    
    // Configurar classes de saída
    LOutput.Classes.Clear;
    LOutput.Classes.Add('Normal');
    LOutput.Classes.Add('Anomalia');
    
    LPipeline.Mode := pmNumericML;
    LPipeline.AutoNormalize := True;
    LPipeline.AutoSoftMax := True;
    
    // Como estamos rodando localmente (sem dependências de rede), 
    // desativamos temporariamente a simulação para este passo
    LProject.SimulationMode := False;
    
    if LProject.Execute then
      WriteLn('  Resultado Classificacao: ' + LProject.LastResult)
    else
      WriteLn('  Erro Classificacao: ' + LProject.LastError);
    WriteLn;

    // Restaura modo de simulação
    LProject.SimulationMode := True;

    // 7. Testar Geração Unificada de Relatórios (pmDocumentGeneration)
    WriteLn('3. Testando Fluxo de Documentacao (pmDocumentGeneration)...');
    LPipeline.Mode := pmDocumentGeneration;
    LPipeline.InputText := 'Resumo Executivo do Agente de IA: Todos os sensores operando sob conformidade.';
    
    // Configurar nomes de arquivos de saída
    LDocs.FileNamePDF := 'relatorio_final.pdf';
    LDocs.FileNameWord := 'relatorio_final.docx';
    LDocs.FileNameExcel := 'dados_final.xlsx';
    LDocs.FileNameTXT := 'relatorio_final.txt';

    // Desativa simulação para salvar arquivos locais reais em disco
    LProject.SimulationMode := False;

    if LProject.Execute then
      WriteLn('  Documentos gerados em disco com sucesso!')
    else
      WriteLn('  Erro na geracao: ' + LProject.LastError);
    WriteLn;

    // 8. Testar o TAIPromptBuilder
    WriteLn('4. Testando o TAIPromptBuilder (Engenharia de Prompts Automatica)...');
    SystemPrompt := LPromptBuilder.BuildFromOwner(LContainer);
    WriteLn('--- PROMPT AUTOMATICO GERADO ---');
    WriteLn(SystemPrompt);
    WriteLn('--------------------------------');
    WriteLn;

    // 9. Visualizar prompt de sistema do projeto
    WriteLn('=== PROMPT DE SISTEMA DO PROJETO ===');
    WriteLn(LProject.BuildSystemPrompt);
    WriteLn('====================================');

  finally
    LContainer.Free;
  end;
  
  WriteLn;
  WriteLn('Pressione [Enter] para finalizar...');
  ReadLn;
end.
