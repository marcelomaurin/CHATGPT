# Email Client & Classifier Demo (TAIEmailClient)

Este projeto de demonstração ilustra como utilizar o componente `TAIEmailClient` (do pacote `openai_input`) para gerenciar conexões de e-mail reais e classificar o conteúdo de mensagens recebidas.

## Funcionalidades Demonstradas

Este demo exercita a integração direta com servidores de e-mail via sockets nativos:
1. **Configurações SMTP**: Define o Host (`HostSMTP`), Porta (`PortSMTP`), Usuário (`Username`) e Senha (`Password`) para conexões de envio.
2. **Configurações POP3**: Define o Host (`HostPOP3`), Porta (`PortPOP3`), Usuário (`Username`) e Senha (`Password`) para conexões de recebimento.
3. **Envio Real de E-mail**: Utiliza o método `SendEmail(ATo, ASubject, ABody)` para despachar uma mensagem de teste.
4. **Recebimento Real de Cabeçalhos**: Utiliza o método `FetchEmails(out AEmails)` para coletar as mensagens armazenadas no servidor.
5. **Classificador de Mensagens Local**: Classifica automaticamente cada e-mail recebido em tempo real através de filtros textuais estruturados:
   - `URGENT SUPPORT` (Assuntos contendo: *urgent*, *alerta*, *urgente*, *critico*)
   - `BILLING / INVOICE` (Assuntos contendo: *invoice*, *fatura*, *pagamento*, *boleto*)
   - `SPAM / ADVERTISING` (Assuntos contendo: *win*, *promo*, *oferta*, *desconto*, *gratis*)
   - `GENERAL INQUIRY` (Para outros assuntos gerais)

## Como Compilar e Executar

1. Certifique-se de que o pacote `openai_input.lpk` está instalado ou referenciado no seu ambiente Lazarus.
2. Abra o arquivo de projeto `email_classifier_demo.lpi` no Lazarus.
3. Insira suas credenciais e endereços de servidores SMTP/POP3 nos campos de texto da tela.
4. Pressione **F9** para compilar e executar o projeto (ou execute via `lazbuild`).
5. Use os botões da interface para enviar um e-mail de teste ou para buscar e classificar mensagens reais em sua caixa postal.
