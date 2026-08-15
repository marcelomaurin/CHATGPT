# MQTT Client Demo (TAIMQTTClient)

Este projeto demonstra a utilização prática do componente `TAIMQTTClient` do pacote `openai_industrial` para comunicação IoT e automação industrial utilizando o protocolo real MQTT (v3.1.1).

## Funcionalidades Demonstradas
- **Conexão Real a Brokers MQTT**: Compatível com brokers públicos (`broker.hivemq.com`, `test.mosquitto.org`, `broker.emqx.io`) ou locais (`localhost:1883`).
- **Configuração de Cliente**: Definição de Client ID personalizável, porta TCP (1883) e intervalo de KeepAlive.
- **Assinatura de Tópicos (Subscribe)**: Registro de tópicos e tópicos com wildcards para recepção assíncrona.
- **Publicação de Mensagens (Publish)**: Envio de payloads (como JSON de telemetria de sensores, comandos de acionamento, status industrial) via `Publish(ATopic, APayload)`.
- **Recepção em Tempo Real (OnMessageReceived)**: Processamento de mensagens recebidas em thread de background com sincronização na interface gráfica.
- **Controle de Sessão e KeepAlive**: Envio manual e automático de pacotes PINGREQ (`Ping`) e encerramento de conexão (`DisconnectBroker`).
- **Sem Simulação Falsa**: Utiliza conexões TCP reais e pacotes binários MQTT em conformidade com o padrão MQTT v3.1.1.

## Como Compilar e Executar
1. Abra o projeto `mqtt_demo.lpi` no Lazarus.
2. Compile com `Ctrl+F9` ou via linha de comando:
   ```bash
   lazbuild mqtt_demo.lpi
   ```
3. Execute o programa, selecione o broker desejado e clique em **"Conectar Broker"**.
4. Clique em **"Assinar Tópico"** e em seguida em **"Publicar Mensagem"** para observar a troca de mensagens em tempo real.
