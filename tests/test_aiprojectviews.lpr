program test_aiprojectviews;

{ Teste das vistas genericas da aba AI Project (LCL): TAIGanttView,
  TAINetworkView e TAIBoardView. Cria uma janela, preenche as vistas, pinta e
  confere geometria, selecao, recolher, edicao na celula, layout em camadas,
  realce de predecessoras/sucessoras, criacao de vinculo por arraste e
  movimento de cartao com recusa.
  Linux: xvfb-run -a ./test_aiprojectviews }

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Interfaces, Classes, SysUtils, Types, Forms, Controls, Graphics,
  aiganttview, ainetworkview, aiboardview;

type
  TNetAccess = class(TAINetworkView);

  TProbe = class
    SelectedRow, SelectedNode: Integer;
    EditedText: string;
    LinkFrom, LinkTo: Integer;
    procedure GanttSelect(Sender: TObject; ARow: Integer);
    procedure GanttEdited(Sender: TObject; ARow, ACol: Integer; var AText: string; var Accept: Boolean);
    function Working(Sender: TObject; ADay: TDateTime): Boolean;
    procedure NetSelect(Sender: TObject; ANode: Integer);
    procedure NetLink(Sender: TObject; AFromNode, AToNode: Integer; AAlt: Boolean);
    procedure BoardMove(Sender: TObject; ACard, ANewColumn: Integer; var Accept: Boolean; var Reason: string);
  end;

var
  Passed, Failed: Integer;

procedure Check(Cond: Boolean; const What: string);
begin
  if Cond then Inc(Passed)
  else
  begin
    Inc(Failed);
    Writeln('FALHOU: ', What);
  end;
end;

procedure TProbe.GanttSelect(Sender: TObject; ARow: Integer);
begin
  SelectedRow := ARow;
end;

procedure TProbe.GanttEdited(Sender: TObject; ARow, ACol: Integer; var AText: string; var Accept: Boolean);
begin
  { o dono normaliza ("2 d" -> "2d") ou recusa }
  if AText = 'xyz' then Accept := False
  else AText := StringReplace(AText, ' ', '', [rfReplaceAll]);
  EditedText := AText;
end;

function TProbe.Working(Sender: TObject; ADay: TDateTime): Boolean;
begin
  Result := not (DayOfWeek(ADay) in [1, 7]) and (Trunc(ADay) <> Trunc(EncodeDate(2026, 11, 2)));
end;

procedure TProbe.NetSelect(Sender: TObject; ANode: Integer);
begin
  SelectedNode := ANode;
end;

procedure TProbe.NetLink(Sender: TObject; AFromNode, AToNode: Integer; AAlt: Boolean);
begin
  LinkFrom := AFromNode;
  LinkTo := AToNode;
end;

procedure TProbe.BoardMove(Sender: TObject; ACard, ANewColumn: Integer; var Accept: Boolean; var Reason: string);
begin
  if ANewColumn = 2 then
  begin
    Accept := False;
    Reason := 'nao e possivel concluir: predecessora aberta';
  end;
end;

function D(M, Dd, H: Word): TDateTime;
begin
  Result := EncodeDate(2026, M, Dd) + EncodeTime(H, 0, 0, 0);
end;

procedure TestGantt(F: TForm; P: TProbe);
var
  G: TAIGanttView;
  R: TAIGanttRow;
  B0, B1: TRect;
  X0: Integer;
begin
  G := TAIGanttView.Create(F);
  G.Parent := F;
  G.SetBounds(0, 0, 900, 300);
  G.OnSelectRow := @P.GanttSelect;
  G.OnCellEdited := @P.GanttEdited;
  G.OnIsWorkingDay := @P.Working;
  G.AddColumn('EAP', 50);
  G.AddColumn('Nome', 200);
  G.AddColumn('Duracao', 70, True, taRightJustify);
  G.TreeColumn := 1;
  G.BeginUpdate;
  R := AIGanttRow('T-0001', 1, D(10, 26, 8), D(10, 28, 17), agbSummary);
  R.Cells := ['1', 'Estrutura', '3d'];
  G.AddRow(R);
  R := AIGanttRow('T-0002', 2, D(10, 26, 8), D(10, 27, 17));
  R.Cells := ['1.1', 'Carcaca', '2d']; R.Critical := True; R.Progress := 50;
  R.BaselineStart := D(10, 26, 8); R.BaselineFinish := D(10, 26, 17);
  G.AddRow(R);
  R := AIGanttRow('T-0003', 2, D(10, 28, 8), D(10, 28, 17));
  R.Cells := ['1.2', 'Eixo', '1d']; R.Dashed := True;
  G.AddRow(R);
  R := AIGanttRow('M-0004', 1, D(10, 28, 17), D(10, 28, 17), agbMilestone);
  R.Cells := ['2', 'Fim', '0d'];
  G.AddRow(R);
  G.AddLink(1, 2, 0, True);
  G.AddLink(2, 3, 2);
  G.EndUpdate;
  G.Origin := EncodeDate(2026, 10, 25);
  G.PixelsPerDay := 40;
  G.StatusDate := D(10, 27, 12);
  F.Show;
  Application.ProcessMessages;
  G.Repaint;
  Check(G.RowCount = 4, 'gantt: 4 linhas');
  Check(G.DateToX(EncodeDate(2026, 10, 25)) = G.TableWidth, 'origem no inicio do grafico');
  Check(Abs(G.XToDate(G.DateToX(D(10, 27, 12))) - D(10, 27, 12)) < 1 / 24, 'X <-> data');
  B0 := G.BarRect(1);
  B1 := G.BarRect(2);
  Check((B0.Right - B0.Left) > (B1.Right - B1.Left), 'barra de 2 dias maior que a de 1 dia');
  Check(B1.Left > B0.Right, 'sucessora depois da predecessora');
  Check(G.RowAtY(G.HeaderHeight + 1) = 0, 'primeira linha sob o cabecalho');
  Check(G.RowAtY(G.HeaderHeight + G.RowHeight * 2 + 2) = 2, 'terceira linha');
  Check(G.RowAtY(2) = -1, 'cabecalho nao e linha');
  Check(G.ColumnAtX(60) = 1, 'coluna do nome');
  G.SelectId('T-0003');
  Check((G.Selected = 2) and (P.SelectedRow = 2), 'selecao por ID dispara o evento');
  G.SetCollapsed(0, True);
  Check(not G.IsRowVisible(1) and not G.IsRowVisible(2) and G.IsRowVisible(3), 'recolher esconde as filhas');
  Check(G.RowAtY(G.HeaderHeight + G.RowHeight + 2) = 3, 'linha seguinte sobe ao recolher');
  G.Selected := 1;
  Check(G.IsRowVisible(1) and not G.IsCollapsed(0), 'selecionar filha reabre o resumo');
  G.EditCell(1, 2);
  Check(G.Editing and (G.Editor.Text = '2d'), 'editor abre com o valor da celula');
  G.Editor.Text := '3 d';
  G.FinishEdit(True);
  Check(not G.Editing and (G.Row(1).Cells[2] = '3d') and (P.EditedText = '3d'), 'edicao aceita com o texto do dono');
  G.EditCell(1, 2);
  G.Editor.Text := 'xyz';
  G.FinishEdit(True);
  Check(G.Row(1).Cells[2] = '3d', 'edicao recusada mantem o valor');
  G.EditCell(1, 1);
  Check(not G.Editing, 'coluna nao editavel nao abre editor');
  X0 := G.DateToX(D(10, 27, 12));
  G.ZoomBy(2, X0);
  Check(Abs(G.DateToX(D(10, 27, 12)) - X0) <= 2, 'zoom mantem a data sob o mouse');
  G.FitToRows;
  Check(G.DateToX(D(10, 26, 8)) >= G.TableWidth, 'ajustar mostra o inicio');
  G.Repaint;
  Application.ProcessMessages;
end;

procedure TestNetwork(F: TForm; P: TProbe);
var
  N: TAINetworkView;
  Nd: TAINetworkNode;
  I: Integer;
  R: TRect;
  C: TPoint;
begin
  N := TAINetworkView.Create(F);
  N.Parent := F;
  N.SetBounds(0, 300, 900, 360);
  N.OnSelect := @P.NetSelect;
  N.OnCreateLink := @P.NetLink;
  N.BeginUpdate;
  for I := 0 to 5 do
  begin
    Nd := AINetworkNode('T-' + IntToStr(I), 'Tarefa ' + IntToStr(I), Ord(I >= 5));
    Nd.Lines := ['26/10 - 27/10', '2d'];
    Nd.Critical := I in [0, 2, 3];
    N.AddNode(Nd);
  end;
  { 0 -> 2, 1 -> 2, 2 -> 3, 2 -> 4 ; 5 sozinho no grupo 1 }
  N.AddLink(0, 2); N.AddLink(1, 2); N.AddLink(2, 3, 'II+2h'); N.AddLink(2, 4);
  N.SetGroupTitle(0, 'Cadeia 1');
  N.SetGroupTitle(1, 'Cadeia 2');
  N.EndUpdate;
  Application.ProcessMessages;
  N.Repaint;
  Check((N.NodeLayer(0) = 0) and (N.NodeLayer(1) = 0), 'origens na camada 0');
  Check(N.NodeLayer(2) = 1, 'juncao na camada 1');
  Check((N.NodeLayer(3) = 2) and (N.NodeLayer(4) = 2), 'sucessoras na camada 2');
  Check(N.NodeRect(2).Left > N.NodeRect(0).Right, 'camada seguinte a direita');
  Check(N.NodeRect(1).Top > N.NodeRect(0).Top, 'mesma camada empilhada');
  Check(N.NodeRect(5).Top > N.NodeRect(1).Bottom, 'segunda cadeia abaixo da primeira');
  R := N.NodeRect(2);
  C := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  Check(N.NodeAt(C.X, C.Y) = 2, 'no sob o mouse');
  N.Selected := 2;
  Check(P.SelectedNode = 2, 'selecao dispara evento');
  Check((N.HighlightOf(0) = 1) and (N.HighlightOf(1) = 1), 'predecessoras realcadas');
  Check((N.HighlightOf(3) = 2) and (N.HighlightOf(4) = 2) and (N.HighlightOf(5) = 0), 'sucessoras realcadas, outra cadeia nao');
  { arrastar do no 3 ao no 5 cria vinculo }
  P.LinkFrom := -1; P.LinkTo := -1;
  R := N.NodeRect(3);
  TNetAccess(N).MouseDown(mbLeft, [], R.Left + 10, R.Top + 10);
  R := N.NodeRect(5);
  TNetAccess(N).MouseMove([ssLeft], R.Left + 10, R.Top + 10);
  TNetAccess(N).MouseUp(mbLeft, [], R.Left + 10, R.Top + 10);
  Check((P.LinkFrom = 3) and (P.LinkTo = 5), 'arraste cria vinculo 3 -> 5');
  N.FitAll;
  N.Zoom(1.2);
  N.Repaint;
  Application.ProcessMessages;
end;

procedure TestBoard(F: TForm; P: TProbe);
var
  B: TAIBoardView;
  Cd: TAIBoardCard;
  R: TRect;
  Reason: string;
begin
  B := TAIBoardView.Create(F);
  B.Parent := F;
  B.SetBounds(0, 660, 900, 300);
  B.OnCardMove := @P.BoardMove;
  B.AddColumn('Planejada', clBlue);
  B.AddColumn('Em andamento', clYellow);
  B.AddColumn('Concluida', clGreen);
  B.BeginUpdate;
  Cd := AIBoardCard('T-0001', 'Carcaca', 0); Cd.Subtitle := 'MultiCAD'; Cd.Badge := 'pronto';
  B.AddCard(Cd);
  B.AddCard(AIBoardCard('T-0002', 'Eixo', 0));
  B.AddCard(AIBoardCard('T-0003', 'Placa', 1));
  B.EndUpdate;
  Application.ProcessMessages;
  B.Repaint;
  Check((B.CardsInColumn(0) = 2) and (B.CardsInColumn(1) = 1), 'cartoes por coluna');
  R := B.CardRect(1);
  Check(R.Top > B.CardRect(0).Bottom, 'segundo cartao abaixo do primeiro');
  Check(B.CardAt(R.Left + 5, R.Top + 5) = 1, 'cartao sob o mouse');
  Check(B.ColumnAt(B.ColumnRect(1).Left + 5) = 1, 'coluna sob o mouse');
  Check(B.TryMoveCard(0, 1, Reason) and (B.Card(0).Column = 1), 'mover aceito');
  Check(not B.TryMoveCard(0, 2, Reason) and (B.Card(0).Column = 1) and (Pos('predecessora', Reason) > 0),
    'mover recusado volta e explica: ' + Reason);
  Check(Pos('predecessora', B.Message) > 0, 'motivo mostrado no quadro');
  Check(B.IndexOfId('T-0003') = 2, 'busca por ID');
  B.Repaint;
  Application.ProcessMessages;
end;

var
  F: TForm;
  P: TProbe;
begin
  Passed := 0; Failed := 0;
  Application.Initialize;
  P := TProbe.Create;
  F := TForm.CreateNew(nil);
  try
    F.SetBounds(0, 0, 920, 980);
    TestGantt(F, P);
    TestNetwork(F, P);
    TestBoard(F, P);
  finally
    F.Free;
    P.Free;
  end;
  if Failed = 0 then
    Writeln(Format('PASS: %d checks (Gantt, diagrama de rede, quadro Kanban)', [Passed]))
  else
  begin
    Writeln(Format('FAIL: %d de %d checks', [Failed, Passed + Failed]));
    Halt(1);
  end;
end.
