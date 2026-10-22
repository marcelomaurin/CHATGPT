# Demonstrador de Identificação Vocal por Assinatura Acústica (`speaker_signature_demo`)

Este exemplo demonstra a utilização do componente [`TAISpeakerIdentifier`](../../../AI%20Input/AIAudio/aispeakersignature.pas), da classe de sessão [`TAISpeakerSession`](../../../AI%20Input/AIAudio/aispeakersignature.pas), do extrator nativo de características acusticas [`TAISpeakerExtractor`](../../../AI%20Input/AIAudio/aispeakersignature.pas) e do catálogo persistente em disco [`TAISpeakerRegistry`](../../../AI%20Input/AIAudio/aispeakersignature.pas), todos integrantes do pacote [`openai_input.lpk`](../../packages/openai_input.lpk).

## O que a aplicação faz
1. **Extração de Biometria Vocal de Áudio WAV**: Lê arquivos de áudio WAV (PCM linear de 8 ou 16 bits, taxas de 8 kHz a 48 kHz, mono ou estéreo), aplica algoritmo de detecção de atividade vocal (VAD) para descartar silêncios e ruídos de fundo, calcula janela de Hamming e FFT de 512 pontos com divisão espectral em 16 sub-bandas e extrai um vetor normalizado de 32 dimensões.
2. **Comparação Direta de Vozes**: Permite carregar dois arquivos WAV quaisquer e comparar a similaridade de cosseno das vozes gravadas, informando se pertencem ao mesmo locutor (`sdSame`), a locutores diferentes (`sdDifferent`) ou se o resultado é inconclusivo (`sdInconclusive`).
3. **Catálogo Persistente de Locutores em Disco**: Permite cadastrar locutores conhecidos pelo seu ID e Nome, gravando a assinatura vocal em um arquivo JSON persistente no disco (`speakers_catalog.json`) para identificação permanente futura.
4. **Identificação Biométrica de Fala Desconhecida**: Recebe uma fala não identificada, busca no catálogo persistente e aponta automaticamente quem é o locutor com a respectiva porcentagem de confiança.

---

## Como Utilizar (Passo a Passo)

### 1. Comparar Duas Vozes Diretamente
1. No painel **1. Comparação Direta Entre Duas Gravações WAV**:
   - Clique em **Procurar...** no campo *Áudio WAV 1 (Ref)* e selecione um arquivo `.wav` de fala.
   - Clique em **Procurar...** no campo *Áudio WAV 2 (Cmp)* e selecione outro arquivo `.wav`.
2. Clique em **Comparar Assinaturas**.
3. O sistema exibirá o veredicto em destaque e registrará o log da operação:
   - `MESMO LOCUTOR (Confiança: 98.9%)`
   - `LOCUTORES DIFERENTES (Similaridade: 4.2%)`
   - `INCONCLUSIVO (Similaridade intermediária)`

### 2. Cadastrar Locutores no Catálogo Persistente
1. No painel **2. Catálogo Persistente em Disco**:
   - Digite o identificador único no campo **ID do Locutor** (ex: `user_01`, `marcelo`).
   - Digite o nome completo no campo **Nome do Locutor** (ex: `Marcelo Maurin`).
   - Certifique-se de que o campo *Áudio WAV 1* aponta para a gravação da voz do usuário a ser cadastrado.
2. Clique no botão **Cadastrar com WAV 1**.
3. A assinatura vocal de 32 dimensões será extraída e gravada automaticamente em `speakers_catalog.json`.
4. A lista de locutores cadastrados será atualizada imediatamente.

### 3. Identificar Locutor Desconhecido
1. No painel **3. Identificação Biométrica Vocal**:
   - Clique em **Procurar...** no campo *Áudio Desconhecido* e selecione qualquer arquivo `.wav` gravado.
2. Clique em **Identificar Quem Está Falando**.
3. O sistema examina todos os locutores cadastrados no catálogo persistente:
   - Se a similaridade for superior ao limiar (ex: `>= 82%`), o locutor será identificado em verde: `RECONHECIDO: Marcelo Maurin (user_01) - 98.9%`.
   - Se a voz não pertencer a nenhum locutor cadastrado, o sistema rejeitará em vermelho com `REJEITADO: Locutor não cadastrado na base`.

---

## Estrutura dos Componentes e Classes

### [`TAISpeakerExtractor`](../../../AI%20Input/AIAudio/aispeakersignature.pas)
Extrator de características acustico-espectrais nativo em Pascal:
- `ExtractFromWav(const AWavFileName: string; out ASig: TAISpeakerSignature; out AError: string): Boolean`: decodifica o arquivo WAV PCM, executa VAD e calcula o vetor de 32 dimensões com norma L2 unitária.
- `ExtractFromPCM(const ASamples: array of Double; ASampleRate: Integer; out ASig: TAISpeakerSignature; out AError: string): Boolean`: processamento direto de buffers PCM normalizados `[-1.0 .. +1.0]`.

### [`TAISpeakerSession`](../../../AI%20Input/AIAudio/aispeakersignature.pas)
Gerencia a sessão de comparação entre áudio de referência e áudio de entrada:
- `Similarity(const A, B: TAISpeakerSignature): Double`: calcula a similaridade por cosseno entre dois vetores.
- `Evaluate(const ASignature: TAISpeakerSignature; out ADecision: TAISpeakerDecision): Boolean`: avalia a assinatura contra a referência bloqueada na sessão.
- `SaveToFile / LoadFromFile`: persistência da sessão em arquivo JSON.

### [`TAISpeakerRegistry`](../../../AI%20Input/AIAudio/aispeakersignature.pas)
Gerenciador de catálogo multi-locutor persistente em disco:
- `AddOrUpdate(const ASpeakerID, ASpeakerName: string; const ASig: TAISpeakerSignature): Boolean`: adiciona ou atualiza o perfil de um locutor.
- `Remove(const ASpeakerID: string): Boolean`: remove um locutor do catálogo.
- `IdentifySpeaker(const ASig: TAISpeakerSignature; out AIdentifiedID, AIdentifiedName: string; out AMaxScore: Double; AThreshold: Double = 0.82): Boolean`: encontra o perfil mais similar no catálogo que satisfaça o limiar de aceitação.
- `SaveToFile / LoadFromFile`: serialização e desserialização completa da base de locutores em JSON.

### [`TAISpeakerIdentifier`](../../../AI%20Input/AIAudio/aispeakersignature.pas)
Componente de alto nível registrável na paleta do Lazarus (`AI Communication`):
- **Propriedades**:
  - `RegistryFile`: caminho do arquivo JSON de catálogo persistente em disco.
  - `AutoSave`: ativa gravação automática em disco a cada novo cadastro.
  - `SameThreshold`: limiar mínimo de similaridade para aceitar mesmo locutor (padrão: `0.82`).
  - `DifferentThreshold`: limiar máximo para rejeição definitiva de locutor (padrão: `0.58`).
- **Métodos**:
  - `ExtractSignature(const AWavFileName: string; out ASig: TAISpeakerSignature): Boolean`
  - `RegisterSpeakerFromWav(const ASpeakerID, ASpeakerName, AWavFileName: string): Boolean`
  - `IdentifyFromWav(const AWavFileName: string; out ASpeakerID, ASpeakerName: string; out AConfidence: Double): Boolean`
  - `VerifyFromWav(const AWavFileName, ASpeakerID: string; out ADecision: TAISpeakerDecision; out AConfidence: Double): Boolean`
- **Eventos**:
  - `OnSpeakerIdentified`: disparado ao identificar com sucesso um locutor cadastrado.
  - `OnSpeakerRejected`: disparado ao rejeitar um áudio cujo locutor não está no catálogo.