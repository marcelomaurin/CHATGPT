unit aiganttview;

{ Lazarus AI Suite - AI Project
  TAIGanttView: grafico de Gantt generico (tabela + escala de tempo), no estilo
  do Microsoft Project.

  - O dono preenche linhas (AddRow) e vinculos (AddLink) entre BeginUpdate e
    EndUpdate; a vista nao conhece o modelo do projeto.
  - Tabela a esquerda com colunas configuraveis, coluna de arvore com recuo
    por nivel e recolher/expandir, edicao na celula (duplo clique, F2 ou
    Enter) com validacao pelo dono (OnCellEdited).
  - Escala de tempo em duas faixas (mes/semana/dia conforme o zoom), dias sem
    expediente sombreados (OnIsWorkingDay), linha da data de status.
  - Barras de tarefa, resumo e marco; progresso; linha de base; critica;
    sugerida (tracejada); setas dos vinculos TI/II/TT/IT em cotovelo.
  - Zoom com Ctrl+roda, rolagem com a roda (Shift = horizontal), barras de
    rolagem, divisor da tabela arrastavel.
  - Cores e fontes sao propriedades: a aplicacao aplica a sua paleta. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, Controls, Graphics, StdCtrls, Forms, LCLType,
  LResources;

type
  TAIGanttBarKind = (agbTask, agbSummary, agbMilestone);

  TAIGanttRow = record
    Id: string;
    Cells: array of string;
    Level: Integer;
    Start, Finish: TDateTime;
    BaselineStart, BaselineFinish: TDateTime;   // 0 = sem linha de base
    Kind: TAIGanttBarKind;
    Critical: Boolean;
    Dashed: Boolean;          // proposta ainda nao aceita
    Progress: Integer;        // 0..100
    Tag: PtrInt;
  end;

  TAIGanttColumn = record
    Caption: string;
    Width: Integer;
    Editable: Boolean;
    Alignment: TAlignment;
  end;

  TAIGanttLink = record
    FromRow, ToRow: Integer;
    LinkType: Integer;        // 0 = TI/FS, 1 = II/SS, 2 = TT/FF, 3 = IT/SF
    Critical: Boolean;
  end;

  TAIGanttRowEvent = procedure(Sender: TObject; ARow: Integer) of object;
  TAIGanttCellEditEvent = procedure(Sender: TObject; ARow, ACol: Integer;
    var AText: string; var Accept: Boolean) of object;
  TAIGanttWorkingDayEvent = function(Sender: TObject; ADay: TDateTime): Boolean of object;
  TAIGanttCellIconEvent = procedure(Sender: TObject; ACanvas: TCanvas; ARow: Integer;
    const ARect: TRect) of object;

  TAIGanttView = class(TCustomControl)
  private
    FRows: array of TAIGanttRow;
    FCollapsed: array of Boolean;
    FVisible: array of Integer;     // indices das linhas visiveis
    FColumns: array of TAIGanttColumn;
    FLinks: array of TAIGanttLink;
    FUpdating: Integer;
    FTreeColumn: Integer;
    FTableWidth: Integer;
    FRowHeight: Integer;
    FHeaderHeight: Integer;
    FPixelsPerDay: Double;
    FOrigin: TDateTime;
    FScrollX: Integer;
    FTopRow: Integer;
    FSelected: Integer;
    FStatusDate: TDateTime;
    FShowLinks, FShowBaseline: Boolean;
    FIconWidth: Integer;
    FVBar, FHBar: TScrollBar;
    FEditor: TEdit;
    FEditRow, FEditCol: Integer;
    FSplitDrag: Boolean;
    FColorBackground, FColorText, FColorMuted, FColorGrid, FColorHeader,
    FColorHeaderText, FColorBar, FColorCritical, FColorSummary, FColorMilestone,
    FColorBaseline, FColorProgress, FColorSelection, FColorNonWork, FColorStatusLine,
    FColorLink: TColor;
    FOnSelectRow: TAIGanttRowEvent;
    FOnRowDblClick: TAIGanttRowEvent;
    FOnCellEdited: TAIGanttCellEditEvent;
    FOnIsWorkingDay: TAIGanttWorkingDayEvent;
    FOnCellIcon: TAIGanttCellIconEvent;
    procedure RebuildVisible;
    procedure UpdateScrollBars;
    procedure ScrollChanged(Sender: TObject);
    procedure EditorKey(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditorExit(Sender: TObject);
    procedure CommitEdit(Accept: Boolean);
    function ChartLeft: Integer;
    function AreaWidth: Integer;
    function AreaHeight: Integer;
    function VisibleRowCount: Integer;
    function ColumnLeft(ACol: Integer): Integer;
    function HasChildren(ARow: Integer): Boolean;
    function HasDates(ARow: Integer): Boolean;
    function ClampX(X: Int64): Integer;
    procedure SetPixelsPerDay(AValue: Double);
    procedure SetTableWidth(AValue: Integer);
    procedure SetSelected(AValue: Integer);
    procedure SetStatusDate(AValue: TDateTime);
    procedure PaintHeader;
    procedure PaintRows;
    procedure PaintTimeGrid;
    procedure PaintBars;
    procedure PaintLinks;
    procedure DrawArrowHead(X, Y: Integer; Dir: Integer);
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure Clear;
    procedure ClearColumns;
    function AddColumn(const ACaption: string; AWidth: Integer; AEditable: Boolean = False;
      AAlignment: TAlignment = taLeftJustify): Integer;
    function AddRow(const ARow: TAIGanttRow): Integer;
    procedure AddLink(AFromRow, AToRow, ALinkType: Integer; ACritical: Boolean = False);
    function RowCount: Integer;
    function Row(I: Integer): TAIGanttRow;
    function IndexOfId(const AId: string): Integer;
    procedure SelectId(const AId: string);
    { geometria (publica para testes e para dicas de tela) }
    function DateToX(ADate: TDateTime): Integer;
    function XToDate(X: Integer): TDateTime;
    function RowAtY(Y: Integer): Integer;
    function ColumnAtX(X: Integer): Integer;
    function RowTop(ARow: Integer): Integer;
    function BarRect(ARow: Integer): TRect;
    function IsRowVisible(ARow: Integer): Boolean;
    procedure SetCollapsed(ARow: Integer; AValue: Boolean);
    function IsCollapsed(ARow: Integer): Boolean;
    procedure FitToRows;
    procedure ZoomBy(AFactor: Double; AnchorX: Integer = -1);
    procedure ScrollToRow(ARow: Integer);
    procedure EditCell(ARow, ACol: Integer);
    { termina a edicao como Enter (Accept) ou Esc }
    procedure FinishEdit(Accept: Boolean);
    function Editing: Boolean;
    property Editor: TEdit read FEditor;
    property Selected: Integer read FSelected write SetSelected;
    property Origin: TDateTime read FOrigin write FOrigin;
    property ScrollX: Integer read FScrollX;
    property TopRow: Integer read FTopRow;
  published
    property Align;
    property Anchors;
    property Font;
    property ParentFont;
    property TabStop default True;
    property TreeColumn: Integer read FTreeColumn write FTreeColumn default 0;
    property TableWidth: Integer read FTableWidth write SetTableWidth default 420;
    property RowHeight: Integer read FRowHeight write FRowHeight default 24;
    property HeaderHeight: Integer read FHeaderHeight write FHeaderHeight default 40;
    property PixelsPerDay: Double read FPixelsPerDay write SetPixelsPerDay;
    property StatusDate: TDateTime read FStatusDate write SetStatusDate;
    property ShowLinks: Boolean read FShowLinks write FShowLinks default True;
    property ShowBaseline: Boolean read FShowBaseline write FShowBaseline default True;
    property IconWidth: Integer read FIconWidth write FIconWidth default 0;
    property ColorBackground: TColor read FColorBackground write FColorBackground;
    property ColorText: TColor read FColorText write FColorText;
    property ColorMuted: TColor read FColorMuted write FColorMuted;
    property ColorGrid: TColor read FColorGrid write FColorGrid;
    property ColorHeader: TColor read FColorHeader write FColorHeader;
    property ColorHeaderText: TColor read FColorHeaderText write FColorHeaderText;
    property ColorBar: TColor read FColorBar write FColorBar;
    property ColorCritical: TColor read FColorCritical write FColorCritical;
    property ColorSummary: TColor read FColorSummary write FColorSummary;
    property ColorMilestone: TColor read FColorMilestone write FColorMilestone;
    property ColorBaseline: TColor read FColorBaseline write FColorBaseline;
    property ColorProgress: TColor read FColorProgress write FColorProgress;
    property ColorSelection: TColor read FColorSelection write FColorSelection;
    property ColorNonWork: TColor read FColorNonWork write FColorNonWork;
    property ColorStatusLine: TColor read FColorStatusLine write FColorStatusLine;
    property ColorLink: TColor read FColorLink write FColorLink;
    property OnSelectRow: TAIGanttRowEvent read FOnSelectRow write FOnSelectRow;
    property OnRowDblClick: TAIGanttRowEvent read FOnRowDblClick write FOnRowDblClick;
    property OnCellEdited: TAIGanttCellEditEvent read FOnCellEdited write FOnCellEdited;
    property OnIsWorkingDay: TAIGanttWorkingDayEvent read FOnIsWorkingDay write FOnIsWorkingDay;
    property OnCellIcon: TAIGanttCellIconEvent read FOnCellIcon write FOnCellIcon;
    property OnKeyDown;
    property OnEnter;
    property OnExit;
  end;

function AIGanttRow(const AId: string; ALevel: Integer; AStart, AFinish: TDateTime;
  AKind: TAIGanttBarKind = agbTask): TAIGanttRow;

procedure Register;

implementation

const
  MONTHS: array[1..12] of string = ('jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez');
  WEEKDAY_LETTER: array[1..7] of string = ('D', 'S', 'T', 'Q', 'Q', 'S', 'S');
  TREE_INDENT = 14;

procedure Register;
begin
  RegisterComponents('AI Project', [TAIGanttView]);
end;

function AIGanttRow(const AId: string; ALevel: Integer; AStart, AFinish: TDateTime;
  AKind: TAIGanttBarKind): TAIGanttRow;
begin
  Result.Id := AId;
  Result.Cells := nil;
  Result.Level := ALevel;
  Result.Start := AStart;
  Result.Finish := AFinish;
  Result.BaselineStart := 0;
  Result.BaselineFinish := 0;
  Result.Kind := AKind;
  Result.Critical := False;
  Result.Dashed := False;
  Result.Progress := 0;
  Result.Tag := 0;
end;

function Darker(C: TColor; F: Double): TColor;
var R, G, B: Integer;
begin
  C := ColorToRGB(C);
  R := Round(Red(C) * F); G := Round(Green(C) * F); B := Round(Blue(C) * F);
  Result := RGBToColor(EnsureRange(R, 0, 255), EnsureRange(G, 0, 255), EnsureRange(B, 0, 255));
end;

{ ---------------- construcao ---------------- }

constructor TAIGanttView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  TabStop := True;
  Width := 640; Height := 320;
  FTreeColumn := 0;
  FTableWidth := 420;
  FRowHeight := 24;
  FHeaderHeight := 40;
  FPixelsPerDay := 24;
  FOrigin := Date - 2;
  FSelected := -1;
  FShowLinks := True;
  FShowBaseline := True;
  FColorBackground := clWhite;
  FColorText := RGBToColor(15, 23, 42);
  FColorMuted := RGBToColor(100, 116, 139);
  FColorGrid := RGBToColor(226, 232, 240);
  FColorHeader := RGBToColor(244, 246, 250);
  FColorHeaderText := RGBToColor(51, 65, 85);
  FColorBar := RGBToColor(37, 99, 235);
  FColorCritical := RGBToColor(220, 38, 38);
  FColorSummary := RGBToColor(15, 23, 42);
  FColorMilestone := RGBToColor(15, 23, 42);
  FColorBaseline := RGBToColor(148, 163, 184);
  FColorProgress := RGBToColor(15, 23, 42);
  FColorSelection := RGBToColor(219, 234, 254);
  FColorNonWork := RGBToColor(241, 245, 249);
  FColorStatusLine := RGBToColor(217, 119, 6);
  FColorLink := RGBToColor(71, 85, 105);
  FVBar := TScrollBar.Create(Self);
  FVBar.Kind := sbVertical;
  FVBar.Parent := Self;
  FVBar.Align := alRight;
  FVBar.TabStop := False;
  FVBar.OnChange := @ScrollChanged;
  FHBar := TScrollBar.Create(Self);
  FHBar.Kind := sbHorizontal;
  FHBar.Parent := Self;
  FHBar.Align := alBottom;
  FHBar.TabStop := False;
  FHBar.OnChange := @ScrollChanged;
end;

procedure TAIGanttView.BeginUpdate;
begin
  Inc(FUpdating);
end;

procedure TAIGanttView.EndUpdate;
begin
  if FUpdating > 0 then Dec(FUpdating);
  if FUpdating = 0 then
  begin
    RebuildVisible;
    UpdateScrollBars;
    Invalidate;
  end;
end;

procedure TAIGanttView.Clear;
begin
  CommitEdit(False);
  FRows := nil;
  FCollapsed := nil;
  FLinks := nil;
  FVisible := nil;
  if FUpdating = 0 then begin UpdateScrollBars; Invalidate; end;
end;

procedure TAIGanttView.ClearColumns;
begin
  FColumns := nil;
end;

function TAIGanttView.AddColumn(const ACaption: string; AWidth: Integer; AEditable: Boolean;
  AAlignment: TAlignment): Integer;
begin
  Result := Length(FColumns);
  SetLength(FColumns, Result + 1);
  FColumns[Result].Caption := ACaption;
  FColumns[Result].Width := AWidth;
  FColumns[Result].Editable := AEditable;
  FColumns[Result].Alignment := AAlignment;
end;

function TAIGanttView.AddRow(const ARow: TAIGanttRow): Integer;
begin
  Result := Length(FRows);
  SetLength(FRows, Result + 1);
  FRows[Result] := ARow;
  FRows[Result].Cells := Copy(ARow.Cells);
  SetLength(FCollapsed, Result + 1);
  FCollapsed[Result] := False;
  if FUpdating = 0 then begin RebuildVisible; UpdateScrollBars; Invalidate; end;
end;

procedure TAIGanttView.AddLink(AFromRow, AToRow, ALinkType: Integer; ACritical: Boolean);
var N: Integer;
begin
  N := Length(FLinks);
  SetLength(FLinks, N + 1);
  FLinks[N].FromRow := AFromRow;
  FLinks[N].ToRow := AToRow;
  FLinks[N].LinkType := ALinkType;
  FLinks[N].Critical := ACritical;
  if FUpdating = 0 then Invalidate;
end;

function TAIGanttView.RowCount: Integer;
begin
  Result := Length(FRows);
end;

function TAIGanttView.Row(I: Integer): TAIGanttRow;
begin
  Result := FRows[I];
end;

function TAIGanttView.IndexOfId(const AId: string): Integer;
var I: Integer;
begin
  for I := 0 to High(FRows) do
    if SameText(FRows[I].Id, AId) then Exit(I);
  Result := -1;
end;

procedure TAIGanttView.SelectId(const AId: string);
begin
  Selected := IndexOfId(AId);
end;

function TAIGanttView.HasChildren(ARow: Integer): Boolean;
begin
  Result := (ARow >= 0) and (ARow < High(FRows)) and (FRows[ARow + 1].Level > FRows[ARow].Level);
end;

procedure TAIGanttView.RebuildVisible;
var I, HideBelow: Integer;
begin
  FVisible := nil;
  HideBelow := MaxInt;
  for I := 0 to High(FRows) do
  begin
    if FRows[I].Level > HideBelow then Continue;
    HideBelow := MaxInt;
    SetLength(FVisible, Length(FVisible) + 1);
    FVisible[High(FVisible)] := I;
    if FCollapsed[I] and HasChildren(I) then HideBelow := FRows[I].Level;
  end;
  if FTopRow > Max(0, Length(FVisible) - 1) then FTopRow := Max(0, Length(FVisible) - 1);
end;

function TAIGanttView.IsRowVisible(ARow: Integer): Boolean;
var V: Integer;
begin
  for V in FVisible do
    if V = ARow then Exit(True);
  Result := False;
end;

procedure TAIGanttView.SetCollapsed(ARow: Integer; AValue: Boolean);
begin
  if (ARow < 0) or (ARow > High(FRows)) then Exit;
  FCollapsed[ARow] := AValue;
  RebuildVisible;
  UpdateScrollBars;
  Invalidate;
end;

function TAIGanttView.IsCollapsed(ARow: Integer): Boolean;
begin
  Result := (ARow >= 0) and (ARow <= High(FRows)) and FCollapsed[ARow];
end;

{ ---------------- geometria ---------------- }

function TAIGanttView.ChartLeft: Integer;
begin
  Result := FTableWidth;
end;

function TAIGanttView.AreaWidth: Integer;
begin
  Result := ClientWidth;
  if FVBar.Visible then Dec(Result, FVBar.Width);
end;

function TAIGanttView.AreaHeight: Integer;
begin
  Result := ClientHeight;
  if FHBar.Visible then Dec(Result, FHBar.Height);
end;

function TAIGanttView.VisibleRowCount: Integer;
begin
  Result := Max(1, (AreaHeight - FHeaderHeight) div FRowHeight);
end;

function TAIGanttView.ColumnLeft(ACol: Integer): Integer;
var I: Integer;
begin
  Result := 0;
  for I := 0 to ACol - 1 do Inc(Result, FColumns[I].Width);
end;

function TAIGanttView.DateToX(ADate: TDateTime): Integer;
begin
  Result := ChartLeft + Round((ADate - FOrigin) * FPixelsPerDay) - FScrollX;
end;

function TAIGanttView.XToDate(X: Integer): TDateTime;
begin
  Result := FOrigin + (X - ChartLeft + FScrollX) / FPixelsPerDay;
end;

function TAIGanttView.RowTop(ARow: Integer): Integer;
var V: Integer;
begin
  for V := 0 to High(FVisible) do
    if FVisible[V] = ARow then Exit(FHeaderHeight + (V - FTopRow) * FRowHeight);
  Result := -1;
end;

function TAIGanttView.RowAtY(Y: Integer): Integer;
var V: Integer;
begin
  Result := -1;
  if Y < FHeaderHeight then Exit;
  V := FTopRow + (Y - FHeaderHeight) div FRowHeight;
  if (V >= 0) and (V <= High(FVisible)) then Result := FVisible[V];
end;

function TAIGanttView.ColumnAtX(X: Integer): Integer;
var I, L: Integer;
begin
  L := 0;
  for I := 0 to High(FColumns) do
  begin
    if (X >= L) and (X < L + FColumns[I].Width) then Exit(I);
    Inc(L, FColumns[I].Width);
  end;
  Result := -1;
end;

function TAIGanttView.HasDates(ARow: Integer): Boolean;
begin
  Result := (ARow >= 0) and (ARow <= High(FRows)) and (FRows[ARow].Start > 0);
end;

function TAIGanttView.ClampX(X: Int64): Integer;
begin
  { o X11/GDK nao aceita coordenadas muito grandes: limita a area desenhada
    (a barra fora da tela continua fora da tela) }
  Result := Integer(EnsureRange(X, Int64(-2000), Int64(AreaWidth + 2000)));
end;

function TAIGanttView.BarRect(ARow: Integer): TRect;
var T, X1, X2: Integer;
begin
  T := RowTop(ARow);
  if (T < 0) or not HasDates(ARow) then Exit(Rect(0, 0, 0, 0));
  X1 := ClampX(Int64(ChartLeft) + Round((FRows[ARow].Start - FOrigin) * FPixelsPerDay) - FScrollX);
  X2 := ClampX(Int64(ChartLeft) + Round((FRows[ARow].Finish - FOrigin) * FPixelsPerDay) - FScrollX);
  if X2 < X1 + 2 then X2 := X1 + 2;
  case FRows[ARow].Kind of
    agbMilestone: Result := Rect(X1 - 6, T + FRowHeight div 2 - 6, X1 + 6, T + FRowHeight div 2 + 6);
    agbSummary: Result := Rect(X1, T + 7, X2, T + 13);
  else
    Result := Rect(X1, T + 5, X2, T + FRowHeight - 7);
  end;
end;

procedure TAIGanttView.SetPixelsPerDay(AValue: Double);
begin
  FPixelsPerDay := EnsureRange(AValue, 0.5, 400);
  UpdateScrollBars;
  Invalidate;
end;

procedure TAIGanttView.SetTableWidth(AValue: Integer);
begin
  FTableWidth := EnsureRange(AValue, 80, Max(120, AreaWidth - 80));
  Invalidate;
end;

procedure TAIGanttView.SetSelected(AValue: Integer);
var P: Integer;
begin
  if (AValue < -1) or (AValue > High(FRows)) then AValue := -1;
  if AValue = FSelected then Exit;
  FSelected := AValue;
  { abre os resumos acima para mostrar a linha }
  if (FSelected >= 0) and not IsRowVisible(FSelected) then
  begin
    for P := FSelected - 1 downto 0 do
      if (FRows[P].Level < FRows[FSelected].Level) then FCollapsed[P] := False;
    RebuildVisible;
    UpdateScrollBars;
  end;
  if FSelected >= 0 then ScrollToRow(FSelected);
  Invalidate;
  if Assigned(FOnSelectRow) then FOnSelectRow(Self, FSelected);
end;

procedure TAIGanttView.SetStatusDate(AValue: TDateTime);
begin
  FStatusDate := AValue;
  Invalidate;
end;

procedure TAIGanttView.ScrollToRow(ARow: Integer);
var V: Integer;
begin
  for V := 0 to High(FVisible) do
    if FVisible[V] = ARow then
    begin
      if V < FTopRow then FTopRow := V
      else if V >= FTopRow + VisibleRowCount then FTopRow := V - VisibleRowCount + 1;
      UpdateScrollBars;
      Invalidate;
      Exit;
    end;
end;

procedure TAIGanttView.FitToRows;
var I: Integer; A, B: TDateTime; W: Integer;
begin
  if Length(FRows) = 0 then Exit;
  A := MaxDouble; B := -MaxDouble;
  for I := 0 to High(FRows) do
  begin
    if FRows[I].Start <= 0 then Continue;
    A := Min(A, FRows[I].Start);
    B := Max(B, Max(FRows[I].Finish, FRows[I].BaselineFinish));
    if FRows[I].BaselineStart > 0 then A := Min(A, FRows[I].BaselineStart);
  end;
  if A = MaxDouble then Exit;
  FOrigin := Trunc(A) - 1;
  W := Max(100, AreaWidth - ChartLeft - 24);
  FPixelsPerDay := EnsureRange(W / Max(1, Trunc(B) + 2 - FOrigin), 0.5, 120);
  FScrollX := 0;
  UpdateScrollBars;
  Invalidate;
end;

procedure TAIGanttView.ZoomBy(AFactor: Double; AnchorX: Integer);
var D: TDateTime; NewPPD: Double;
begin
  if AnchorX < ChartLeft then AnchorX := ChartLeft + (AreaWidth - ChartLeft) div 2;
  D := XToDate(AnchorX);
  NewPPD := EnsureRange(FPixelsPerDay * AFactor, 0.5, 400);
  FPixelsPerDay := NewPPD;
  { mantem a data sob o mouse no mesmo lugar }
  FScrollX := Max(0, Round((D - FOrigin) * NewPPD) - (AnchorX - ChartLeft));
  UpdateScrollBars;
  Invalidate;
end;

procedure TAIGanttView.UpdateScrollBars;
var Total, Last: Double; I: Integer;
begin
  if (FVBar = nil) or (FHBar = nil) then Exit;
  FVBar.Max := Max(1, Length(FVisible));
  FVBar.PageSize := Min(FVBar.Max, VisibleRowCount);
  FVBar.Visible := Length(FVisible) > VisibleRowCount;
  if not FVBar.Visible then FTopRow := 0;
  FVBar.Position := Min(FTopRow, Max(0, FVBar.Max - FVBar.PageSize));
  Last := FOrigin + 30;
  for I := 0 to High(FRows) do Last := Max(Last, Max(FRows[I].Finish, FRows[I].BaselineFinish));
  Total := (Last - FOrigin + 14) * FPixelsPerDay;
  FHBar.Max := Max(1, Round(Total));
  FHBar.PageSize := Max(1, Min(FHBar.Max, AreaWidth - ChartLeft));
  FHBar.Visible := True;
  if FScrollX > FHBar.Max then FScrollX := FHBar.Max;
  FHBar.Position := FScrollX;
end;

procedure TAIGanttView.ScrollChanged(Sender: TObject);
begin
  if Sender = FVBar then FTopRow := FVBar.Position
  else FScrollX := FHBar.Position;
  Invalidate;
end;

procedure TAIGanttView.Resize;
begin
  inherited Resize;
  UpdateScrollBars;
end;

{ ---------------- pintura ---------------- }

procedure TAIGanttView.Paint;
begin
  Canvas.Font.Assign(Font);
  Canvas.Brush.Color := FColorBackground;
  Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));
  PaintTimeGrid;
  PaintRows;
  PaintBars;
  if FShowLinks then PaintLinks;
  PaintHeader;
end;

procedure TAIGanttView.PaintTimeGrid;
var
  D, First, Last: Integer;
  X, X2, H: Integer;
  Work: Boolean;
begin
  H := AreaHeight;
  Canvas.ClipRect := Rect(ChartLeft, 0, AreaWidth, H);
  Canvas.Clipping := True;
  try
    First := Trunc(XToDate(ChartLeft)) - 1;
    Last := Trunc(XToDate(AreaWidth)) + 1;
    for D := First to Last do
    begin
      X := DateToX(D);
      X2 := DateToX(D + 1);
      if Assigned(FOnIsWorkingDay) then Work := FOnIsWorkingDay(Self, D)
      else Work := not (DayOfWeek(D) in [1, 7]);
      if not Work and (FPixelsPerDay >= 3) then
      begin
        Canvas.Brush.Color := FColorNonWork;
        Canvas.FillRect(Rect(X, FHeaderHeight, X2, H));
      end;
      { linha no inicio de cada semana (segunda) ou de cada dia quando ampliado }
      if (FPixelsPerDay >= 18) or (DayOfWeek(D) = 2) then
      begin
        Canvas.Pen.Color := FColorGrid;
        Canvas.Line(X, FHeaderHeight, X, H);
      end;
    end;
    if FStatusDate > 0 then
    begin
      X := ClampX(DateToX(FStatusDate));
      Canvas.Pen.Color := FColorStatusLine;
      Canvas.Pen.Style := psDash;
      Canvas.Line(X, FHeaderHeight, X, H);
      Canvas.Pen.Style := psSolid;
    end;
  finally
    Canvas.Clipping := False;
  end;
end;

procedure TAIGanttView.PaintRows;
var
  V, R, Y, C, L, W, TX, TY, Indent: Integer;
  S: string;
  Cell: TRect;
  Tri: array[0..2] of TPoint;
begin
  for V := FTopRow to High(FVisible) do
  begin
    R := FVisible[V];
    Y := FHeaderHeight + (V - FTopRow) * FRowHeight;
    if Y > AreaHeight then Break;
    if R = FSelected then
    begin
      Canvas.Brush.Color := FColorSelection;
      Canvas.FillRect(Rect(0, Y, AreaWidth, Y + FRowHeight));
    end;
    Canvas.Pen.Color := FColorGrid;
    Canvas.Line(0, Y + FRowHeight - 1, ChartLeft, Y + FRowHeight - 1);
    L := 0;
    for C := 0 to High(FColumns) do
    begin
      W := FColumns[C].Width;
      if L >= ChartLeft then Break;
      Cell := Rect(L, Y, Min(L + W, ChartLeft), Y + FRowHeight);
      Canvas.Pen.Color := FColorGrid;
      Canvas.Line(L + W - 1, Y, L + W - 1, Y + FRowHeight);
      if C <= High(FRows[R].Cells) then S := FRows[R].Cells[C] else S := '';
      TX := L + 4;
      Indent := 0;
      if C = FTreeColumn then
      begin
        Indent := (FRows[R].Level - 1) * TREE_INDENT;
        if Indent < 0 then Indent := 0;
        if HasChildren(R) then
        begin
          { triangulo de recolher/expandir }
          Canvas.Brush.Color := FColorMuted;
          Canvas.Pen.Color := FColorMuted;
          TY := Y + FRowHeight div 2;
          if FCollapsed[R] then
          begin
            Tri[0] := Point(TX + Indent + 2, TY - 4); Tri[1] := Point(TX + Indent + 6, TY);
            Tri[2] := Point(TX + Indent + 2, TY + 4);
          end
          else
          begin
            Tri[0] := Point(TX + Indent, TY - 2); Tri[1] := Point(TX + Indent + 8, TY - 2);
            Tri[2] := Point(TX + Indent + 4, TY + 3);
          end;
          Canvas.Polygon(Tri);
        end;
        Inc(Indent, 12);
        if (FIconWidth > 0) and Assigned(FOnCellIcon) then
        begin
          FOnCellIcon(Self, Canvas, R, Rect(TX + Indent, Y + (FRowHeight - FIconWidth) div 2,
            TX + Indent + FIconWidth, Y + (FRowHeight + FIconWidth) div 2));
          Inc(Indent, FIconWidth + 4);
        end;
      end;
      Canvas.Brush.Style := bsClear;
      if HasChildren(R) then Canvas.Font.Style := [fsBold] else Canvas.Font.Style := [];
      if FRows[R].Dashed then Canvas.Font.Color := FColorMuted else Canvas.Font.Color := FColorText;
      TY := Y + (FRowHeight - Canvas.TextHeight('Ag')) div 2;
      Canvas.ClipRect := Rect(Cell.Left + 1, Cell.Top, Cell.Right - 3, Cell.Bottom);
      Canvas.Clipping := True;
      case FColumns[C].Alignment of
        taRightJustify: Canvas.TextOut(Cell.Right - 6 - Canvas.TextWidth(S), TY, S);
        taCenter: Canvas.TextOut((Cell.Left + Cell.Right - Canvas.TextWidth(S)) div 2, TY, S);
      else
        Canvas.TextOut(TX + Indent, TY, S);
      end;
      Canvas.Clipping := False;
      Canvas.Brush.Style := bsSolid;
      Inc(L, W);
    end;
  end;
  Canvas.Font.Style := [];
  { divisor tabela / grafico }
  Canvas.Pen.Color := Darker(FColorGrid, 0.85);
  Canvas.Line(ChartLeft - 1, 0, ChartLeft - 1, AreaHeight);
end;

procedure TAIGanttView.PaintBars;
var
  V, R, Mid, PW: Integer;
  B: TRect;
  Col: TColor;
  Pts: array[0..3] of TPoint;
  Caps: array[0..2] of TPoint;
  BX1, BX2, Y: Integer;
begin
  Canvas.ClipRect := Rect(ChartLeft, FHeaderHeight, AreaWidth, AreaHeight);
  Canvas.Clipping := True;
  try
    for V := FTopRow to High(FVisible) do
    begin
      R := FVisible[V];
      if FHeaderHeight + (V - FTopRow) * FRowHeight > AreaHeight then Break;
      { linha sem datas (grupo, tarefa ainda nao calculada): sem barra }
      if not HasDates(R) then Continue;
      B := BarRect(R);
      if (B.Right < ChartLeft - 20) or (B.Left > AreaWidth + 20) then Continue;
      if FRows[R].Critical then Col := FColorCritical
      else if FRows[R].Kind = agbSummary then Col := FColorSummary
      else if FRows[R].Kind = agbMilestone then Col := FColorMilestone
      else Col := FColorBar;
      { linha de base: faixa fina sob a barra }
      if FShowBaseline and (FRows[R].BaselineStart > 0) and (FRows[R].Kind <> agbMilestone) then
      begin
        BX1 := ClampX(DateToX(FRows[R].BaselineStart));
        BX2 := Max(BX1 + 2, ClampX(DateToX(FRows[R].BaselineFinish)));
        Y := RowTop(R) + FRowHeight - 6;
        Canvas.Brush.Color := FColorBaseline;
        Canvas.Pen.Color := FColorBaseline;
        Canvas.FillRect(Rect(BX1, Y, BX2, Y + 3));
      end;
      case FRows[R].Kind of
        agbMilestone:
          begin
            Mid := (B.Top + B.Bottom) div 2;
            Pts[0] := Point((B.Left + B.Right) div 2, B.Top);
            Pts[1] := Point(B.Right, Mid);
            Pts[2] := Point((B.Left + B.Right) div 2, B.Bottom);
            Pts[3] := Point(B.Left, Mid);
            Canvas.Brush.Color := Col;
            Canvas.Pen.Color := Col;
            if FRows[R].Dashed then Canvas.Brush.Style := bsClear;
            Canvas.Polygon(Pts);
            Canvas.Brush.Style := bsSolid;
          end;
        agbSummary:
          begin
            Canvas.Brush.Color := Col;
            Canvas.Pen.Color := Col;
            Canvas.FillRect(B);
            Caps[0] := Point(B.Left, B.Bottom); Caps[1] := Point(B.Left + 5, B.Bottom);
            Caps[2] := Point(B.Left, B.Bottom + 5);
            Canvas.Polygon(Caps);
            Caps[0] := Point(B.Right, B.Bottom); Caps[1] := Point(B.Right - 5, B.Bottom);
            Caps[2] := Point(B.Right, B.Bottom + 5);
            Canvas.Polygon(Caps);
          end;
      else
        begin
          if FRows[R].Dashed then
          begin
            Canvas.Brush.Style := bsClear;
            Canvas.Pen.Style := psDash;
            Canvas.Pen.Color := Col;
            Canvas.Rectangle(B);
            Canvas.Pen.Style := psSolid;
            Canvas.Brush.Style := bsSolid;
          end
          else
          begin
            Canvas.Brush.Color := Col;
            Canvas.Pen.Color := Darker(Col, 0.8);
            Canvas.RoundRect(B.Left, B.Top, B.Right, B.Bottom, 4, 4);
            if FRows[R].Progress > 0 then
            begin
              PW := Round((B.Right - B.Left) * EnsureRange(FRows[R].Progress, 0, 100) / 100);
              Canvas.Brush.Color := Darker(Col, 0.55);
              Canvas.FillRect(Rect(B.Left, (B.Top + B.Bottom) div 2 - 2, B.Left + PW, (B.Top + B.Bottom) div 2 + 2));
            end;
          end;
        end;
      end;
    end;
  finally
    Canvas.Clipping := False;
  end;
end;

procedure TAIGanttView.DrawArrowHead(X, Y: Integer; Dir: Integer);
var P: array[0..2] of TPoint;
begin
  { Dir: 0 = para a direita, 1 = para baixo, 2 = para a esquerda, 3 = para cima }
  case Dir of
    0: begin P[0] := Point(X, Y); P[1] := Point(X - 5, Y - 3); P[2] := Point(X - 5, Y + 3); end;
    1: begin P[0] := Point(X, Y); P[1] := Point(X - 3, Y - 5); P[2] := Point(X + 3, Y - 5); end;
    2: begin P[0] := Point(X, Y); P[1] := Point(X + 5, Y - 3); P[2] := Point(X + 5, Y + 3); end;
  else
    begin P[0] := Point(X, Y); P[1] := Point(X - 3, Y + 5); P[2] := Point(X + 3, Y + 5); end;
  end;
  Canvas.Polygon(P);
end;

procedure TAIGanttView.PaintLinks;
var
  I, YA, YB, XA, XB, XM: Integer;
  A, B: TRect;
  L: TAIGanttLink;
  Down: Boolean;
  FromEnd, ToEnd: Boolean;
begin
  Canvas.ClipRect := Rect(ChartLeft, FHeaderHeight, AreaWidth, AreaHeight);
  Canvas.Clipping := True;
  try
    for I := 0 to High(FLinks) do
    begin
      L := FLinks[I];
      if (L.FromRow < 0) or (L.ToRow < 0) or (L.FromRow > High(FRows)) or (L.ToRow > High(FRows)) then Continue;
      if (RowTop(L.FromRow) < 0) or (RowTop(L.ToRow) < 0) then Continue;
      if not HasDates(L.FromRow) or not HasDates(L.ToRow) then Continue;
      A := BarRect(L.FromRow);
      B := BarRect(L.ToRow);
      if L.Critical then Canvas.Pen.Color := FColorCritical else Canvas.Pen.Color := FColorLink;
      Canvas.Brush.Color := Canvas.Pen.Color;
      YA := (A.Top + A.Bottom) div 2;
      YB := (B.Top + B.Bottom) div 2;
      Down := YB > YA;
      FromEnd := L.LinkType in [0, 2];   // TI e TT saem do termino
      ToEnd := L.LinkType in [2, 3];     // TT e IT chegam no termino
      if FromEnd then XA := A.Right else XA := A.Left;
      if ToEnd then XB := B.Right else XB := B.Left;
      if (L.LinkType = 0) and (XB >= XA + 6) then
      begin
        { TI classico: sai pela direita e desce sobre o inicio da sucessora }
        Canvas.Line(XA, YA, XB + 4, YA);
        if Down then
        begin
          Canvas.Line(XB + 4, YA, XB + 4, B.Top - 1);
          DrawArrowHead(XB + 4, B.Top - 1, 1);
        end
        else
        begin
          Canvas.Line(XB + 4, YA, XB + 4, B.Bottom + 1);
          DrawArrowHead(XB + 4, B.Bottom + 1, 3);
        end;
        Continue;
      end;
      { cotovelo: sai 8 px para o lado, vai ate a linha da sucessora e entra pelo lado certo }
      if FromEnd then XM := XA + 8 else XM := XA - 8;
      if ToEnd then XM := Max(XM, XB + 8) else XM := Min(XM, XB - 8);
      Canvas.Line(XA, YA, XM, YA);
      Canvas.Line(XM, YA, XM, YB);
      Canvas.Line(XM, YB, XB, YB);
      if ToEnd then DrawArrowHead(XB + 1, YB, 2) else DrawArrowHead(XB - 1, YB, 0);
    end;
  finally
    Canvas.Clipping := False;
  end;
end;

procedure TAIGanttView.PaintHeader;
var
  C, L, Mid, X, X2, D, First, Last: Integer;
  Yr, Mo, Da: Word;
  S: string;
begin
  Mid := FHeaderHeight div 2;
  Canvas.Brush.Color := FColorHeader;
  Canvas.FillRect(Rect(0, 0, AreaWidth, FHeaderHeight));
  Canvas.Font.Color := FColorHeaderText;
  Canvas.Font.Style := [fsBold];
  L := 0;
  for C := 0 to High(FColumns) do
  begin
    if L >= ChartLeft then Break;
    Canvas.ClipRect := Rect(L, 0, Min(L + FColumns[C].Width, ChartLeft) - 2, FHeaderHeight);
    Canvas.Clipping := True;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(L + 6, (FHeaderHeight - Canvas.TextHeight('Ag')) div 2, FColumns[C].Caption);
    Canvas.Brush.Style := bsSolid;
    Canvas.Clipping := False;
    Canvas.Pen.Color := FColorGrid;
    Canvas.Line(L + FColumns[C].Width - 1, 4, L + FColumns[C].Width - 1, FHeaderHeight - 4);
    Inc(L, FColumns[C].Width);
  end;
  Canvas.Font.Style := [];
  { escala de tempo: faixa de cima (mes ou semana) e de baixo (semana ou dia) }
  Canvas.ClipRect := Rect(ChartLeft, 0, AreaWidth, FHeaderHeight);
  Canvas.Clipping := True;
  try
    First := Trunc(XToDate(ChartLeft)) - 7;
    Last := Trunc(XToDate(AreaWidth)) + 7;
    Canvas.Brush.Style := bsClear;
    for D := First to Last do
    begin
      DecodeDate(D, Yr, Mo, Da);
      X := DateToX(D);
      { faixa de cima }
      if FPixelsPerDay >= 12 then
      begin
        if DayOfWeek(D) = 2 then
        begin
          Canvas.Pen.Color := FColorGrid;
          Canvas.Line(X, 2, X, Mid);
          Canvas.Font.Color := FColorHeaderText;
          Canvas.TextOut(X + 4, (Mid - Canvas.TextHeight('A')) div 2,
            Format('%.2d/%.2d', [Da, Mo]) + ' ' + MONTHS[Mo] + ' ' + IntToStr(Yr));
        end;
      end
      else if Da = 1 then
      begin
        Canvas.Pen.Color := FColorGrid;
        Canvas.Line(X, 2, X, Mid);
        Canvas.Font.Color := FColorHeaderText;
        Canvas.TextOut(X + 4, (Mid - Canvas.TextHeight('A')) div 2, MONTHS[Mo] + ' ' + IntToStr(Yr));
      end;
      { faixa de baixo }
      X2 := DateToX(D + 1);
      Canvas.Font.Color := FColorMuted;
      if FPixelsPerDay >= 18 then
      begin
        S := WEEKDAY_LETTER[DayOfWeek(D)] + ' ' + IntToStr(Da);
        if Canvas.TextWidth(S) > X2 - X - 2 then S := IntToStr(Da);
        Canvas.TextOut(X + (X2 - X - Canvas.TextWidth(S)) div 2, Mid + (Mid - Canvas.TextHeight('A')) div 2, S);
        Canvas.Pen.Color := FColorGrid;
        Canvas.Line(X, Mid, X, FHeaderHeight);
      end
      else if (FPixelsPerDay >= 3) and (DayOfWeek(D) = 2) then
      begin
        Canvas.TextOut(X + 3, Mid + (Mid - Canvas.TextHeight('A')) div 2, IntToStr(Da));
        Canvas.Pen.Color := FColorGrid;
        Canvas.Line(X, Mid, X, FHeaderHeight);
      end
      else if (FPixelsPerDay < 3) and (Da = 1) then
      begin
        Canvas.TextOut(X + 3, Mid + (Mid - Canvas.TextHeight('A')) div 2, MONTHS[Mo]);
        Canvas.Pen.Color := FColorGrid;
        Canvas.Line(X, Mid, X, FHeaderHeight);
      end;
    end;
    Canvas.Brush.Style := bsSolid;
    Canvas.Pen.Color := FColorGrid;
    Canvas.Line(ChartLeft, Mid, AreaWidth, Mid);
  finally
    Canvas.Clipping := False;
  end;
  Canvas.Pen.Color := Darker(FColorGrid, 0.85);
  Canvas.Line(0, FHeaderHeight - 1, AreaWidth, FHeaderHeight - 1);
end;

{ ---------------- mouse e teclado ---------------- }

procedure TAIGanttView.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var R, C, Indent: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if CanFocus then SetFocus;
  if Editing then CommitEdit(True);
  if (Button = mbLeft) and (Abs(X - ChartLeft) <= 3) then
  begin
    FSplitDrag := True;
    Exit;
  end;
  if Button <> mbLeft then Exit;
  R := RowAtY(Y);
  if R < 0 then Exit;
  C := ColumnAtX(X);
  if (X < ChartLeft) and (C = FTreeColumn) and HasChildren(R) then
  begin
    Indent := ColumnLeft(C) + 4 + (FRows[R].Level - 1) * TREE_INDENT;
    if (X >= Indent - 2) and (X <= Indent + 12) then
    begin
      SetCollapsed(R, not FCollapsed[R]);
      Exit;
    end;
  end;
  Selected := R;
end;

procedure TAIGanttView.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FSplitDrag then
  begin
    TableWidth := X;
    UpdateScrollBars;
    Exit;
  end;
  if Abs(X - ChartLeft) <= 3 then Cursor := crHSplit else Cursor := crDefault;
end;

procedure TAIGanttView.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseUp(Button, Shift, X, Y);
  FSplitDrag := False;
end;

procedure TAIGanttView.DblClick;
var P: TPoint; R, C: Integer;
begin
  inherited DblClick;
  P := ScreenToClient(Mouse.CursorPos);
  R := RowAtY(P.Y);
  if R < 0 then Exit;
  C := ColumnAtX(P.X);
  if (P.X < ChartLeft) and (C >= 0) and FColumns[C].Editable then EditCell(R, C)
  else if Assigned(FOnRowDblClick) then FOnRowDblClick(Self, R);
end;

function TAIGanttView.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := True;
  if ssCtrl in Shift then
  begin
    if WheelDelta > 0 then ZoomBy(1.25, MousePos.X) else ZoomBy(0.8, MousePos.X);
  end
  else if ssShift in Shift then
  begin
    FScrollX := Max(0, FScrollX - Sign(WheelDelta) * 60);
    UpdateScrollBars;
    Invalidate;
  end
  else
  begin
    FTopRow := EnsureRange(FTopRow - Sign(WheelDelta) * 3, 0, Max(0, Length(FVisible) - VisibleRowCount));
    UpdateScrollBars;
    Invalidate;
  end;
end;

procedure TAIGanttView.KeyDown(var Key: Word; Shift: TShiftState);
var V, I, C: Integer;
begin
  inherited KeyDown(Key, Shift);
  if Key = 0 then Exit;
  V := -1;
  for I := 0 to High(FVisible) do
    if FVisible[I] = FSelected then V := I;
  case Key of
    VK_UP: if V > 0 then begin Selected := FVisible[V - 1]; Key := 0; end
           else if (V < 0) and (Length(FVisible) > 0) then begin Selected := FVisible[0]; Key := 0; end;
    VK_DOWN: if (V >= 0) and (V < High(FVisible)) then begin Selected := FVisible[V + 1]; Key := 0; end
             else if (V < 0) and (Length(FVisible) > 0) then begin Selected := FVisible[0]; Key := 0; end;
    VK_HOME: if (Length(FVisible) > 0) and (Shift = []) then begin Selected := FVisible[0]; Key := 0; end;
    VK_END: if (Length(FVisible) > 0) and (Shift = []) then begin Selected := FVisible[High(FVisible)]; Key := 0; end;
    VK_LEFT: if (Shift = []) and (FSelected >= 0) and HasChildren(FSelected) and not FCollapsed[FSelected] then
               begin SetCollapsed(FSelected, True); Key := 0; end;
    VK_RIGHT: if (Shift = []) and (FSelected >= 0) and FCollapsed[FSelected] then
               begin SetCollapsed(FSelected, False); Key := 0; end;
    VK_F2, VK_RETURN:
      if (FSelected >= 0) and (Shift = []) then
      begin
        for C := 0 to High(FColumns) do
          if FColumns[C].Editable then
          begin
            EditCell(FSelected, C);
            Key := 0;
            Break;
          end;
      end;
  end;
end;

{ ---------------- edicao na celula ---------------- }

function TAIGanttView.Editing: Boolean;
begin
  Result := (FEditor <> nil) and FEditor.Visible;
end;

procedure TAIGanttView.EditCell(ARow, ACol: Integer);
var T: Integer;
begin
  if (ARow < 0) or (ARow > High(FRows)) or (ACol < 0) or (ACol > High(FColumns)) then Exit;
  if not FColumns[ACol].Editable then Exit;
  Selected := ARow;
  T := RowTop(ARow);
  if T < 0 then Exit;
  if FEditor = nil then
  begin
    FEditor := TEdit.Create(Self);
    FEditor.Parent := Self;
    FEditor.BorderStyle := bsSingle;
    FEditor.OnKeyDown := @EditorKey;
    FEditor.OnExit := @EditorExit;
  end;
  FEditRow := ARow;
  FEditCol := ACol;
  FEditor.SetBounds(ColumnLeft(ACol), T, Min(FColumns[ACol].Width, ChartLeft - ColumnLeft(ACol)), FRowHeight);
  if ACol <= High(FRows[ARow].Cells) then FEditor.Text := FRows[ARow].Cells[ACol]
  else FEditor.Text := '';
  FEditor.Visible := True;
  if FEditor.CanFocus then FEditor.SetFocus;
  FEditor.SelectAll;
end;

procedure TAIGanttView.CommitEdit(Accept: Boolean);
var S: string; Ok: Boolean;
begin
  if not Editing then Exit;
  FEditor.Visible := False;
  if not Accept then Exit;
  S := FEditor.Text;
  Ok := True;
  if Assigned(FOnCellEdited) then FOnCellEdited(Self, FEditRow, FEditCol, S, Ok);
  if Ok and (FEditRow <= High(FRows)) then
  begin
    if FEditCol > High(FRows[FEditRow].Cells) then SetLength(FRows[FEditRow].Cells, FEditCol + 1);
    FRows[FEditRow].Cells[FEditCol] := S;
  end;
  Invalidate;
end;

procedure TAIGanttView.EditorKey(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN: begin CommitEdit(True); Key := 0; if CanFocus then SetFocus; end;
    VK_ESCAPE: begin CommitEdit(False); Key := 0; if CanFocus then SetFocus; end;
    VK_TAB: begin CommitEdit(True); Key := 0; if CanFocus then SetFocus; end;
  end;
end;

procedure TAIGanttView.FinishEdit(Accept: Boolean);
begin
  CommitEdit(Accept);
end;

procedure TAIGanttView.EditorExit(Sender: TObject);
begin
  CommitEdit(True);
end;

initialization
  {$I aiganttview_icon.lrs}

end.
