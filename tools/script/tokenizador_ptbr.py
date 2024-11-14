import spacy
import json
import os

def processar_palavras(arquivo_entrada, arquivo_saida):
    # Carrega o modelo de linguagem para português
    nlp = spacy.load('pt_core_news_lg')

    # Garante que o diretório de saída exista
    diretorio_saida = os.path.dirname(arquivo_saida)
    os.makedirs(diretorio_saida, exist_ok=True)

    # Lê o conteúdo inteiro do arquivo
    with open(arquivo_entrada, 'r', encoding='iso-8859-1') as file:
        linhas = file.read().splitlines()

    # Lista para guardar todos os tokens
    all_tokens = []

    # Processa cada linha e extrai os tokens
    for linha in linhas:
        print('Processando linha:', linha)  # Print para depuração
        doc = nlp(linha.strip())  # Tokeniza a linha
        tokens = [{'token': token.text} for token in doc]  # Prepara os dados para JSON
        all_tokens.append({linha: tokens})  # Adiciona os tokens da linha à lista geral
        print('Tokens:', tokens)  # Print para depuração

    # Print final antes de salvar
    print('Todos os tokens:', all_tokens)

    # Salva todos os tokens no arquivo JSON especificado
    with open(arquivo_saida, 'w', encoding='utf-8') as f:
        json.dump(all_tokens, f, ensure_ascii=False, indent=4)

# Exemplo de uso
entrada = 'br-com-trema-latin1.txt'
saida = './saida/Dicionario_PTBR.json'
processar_palavras(entrada, saida)

