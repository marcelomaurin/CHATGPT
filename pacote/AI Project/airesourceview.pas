unit airesourceview;

{ Lazarus AI Suite - AI Project
  TAIResourceView: planejador de equipe (Team Planner) generico.

  - Uma linha por recurso (pessoa, maquina...), com titulo, subtitulo, cor e
    grupo (titulo de grupo antes da primeira linha de cada grupo).
  - Barras das atribuicoes no tempo; barras que se sobrepoem na mesma linha
    vao para faixas empilhadas, e a linha cresce para mostrar o conflito.
  - Intervalos de superalocacao (AddOverload) aparecem hachurados na cor de
    perigo atras das barras, e o nome do recurso fica em vermelho.
  - Escala de tempo em duas faixas (semana / dia), dias sem expediente
    sombreados (OnIsWorkingDay), linha de data de status.
  - Clique seleciona a barra (OnSelectBar), duplo clique dispara
    OnBarDblClick, arrastar uma barra para outra linha dispara OnReassign: o
    dono aceita ou recusa com o motivo, que aparece na propria vista.
  - Roda rola na vertical, Shift+roda na horizontal e Ctrl+roda amplia. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, DateUtils, Controls, Graphics, Forms, StdCtrls,
  LCLType, LResources;

type
  TAIResourceRow = record
    Id: string;
    Title, Subtitle, Group: string;
    Color: TColor;              // marca a esquerda do nome; clNone = sem marca
    Overallocated: Boolean;
    Tag: PtrInt;
  end;

  TAIResourceBar = record
    Id: string;                 // normalmente o ID da tarefa
    Row: Integer;
    Start, Finish: TDateTime;
    Caption: string;
    Color: TColor;              // clNone = ColorBar
    Critical, Dashed, Overloaded: Boolean;
    Tag: PtrInt;
  end;

  TAIResourceOverloadBand = record
    Row: Integer;
    Start, Finish: TDateTime;
  end;

  TAIResourceBarEvent = procedure(Sender: TObject; ABar: Integer) of object;
  TAIResourceReassignEvent = procedure(Sender: TObject; ABar, ANewRow: Integer;
    var Accept: Boolean; var Reason: string) of object;
  TAIResourceWorkingDayEvent = function(Sender: TObject; ADay: TDateTime): Boolean of object;

  TAIResourceView = class(TCustomControl)
  private
    FRows: array of TAIResourceRow;
    FBars: array of TAIResourceBar;
    FBands: array of TAIResourceOverloadBand;
    FLane: array of Integer;          // faixa de cada barra
    FLanes: array of Integer;         // faixas de cada linha
    FRowTop: array of Integer;        // topo de cada linha (sem rolagem)
    FContentHeight: Integer;
    FUpdating: Integer;
    FSelected: Integer;
    FOrigin: TDateTime;
    FPixelsPerDay: Double;
    FStatusDate: TDateTime;
    FScrollX, FScrollY: Integer;
    FHBar, FVBar: TScrollBar;
    FLabelWidth, FHeaderHeight, FLaneHeight, FGroupHeight: Integer;
    FMessage: string;
    FDragBar: Integer;
    FDragStart, FDragPos: TPoint;
    FDragging: Boolean;
    FColorBackground, FColorHeader, FColorHeaderText, FColorGrid, FColorText,
    FColorMuted, FColorBar, FColorCritical, FColorSelection, FColorDanger,
    FColorNonWork, FColorStatusLine, FColorLabel: TColor;
    FOnSelectBar: TAIResourceBarEvent;
    FOnBarDblClick: TAIResourceBarEvent;
    FOnReassign: TAIResourceReassignEvent;
    FOnIsWorkingDay: TAIResourceWorkingDayEvent;
    procedure Layout;
    procedure UpdateScrollBars;
    procedure ScrollChanged(Sender: TObject);
    procedure SetSelected(AValue: Integer);
    procedure SetPixelsPerDay(AValue: Double);
    function AreaWidth: Integer;
    function AreaHeight: Integer;
    function ChartWidth: Integer;
    function ClampX(X: Int64): Integer;
    function RangeEnd: TDateTime;
    function TextH: Integer;
    function RowHeight(ARow: Integer): Integer;
    procedure PaintGrid;
    procedure PaintRows;
    procedure PaintBars;
    procedure PaintHeader;
    procedure PaintBar(const R: TRect; const B: TAIResourceBar; ASelected: Boolean);
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure Clear;
    function AddRow(const ARow: TAIResourceRow): Integer;
    function AddBar(const ABar: TAIResourceBar): Integer;
    procedure AddOverload(ARow: Integer; AStart, AFinish: TDateTime);
    function RowCount: Integer;
    function BarCount: Integer;
    function OverloadBandCount: Integer;
    function Row(I: Integer): TAIResourceRow;
    function Bar(I: Integer): TAIResourceBar;
    function IndexOfRow(const AId: string): Integer;
    function IndexOfBar(const AId: string): Integer;
    function BarsInRow(ARow: Integer): Integer;
    function LanesOf(ARow: Integer): Integer;
    function LaneOf(ABar: Integer): Integer;
    function RowRect(ARow: Integer): TRect;
    function BarRect(ABar: Integer): TRect;
    function RowAtY(Y: Integer): Integer;
    function BarAt(X, Y: Integer): Integer;
    function DateToX(ADate: TDateTime): Integer;
    function XToDate(X: Integer): TDateTime;
    procedure SelectId(const AId: string);
    procedure ScrollToDate(ADate: TDateTime);
    procedure FitToBars;
    procedure ZoomBy(AFactor: Double);
    { o mesmo caminho do arraste: pergunta ao dono e move se aceito }
    function TryReassign(ABar, ANewRow: Integer; out Reason: string): Boolean;
    property Selected: Integer read FSelected write SetSelected;
    property Origin: TDateTime read FOrigin write FOrigin;
    property PixelsPerDay: Double read FPixelsPerDay write SetPixelsPerDay;
    property StatusDate: TDateTime read FStatusDate write FStatusDate;
    property Message: string read FMessage write FMessage;
  published
    property Align;
    property Anchors;
    property Font;
    property ParentFont;
    property LabelWidth: Integer read FLabelWidth write FLabelWidth default 210;
    property LaneHeight: Integer read FLaneHeight write FLaneHeight default 26;
    property ColorBackground: TColor read FColorBackground write FColorBackground;
    property ColorHeader: TColor read FColorHeader write FColorHeader;
    property ColorHeaderText: TColor read FColorHeaderText write FColorHeaderText;
    property ColorGrid: TColor read FColorGrid write FColorGrid;
    property ColorText: TColor read FColorText write FColorText;
    property ColorMuted: TColor read FColorMuted write FColorMuted;
    property ColorBar: TColor read FColorBar write FColorBar;
    property ColorCritical: TColor read FColorCritical write FColorCritical;
    property ColorSelection: TColor read FColorSelection write FColorSelection;
    property ColorDanger: TColor read FColorDanger write FColorDanger;
    property ColorNonWork: TColor read FColorNonWork write FColorNonWork;
    property ColorStatusLine: TColor read FColorStatusLine write FColorStatusLine;
    property ColorLabel: TColor read FColorLabel write FColorLabel;
    property OnSelectBar: TAIResourceBarEvent read FOnSelectBar write FOnSelectBar;
    property OnBarDblClick: TAIResourceBarEvent read FOnBarDblClick write FOnBarDblClick;
    property OnReassign: TAIResourceReassignEvent read FOnReassign write FOnReassign;
    property OnIsWorkingDay: TAIResourceWorkingDayEvent read FOnIsWorkingDay write FOnIsWorkingDay;
  end;

function AIResourceRow(const AId, ATitle: string; const AGroup: string = ''): TAIResourceRow;
function AIResourceBar(const AId: string; ARow: Integer; AStart, AFinish: TDateTime;
  const ACaption: string = ''): TAIResourceBar;

procedure Register;

implementation

const
  MONTHS: array[1..12] of string = ('jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez');
  ROW_PAD = 4;

procedure Register;
begin
  RegisterComponents('AI Project', [TAIResourceView]);
end;

function AIResourceRow(const AId, ATitle: string; const AGroup: string): TAIResourceRow;
begin
  Result.Id := AId;
  Result.Title := ATitle;
  Result.Subtitle := '';
  Result.Group := AGroup;
  Result.Color := clNone;
  Result.Overallocated := False;
  Result.Tag := 0;
end;

function AIResourceBar(const AId: string; ARow: Integer; AStart, AFinish: TDateTime;
  const ACaption: string): TAIResourceBar;
begin
  Result.Id := AId;
  Result.Row := ARow;
  Result.Start := AStart;
  Result.Finish := AFinish;
  if ACaption = '' then Result.Caption := AId else Result.Caption := ACaption;
  Result.Color := clNone;
  Result.Critical := False;
  Result.Dashed := False;
  Result.Overloaded := False;
  Result.Tag := 0;
end;

constructor TAIResourceView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  Width := 760; Height := 360;
  FLabelWidth := 210;
  FHeaderHeight := 44;
  FLaneHeight := 26;
  FGroupHeight := 24;
  FPixelsPerDay := 28;
  FOrigin := Date - 1;
  FSelected := -1;
  FDragBar := -1;
  FColorBackground := clWhite;
  FColorHeader := RGBToColor(244, 246, 250);
  FColorHeaderText := RGBToColor(51, 65, 85);
  FColorGrid := RGBToColor(226, 232, 240);
  FColorText := RGBToColor(15, 23, 42);
  FColorMuted := RGBToColor(100, 116, 139);
  FColorBar := RGBToColor(37, 99, 235);
  FColorCritical := RGBToColor(220, 38, 38);
  FColorSelection := RGBToColor(30, 41, 59);
  FColorDanger := RGBToColor(220, 38, 38);
  FColorNonWork := RGBToColor(241, 245, 249);
  FColorStatusLine := RGBToColor(217, 119, 6);
  FColorLabel := RGBToColor(248, 250, 252);
  FHBar := TScrollBar.Create(Self);
  FHBar.Kind := sbHorizontal;
  FHBar.Parent := Self;
  FHBar.Align := alBottom;
  FHBar.TabStop := False;
  FHBar.OnChange := @ScrollChanged;
  FVBar := TScrollBar.Create(Self);
  FVBar.Kind := sbVertical;
  FVBar.Parent := Self;
  FVBar.Align := alRight;
  FVBar.TabStop := False;
  FVBar.Visible := False;
  FVBar.OnChange := @ScrollChanged;
end;

{ ---------------- dados ---------------- }

procedure TAIResourceView.BeginUpdate;
begin
  Inc(FUpdating);
end;

procedure TAIResourceView.EndUpdate;
begin
  if FUpdating > 0 then Dec(FUpdating);
  if FUpdating = 0 then
  begin
    if FSelected > High(FBars) then FSelected := -1;
    Layout;
    UpdateScrollBars;
    Invalidate;
  end;
end;

procedure TAIResourceView.Clear;
begin
  FRows := nil;
  FBars := nil;
  FBands := nil;
  FSelected := -1;
  if FUpdating = 0 then
  begin
    Layout;
    UpdateScrollBars;
    Invalidate;
  end;
end;

function TAIResourceView.AddRow(const ARow: TAIResourceRow): Integer;
begin
  Result := Length(FRows);
  SetLength(FRows, Result + 1);
  FRows[Result] := ARow;
  if FUpdating = 0 then begin Layout; Invalidate; end;
end;

function TAIResourceView.AddBar(const ABar: TAIResourceBar): Integer;
begin
  Result := Length(FBars);
  SetLength(FBars, Result + 1);
  FBars[Result] := ABar;
  if FUpdating = 0 then begin Layout; Invalidate; end;
end;

procedure TAIResourceView.AddOverload(ARow: Integer; AStart, AFinish: TDateTime);
var N: Integer;
begin
  N := Length(FBands);
  SetLength(FBands, N + 1);
  FBands[N].Row := ARow;
  FBands[N].Start := AStart;
  FBands[N].Finish := AFinish;
  if (ARow >= 0) and (ARow <= High(FRows)) then FRows[ARow].Overallocated := True;
  if FUpdating = 0 then Invalidate;
end;

function TAIResourceView.RowCount: Integer;
begin
  Result := Length(FRows);
end;

function TAIResourceView.BarCount: Integer;
begin
  Result := Length(FBars);
end;

function TAIResourceView.OverloadBandCount: Integer;
begin
  Result := Length(FBands);
end;

function TAIResourceView.Row(I: Integer): TAIResourceRow;
begin
  Result := FRows[I];
end;

function TAIResourceView.Bar(I: Integer): TAIResourceBar;
begin
  Result := FBars[I];
end;

function TAIResourceView.IndexOfRow(const AId: string): Integer;
begin
  for Result := 0 to High(FRows) do
    if SameText(FRows[Result].Id, AId) then Exit;
  Result := -1;
end;

function TAIResourceView.IndexOfBar(const AId: string): Integer;
begin
  for Result := 0 to High(FBars) do
    if SameText(FBars[Result].Id, AId) then Exit;
  Result := -1;
end;

function TAIResourceView.BarsInRow(ARow: Integer): Integer;
var I: Integer;
begin
  Result := 0;
  for I := 0 to High(FBars) do
    if FBars[I].Row = ARow then Inc(Result);
end;

function TAIResourceView.LanesOf(ARow: Integer): Integer;
begin
  if (ARow < 0) or (ARow > High(FLanes)) then Exit(1);
  Result := FLanes[ARow];
end;

function TAIResourceView.LaneOf(ABar: Integer): Integer;
begin
  if (ABar < 0) or (ABar > High(FLane)) then Exit(0);
  Result := FLane[ABar];
end;

{ faixas: cada barra vai para a primeira faixa livre da linha (ordem de inicio) }
procedure TAIResourceView.Layout;
var
  R, I, J, K, Y, N: Integer;
  Order: array of Integer;
  LaneEnd: array of TDateTime;
  Placed: Boolean;
begin
  SetLength(FLane, Length(FBars));
  SetLength(FLanes, Length(FRows));
  SetLength(FRowTop, Length(FRows));
  for R := 0 to High(FRows) do
  begin
    Order := nil;
    for I := 0 to High(FBars) do
      if FBars[I].Row = R then
      begin
        N := Length(Order);
        SetLength(Order, N + 1);
        K := N;
        while (K > 0) and (FBars[Order[K - 1]].Start > FBars[I].Start) do
        begin
          Order[K] := Order[K - 1];
          Dec(K);
        end;
        Order[K] := I;
      end;
    LaneEnd := nil;
    for I in Order do
    begin
      Placed := False;
      for J := 0 to High(LaneEnd) do
        if FBars[I].Start >= LaneEnd[J] - 0.5 / 1440 then
        begin
          FLane[I] := J;
          LaneEnd[J] := Max(FBars[I].Finish, FBars[I].Start + 1 / 1440);
          Placed := True;
          Break;
        end;
      if not Placed then
      begin
        N := Length(LaneEnd);
        SetLength(LaneEnd, N + 1);
        LaneEnd[N] := Max(FBars[I].Finish, FBars[I].Start + 1 / 1440);
        FLane[I] := N;
      end;
    end;
    FLanes[R] := Max(1, Length(LaneEnd));
  end;
  Y := 0;
  for R := 0 to High(FRows) do
  begin
    if (FRows[R].Group <> '') and ((R = 0) or (FRows[R].Group <> FRows[R - 1].Group)) then
      Inc(Y, FGroupHeight);
    FRowTop[R] := Y;
    Inc(Y, RowHeight(R));
  end;
  FContentHeight := Y;
end;

{ ---------------- geometria ---------------- }

function TAIResourceView.AreaWidth: Integer;
begin
  Result := ClientWidth;
  if (FVBar <> nil) and FVBar.Visible then Dec(Result, FVBar.Width);
end;

function TAIResourceView.AreaHeight: Integer;
begin
  Result := ClientHeight;
  if (FHBar <> nil) and FHBar.Visible then Dec(Result, FHBar.Height);
end;

function TAIResourceView.ChartWidth: Integer;
begin
  Result := Max(1, AreaWidth - FLabelWidth);
end;

function TAIResourceView.ClampX(X: Int64): Integer;
begin
  { o X11/GDK nao aceita coordenadas muito grandes }
  Result := Integer(EnsureRange(X, Int64(-2000), Int64(AreaWidth + 2000)));
end;

function TAIResourceView.DateToX(ADate: TDateTime): Integer;
begin
  Result := ClampX(FLabelWidth + Round((ADate - FOrigin) * FPixelsPerDay) - FScrollX);
end;

function TAIResourceView.XToDate(X: Integer): TDateTime;
begin
  Result := FOrigin + (X - FLabelWidth + FScrollX) / FPixelsPerDay;
end;

function TAIResourceView.TextH: Integer;
begin
  if HandleAllocated then
  begin
    Canvas.Font.Assign(Font);
    Result := Canvas.TextHeight('Ag');
  end
  else if Font.Height <> 0 then Result := Abs(Font.Height) + 4
  else Result := 16;
end;

function TAIResourceView.RowHeight(ARow: Integer): Integer;
begin
  Result := Max(LanesOf(ARow) * FLaneHeight, 2 * TextH + 2 * ROW_PAD) + 2 * ROW_PAD;
end;

function TAIResourceView.RangeEnd: TDateTime;
var I: Integer;
begin
  Result := FOrigin + 30;
  for I := 0 to High(FBars) do
    if FBars[I].Finish + 7 > Result then Result := FBars[I].Finish + 7;
end;

function TAIResourceView.RowRect(ARow: Integer): TRect;
var H: Integer;
begin
  if (ARow < 0) or (ARow > High(FRows)) or (ARow > High(FRowTop)) then Exit(Rect(0, 0, 0, 0));
  H := RowHeight(ARow);
  Result := Rect(0, FHeaderHeight + FRowTop[ARow] - FScrollY, AreaWidth,
    FHeaderHeight + FRowTop[ARow] - FScrollY + H);
end;

function TAIResourceView.BarRect(ABar: Integer): TRect;
var RR: TRect; X1, X2: Integer;
begin
  if (ABar < 0) or (ABar > High(FBars)) then Exit(Rect(0, 0, 0, 0));
  RR := RowRect(FBars[ABar].Row);
  X1 := DateToX(FBars[ABar].Start);
  X2 := DateToX(FBars[ABar].Finish);
  if X2 - X1 < 6 then X2 := X1 + 6;
  Result.Left := X1;
  Result.Right := X2;
  Result.Top := RR.Top + ROW_PAD + LaneOf(ABar) * FLaneHeight + 3;
  Result.Bottom := Result.Top + FLaneHeight - 6;
end;

function TAIResourceView.RowAtY(Y: Integer): Integer;
var R: Integer; RR: TRect;
begin
  for R := 0 to High(FRows) do
  begin
    RR := RowRect(R);
    if (Y >= RR.Top) and (Y < RR.Bottom) then Exit(R);
  end;
  Result := -1;
end;

function TAIResourceView.BarAt(X, Y: Integer): Integer;
var I: Integer;
begin
  if (X < FLabelWidth) or (Y < FHeaderHeight) then Exit(-1);
  for I := High(FBars) downto 0 do
    if PtInRect(BarRect(I), Point(X, Y)) then Exit(I);
  Result := -1;
end;

procedure TAIResourceView.UpdateScrollBars;
var W, H: Integer;
begin
  if (FHBar = nil) or (FVBar = nil) then Exit;
  H := FContentHeight + FHeaderHeight;
  FVBar.Visible := H > ClientHeight - FHBar.Height;
  if FVBar.Visible then
  begin
    FVBar.Max := H;
    FVBar.PageSize := Max(1, AreaHeight);
    FScrollY := EnsureRange(FScrollY, 0, Max(0, H - AreaHeight));
    FVBar.Position := FScrollY;
  end
  else
    FScrollY := 0;
  W := Round((RangeEnd - FOrigin) * FPixelsPerDay);
  FHBar.Max := Max(1, W);
  FHBar.PageSize := Max(1, ChartWidth);
  FScrollX := EnsureRange(FScrollX, 0, Max(0, W - ChartWidth));
  FHBar.Position := FScrollX;
end;

procedure TAIResourceView.ScrollChanged(Sender: TObject);
begin
  if Sender = FHBar then FScrollX := FHBar.Position
  else FScrollY := FVBar.Position;
  Invalidate;
end;

procedure TAIResourceView.Resize;
begin
  inherited Resize;
  UpdateScrollBars;
end;

procedure TAIResourceView.SetSelected(AValue: Integer);
begin
  if (AValue < -1) or (AValue > High(FBars)) then AValue := -1;
  if AValue = FSelected then Exit;
  FSelected := AValue;
  Invalidate;
  if Assigned(FOnSelectBar) then FOnSelectBar(Self, FSelected);
end;

procedure TAIResourceView.SelectId(const AId: string);
begin
  Selected := IndexOfBar(AId);
end;

procedure TAIResourceView.SetPixelsPerDay(AValue: Double);
begin
  FPixelsPerDay := EnsureRange(AValue, 2, 200);
  UpdateScrollBars;
  Invalidate;
end;

procedure TAIResourceView.ZoomBy(AFactor: Double);
var Mid: TDateTime;
begin
  Mid := XToDate(FLabelWidth + ChartWidth div 2);
  FPixelsPerDay := EnsureRange(FPixelsPerDay * AFactor, 2, 200);
  FScrollX := Max(0, Round((Mid - FOrigin) * FPixelsPerDay) - ChartWidth div 2);
  UpdateScrollBars;
  Invalidate;
end;

procedure TAIResourceView.ScrollToDate(ADate: TDateTime);
begin
  FScrollX := Max(0, Round((ADate - FOrigin) * FPixelsPerDay) - 20);
  UpdateScrollBars;
  Invalidate;
end;

procedure TAIResourceView.FitToBars;
var I: Integer; A, B: TDateTime;
begin
  if Length(FBars) = 0 then Exit;
  A := FBars[0].Start;
  B := FBars[0].Finish;
  for I := 1 to High(FBars) do
  begin
    if FBars[I].Start < A then A := FBars[I].Start;
    if FBars[I].Finish > B then B := FBars[I].Finish;
  end;
  FOrigin := Trunc(A) - 1;
  FScrollX := 0;
  FPixelsPerDay := EnsureRange((ChartWidth - 20) / Max(1, B - FOrigin + 1), 4, 60);
  UpdateScrollBars;
  Invalidate;
end;

function TAIResourceView.TryReassign(ABar, ANewRow: Integer; out Reason: string): Boolean;
begin
  Reason := '';
  Result := False;
  if (ABar < 0) or (ABar > High(FBars)) or (ANewRow < 0) or (ANewRow > High(FRows)) then
  begin
    Reason := 'barra ou linha inexistente';
    Exit;
  end;
  if FBars[ABar].Row = ANewRow then Exit(True);
  Result := True;
  if Assigned(FOnReassign) then FOnReassign(Self, ABar, ANewRow, Result, Reason);
  if Result then
  begin
    FBars[ABar].Row := ANewRow;
    FMessage := '';
    Layout;
    UpdateScrollBars;
  end
  else
    FMessage := Reason;
  Invalidate;
end;

{ ---------------- pintura ---------------- }

procedure TAIResourceView.Paint;
begin
  if Length(FRowTop) <> Length(FRows) then Layout;
  Canvas.Font.Assign(Font);
  Canvas.Brush.Color := FColorBackground;
  Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));
  PaintGrid;
  PaintRows;
  PaintBars;
  PaintHeader;
  if FMessage <> '' then
  begin
    Canvas.Font.Color := FColorDanger;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(FLabelWidth + 8, AreaHeight - Canvas.TextHeight('A') - 6, FMessage);
    Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TAIResourceView.PaintGrid;
var
  D, First, Last, X, X2, H, I: Integer;
  Work: Boolean;
  RR: TRect;
begin
  H := AreaHeight;
  Canvas.ClipRect := Rect(FLabelWidth, FHeaderHeight, AreaWidth, H);
  Canvas.Clipping := True;
  try
    First := Trunc(XToDate(FLabelWidth)) - 1;
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
      if (FPixelsPerDay >= 18) or (DayOfWeek(D) = 2) then
      begin
        Canvas.Pen.Color := FColorGrid;
        Canvas.Line(X, FHeaderHeight, X, H);
      end;
    end;
    { superalocacao: faixa hachurada na linha do recurso }
    for I := 0 to High(FBands) do
    begin
      RR := RowRect(FBands[I].Row);
      if (RR.Bottom < FHeaderHeight) or (RR.Top > H) then Continue;
      X := DateToX(FBands[I].Start);
      X2 := Max(X + 2, DateToX(FBands[I].Finish));
      Canvas.Brush.Color := RGBToColor(254, 226, 226);
      Canvas.FillRect(Rect(X, RR.Top + 1, X2, RR.Bottom - 1));
      Canvas.Brush.Color := FColorDanger;
      Canvas.Brush.Style := bsBDiagonal;
      Canvas.Pen.Style := psClear;
      Canvas.Rectangle(X, RR.Top + 1, X2 + 1, RR.Bottom);
      Canvas.Pen.Style := psSolid;
      Canvas.Brush.Style := bsSolid;
    end;
    if FStatusDate > 0 then
    begin
      X := DateToX(FStatusDate);
      Canvas.Pen.Color := FColorStatusLine;
      Canvas.Pen.Style := psDash;
      Canvas.Line(X, FHeaderHeight, X, H);
      Canvas.Pen.Style := psSolid;
    end;
  finally
    Canvas.Clipping := False;
  end;
end;

procedure TAIResourceView.PaintRows;
var
  R, TY, H: Integer;
  RR, GR: TRect;
  S: string;
begin
  H := AreaHeight;
  Canvas.Brush.Color := FColorLabel;
  Canvas.FillRect(Rect(0, FHeaderHeight, FLabelWidth, H));
  Canvas.ClipRect := Rect(0, FHeaderHeight, AreaWidth, H);
  Canvas.Clipping := True;
  try
    for R := 0 to High(FRows) do
    begin
      RR := RowRect(R);
      if RR.Bottom < FHeaderHeight then Continue;
      if RR.Top > H then Break;
      { titulo do grupo }
      if (FRows[R].Group <> '') and ((R = 0) or (FRows[R].Group <> FRows[R - 1].Group)) then
      begin
        GR := Rect(0, RR.Top - FGroupHeight, AreaWidth, RR.Top);
        Canvas.Brush.Color := FColorHeader;
        Canvas.FillRect(GR);
        Canvas.Brush.Style := bsClear;
        Canvas.Font.Style := [fsBold];
        Canvas.Font.Color := FColorMuted;
        Canvas.TextOut(10, GR.Top + (FGroupHeight - Canvas.TextHeight('A')) div 2, UpperCase(FRows[R].Group));
        Canvas.Font.Style := [];
        Canvas.Brush.Style := bsSolid;
      end;
      Canvas.Pen.Color := FColorGrid;
      Canvas.Line(0, RR.Bottom - 1, AreaWidth, RR.Bottom - 1);
      if FRows[R].Color <> clNone then
      begin
        Canvas.Brush.Color := FRows[R].Color;
        Canvas.FillRect(Rect(6, RR.Top + 6, 10, RR.Bottom - 6));
      end;
      Canvas.ClipRect := Rect(0, Max(RR.Top, FHeaderHeight), FLabelWidth - 6, Min(RR.Bottom, H));
      Canvas.Brush.Style := bsClear;
      TY := RR.Top + ROW_PAD + 1;
      Canvas.Font.Style := [fsBold];
      if FRows[R].Overallocated then Canvas.Font.Color := FColorDanger
      else Canvas.Font.Color := FColorText;
      S := FRows[R].Title;
      if FRows[R].Overallocated then S := S + '  !';
      Canvas.TextOut(16, TY, S);
      Canvas.Font.Style := [];
      Canvas.Font.Color := FColorMuted;
      Canvas.TextOut(16, TY + Canvas.TextHeight('Ag'), FRows[R].Subtitle);
      Canvas.Brush.Style := bsSolid;
      Canvas.ClipRect := Rect(0, FHeaderHeight, AreaWidth, H);
    end;
  finally
    Canvas.Clipping := False;
  end;
  Canvas.Pen.Color := FColorGrid;
  Canvas.Line(FLabelWidth - 1, FHeaderHeight, FLabelWidth - 1, H);
end;

procedure TAIResourceView.PaintBar(const R: TRect; const B: TAIResourceBar; ASelected: Boolean);
var C: TColor; TW: Integer;
begin
  if B.Critical then C := FColorCritical
  else if B.Color <> clNone then C := B.Color
  else C := FColorBar;
  Canvas.Brush.Color := C;
  if B.Overloaded then
  begin
    Canvas.Pen.Color := FColorDanger;
    Canvas.Pen.Width := 2;
  end
  else
  begin
    Canvas.Pen.Color := C;
    Canvas.Pen.Width := 1;
  end;
  if ASelected then
  begin
    Canvas.Pen.Color := FColorSelection;
    Canvas.Pen.Width := 2;
  end;
  if B.Dashed then Canvas.Pen.Style := psDash;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 6, 6);
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;
  { texto dentro da barra se couber; senao, a direita }
  Canvas.Brush.Style := bsClear;
  TW := Canvas.TextWidth(B.Caption);
  if TW + 8 <= R.Right - R.Left then
  begin
    Canvas.Font.Color := clWhite;
    Canvas.TextOut(R.Left + 4, R.Top + (R.Bottom - R.Top - Canvas.TextHeight('Ag')) div 2, B.Caption);
  end
  else
  begin
    Canvas.Font.Color := FColorText;
    Canvas.TextOut(R.Right + 4, R.Top + (R.Bottom - R.Top - Canvas.TextHeight('Ag')) div 2, B.Caption);
  end;
  Canvas.Brush.Style := bsSolid;
end;

procedure TAIResourceView.PaintBars;
var I, H: Integer; R: TRect;
begin
  H := AreaHeight;
  Canvas.ClipRect := Rect(FLabelWidth, FHeaderHeight, AreaWidth, H);
  Canvas.Clipping := True;
  try
    for I := 0 to High(FBars) do
    begin
      if FDragging and (I = FDragBar) then Continue;
      R := BarRect(I);
      if (R.Bottom < FHeaderHeight) or (R.Top > H) or (R.Right < FLabelWidth) or (R.Left > AreaWidth) then
        Continue;
      PaintBar(R, FBars[I], I = FSelected);
    end;
    if FDragging and (FDragBar >= 0) then
    begin
      R := BarRect(FDragBar);
      OffsetRect(R, 0, FDragPos.Y - FDragStart.Y);
      Canvas.Pen.Style := psDash;
      PaintBar(R, FBars[FDragBar], True);
      Canvas.Pen.Style := psSolid;
    end;
  finally
    Canvas.Clipping := False;
  end;
end;

procedure TAIResourceView.PaintHeader;
var
  Mid, D, First, Last, X, X2: Integer;
  Yr, Mo, Da: Word;
  S: string;
begin
  Mid := FHeaderHeight div 2;
  Canvas.Brush.Color := FColorHeader;
  Canvas.FillRect(Rect(0, 0, AreaWidth, FHeaderHeight));
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := FColorHeaderText;
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(10, (FHeaderHeight - Canvas.TextHeight('Ag')) div 2, 'Recurso');
  Canvas.Font.Style := [];
  Canvas.ClipRect := Rect(FLabelWidth, 0, AreaWidth, FHeaderHeight);
  Canvas.Clipping := True;
  try
    First := Trunc(XToDate(FLabelWidth)) - 7;
    Last := Trunc(XToDate(AreaWidth)) + 7;
    for D := First to Last do
    begin
      DecodeDate(D, Yr, Mo, Da);
      X := DateToX(D);
      X2 := DateToX(D + 1);
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
      Canvas.Font.Color := FColorMuted;
      if FPixelsPerDay >= 18 then
      begin
        S := IntToStr(Da);
        Canvas.Pen.Color := FColorGrid;
        Canvas.Line(X, Mid, X, FHeaderHeight);
        Canvas.TextOut(X + (X2 - X - Canvas.TextWidth(S)) div 2, Mid + (Mid - Canvas.TextHeight('A')) div 2, S);
      end
      else if DayOfWeek(D) = 2 then
      begin
        Canvas.Pen.Color := FColorGrid;
        Canvas.Line(X, Mid, X, FHeaderHeight);
        Canvas.TextOut(X + 3, Mid + (Mid - Canvas.TextHeight('A')) div 2, Format('%.2d', [Da]));
      end;
    end;
  finally
    Canvas.Clipping := False;
    Canvas.Brush.Style := bsSolid;
  end;
  Canvas.Pen.Color := FColorGrid;
  Canvas.Line(0, FHeaderHeight - 1, AreaWidth, FHeaderHeight - 1);
  Canvas.Line(FLabelWidth - 1, 0, FLabelWidth - 1, FHeaderHeight);
end;

{ ---------------- mouse ---------------- }

procedure TAIResourceView.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var N: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if CanFocus then SetFocus;
  if Button <> mbLeft then Exit;
  N := BarAt(X, Y);
  Selected := N;
  FDragBar := N;
  FDragStart := Point(X, Y);
  FDragPos := FDragStart;
  FDragging := False;
end;

procedure TAIResourceView.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FDragBar < 0 then Exit;
  FDragPos := Point(X, Y);
  if not FDragging and (Abs(Y - FDragStart.Y) > 6) then FDragging := True;
  if FDragging then Invalidate;
end;

procedure TAIResourceView.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var R: Integer; Reason: string;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if FDragging and (FDragBar >= 0) then
  begin
    FDragging := False;
    R := RowAtY(Y);
    if R >= 0 then TryReassign(FDragBar, R, Reason);
  end;
  FDragging := False;
  FDragBar := -1;
  Invalidate;
end;

procedure TAIResourceView.DblClick;
var P: TPoint; N: Integer;
begin
  inherited DblClick;
  P := ScreenToClient(Mouse.CursorPos);
  N := BarAt(P.X, P.Y);
  FDragBar := -1;
  FDragging := False;
  if (N >= 0) and Assigned(FOnBarDblClick) then FOnBarDblClick(Self, N);
end;

function TAIResourceView.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := True;
  if ssCtrl in Shift then
  begin
    if WheelDelta > 0 then ZoomBy(1.25) else ZoomBy(0.8);
    Exit;
  end;
  if ssShift in Shift then FScrollX := Max(0, FScrollX - Sign(WheelDelta) * 60)
  else FScrollY := Max(0, FScrollY - Sign(WheelDelta) * 40);
  UpdateScrollBars;
  Invalidate;
end;

initialization
  {$I airesourceview_icon.lrs}

end.
