# Manual do Protocolo DOCX (OpenXML / WordprocessingML)

Este manual descreve de forma técnica e detalhada a especificação do formato **DOCX**, baseado no padrão **OpenXML (ECMA-376 / ISO/IEC 29500)**. Ele serve como guia de referência para o desenvolvimento e manutenção do componente `TAIWordDocument`, fornecendo os esquemas XML, as convenções de empacotamento, as regras de conversão de unidades e os relacionamentos internos do formato WordprocessingML.

---

## 1. O Formato OPC (Open Packaging Conventions)

Um arquivo `.docx` não é um arquivo binário simples, mas sim um arquivo **ZIP** compactado contendo uma estrutura específica de pastas e arquivos XML, conhecida como **Open Packaging Conventions (OPC)**.

### 1.1 Estrutura de Diretórios Mínima
Para que um arquivo `.docx` seja considerado válido e possa ser aberto pelo Microsoft Word ou LibreOffice, ele deve conter a seguinte estrutura de arquivos internos:

```text
meu_documento.docx (Arquivo ZIP)
├── [Content_Types].xml
├── _rels/
│   └── .rels
├── docProps/
│   ├── core.xml
│   └── app.xml
└── word/
    ├── document.xml
    ├── styles.xml
    ├── settings.xml
    ├── _rels/
    │   └── document.xml.rels
    └── media/  (Opcional: se houver imagens)
        └── image1.png
```

---

## 2. Arquivos Globais de Estrutura

### 2.1 `[Content_Types].xml`
Este arquivo fica na raiz do ZIP e descreve os tipos de conteúdo (MIME types) de todas as partes incluídas no pacote. Se um tipo de arquivo ou arquivo XML específico não estiver listado aqui, o Word reportará o arquivo como corrompido.

#### Exemplo de `[Content_Types].xml` mínimo:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <!-- Extensões padrão -->
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Default Extension="png" ContentType="image/png"/>
  <Default Extension="jpeg" ContentType="image/jpeg"/>
  <Default Extension="jpg" ContentType="image/jpeg"/>
  
  <!-- Partes específicas do WordprocessingML -->
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>
```

### 2.2 Relacionamentos Globais: `_rels/.rels`
Localizado na pasta `_rels/`, define o ponto de entrada principal do pacote ZIP. Ele instrui o leitor a encontrar o documento principal (`word/document.xml`) e as propriedades do documento.

#### Exemplo de `_rels/.rels`:
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" 
                Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" 
                Target="word/document.xml"/>
  <Relationship Id="rId2" 
                Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" 
                Target="docProps/core.xml"/>
  <Relationship Id="rId3" 
                Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" 
                Target="docProps/app.xml"/>
</Relationships>
```

---

## 3. O Documento Principal (`word/document.xml`)

Este arquivo contém o fluxo real de texto, tabelas, imagens e estruturas de layout do documento.

### 3.1 Tags Fundamentais (Hierarquia de Texto)

Toda a estrutura textual é hierárquica e obedece à regra de contenção:
`w:document` $\rightarrow$ `w:body` $\rightarrow$ `w:p` (Parágrafo) $\rightarrow$ `w:r` (Run/Trecho) $\rightarrow$ `w:t` (Texto).

| Tag | Descrição |
| :--- | :--- |
| `<w:document>` | O elemento raiz do documento. Define os namespaces do WordprocessingML. |
| `<w:body>` | O corpo do documento, que abriga o conteúdo visível. |
| `<w:p>` | **Parágrafo** (Paragraph). Agrupa linhas de texto e define o alinhamento. |
| `<w:pPr>` | **Propriedades do Parágrafo** (Paragraph Properties). Contém estilos, alinhamento, etc. |
| `<w:r>` | **Trecho** (Run). Define um bloco contínuo de texto com a mesma formatação (fonte, negrito, etc.). |
| `<w:rPr>` | **Propriedades do Run** (Run Properties). Formatação da fonte (negrito, itálico, cor). |
| `<w:t>` | **Texto** (Text). Contém a string visível. |

### 3.2 Estrutura Mínima de Texto
```xml
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr>
        <w:jc w:val="both"/> <!-- Alinhamento Justificado -->
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/> <!-- Negrito -->
          <w:sz w:val="24"/> <!-- Tamanho da Fonte (12pt = 24 half-points) -->
          <w:rFonts w:ascii="Arial" w:hAnsi="Arial"/>
        </w:rPr>
        <w:t xml:space="preserve">Este é um parágrafo formatado em negrito e Arial 12.</w:t>
      </w:r>
    </w:p>
  </w:body>
</w:document>
```
> [!IMPORTANT]
> A propriedade `xml:space="preserve"` na tag `<w:t>` é de extrema importância quando o texto contém espaços em branco no início ou no fim. Sem ela, os softwares de leitura (como o MS Word) ignoram múltiplos espaços subsequentes.

---

## 4. Elementos de Formatação e Estilos

### 4.1 Formatação do Parágrafo (`w:pPr`)
As propriedades do parágrafo definem como o bloco inteiro se comporta.

* **Alinhamento (`w:jc`)**:
  - `<w:jc w:val="left"/>` (Esquerda)
  - `<w:jc w:val="center"/>` (Centralizado)
  - `<w:jc w:val="right"/>` (Direita)
  - `<w:jc w:val="both"/>` (Justificado)
* **Espaçamento (`w:spacing`)**:
  - `<w:spacing w:before="240" w:after="120" w:line="240" w:lineRule="auto"/>`
  - Valores são definidos em **Twips** (1/20 de ponto). `before` é o espaço antes, `after` o espaço depois.
* **Recuo (`w:ind`)**:
  - `<w:ind w:left="720" w:firstLine="360"/>` (Recuo esquerdo e recuo da primeira linha).

### 4.2 Formatação do Run (`w:rPr`)
Aplica estilos a trechos de texto específicos dentro do parágrafo.

* **Negrito**: `<w:b w:val="true"/>` ou simplesmente `<w:b/>`
* **Itálico**: `<w:i w:val="true"/>` ou simplesmente `<w:i/>`
* **Sublinhado**: `<w:u w:val="single"/>`
* **Tamanho da Fonte (`w:sz`)**: Definido em **half-points** (metade de 1 ponto). Para usar fonte tamanho `11`, grave `22`.
* **Cor da Fonte (`w:color`)**: Definido em hexadecimal RGB. Exemplo: `<w:color w:val="FF0000"/>` para vermelho.
* **Cor de Destaque (`w:highlight`)**: Define a cor de fundo do texto. Exemplo: `<w:highlight w:val="yellow"/>`.
* **Família de Fontes (`w:rFonts`)**: Define o nome da fonte. Exemplo: `<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman"/>`.

---

## 5. Tabelas (`w:tbl`)

As tabelas no WordprocessingML seguem uma estrutura baseada em linhas (`w:tr`) e colunas/células (`w:tc`).

```text
w:tbl (Tabela)
├── w:tblPr (Propriedades da Tabela)
├── w:tr (Linha)
│   ├── w:trPr (Propriedades da Linha)
│   └── w:tc (Célula)
│       ├── w:tcPr (Propriedades da Célula)
│       └── w:p (Parágrafo - Obrigatório dentro de células)
```

### 5.1 Estrutura de XML de Tabela
```xml
<w:tbl>
  <!-- Propriedades da Tabela -->
  <w:tblPr>
    <w:tblW w:w="5000" w:type="pct"/> <!-- Largura da tabela (50% do espaço disponível) -->
    <w:tblBorders>
      <w:top w:val="single" w:sz="4" w:space="0" w:color="auto"/>
      <w:left w:val="single" w:sz="4" w:space="0" w:color="auto"/>
      <w:bottom w:val="single" w:sz="4" w:space="0" w:color="auto"/>
      <w:right w:val="single" w:sz="4" w:space="0" w:color="auto"/>
      <w:insideH w:val="single" w:sz="4" w:space="0" w:color="auto"/>
      <w:insideV w:val="single" w:sz="4" w:space="0" w:color="auto"/>
    </w:tblBorders>
  </w:tblPr>
  
  <!-- Primeira Linha -->
  <w:tr>
    <!-- Célula 1 -->
    <w:tc>
      <w:tcPr>
        <w:tcW w:w="2500" w:type="dxa"/> <!-- Largura da célula em dxa (twips) -->
        <w:shd w:val="clear" w:color="auto" w:fill="ECECEC"/> <!-- Sombreamento cinza -->
      </w:tcPr>
      <w:p>
        <w:r>
          <w:rPr><w:b/></w:rPr>
          <w:t>Cabeçalho 1</w:t>
        </w:r>
      </w:p>
    </w:tc>
    <!-- Célula 2 -->
    <w:tc>
      <w:tcPr>
        <w:tcW w:w="2500" w:type="dxa"/>
      </w:tcPr>
      <w:p>
        <w:t>Cabeçalho 2</w:t>
      </w:p>
    </w:tc>
  </w:tr>
</w:tbl>
```
> [!WARNING]
> Toda célula `<w:tc>` deve conter obrigatoriamente no mínimo um parágrafo `<w:p>`, mesmo que ele esteja vazio. A ausência de parágrafos dentro de uma célula gera erro de validação fatal no formato OpenXML.

---

## 6. Imagens (`w:drawing`)

Para adicionar uma imagem, ela deve primeiro ser copiada fisicamente para a pasta `word/media/` do pacote ZIP (por exemplo: `word/media/image1.png`). Em seguida, deve-se criar um relacionamento no arquivo `word/_rels/document.xml.rels` vinculando essa imagem a um identificador único (`rId`).

### 6.1 O Arquivo de Relacionamentos do Documento (`word/_rels/document.xml.rels`)
Registra todas as dependências externas do documento.

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rIdImages1" 
                Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" 
                Target="media/image1.png"/>
  <Relationship Id="rIdStyles" 
                Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" 
                Target="styles.xml"/>
</Relationships>
```

### 6.2 Estrutura XML de uma Imagem Inline (DrawingML)
A imagem inline é inserida dentro de um run (`w:r`) utilizando a tag `<w:drawing>`:

```xml
<w:p>
  <w:r>
    <w:drawing>
      <wp:inline distT="0" distB="0" distL="0" distR="0">
        <wp:extent cx="1905000" cy="1143000"/> <!-- Tamanho em EMUs (50mm x 30mm) -->
        <wp:docPr id="1" name="Imagem 1" descr="Legenda Opcional"/>
        <wp:cNvGraphicFramePr>
          <a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/>
        </wp:cNvGraphicFramePr>
        <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
          <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
            <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:nvPicPr>
                <pic:cNvPr id="1" name="image1.png"/>
                <pic:cNvPicPr/>
              </pic:nvPicPr>
              <pic:blipFill>
                <!-- Blip usa o rId definido em document.xml.rels -->
                <a:blip r:embed="rIdImages1" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
                <a:stretch>
                  <a:fillRect/>
                </a:stretch>
              </pic:blipFill>
              <pic:spPr>
                <a:xfrm>
                  <a:off x="0" y="0"/>
                  <a:ext cx="1905000" cy="1143000"/>
                </a:xfrm>
                <a:prstGeom prst="rect">
                  <a:avLst/>
                </a:prstGeom>
              </pic:spPr>
            </pic:pic>
          </a:graphicData>
        </a:graphic>
      </wp:inline>
    </w:drawing>
  </w:r>
</w:p>
```

---

## 7. Cabeçalhos, Rodapés e Seções

Cabeçalhos e rodapés são armazenados em arquivos separados (ex: `word/header1.xml`, `word/footer1.xml`) e são referenciados no final do `word/document.xml` através do elemento de propriedade de seção (`w:sectPr`).

### 7.1 Arquivo do Cabeçalho (`word/header1.xml`)
```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p>
    <w:pPr>
      <w:jc w:val="right"/>
    </w:pPr>
    <w:r>
      <w:t>Cabeçalho do Relatório</w:t>
    </w:r>
  </w:p>
</w:hdr>
```

### 7.2 Arquivo do Rodapé (`word/footer1.xml`) com Número de Página
Para inserir o número de página dinâmico, usa-se um campo simples (`w:fldSimple w:instr="PAGE"`).

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p>
    <w:pPr>
      <w:jc w:val="center"/>
    </w:pPr>
    <w:r>
      <w:t>Página </w:t>
    </w:r>
    <!-- Campo Dinâmico de Página -->
    <w:fldSimple w:instr="PAGE"/>
  </w:p>
</w:ftr>
```

### 7.3 Vinculando Header/Footer no `word/document.xml`
No final da tag `<w:body>`, fica a tag `<w:sectPr>`, que gerencia as configurações da seção e referencia os ids das relações (`rId`) que apontam para o cabeçalho e rodapé.

```xml
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
    <!-- Conteúdo do Documento -->
    <w:p><w:r><w:t>Corpo do Texto...</w:t></w:r></w:p>
    
    <!-- Propriedades de Seção (Fim do Body) -->
    <w:sectPr>
      <w:headerReference w:type="default" r:id="rIdHeader1"/>
      <w:footerReference w:type="default" r:id="rIdFooter1"/>
      
      <!-- Configurações de Tamanho e Margens de Página -->
      <w:pgSz w:w="11906" w:h="16838" w:orient="portrait"/> <!-- A4 em Twips -->
      <w:pgMar w:top="1134" w:right="1417" w:bottom="1134" w:left="1417" w:header="708" w:footer="708" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
```

---

## 8. Unidades de Medida e Conversões

O OpenXML trabalha com diferentes unidades de medida a depender do elemento. A tabela abaixo e as equações detalham como converter valores de milímetros (`mm`) e pontos (`pt`) para as unidades do WordprocessingML:

| Unidade OpenXML | Onde é utilizada? | Relação de Conversão | Fórmula de Conversão |
| :--- | :--- | :--- | :--- |
| **Twips** (dxa) | Margens, recuos de parágrafo, espaçamento entre parágrafos, largura de células e posições de seção. | $1\text{ pt} = 20\text{ twips}$<br>$1\text{ polegada} = 1440\text{ twips}$<br>$1\text{ mm} \approx 56.69\text{ twips}$ | $\text{Twips} = \text{Valor em mm} \times 56.6929$ |
| **Half-Points** | Tamanho de fontes (`w:sz`). | $1\text{ pt} = 2\text{ half-points}$ | $\text{Half-Points} = \text{Valor em pt} \times 2$ |
| **EMUs** (English Metric Units) | Dimensões de imagens e formas vetoriais (`wp:extent`, `a:ext`). | $1\text{ mm} = 36000\text{ EMUs}$<br>$1\text{ pt} = 12700\text{ EMUs}$ | $\text{EMUs} = \text{Valor em mm} \times 36000$<br>$\text{EMUs} = \text{Valor em pt} \times 12700$ |

### 8.1 Implementação de Conversão (Exemplo em Pascal)
```pascal
function MMToTwip(AValueMM: Double): Integer;
begin
  Result := Round(AValueMM * 56.692913);
end;

function PtToHalfPoint(APointSize: Double): Integer;
begin
  Result := Round(APointSize * 2.0);
end;

function MMToEMU(AValueMM: Double): Int64;
begin
  Result := Round(AValueMM * 36000.0);
end;

function ColorToHex(AColor: TColor): string;
var
  R, G, B: Byte;
begin
  // Converte a cor do Lazarus (TColor) para string Hexadecimal RGB
  // Exemplo: clRed -> 'FF0000'
  R := Red(AColor);
  G := Green(AColor);
  B := Blue(AColor);
  Result := Format('%.2X%.2X%.2X', [R, G, B]);
end;
```

---

## 9. Quebras de Página e de Seção

### 9.1 Quebra de Página Simples
Uma quebra de página simples é representada pela inserção de uma tag `<w:br w:type="page"/>` dentro de um run (`w:r`).

```xml
<w:p>
  <w:r>
    <w:br w:type="page"/>
  </w:r>
</w:p>
```

### 9.2 Quebra de Seção (Troca de Orientação)
Para quebras de seção (onde a orientação da página muda de retrato para paisagem, por exemplo), a propriedade `<w:sectPr>` deve ser inserida dentro de um parágrafo específico (`w:p` $\rightarrow$ `w:pPr` $\rightarrow$ `w:sectPr`), e não apenas no final do corpo do documento.

---

## 10. Requisitos para Processamento e Preservação de XML

Quando o componente `TAIWordDocument` carregar um arquivo DOCX existente (`PreserveUnsupportedXml = True`), ele deve ler o arquivo ZIP e manter em memória (ou arquivos temporários) as partes que ele não sabe modificar. 

Durante o processo de salvamento, as partes modificadas (`word/document.xml`, `word/_rels/document.xml.rels`, etc.) devem ser sobrescritas no ZIP, mas as partes desconhecidas (como tabelas complexas, SmartArts, assinaturas digitais e macros VBA) devem ser reempacotadas de forma intocada para evitar a corrupção do documento original.
