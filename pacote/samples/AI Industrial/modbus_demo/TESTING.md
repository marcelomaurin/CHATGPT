# Roteiro de Testes Reais (sem Fake)

## Passos para Verificacao Manual

1. **Abrir a aplicacao**: Execute `modbus_demo.exe`.
2. **Verificar interface**: Confirme que a aba de operacao possui os campos de selecao RTU/TCP, IP, Porta, Porta Serial, Baud Rate, Slave ID, Endereco, Quantidade e Valor, alem dos botoes Conectar e Desconectar.
3. **Verificar a aba Pinout**: Verifique se o grid de pinagem esta preenchido com a documentacao do mapa fisico do Arduino Nano.
4. **Testar sem conexao**:
   - Clique em **Ler Holding Registers** sem conectar. A aplicacao deve exibir erro nos logs e o status "Status: Falha na operacao".
5. **Testar com Servidor Modbus TCP real**:
   - Abra um servidor Modbus TCP real em sua maquina, como `diagslave -m tcp` ou um script `pymodbus`.
   - Mude para o protocolo **TCP** na aplicacao.
   - Configure o IP (`127.0.0.1`) e a porta (`502` ou a porta configurada no servidor).
   - Clique em **Conectar**.
   - Defina Slave ID = 1, Endereco = 10, Quantidade = 1.
   - Clique em **Ler Holding Registers**. A leitura deve retornar sucesso com o valor do servidor.
   - Teste a escrita: marque "Permitir escrita em registradores", configure um valor e clique em **Escrever Single Register**.
6. **Testar com Arduino Nano real (RTU)**:
   - Carregue o firmware `arduino/arduino_nano_sample/arduino_nano_sample.ino` em um Arduino Nano fisico.
   - Selecione **RTU** na aplicacao.
   - Selecione a porta serial do Arduino e Baud Rate = 9600.
   - Clique em **Conectar**.
   - Faça leituras e escritas nos pinos conforme o mapa de registradores documentado no `README.md`.
7. **Testar com ESP32 real (RTU)**:
   - Carregue o firmware `arduino/esp32_modbus_sample/esp32_modbus_sample.ino` em uma placa ESP32 compatível.
   - Use a porta serial USB do ESP32 ou adapte o sketch para `Serial2` se estiver usando um conversor RS485.
   - Selecione **RTU** na aplicacao.
   - Selecione a porta serial da placa e Baud Rate = 9600.
   - Clique em **Conectar**.
   - Faça leituras e escritas nos registradores conforme o mapa do ESP32 no `README.md`.
