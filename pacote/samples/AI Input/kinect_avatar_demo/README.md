# Kinect → Avatar do Assistente

Sample Lazarus/Free Pascal para o repositório CHATGPT. Usa diretamente os modelos
`AVATARES/*/modelo.gltf` do Assistente e seu renderizador Castle (`TProfessorView`).
Não gera personagens novos nem modifica os modelos originais.

## Compilar e executar

No PowerShell, nesta pasta:

```powershell
.\build.ps1
.\bin\kinect_avatar_demo.exe
```

Requer o Assistente em `C:\projetos\maurinsoft\Assistente`, a biblioteca CHATGPT
e Lazarus/FPC 3.2.2 Win32. Reutiliza as unidades Castle já compiladas em
`Assistente/build/professor/units/i386-win32`. Se ausentes, compile primeiro
o professor pelo script `Assistente/scripts/build_professor.ps1`.
`build.ps1` aceita `-Assistente`, `-ChatGPT`, `-Lazarus` e `-Compiler`.
Na execução, `ASSISTENTE_ROOT` permite alterar a pasta do Assistente.

Selecione o avatar, informe o índice do sensor (normalmente 0) e clique em
**Conectar Kinect**. Use Kinect v1/Xbox 360 com alimentação/adaptador USB e
SDK Microsoft 1.8 instalado. Falhas aparecem na janela. Kinect v2/Azure não
são suportados por este backend. A captura é local e não usa a API do ChatGPT.

**Demonstração sem sensor** anima o braço do modelo selecionado.
Também pode iniciar com `--demo`. `--smoke` abre e fecha após cinco segundos;
retorna 2 se o esqueleto não estiver disponível.

## Movimento

`kinect_retarget.pas` alinha os segmentos do avatar às direções 3D das juntas,
convertendo rotações globais para o espaço local de cada pai. Aplica suavização
por quaternion. Usa braços, antebraços, coxas, pernas, tronco e pescoço.
Preserva proporções e posição do avatar. O editor de movimentos do Assistente
aplica seus limites de colisão; a pose pode ser limitada quando necessário.

Seleciona a primeira pessoa rastreada e mantém seu identificador durante
oclusões breves. Após um segundo permite selecionar outra pessoa. Juntas
inferidas ou ausentes mantêm a última rotação. Ao perder a pessoa, mantém a pose.
Não estima dedos, expressão facial, torção axial dos membros ou deslocamento
global. Essas informações não são recuperadas apenas pelas direções dos segmentos.

## Verificação

```powershell
.\build.ps1 -Target test_retarget.lpr
.\bin\test_retarget.exe
.\bin\kinect_avatar_demo.exe --smoke
```

O teste numérico verifica a conversão de direções 3D, inclusive vetores opostos.
A validação final de latência, eixos e movimentos exige captura com sensor físico.
Os modelos continuam sujeitos às licenças distribuídas pelo Assistente.
