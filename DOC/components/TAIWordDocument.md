# Especificação de Projeto — Componente DOCX Real para Lazarus AI Suite

## 1. Nome do projeto

**TAIWordDocument — Manipulação Real de DOCX via OpenXML**

## 2. Objetivo

Criar um novo componente Lazarus/Free Pascal capaz de **gerar, carregar, editar e salvar arquivos `.docx` reais**, usando a estrutura OpenXML/WordprocessingML, sem depender do Microsoft Word instalado.

O componente deve permitir manipular objetos do documento de forma simples e prática, oferecendo uma API Pascal orientada a objetos para:

* criar documentos DOCX;
* carregar documentos DOCX existentes;
* salvar documentos DOCX válidos;
* incluir e editar parágrafos;
* configurar fonte, tamanho, cor, negrito, itálico e sublinhado;
* alinhar e justificar textos;
* localizar parágrafos;
* substituir textos;
* inserir imagens;
* definir tamanho de imagem;
* definir posicionamento básico de imagem;
* inserir título;
* inserir cabeçalho;
* inserir rodapé;
* inserir quebra de página;
* inserir tabelas;
* preservar partes desconhecidas do DOCX sempre que possível.

## 3. Justificativa

O componente atual `TAIWordOutput` gera arquivo compatível com Word usando HTML salvo com extensão `.docx`. Essa abordagem é simples, mas não permite manipular objetos reais do Word.

Este projeto cria um novo componente, separado do antigo, com suporte real a DOCX/OpenXML.

## 4. Novo componente

Criar a unit:

```text
pacote/IA Output/aiworddocument.pas
```

Criar o componente principal:

```pascal
TAIWordDocument = class(TAIBaseComponent)
```

Registrar o componente na aba:

```pascal
RegisterComponents('AI Documents', [TAIWordDocument]);
```

## 5. Não remover o componente antigo

Não apagar nem substituir `TAIWordOutput`.

Manter os dois:

```text
TAIWordOutput       = saída simples compatível com Word via HTML
TAIWordDocument     = DOCX real manipulável por objetos
```

## 6. Estrutura interna sugerida

Criar as seguintes units auxiliares:

```text
aiworddocument.pas          // componente principal
aiwordtypes.pas             // enums, records e constantes
aiwordpackage.pas           // leitura/gravação do pacote ZIP DOCX
aiwordxml.pas               // helpers de XML DOM
aiwordrelationships.pas     // gerenciamento de relacionamentos rId
aiwordstyles.pas            // estilos básicos
aiwordobjects.pas           // classes de parágrafo, run, imagem, tabela
aiwordunits.pas             // conversões mm, pt, twip e EMU
```

## 7. Estrutura DOCX mínima a gerar

O componente deve criar um `.docx` válido contendo, no mínimo:

```text
[Content_Types].xml
_rels/.rels
docProps/core.xml
docProps/app.xml
word/document.xml
word/styles.xml
word/settings.xml
word/_rels/document.xml.rels
```

Quando houver imagem:

```text
word/media/image1.png
word/media/image2.jpg
```

Quando houver cabeçalho:

```text
word/header1.xml
```

Quando houver rodapé:

```text
word/footer1.xml
```

## 8. API pública do componente principal

Criar a classe:

```pascal
type
  TAIWordDocument = class(TAIBaseComponent)
  private
    FFileName: string;
    FTitle: string;
    FAuthor: string;
    FSubject: string;
    FPreserveUnsupportedXml: Boolean;

    FParagraphs: TAIWordParagraphList;
    FHeader: TAIWordHeaderFooter;
    FFooter: TAIWordHeaderFooter;
    FPageSetup: TAIWordPageSetup;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure NewDocument;
    function LoadFromFile(const AFileName: string): Boolean;
    function SaveToFile(const AFileName: string = ''): Boolean;

    // Métodos de inserção rápida
    function AddTitle(const AText: string): TAIWordParagraph;
    function AddHeading(const AText: string; ALevel: Integer = 1): TAIWordParagraph;
    function AddParagraph(const AText: string = ''): TAIWordParagraph;
    procedure AddPageBreak;

    function AddImage(
      const AFileName: string;
      AWidthMM: Double = 0;
      AHeightMM: Double = 0;
      APosition: TAIWordImagePosition = wipInline
    ): TAIWordImage;

    function AddTable(ARows, ACols: Integer): TAIWordTable;

    // Métodos de localização e substituição
    function FindParagraph(const AText: string): TAIWordParagraph;
    function FindParagraphs(const AText: string): TAIWordParagraphList;
    function ReplaceText(const ASearch, AReplace: string): Integer;

    procedure Clear;

    property Paragraphs: TAIWordParagraphList read FParagraphs;
    property Header: TAIWordHeaderFooter read FHeader;
    property Footer: TAIWordHeaderFooter read FFooter;
    property PageSetup: TAIWordPageSetup read FPageSetup;
  published
    property FileName: string read FFileName write FFileName;
    property Title: string read FTitle write FTitle;
    property Author: string read FAuthor write FAuthor;
    property Subject: string read FSubject write FSubject;
    property PreserveUnsupportedXml: Boolean
      read FPreserveUnsupportedXml
      write FPreserveUnsupportedXml
      default True;
  end;
```

## 9. Tipos enumerados

Criar em `aiwordtypes.pas`:

```pascal
type
  TAIWordAlignment = (
    waLeft,
    waCenter,
    waRight,
    waJustify
  );

  TAIWordImagePosition = (
    wipInline,
    wipFloating,
    wipBehindText,
    wipInFrontOfText,
    wipSquareWrap
  );

  TAIWordPaperSize = (
    wpsA4,
    wpsLetter,
    wpsLegal
  );

  TAIWordOrientation = (
    woPortrait,
    woLandscape
  );

  TAIWordVerticalAlignment = (
    wvaTop,
    wvaCenter,
    wvaBottom
  );
```

Na primeira versão implementar apenas imagem `wipInline`.

Os demais tipos de posicionamento podem existir na enumeração, mas devem retornar erro controlado se ainda não forem suportados.

## 10. Classe de parágrafo

Criar:

```pascal
type
  TAIWordParagraph = class
  private
    FOwner: TAIWordDocument;
    FXmlNode: TDOMNode;
  public
    constructor Create(AOwner: TAIWordDocument; AXmlNode: TDOMNode);

    function AddRun(const AText: string): TAIWordRun;
    function AddImage(
      const AFileName: string;
      AWidthMM: Double;
      AHeightMM: Double
    ): TAIWordImage;

    procedure ClearRuns;
    procedure Delete;

    function GetText: string;
    procedure SetText(const AValue: string);

    property Text: string read GetText write SetText;
    property Style: string read GetStyle write SetStyle;
    property Alignment: TAIWordAlignment read GetAlignment write SetAlignment;

    property FontName: string read GetFontName write SetFontName;
    property FontSize: Integer read GetFontSize write SetFontSize;
    property Bold: Boolean read GetBold write SetBold;
    property Italic: Boolean read GetItalic write SetItalic;
    property Underline: Boolean read GetUnderline write SetUnderline;

    property SpaceBeforePt: Integer read GetSpaceBeforePt write SetSpaceBeforePt;
    property SpaceAfterPt: Integer read GetSpaceAfterPt write SetSpaceAfterPt;
    property FirstLineIndentMM: Double read GetFirstLineIndentMM write SetFirstLineIndentMM;
  end;
```

## 11. Classe de run

Criar:

```pascal
type
  TAIWordRun = class
  private
    FOwner: TAIWordDocument;
    FXmlNode: TDOMNode;
  public
    constructor Create(AOwner: TAIWordDocument; AXmlNode: TDOMNode);

    property Text: string read GetText write SetText;
    property FontName: string read GetFontName write SetFontName;
    property FontSize: Integer read GetFontSize write SetFontSize;
    property Bold: Boolean read GetBold write SetBold;
    property Italic: Boolean read GetItalic write SetItalic;
    property Underline: Boolean read GetUnderline write SetUnderline;
    property Color: TColor read GetColor write SetColor;
    property HighlightColor: TColor read GetHighlightColor write SetHighlightColor;
  end;
```

## 12. Classe de imagem

Criar:

```pascal
type
  TAIWordImage = class
  private
    FOwner: TAIWordDocument;
    FRelationshipId: string;
    FFileName: string;
    FXmlNode: TDOMNode;
  public
    property FileName: string read FFileName;
    property RelationshipId: string read FRelationshipId;

    property WidthMM: Double read GetWidthMM write SetWidthMM;
    property HeightMM: Double read GetHeightMM write SetHeightMM;
    property Position: TAIWordImagePosition read GetPosition write SetPosition;
    property Alignment: TAIWordAlignment read GetAlignment write SetAlignment;
    property AltText: string read GetAltText write SetAltText;
  end;
```

A imagem deve ser copiada para:

```text
word/media/
```

E registrada em:

```text
word/_rels/document.xml.rels
```

Exemplo:

```xml
<Relationship Id="rId5"
 Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image"
 Target="media/image1.png"/>
```

## 13. Classe de tabela

Criar:

```pascal
type
  TAIWordTable = class
  public
    function Cell(ARow, ACol: Integer): TAIWordTableCell;

    property Rows: Integer read GetRows;
    property Cols: Integer read GetCols;
    property Border: Boolean read GetBorder write SetBorder;
    property WidthPercent: Integer read GetWidthPercent write SetWidthPercent;
  end;

  TAIWordTableCell = class
  public
    property Text: string read GetText write SetText;
    property Alignment: TAIWordAlignment read GetAlignment write SetAlignment;
    property Bold: Boolean read GetBold write SetBold;
    property ShadingColor: TColor read GetShadingColor write SetShadingColor;
  end;
```

## 14. Cabeçalho e rodapé

Criar uma classe comum:

```pascal
type
  TAIWordHeaderFooter = class
  public
    procedure Clear;
    function AddParagraph(const AText: string = ''): TAIWordParagraph;
    procedure AddPageNumber;
  end;
```

Na primeira versão, suportar:

```text
Header padrão
Footer padrão
Número de página simples no rodapé
```

Não implementar ainda primeira página diferente nem páginas pares/ímpares.

## 15. Configuração de página

Criar:

```pascal
type
  TAIWordPageSetup = class
  public
    property PaperSize: TAIWordPaperSize read FPaperSize write FPaperSize;
    property Orientation: TAIWordOrientation read FOrientation write FOrientation;

    property MarginLeftMM: Double read FMarginLeftMM write FMarginLeftMM;
    property MarginRightMM: Double read FMarginRightMM write FMarginRightMM;
    property MarginTopMM: Double read FMarginTopMM write FMarginTopMM;
    property MarginBottomMM: Double read FMarginBottomMM write FMarginBottomMM;
  end;
```

Valores padrão:

```text
PaperSize: A4
Orientation: Portrait
MarginLeftMM: 25
MarginRightMM: 25
MarginTopMM: 20
MarginBottomMM: 20
```

## 16. Localização de parágrafos

Implementar:

```pascal
function FindParagraph(const AText: string): TAIWordParagraph;
function FindParagraphs(const AText: string): TAIWordParagraphList;
```

O método não deve procurar apenas em um único `<w:t>`.

Ele deve montar o texto completo do parágrafo concatenando todos os runs internos.

Exemplo:

```xml
<w:r><w:t>Marc</w:t></w:r>
<w:r><w:t>elo</w:t></w:r>
```

Deve ser encontrado como:

```text
Marcelo
```

## 17. Substituição de texto

Implementar:

```pascal
function ReplaceText(const ASearch, AReplace: string): Integer;
```

Na primeira versão, pode funcionar assim:

* localizar parágrafos que contenham o texto;
* substituir no texto completo do parágrafo;
* recriar o parágrafo com um único run;
* retornar a quantidade de substituições.

Na segunda versão, preservar runs e formatação parcial.

## 18. Modo template

Adicionar método opcional:

```pascal
procedure SetVariable(const AName, AValue: string);
function ApplyVariables: Integer;
```

Funcionamento esperado:

```pascal
Doc.SetVariable('NOME', 'Marcelo Martins');
Doc.SetVariable('UNIDADE', 'UBS Central');
Doc.ApplyVariables;
```

Substituir no documento:

```text
{{NOME}}
{{UNIDADE}}
```

## 19. Requisitos de leitura

Ao carregar um DOCX existente:

```pascal
Doc.LoadFromFile('modelo.docx');
```

O componente deve:

* abrir o pacote ZIP;
* localizar `word/document.xml`;
* carregar o XML principal;
* carregar relacionamentos;
* carregar estilos se existirem;
* identificar parágrafos;
* identificar runs;
* identificar tabelas simples;
* identificar imagens inline simples;
* identificar header/footer se existirem;
* preservar arquivos e XMLs desconhecidos.

## 20. Requisitos de gravação

Ao salvar:

```pascal
Doc.SaveToFile('saida.docx');
```

O componente deve:

* recriar o pacote DOCX;
* gravar `[Content_Types].xml`;
* gravar `_rels/.rels`;
* gravar `word/document.xml`;
* gravar `word/styles.xml`;
* gravar `word/settings.xml`;
* gravar `word/_rels/document.xml.rels`;
* gravar headers e footers se existirem;
* gravar imagens em `word/media`;
* preservar partes não modificadas sempre que `PreserveUnsupportedXml=True`.

## 21. Conversões obrigatórias

Criar funções auxiliares em `aiwordunits.pas`:

```pascal
function MMToTwip(AValueMM: Double): Integer;
function PtToHalfPoint(APointSize: Double): Integer;
function MMToEMU(AValueMM: Double): Int64;
function ColorToHex(AColor: TColor): string;
```

Usos:

```text
twip       = margens, recuos, espaçamentos
half-point = tamanho de fonte
EMU        = tamanho de imagem
hex color  = cor em OpenXML
```

## 22. Tratamento de erro

Todos os métodos principais devem preencher:

```pascal
LastError
LastResult
LastSuccess
```

Exemplo:

```pascal
if not Doc.SaveToFile('saida.docx') then
  ShowMessage(Doc.LastError);
```

Não lançar exceção para erro comum de uso.

Exceções internas devem ser capturadas e convertidas para `LastError`.

## 23. Compatibilidade

O componente deve compilar em:

```text
Windows 32-bit
Windows 64-bit
Linux 64-bit
Linux ARM64
```

Não deve depender do Microsoft Word.

Não deve depender de COM/OLE Automation.

Não deve depender de LibreOffice.

Não deve depender de Python.

## 24. Dependências Lazarus/FPC permitidas

Usar preferencialmente bibliotecas padrão do Free Pascal/Lazarus:

```pascal
Classes
SysUtils
DOM
XMLRead
XMLWrite
Zipper
FileUtil
Graphics
```

Se `Zipper` não for suficiente para preservar corretamente o pacote DOCX, criar camada própria `TAIWordPackage` isolando a dependência para futura substituição.

## 25. Sample obrigatório

Criar novo sample:

```text
pacote/samples/IA Output/word_object_demo/
```

Arquivos:

```text
word_object_demo.lpi
word_object_demo.lpr
main.pas
main.lfm
README.md
imagem/logo.png
modelo/modelo_basico.docx
```

## 26. O sample deve demonstrar

A tela deve conter botões:

```text
Novo Documento
Carregar DOCX
Gerar Documento
Achar Parágrafo
Substituir Texto
Adicionar Imagem
Adicionar Tabela
Salvar DOCX
Limpar Log
```

O sample deve gerar um documento contendo:

* título;
* cabeçalho;
* rodapé;
* número de página;
* parágrafo normal;
* parágrafo justificado;
* trecho em negrito;
* trecho colorido;
* imagem inline com tamanho definido;
* tabela com cabeçalho;
* quebra de página;
* segundo título em nova página;
* salvamento final em `.docx`.

## 27. Exemplo de uso no sample

```pascal
procedure TfrmMain.btnGenerateClick(Sender: TObject);
var
  P: TAIWordParagraph;
  R: TAIWordRun;
  T: TAIWordTable;
begin
  WordDoc.NewDocument;

  WordDoc.Title := 'Relatório DOCX Real';
  WordDoc.Author := 'Lazarus AI Suite';

  WordDoc.PageSetup.PaperSize := wpsA4;
  WordDoc.PageSetup.MarginLeftMM := 25;
  WordDoc.PageSetup.MarginRightMM := 25;

  WordDoc.Header.AddParagraph('Lazarus AI Suite');
  WordDoc.Footer.AddParagraph('Documento gerado automaticamente');
  WordDoc.Footer.AddPageNumber;

  WordDoc.AddTitle('Relatório DOCX Real');

  P := WordDoc.AddParagraph('Este parágrafo foi criado por objeto Pascal.');
  P.Alignment := waJustify;
  P.FontName := 'Arial';
  P.FontSize := 12;

  R := P.AddRun(' Este trecho está em negrito.');
  R.Bold := True;
  R.Color := clBlue;

  WordDoc.AddImage('imagem/logo.png', 50, 30, wipInline);

  T := WordDoc.AddTable(3, 3);
  T.Cell(0, 0).Text := 'Campo';
  T.Cell(0, 1).Text := 'Valor';
  T.Cell(0, 2).Text := 'Status';

  T.Cell(1, 0).Text := 'Componente';
  T.Cell(1, 1).Text := 'TAIWordDocument';
  T.Cell(1, 2).Text := 'OK';

  WordDoc.AddPageBreak;
  WordDoc.AddHeading('Segunda Página', 1);
  WordDoc.AddParagraph('Conteúdo após quebra de página.');

  if WordDoc.SaveToFile('saida_word_object_demo.docx') then
    AddLog('DOCX salvo com sucesso.')
  else
    AddLog('Erro: ' + WordDoc.LastError);
end;
```

## 28. README do sample

O `README.md` do sample deve explicar:

```text
Este sample demonstra geração e edição real de DOCX usando OpenXML.
Não usa Microsoft Word.
Não usa LibreOffice.
Não usa HTML disfarçado de DOCX.
```

Também deve listar:

```text
Componente: TAIWordDocument
Unit: aiworddocument.pas
Pacote: openai_output.lpk
Status: Experimental/Beta
Dependências: FPC/Lazarus padrão
```

## 29. Critérios de aceite

A implementação será considerada válida quando:

1. o componente compilar no Lazarus;
2. o sample `word_object_demo` compilar;
3. o sample gerar um `.docx` que abre no Microsoft Word;
4. o mesmo `.docx` abrir no LibreOffice Writer;
5. o documento gerado contiver título, parágrafo, imagem, tabela, cabeçalho e rodapé;
6. `FindParagraph` localizar texto mesmo quando o parágrafo tiver múltiplos runs;
7. `ReplaceText` substituir texto simples;
8. `LoadFromFile` abrir um `.docx` simples existente;
9. `SaveToFile` salvar sem corromper o arquivo;
10. `LastError` trazer mensagem útil em caso de falha.

## 30. Fase 1 — MVP obrigatório

Implementar primeiro:

```text
NewDocument
SaveToFile
LoadFromFile básico
AddTitle
AddHeading
AddParagraph
AddRun
Fonte
Tamanho
Negrito
Itálico
Sublinhado
Cor
Alinhamento
Justificado
AddPageBreak
Header simples
Footer simples
PageNumber simples
AddImage inline
AddTable simples
FindParagraph
ReplaceText
```

## 31. Fase 2 — Evolução

Implementar depois:

```text
imagem flutuante
imagem atrás do texto
imagem na frente do texto
texto contornando imagem
múltiplas seções
cabeçalho diferente na primeira página
cabeçalho diferente em páginas pares
rodapé diferente na primeira página
estilos customizados
listas numeradas
bullets
hyperlinks
notas de rodapé
comentários
sumário
campos automáticos
proteção de documento
```

## 32. Fase 3 — Templates avançados

Implementar:

```text
SetVariable
ApplyVariables
clonagem de parágrafo
clonagem de tabela
preenchimento de tabela por dataset
repetição de bloco
condicionais simples
```

Exemplo futuro:

```pascal
Doc.LoadFromFile('modelo_os.docx');
Doc.SetVariable('NOME', 'Marcelo Martins');
Doc.SetVariable('UNIDADE', 'UBS Central');
Doc.SetVariable('EQUIPAMENTO', 'Monitor Multiparamétrico');
Doc.ApplyVariables;
Doc.SaveToFile('os_preenchida.docx');
```

## 33. Observação importante

Não implementar `.doc` binário antigo.

O foco deve ser exclusivamente `.docx` real, baseado em OpenXML.

O componente deve ser pensado como um editor DOCX orientado a objetos para Lazarus, não apenas como gerador de texto.

## 34. Resultado esperado

Ao final, a Lazarus AI Suite terá um componente profissional para criação e edição de documentos Word reais:

```text
TAIWordDocument
```

com API simples, prática e expansível, permitindo ao programador manipular DOCX diretamente em Lazarus sem Word instalado e sem automação externa.
