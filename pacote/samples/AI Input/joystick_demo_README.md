# 🎮 TAIJoystick — Manual do Usuário e Demonstração

O componente [`TAIJoystick`](../../../AI%20Input/AIJoystick/aijoystick.pas) fornece uma interface de leitura unificada e orientada a eventos/polling para joysticks no ambiente Windows (controles padrão Xbox 360/One via XInput e joysticks convencionais via WinMM), com fallback automático em outras plataformas.

---

## 📋 O que faz o Componente

1. **Enumeração e Hotplug:** Detecta automaticamente a conexão e desconexão de controles em tempo real sem travar a interface da aplicação.
2. **Prioridade Inteligente:** Se conectado um controle Xbox, prioriza o driver XInput (permitindo leituras analógicas e independentes dos gatilhos LT/RT). Caso contrário, utiliza WinMM para controles genéricos USB.
3. **Normalização dos Eixos:** Converte todos os ranges brutos de eixos para valores entre `-1.0` e `1.0`, com o eixo vertical padronizado (valores positivos representam movimento para cima).
4. **Sem Dependência de DLLs Extras:** Carrega dinamicamente a biblioteca XInput do diretório do Windows (`xinput1_4.dll`, `xinput1_3.dll` ou `xinput9_1_0.dll`).

---

## 🚀 Como Utilizar (Passo a Passo)

### 1. Criação e Configuração Básica

Adicione a unit `aijoystick` na cláusula `uses` do seu formulário ou projeto:

```pascal
uses
  aijoystick;

var
  Joystick: TAIJoystick;
begin
  Joystick := TAIJoystick.Create(Self);
  Joystick.DeviceID := ''; // Vazio = seleção automática do primeiro controle ativo
end;
```

### 2. Leitura Contínua via Timer (Polling)

Insira um `TTimer` no formulário configurado com intervalo entre 20ms e 50ms:

```pascal
procedure TForm1.TimerPollTimer(Sender: TObject);
begin
  if Joystick.Poll then
  begin
    // Controle conectado e lido com sucesso
    LabelStatus.Caption := 'Conectado: ' + Joystick.State.DeviceName;
    
    // Ler analógico esquerdo (Eixo 0 = X, Eixo 1 = Y)
    ProgressBarX.Position := Round((Joystick.State.Axes[0] + 1.0) * 50);
    ProgressBarY.Position := Round((Joystick.State.Axes[1] + 1.0) * 50);

    // Ler Botão A
    ShapeBtnA.Brush.Color := IfThen(Joystick.State.Controls[ajA], clLime, clGray);

    // Ler Gatilho RT (Gatilho direito)
    if Joystick.State.Controls[ajRT] then
      LogMessage('Gatilho RT pressionado (> 25%)');
  end
  else
  begin
    LabelStatus.Caption := 'Nenhum joystick conectado';
  end;
end;
```

---

## 🔍 Referência do Componente

### Propriedades (`Published` / `Public`)

| Propriedade | Tipo | Descrição |
|---|---|---|
| [`DeviceID`](../../../AI%20Input/AIJoystick/aijoystick.pas) | `string` | ID do dispositivo selecionado. Se vazio (`''`), opera em modo automático, mantendo o controle conectado ativo. Pode ser configurado manualmente para `'xinput:0'`, `'winmm:0'`, etc. |
| [`State`](../../../AI%20Input/AIJoystick/aijoystick.pas) | `TAIJoystickState` | Estrutura de somente leitura contendo o snapshot da última leitura: `Connected`, `DeviceName`, `Axes[0..5]` e `Controls[1..34]`. |
| [`Devices`](../../../AI%20Input/AIJoystick/aijoystick.pas) | `TAIJoystickDevices` | Lista dinâmica de todos os joysticks e gamepads detectados no sistema. |

### Métodos (`Public`)

| Método | Assinatura | Descrição |
|---|---|---|
| [`Poll`](../../../AI%20Input/AIJoystick/aijoystick.pas) | `function Poll: Boolean;` | Executa a varredura e atualização do estado do controle. Retorna `True` se um controle válido foi lido. Deve ser chamado na thread da interface. |
| [`RefreshDevices`](../../../AI%20Input/AIJoystick/aijoystick.pas) | `procedure RefreshDevices;` | Força a re-enumeração imediata de todos os dispositivos USB/XInput disponíveis no sistema operacional. |
| [`NormalizeAxis`](../../../AI%20Input/AIJoystick/aijoystick.pas) | `class function NormalizeAxis(Value, Minimum, Maximum: Int64): Double; static;` | Função utilitária estática para normalizar qualquer valor de eixo inteiro para o intervalo flotante de `-1.0` a `1.0`. |

### Mapeamento de Controles e Botões (`Controls[1..34]`)

- `ajA` (1), `ajB` (2), `ajX` (3), `ajY` (4): Botões de ação frontais.
- `ajLB` (5), `ajRB` (6): Botões de ombro (Bumpers).
- `7`: Botão Back / View.
- `8`: Botão Start / Menu.
- `9`, `10`: Cliques dos direcionais analógicos (L3 / R3).
- `11..14`: D-Pad digital (Cima, Baixo, Esquerda, Direita).
- `ajLT` (33), `ajRT` (34): Gatilhos analógicos virtuais (acionados quando o gatilho passa de 25% do curso).