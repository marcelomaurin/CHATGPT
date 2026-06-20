# Sound Filters Visual Demo

## Visão geral

O `sound_filters_visual_demo` é um exemplo visual feito em Lazarus para demonstrar o uso dos componentes de filtros sonoros do projeto CHATGPT.

A ideia do exemplo é mostrar, de forma gráfica, como um sinal de áudio pode ser gerado em memória, processado por filtros digitais e exibido na tela antes e depois da filtragem.

Este demo **não deve usar Simulation Mode**. O objetivo correto é trabalhar com dados reais em memória, usando arrays numéricos de amostras de áudio.

---

## Componente utilizado

O exemplo usa a unit:

```pascal
soundfilters
```

Essa unit contém os principais componentes usados no demo:

```pascal
TLowPassFilter
THighPassFilter
TAverageFilter
```

No formulário principal, os filtros devem ser declarados como campos privados:

```pascal
private
  FLowPass: TLowPassFilter;
  FHighPass: THighPassFilter;
  FAverage: TAverageFilter;
```

E criados no `FormCreate`:

```pascal
procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FLowPass := TLowPassFilter.Create(Self);
  FHighPass := THighPassFilter.Create(Self);
  FAverage := TAverageFilter.Create(Self);
end;
```

---

## Para que serve cada filtro

### TLowPassFilter

O `TLowPassFilter` é um filtro passa-baixa.

Ele deixa passar frequências baixas e reduz frequências altas.

Exemplo:

```text
Base frequency: 1000 Hz
Noise frequency: 12000 Hz
Low-pass cutoff: 4000 Hz
```

Nesse caso:

```text
1000 Hz deve permanecer, porque está abaixo de 4000 Hz.
12000 Hz deve ser reduzido, porque está acima de 4000 Hz.
```

Uso básico:

```pascal
FLowPass.SampleRate := 44100;
FLowPass.CutoffFrequency := 4000;
FLowPass.Reset;
FOutputSignal := FLowPass.ProcessArray(FInputSignal);
```

---

### THighPassFilter

O `THighPassFilter` é um filtro passa-alta.

Ele reduz frequências baixas e deixa passar frequências altas.

Exemplo:

```text
Base frequency: 1000 Hz
Noise frequency: 12000 Hz
High-pass cutoff: 6000 Hz
```

Nesse caso:

```text
1000 Hz deve ser reduzido, porque está abaixo de 6000 Hz.
12000 Hz deve permanecer mais forte, porque está acima de 6000 Hz.
```

Uso básico:

```pascal
FHighPass.SampleRate := 44100;
FHighPass.CutoffFrequency := 6000;
FHighPass.Reset;
FOutputSignal := FHighPass.ProcessArray(FInputSignal);
```

> Observação: para teste didático, o corte do passa-alta deve ficar abaixo da frequência de ruído. Por isso, `6000 Hz` é melhor do que `12000 Hz` quando o ruído gerado está em `12000 Hz`.

---

### TAverageFilter

O `TAverageFilter` é um filtro de média móvel.

Ele suaviza o sinal, reduzindo variações rápidas. É útil para demonstrar redução simples de ruído.

Exemplo:

```pascal
FAverage.WindowSize := 5;
FAverage.Reset;
FOutputSignal := FAverage.ProcessArray(FInputSignal);
```

Quanto maior o `WindowSize`, maior tende a ser a suavização.

---

## Fluxo correto do exemplo

O fluxo correto do `sound_filters_visual_demo` deve ser:

```text
1. Gerar um sinal de entrada em memória.
2. Configurar o filtro escolhido.
3. Aplicar o filtro usando ProcessArray.
4. Guardar o resultado em outro array.
5. Mostrar o sinal original e o sinal filtrado.
6. Mostrar métricas para o usuário entender o resultado.
7. Mostrar uma explicação simples dizendo se o filtro funcionou.
```

---

## Geração do sinal

O demo deve gerar um sinal numérico em memória usando um array:

```pascal
FInputSignal: TDoubleArray;
```

O sinal deve combinar:

```text
uma frequência base + um ruído de alta frequência
```

Exemplo:

```pascal
Signal[I] :=
  Sin(2 * Pi * BaseFrequency * T) +
  NoiseAmplitude * Sin(2 * Pi * NoiseFrequency * T);
```

Com valores padrão:

```text
Sample rate: 44100 Hz
Duration: 1 second
Base frequency: 1000 Hz
Noise frequency: 12000 Hz
Noise amplitude: 0.35
```

Esse sinal permite testar os filtros de forma visual e mensurável.

---

## Aplicação do filtro

Depois de gerar o sinal, o usuário escolhe um filtro na aba `Filters`.

Exemplo de aplicação:

```pascal
if cbFilterType.Text = 'Low-pass' then
begin
  FLowPass.SampleRate := FSampleRate;
  FLowPass.CutoffFrequency := StrToFloatDef(edtLowPassCutoff.Text, 4000);
  FLowPass.Reset;
  FOutputSignal := FLowPass.ProcessArray(FInputSignal);
end
else if cbFilterType.Text = 'High-pass' then
begin
  FHighPass.SampleRate := FSampleRate;
  FHighPass.CutoffFrequency := StrToFloatDef(edtHighPassCutoff.Text, 6000);
  FHighPass.Reset;
  FOutputSignal := FHighPass.ProcessArray(FInputSignal);
end
else if cbFilterType.Text = 'Moving average' then
begin
  FAverage.WindowSize := StrToIntDef(edtAverageWindow.Text, 5);
  FAverage.Reset;
  FOutputSignal := FAverage.ProcessArray(FInputSignal);
end;
```

O uso de `Reset` é importante porque filtros digitais guardam estado interno entre uma execução e outra.

---

## O que o usuário deve ver na tela

A aba `Result` deve mostrar:

```text
Input signal
Filtered signal
Signal metrics
Plain explanation
PASS / WARNING / FAIL
```

O usuário não deve precisar entender teoria de áudio para saber se o filtro funcionou.

---

## Métricas recomendadas

O demo deve calcular e exibir:

```text
Input samples
Output samples
Sample rate
Duration
Selected filter
Input peak
Output peak
Input RMS
Output RMS
```

Os números devem ser formatados com no máximo 3 casas decimais.

Exemplo correto:

```text
Input peak: 1.341
Output peak: 1.053
Input RMS: 0.749
Output RMS: 0.679
```

Evitar números longos como:

```text
1,3412605356136484
```

---

## Explicação simples do resultado

Além das métricas, o demo deve mostrar uma explicação simples.

### Exemplo para Low-pass

```text
The low-pass filter keeps frequencies below the cutoff and reduces frequencies above it.

In this test, the 1000 Hz base signal is below the 4000 Hz cutoff and should remain.
The 12000 Hz noise is above the cutoff and should be reduced.

Result: PASS.
The output RMS decreased, indicating that part of the high-frequency energy was reduced.
```

### Exemplo para High-pass

```text
The high-pass filter reduces frequencies below the cutoff and keeps frequencies above it.

In this test, the 1000 Hz base signal is below the 6000 Hz cutoff and should be reduced.
The 12000 Hz noise is above the cutoff and should remain.

Result: PASS.
The output signal contains less low-frequency energy.
```

### Exemplo para Moving average

```text
The moving average filter smooths fast variations in the signal.

Result: PASS.
The output signal is smoother and the peak/RMS values were reduced.
```

---

## Validação PASS / WARNING / FAIL

O demo deve mostrar um resultado visual simples:

```text
PASS
WARNING
FAIL
```

Sugestão de regra inicial:

### Low-pass

```text
PASS    -> Output RMS menor que Input RMS
WARNING -> Output RMS quase igual ao Input RMS
FAIL    -> Output RMS maior que Input RMS
```

### High-pass

```text
PASS    -> O sinal foi alterado e o componente de baixa frequência foi reduzido
WARNING -> Pouca alteração detectada
FAIL    -> Nenhuma alteração ou resultado incompatível
```

### Moving average

```text
PASS    -> Output peak ou Output RMS menor que Input
WARNING -> Pouca suavização detectada
FAIL    -> Nenhuma alteração detectada
```

---

## Visualização do sinal

O demo não deve desenhar todas as 44100 amostras diretamente no `PaintBox`, pois isso deixa o gráfico comprimido e difícil de entender.

Adicionar uma opção de visualização:

```text
View mode:
- First 5 ms
- First 20 ms
- Full signal envelope
```

Valor padrão recomendado:

```text
First 5 ms
```

---

## O que o demo não deve fazer

O exemplo **não deve**:

```text
usar Simulation Mode
fingir carregar audio.wav
fingir conversão WAV
mostrar "Simulated wav file conversion"
mostrar sucesso falso
criar controles principais em runtime
```

Enquanto não existir leitor WAV real no componente, o demo deve explicar que trabalha com:

```text
real numeric sample arrays in memory
```

---

## Texto curto para o README

```markdown
## How this demo uses the sound filter components

This demo uses the `soundfilters` unit and the following components:

- `TLowPassFilter`
- `THighPassFilter`
- `TAverageFilter`

The demo generates a real in-memory audio signal composed of a base sine wave plus high-frequency noise. The generated signal is stored in a `TDoubleArray`.

When the user selects a filter and clicks `Apply Filter`, the demo configures the selected component and calls its `ProcessArray` method.

The result is stored in another `TDoubleArray` and displayed as a filtered waveform.

The demo does not use simulation mode. It processes real numeric sample arrays in memory.

The goal is to visually demonstrate how low-pass, high-pass and moving average filters affect a signal.
```

---

## Explicação simples para o usuário final

O demo funciona assim:

```text
Ele cria um som matemático dentro da memória.
Esse som tem uma parte principal e uma parte de ruído.
Depois ele passa esse som por um filtro.
O filtro tenta reduzir uma parte do sinal.
A tela mostra o antes e o depois.
As métricas mostram se o sinal mudou.
```

Resumo dos filtros:

```text
Low-pass:
Mantém sons baixos/graves e reduz sons altos/agudos.

High-pass:
Reduz sons baixos/graves e mantém sons altos/agudos.

Moving average:
Suaviza o sinal e reduz variações rápidas.
```

---

## Conclusão

O `sound_filters_visual_demo` deve demonstrar o uso real dos componentes:

```pascal
TLowPassFilter.ProcessArray
THighPassFilter.ProcessArray
TAverageFilter.ProcessArray
```

Ele deve aplicar filtros sobre sinais numéricos reais em memória, mostrar o antes e depois, exibir métricas e explicar o resultado em linguagem simples.

O exemplo correto não deve simular processamento, não deve fingir conversão de arquivo WAV e não deve mostrar mensagens falsas.
