# TAIDiskTreeScanner

## Finalidade

`TAIDiskTreeScanner` é um componente assíncrono projetado para varredura de sistemas de arquivos, navegação e preparação de datasets de Inteligência Artificial de forma nativa em Lazarus/Free Pascal, compatível com Windows e Linux.

## Unit

```pascal
pacote/componentes/ai_files/aidisktreescanner.pas
```

## Pacote

```text
ai_files.lpk
```

## Aba na IDE

```text
AI Utilities
```

## Status

```text
Beta
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `RootPath` | Caminho do diretório raiz para início da varredura |
| `IncludeFiles` | Define se arquivos devem ser incluídos nos resultados |
| `IncludeDirectories` | Define se diretórios devem ser incluídos nos resultados |
| `Recursive` | Varredura recursiva em subdiretórios |
| `MaxDepth` | Limite de profundidade da varredura |
| `FileMask` | Máscara de busca de arquivos (ex: `*.pas`) |
| `Extensions` | Lista de extensões permitidas |
| `ExcludeDirs` | Lista de diretórios a serem ignorados |
| `ExcludeExtensions` | Lista de extensões a serem ignoradas |
| `ReturnOnMainThread` | Sincroniza eventos de notificação na Thread Principal da LCL |
| `AutoClearResults` | Limpa resultados anteriores ao iniciar uma nova busca |

## Eventos principais

| Evento | Descrição |
|---|---|
| `OnTaskStart` | Fired ao iniciar a tarefa de busca |
| `OnItemFound` | Fired a cada item (arquivo/diretório/volume) correspondente encontrado |
| `OnProgress` | Fired periodicamente indicando o progresso da varredura |
| `OnTaskFinish` | Fired ao concluir a tarefa (com sucesso, cancelamento ou erro) |
| `OnError` | Fired em caso de falha ou acesso negado a um determinado diretório |

## Exemplo de uso

```pascal
procedure TForm1.FormCreate(Sender: TObject);
begin
  DiskTreeScanner1 := TAIDiskTreeScanner.Create(Self);
  DiskTreeScanner1.OnItemFound := @OnItemFound;
  DiskTreeScanner1.OnTaskFinish := @OnTaskFinish;
  
  // Inicia varredura recursiva assíncrona
  DiskTreeScanner1.ScanBranchAsync('D:\datasets', dsmRecursive);
end;

procedure TForm1.OnItemFound(Sender: TObject; TaskId: Integer; Item: TAIDiskItem);
begin
  Memo1.Lines.Add(Item.FullPath);
end;

procedure TForm1.OnTaskFinish(Sender: TObject; TaskId: Integer; State: TAIDiskTaskState; TotalDirs, TotalFiles, TotalFound: Int64; const ErrorMsg: string);
begin
  ShowMessage('Fim da busca! Total de itens encontrados: ' + IntToStr(TotalFound));
end;
```

## Métodos de Exportação (IA)

- **`ExportToJSON(const AFileName: string): Boolean`**
- **`ExportToCSV(const AFileName: string): Boolean`**
- **`ExportToTXT(const AFileName: string): Boolean`**
