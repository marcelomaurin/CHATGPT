# TAIMapaDeMemoria Demo

Este sample demonstra o componente TAIMapaDeMemoria.

O mapa de memória registra a solicitação original, o pedido recebido por cada agente, o tipo do agente, as perguntas feitas, as análises realizadas, a explicação, a ação tomada e a saída gerada.

Ele permite que cada agente avalie se alguma informação se perdeu durante o processo.

O mapa de memória não é pensamento interno oculto do modelo.
Ele é um registro operacional estruturado do fluxo de agentes.

O TAIMapaDeMemoria é o componente responsável por preservar o contexto entre agentes.

Ele registra a ordem da análise, o pedido recebido, o tipo do agente, as perguntas realizadas, a análise, a explicação, a ação tomada e a saída gerada.

Com isso, cada agente consegue verificar se alguma informação se perdeu antes de continuar o fluxo.
