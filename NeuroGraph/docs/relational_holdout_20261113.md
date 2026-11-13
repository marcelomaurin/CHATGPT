# NeuroGraph — experimento de propagação relacional (2026-11-13)

Referência: `NeuroGraph/tests/relational_holdout_20261113.py`.

## Método
20 triplas de fatos em português, 15 para treino e 5 sujeitos inteiros reservados para teste. 10 consultas com relação ausente testam abstenção. Comparamos uma passagem contra duas passagens sobre **o mesmo grafo** e os mesmos pesos (1.0 nas arestas, decaimento 0.9 por salto, limiar 0.5). A inferência não usa regras gramaticais; as triplas já vêm estruturadas, portanto isto **não** avalia compreensão de perguntas em linguagem natural.

## Resultado reproduzido com Python 3
| Métrica | 1 salto | 2 saltos |
|---|---:|---:|
| Acertos em fatos treinados | 0/15 | 15/15 |
| Acertos em sujeitos reservados | 0/5 | 0/5 |
| Abstenções em relações ausentes | 10/10 | 10/10 |

Duas passagens permitem recuperar relações de dois saltos, mas **não** generalizam para sujeitos não vistos. Os resultados são do protótipo Python, não do motor Free Pascal, nem da memória v6. Não houve ajuste de pesos da v6.

## Próximas etapas
1. Adicionar testes equivalentes ao motor `NeuroGraphCore.pas` com FPC e comparar sinais de ativação.
2. Introduzir aprendizado de arestas supervisionado/contrastivo, com validação por famílias inteiras e teste final lacrado.
3. Integrar tokenização portuguesa sem codificar regras gramaticais para produzir respostas.
4. Medir cobertura, respostas indevidas, latência, RAM e regressão contra pesos v6 antes de qualquer substituição.

A execução não dispunha do compilador FPC, então a compatibilidade com Lazarus ainda não foi verificada.
