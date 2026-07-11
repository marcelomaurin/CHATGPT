# AI Hardware - System Manager Demo

Demo visual do pacote `AI Hardware`, com foco em um painel no estilo:

- Gerenciador de Tarefas
- Gerenciador de Dispositivos

## O que mostra

- CPU: quantidade de CPUs, nucleos, cache, ID, frequencia e uso por nucleo
- Memoria: tipo, total, disponivel, usada e quantidade de pentes
- GPU: nome, memoria e uso
- Discos: quantidade, capacidade e espaco livre/usado
- SO: tipo, versao, bits e memoria virtual
- Tarefas: lista de processos com CPU e memoria

## Arquivos

- `hardware_system_manager_demo.lpr`
- `hardware_system_manager_demo.lpi`
- `main.pas`
- `main.lfm`

## Dependencias

- `AI Hardware`
- LCL

## Observacao

Os componentes de GPU, CPU, memoria, disco e SO foram mantidos no padrao atual
do pacote. Em especial, `TAIGPU` continua retornando dados basicos quando nao ha
integração nativa de GPU disponivel na maquina.
