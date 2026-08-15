unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, aigraphmap, airag;

type

  { TfrmRAGBulkloadBench }

  TfrmRAGBulkloadBench = class(TForm)
    AIGraphMap1: TAIGraphMap;
    AIRAG1: TAIRAG;
    btnClearLog: TButton;
    btnRunAll: TButton;
    btnRunWithBulk: TButton;
    btnRunWithoutBulk: TButton;
    edtChunkOverlap: TEdit;
    edtChunkSize: TEdit;
    edtQtdRegistros: TEdit;
    gbConfig: TGroupBox;
    gbResults: TGroupBox;
    gbSummary: TGroupBox;
    lblChunkOverlap: TLabel;
    lblChunkSize: TLabel;
    lblLog: TLabel;
    lblQtdRegistros: TLabel;
    lblSpeedup: TLabel;
    lblStatus: TLabel;
    lblSubtitle: TLabel;
    lblTitle: TLabel;
    lblWithBulk: TLabel;
    lblWithoutBulk: TLabel;
    lvBenchmark: TListView;
    mmoLog: TMemo;
    pnlBottom: TPanel;
    pnlCenter: TPanel;
    pnlLeft: TPanel;
    pnlStatus: TPanel;
    pnlSummaryCards: TPanel;
    pnlTop: TPanel;
    ProgressBar1: TProgressBar;
    procedure btnClearLogClick(Sender: TObject);
    procedure btnRunAllClick(Sender: TObject);
    procedure btnRunWithBulkClick(Sender: TObject);
    procedure btnRunWithoutBulkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    function Medir(AUsarBulk: Boolean; out ATempoMs: Int64; out AChunks: Integer): Boolean;
    procedure Log(const AMsg: string);
    procedure UpdateSummary(ATempoSemBulk, ATempoComBulk: Int64);
  public
  end;

var
  frmRAGBulkloadBench: TfrmRAGBulkloadBench;

implementation

{$R *.lfm}

{ TfrmRAGBulkloadBench }

procedure TfrmRAGBulkloadBench.FormCreate(Sender: TObject);
begin
  Log('Pronto para executar os testes de carga em massa.');
end;

procedure TfrmRAGBulkloadBench.Log(const AMsg: string);
begin
  mmoLog.Lines.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), AMsg]));
end;

function TfrmRAGBulkloadBench.Medir(AUsarBulk: Boolean; out ATempoMs: Int64; out AChunks: Integer): Boolean;
var
  Qtd: Integer;
  ChunkSz: Integer;
  Overlap: Integer;
  I: Integer;
  LInicio: TDateTime;
  LRotulo: string;
  ListItem: TListItem;
  UpdateInterval: Integer;
begin
  Result := False;
  ATempoMs := 0;
  AChunks := 0;

  Qtd := StrToIntDef(Trim(edtQtdRegistros.Text), 20000);
  if Qtd < 10 then Qtd := 10;

  ChunkSz := StrToIntDef(Trim(edtChunkSize.Text), 4000);
  if ChunkSz < 50 then ChunkSz := 50;

  Overlap := StrToIntDef(Trim(edtChunkOverlap.Text), 0);
  if Overlap < 0 then Overlap := 0;

  if AUsarBulk then
    LRotulo := 'COM BeginBulkLoad'
  else
    LRotulo := 'SEM BeginBulkLoad';

  Log(Format('Iniciando teste %s para %d registros...', [LRotulo, Qtd]));
  lblStatus.Caption := Format('Executando %s...', [LRotulo]);
  Application.ProcessMessages;

  ProgressBar1.Position := 0;
  ProgressBar1.Max := Qtd;
  UpdateInterval := Qtd div 20;
  if UpdateInterval < 100 then UpdateInterval := 100;

  Screen.Cursor := crHourGlass;
  try
    AIRAG1.Clear;
    AIGraphMap1.ClearGraph;
    AIGraphMap1.ClearTraining;
    AIRAG1.GraphMap := AIGraphMap1;
    AIRAG1.ChunkSize := ChunkSz;
    AIRAG1.ChunkOverlap := Overlap;

    if AUsarBulk then
      AIRAG1.BeginBulkLoad;

    LInicio := Now;
    for I := 1 to Qtd do
    begin
      AIRAG1.AddText(
        Format('row/public.clientes/%d', [I]),
        Format('Cliente numero %d, cidade Ribeirao Preto, situacao ativa.', [I]));

      if (I mod UpdateInterval = 0) or (I = Qtd) then
      begin
        ProgressBar1.Position := I;
        Application.ProcessMessages;
      end;
    end;

    ATempoMs := MilliSecondsBetween(Now, LInicio);

    if AUsarBulk then
      AIRAG1.EndBulkLoad;

    AChunks := AIGraphMap1.Training.Count;
    Result := True;

    Log(Format('%s: %d registros | %d ms | %d chunks', [LRotulo, Qtd, ATempoMs, AChunks]));

    ListItem := lvBenchmark.Items.Add;
    ListItem.Caption := LRotulo;
    ListItem.SubItems.Add(IntToStr(Qtd));
    ListItem.SubItems.Add(Format('%d ms', [ATempoMs]));
    ListItem.SubItems.Add(IntToStr(AChunks));
    ListItem.SubItems.Add(Format('%.2f reg/s', [(Qtd / (ATempoMs / 1000.0))]));

    lblStatus.Caption := Format('%s concluído em %d ms.', [LRotulo, ATempoMs]);
  finally
    ProgressBar1.Position := 0;
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmRAGBulkloadBench.UpdateSummary(ATempoSemBulk, ATempoComBulk: Int64);
var
  Speedup: Double;
  PctGanho: Double;
begin
  lblWithoutBulk.Caption := Format('SEM BulkLoad: %d ms', [ATempoSemBulk]);
  lblWithBulk.Caption := Format('COM BulkLoad: %d ms', [ATempoComBulk]);

  if (ATempoComBulk > 0) and (ATempoSemBulk > 0) then
  begin
    Speedup := ATempoSemBulk / ATempoComBulk;
    PctGanho := ((ATempoSemBulk - ATempoComBulk) / ATempoSemBulk) * 100.0;
    lblSpeedup.Caption := Format('Ganho: %.2fx mais rápido (%.1f%% de redução no tempo)', [Speedup, PctGanho]);
    lblSpeedup.Font.Color := clGreen;
  end
  else
  begin
    lblSpeedup.Caption := 'Ganho: -';
    lblSpeedup.Font.Color := clDefault;
  end;
end;

procedure TfrmRAGBulkloadBench.btnRunAllClick(Sender: TObject);
var
  TempoSem, TempoCom: Int64;
  ChunksSem, ChunksCom: Integer;
begin
  btnRunAll.Enabled := False;
  btnRunWithoutBulk.Enabled := False;
  btnRunWithBulk.Enabled := False;
  try
    Log('=== Executando Benchmark Comparativo Completo ===');
    if Medir(False, TempoSem, ChunksSem) then
    begin
      Sleep(100);
      if Medir(True, TempoCom, ChunksCom) then
      begin
        UpdateSummary(TempoSem, TempoCom);
        Log('=== Benchmark Finalizado com Sucesso ===');
      end;
    end;
  finally
    btnRunAll.Enabled := True;
    btnRunWithoutBulk.Enabled := True;
    btnRunWithBulk.Enabled := True;
  end;
end;

procedure TfrmRAGBulkloadBench.btnRunWithoutBulkClick(Sender: TObject);
var
  Tempo: Int64;
  Chunks: Integer;
begin
  btnRunWithoutBulk.Enabled := False;
  try
    if Medir(False, Tempo, Chunks) then
      lblWithoutBulk.Caption := Format('SEM BulkLoad: %d ms', [Tempo]);
  finally
    btnRunWithoutBulk.Enabled := True;
  end;
end;

procedure TfrmRAGBulkloadBench.btnRunWithBulkClick(Sender: TObject);
var
  Tempo: Int64;
  Chunks: Integer;
begin
  btnRunWithBulk.Enabled := False;
  try
    if Medir(True, Tempo, Chunks) then
      lblWithBulk.Caption := Format('COM BulkLoad: %d ms', [Tempo]);
  finally
    btnRunWithBulk.Enabled := True;
  end;
end;

procedure TfrmRAGBulkloadBench.btnClearLogClick(Sender: TObject);
begin
  mmoLog.Clear;
  lvBenchmark.Items.Clear;
  lblWithoutBulk.Caption := 'SEM BulkLoad: -';
  lblWithBulk.Caption := 'COM BulkLoad: -';
  lblSpeedup.Caption := 'Ganho: -';
  lblSpeedup.Font.Color := clDefault;
  lblStatus.Caption := 'Resultados limpos.';
end;

initialization
  RegisterClasses([
    TAIGraphMap,
    TAIRAG
  ]);

end.
