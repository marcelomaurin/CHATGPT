# Roteiro de Testes Reais (sem Fake)

## Passos para Verificação Manual

1. **Abrir a aplicação**: Execute `modbus_demo.exe`.
2. **Verificar interface**: Confirme que a aba **Operação** possui os campos de seleção RTU/TCP, IP, Porta, Porta Serial, Baud Rate, Slave ID, Endereço, Quantidade e Valor, além dos botões Conectar e Desconectar.
3. **Verificar a aba Pinout**: Verifique se o Grid de pinagem está preenchido com a documentação do mapa físico do Arduino Nano.
4. **Testar sem conexão**:
   - Clique em **Ler Holding Registers** sem conectar. A aplicação deve exibir erro nos logs e o status "Status: Falha na operação".
5. **Testar com Servidor Modbus TCP Simulado**:
   - Abra um servidor Modbus TCP real em sua máquina (como `diagslave -m tcp` ou um script `pymodbus`).
   - Mude para o protocolo **TCP** na aplicação.
   - Configure o IP (`127.0.0.1`) e a porta (`502` ou a porta configurada no simulador).
   - Clique em **Conectar**.
   - Defina Slave ID = 1, Endereço = 10, Quantidade = 1.
   - Clique em **Ler Holding Registers**. A leitura deve retornar sucesso com o valor do simulador.
   - Teste a escrita: Marque "Permitir escrita em registradores", configure um valor e clique em **Escrever Single Register**.
6. **Testar com Arduino Real (RTU)**:
   - Carregue o firmware `arduino/arduino_nano_sample/arduino_nano_sample.ino` em um Arduino Nano físico.
   - Selecione **RTU** na aplicação.
   - Selecione a porta serial do Arduino e Baud Rate = 9600.
   - Clique em **Conectar** (haverá um atraso de 2 segundos para estabilização automática).
   - Faça leituras e escritas nos pinos conforme o mapa de registradores documentado no `README.md`.
