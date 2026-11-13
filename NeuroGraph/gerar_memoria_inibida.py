#!/usr/bin/env python3
"""Recria o mapa binário inicial, com todos os pesos zero.
Formato NGMAP001: magic(8), versão(u32), tokens(u32), arestas(u32),
tokens [comprimento(u32), UTF8], arestas [origem(u32), destino(u32), peso(f32)].
Little-endian. Não cria associações semânticas aprendidas.
"""
import struct
from pathlib import Path

GROUPS = [
  "a o as os um uma uns umas de do da dos das em no na nos nas por para com sem sob sobre entre até desde após antes depois que quem qual quais quando onde como porque se não sim e ou mas porém embora enquanto então já ainda também só muito pouco mais menos todo toda todos todas cada algum alguma alguns algumas nenhum nenhuma este esta estes estas esse essa esses essas aquele aquela aqueles aquelas eu tu você vocês ele ela eles elas nós meu minha meus minhas seu sua seus suas nosso nossa nossos nossas ser estar ter haver fazer ir vir poder dever querer saber dizer falar ouvir ver olhar sentir pensar conhecer entender aprender ensinar lembrar esquecer gostar precisar tentar conseguir começar terminar continuar mudar criar usar dar receber levar trazer deixar ficar parecer acontecer existir tornar",
  "homem mulher pessoa criança jovem adulto idoso bebê menino menina pai mãe filho filha irmão irmã avô avó amigo amiga família gente povo grupo equipe professor professora aluno aluna estudante médico médica enfermeiro enfermeira paciente trabalhador funcionária funcionário gestor gestora usuário usuária cliente cidadão cidadã",
  "casa apartamento prédio rua avenida cidade bairro estado país mundo lugar espaço quarto sala cozinha banheiro porta janela parede chão teto mesa cadeira cama sofá armário escola universidade hospital posto clínica escritório empresa loja mercado restaurante parque praça jardim campo fazenda floresta rio lago mar praia montanha céu terra sol lua estrela planeta árvore flor folha raiz fruto semente animal cachorro cão cadela gato gata pássaro peixe cavalo vaca inseto",
  "água ar fogo luz calor frio vento chuva neve nuvem tempo dia noite manhã tarde hoje ontem amanhã semana mês ano hora minuto segundo momento início fim passado presente futuro história memória conhecimento informação dado dados palavra frase texto livro página documento arquivo pasta programa sistema computador máquina servidor rede internet site aplicativo celular telefone tela teclado mouse câmera microfone alto-falante voz som imagem vídeo foto gráfico mapa grafo nó conexão relação peso sinal ativação token tokens neurônio neurônios inteligência artificial modelo algoritmo função variável número valor cálculo resultado entrada saída resposta pergunta comando tarefa processo teste erro acerto",
  "bom boa bons boas ruim grande pequeno pequena alto alta baixo baixa novo nova velho velha forte fraco rápida rápido lento lenta fácil difícil claro clara escuro escura certo certa errado errada verdadeiro verdadeira falso falsa possível impossível importante necessário útil diferente igual próximo próxima distante aberto aberta fechado fechada livre ocupado vazia vazio cheio cheia feliz triste calmo calma bonito bonita simples complexo complexa seguro segura perigoso perigosa",
  "andar correr caminhar pular sentar levantar dormir acordar comer beber cozinhar comprar vender pagar trabalhar estudar ler escrever desenhar pintar cantar dançar brincar jogar treinar cuidar ajudar proteger construir quebrar abrir fechar ligar desligar entrar sair subir descer chegar partir viajar voltar buscar encontrar perder guardar salvar carregar baixar enviar compartilhar copiar colar cortar escolher decidir comparar medir contar somar subtrair multiplicar dividir calcular verificar testar corrigir atualizar instalar executar compilar programar conectar associar relacionar propagar reforçar reduzir aumentar diminuir armazenar registrar consultar pesquisar responder perguntar gerar produzir reconhecer identificar classificar organizar planejar controlar monitorar analisar explicar descrever mostrar exibir",
  "zero um dois três quatro cinco seis sete oito nove dez cem mil milhão primeiro primeira segundo segunda terceiro terceira último última esquerda direita frente trás cima baixo dentro fora perto longe norte sul leste oeste vermelho vermelha azul verde amarelo amarela preto preta branco branca cinza marrom roxo roxa laranja rosa círculo quadrado triângulo linha ponto curva ângulo tamanho largura altura comprimento profundidade distância velocidade força energia potência massa volume temperatura pressão corrente tensão resistência frequência",
  "saúde doença dor febre tosse sangue coração pulmão cérebro corpo cabeça braço mão dedo perna pé olho orelha boca nariz pele osso músculo célula tecido órgão remédio medicamento exame consulta atendimento tratamento vacina alimentação exercício descanso higiene matemática física química biologia português linguagem língua gramática ciência tecnologia engenharia eletrônica mecânica informática programação código fonte memória processamento armazenamento banco tabela registro chave identificador índice estrutura matriz vetor lista conjunto sequência ordem direção contexto significado semântica sintaxe probabilidade confiança aprendizado aprendizagem treinamento inferência conhecimento associação conexão pesos estímulo inibição inibido inibida ativado ativada desativado desativada"
]
tokens = list(dict.fromkeys(token for group in GROUPS for token in group.split()))
assert len(tokens) == 691, len(tokens)
path = Path(__file__).resolve().parent / "neurograph_memoria_ptbr_inibida_completa.ngm"
n = len(tokens)
with path.open("wb") as f:
    f.write(struct.pack("<8sIII", b"NGMAP001", 1, n, n * (n - 1)))
    for token in tokens:
        raw = token.encode("utf-8")
        f.write(struct.pack("<I", len(raw)))
        f.write(raw)
    for a in range(n):
        for b in range(n):
            if a != b:
                f.write(struct.pack("<IIf", a, b, 0.0))
print(f"{path}: {n} tokens, {n*(n-1)} conexões inibidas, {path.stat().st_size} bytes")
