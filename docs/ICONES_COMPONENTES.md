# Ícones dos componentes

A paleta usa pictogramas de 24 × 24 pixels, sem letras, iniciais ou texto dentro
dos ícones. Cores identificam as áreas da suíte; símbolos e pequenos indicadores
gráficos representam a função e a operação do componente.

O desenho é feito por `pacote/palette_pictograms.py`, sem fontes e sem dependências
de bibliotecas de imagem. `pacote/generate_all_icons.py` converte os desenhos para
os recursos BMP/LRS nativos do Lazarus e inclui também os antigos recursos manuais.

```text
python pacote/generate_all_icons.py
python pacote/generate_all_icons.py --check
python tests/ci_validate_icons.py
python -m unittest discover -s tests -p test_ci_validate_icons.py
```

A validação confere o conteúdo dos bitmaps, o nome das classes e o carregamento
dos recursos pelos pacotes que registram os componentes. Um LRS apenas existente
no disco não é suficiente: ele precisa ser incluído por uma unidade do pacote
ou por uma dependência.

As unidades `*_paletteicons.pas` carregam recursos de design-time sem adicionar
dependências gráficas às unidades de execução. Elas constam nos arquivos LPK,
por isso continuam vinculadas quando o Lazarus regenera o fonte do pacote.

O componente de identificação de locutor integra `openai_input`. O listener
contínuo de `openai_voice` carrega o mesmo recurso da implementação compatível
existente em `AI Input/AIAudio`, evitando dois desenhos ou nomes divergentes.
