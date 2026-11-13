# Validação — 01/11/2026

- Compilação Win32/FPC 3.2.2 concluída.
- Testes numéricos aprovados: rotação de 90°, vetores opostos, direção 3D,
  segmento nulo, pose de repouso do professor, mudança de direção do braço
  e preservação da pose quando a junta não é rastreada.
- Abertura do renderizador e carga do modelo e esqueleto do professor aprovadas
  pelo modo de verificação. A carga inicial demorou aproximadamente um minuto.
- Captura física do Kinect, latência, calibração dos eixos e aparência durante
  movimentos reais ainda não foram validadas.
- A seleção enumera os modelos do Assistente. O mapeamento de movimento usa
  nomes do rig MakeHuman; modelos com outro esqueleto precisam de mapeamento próprio.

O modo de verificação encerra cinco segundos após o início quando a carga termina;
em máquinas lentas, o carregamento inicial pode ultrapassar esse intervalo.
