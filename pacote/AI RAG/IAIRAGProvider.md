# Decisao arquitetural: `IAIRAGProvider`

Status: A01 concluida em 09/08/2026. A02 e A03 implementadas em seguida.

## Contrato atual

A interface `IAIRAGProvider`, declarada em `AI/airagbridge.pas`, possui GUID e
define exatamente estes cinco metodos:

1. `BuildContext(const AQuestion: string): Boolean`
2. `GetLastQuestion: string`
3. `GetLastContext: string`
4. `GetLastAnswer: string`
5. `GetLastSources: TStrings`

O unico consumo encontrado esta em `TAIAgent.LoadRAGContext`, em
`AI Agent/aiagent.pas`. O Agent recebe o RAG como `TComponent`, usa
`Supports(FRAG, IAIRAGProvider, RAGProvider)` e, quando o contrato esta
disponivel, chama `BuildContext`, copia `GetLastContext` e copia o conteudo de
`GetLastSources` para seu proprio `TStringList`.

## Estado atual de `TAIRAG`

Na auditoria A01, `TAIRAG` ainda nao declarava `IAIRAGProvider`. A tarefa A02
passou a declara-lo como `class(TAIBaseComponent, IAIRAGProvider)` e A03
adicionou os quatro getters como adaptadores dos campos existentes. As
propriedades publicas anteriores foram preservadas e nenhum estado foi
duplicado.

## Convencao de interface e ciclo de vida

O projeto usa `{$mode objfpc}` e nao seleciona interfaces CORBA; portanto,
`IAIRAGProvider` segue a convencao de interface com GUID usada por `Supports`.
`TAIBaseComponent` nao adiciona gerenciamento de interfaces: ele apenas deriva
de `TComponent`.

Foi compilado e executado um teste isolado com o FPC 3.2.2 instalado no
ambiente. Uma classe `TComponent` que declara uma interface com GUID foi
reconhecida por `Supports`; ao liberar a referencia de interface, o componente
nao foi destruido, e sua destruicao ocorreu somente com `Free`. Assim, para
componentes do projeto, o ownership continua sendo o de `TComponent`, sem
transferencia para a referencia de interface.

## Decisao para as proximas tarefas

- Preservar `TAIRAG = class(TAIBaseComponent, IAIRAGProvider)`; a classe-base
  nao foi trocada.
- Usar o suporte de interface herdado de `TComponent`; nao criar contador de
  referencias nem reimplementar `_AddRef`/`_Release` em `TAIRAG`.
- Manter a associacao `TAIAgent.RAG` como referencia de componente com
  `FreeNotification`, ja usada por `TAIAgent.SetRAG` e `Notification`.
- Manter os getters como adaptadores dos campos existentes, sem duplicar
  estado.
- Tratar o objeto retornado por `GetLastSources` como pertencente ao provider.
  Consumidores podem ler ou copiar seu conteudo, mas nao devem libera-lo.
- Manter a interface estavel; A02 e A03 foram implementadas sem alterar o
  contrato.

## Conclusao

A interface atual e suficiente para desacoplar o Agent da implementacao RAG.
As lacunas comprovadas de declaracao e getters foram preenchidas preservando o
ciclo de vida atual dos componentes.
