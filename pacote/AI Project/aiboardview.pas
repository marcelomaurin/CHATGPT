unit aiboardview;

{ Lazarus AI Suite - AI Project
  TAIBoardView: quadro de tarefas (Kanban) generico.

  - Colunas (estados) e cartoes; o dono preenche entre BeginUpdate/EndUpdate.
  - Arrastar um cartao para outra coluna dispara OnCardMove; o dono decide
    (Accept) e pode explicar a recusa (Reason), que a vista mostra no proprio
    quadro. Movimento aceito so muda a vista depois do dono confirmar.
  - Cartao: titulo, subtitulo, rodape, faixa de destaque e etiqueta.
  - Roda rola; cores sao propriedades. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, Controls, Graphics, Forms, StdCtrls, LCLType, LResources;

type
  TAIBoardColumn = record
    Caption: string;
    Color: TColor;
  end;

  TAIBoardCard = record
    Id: string;
    Title, Subtitle, Footer, Badge: string;
    Column: Integer;
    AccentColor: TColor;     // clNone = sem faixa
    BadgeColor: TColor;
    Dashed: Boolean;
    Tag: PtrInt;
  end;

  TAIBoardCardEvent = procedure(Sender: TObject; ACard: Integer) of object;
  TAIBoardMoveEvent = procedure(Sender: TObject; ACard, ANewColumn: Integer;
    var Accept: Boolean; var Reason: string) of object;

  TAIBoardView = class(TCustomControl)
  private
    FColumns: array of TAIBoardColumn;
    FCards: array of TAIBoardCard;
    FUpdating: Integer;
    FSelected: Integer;
    FScrollY: Integer;
    FScrollX: Integer;
    FHBar: TScrollBar;
    FDragCard: Integer;
    FDragStart, FDragPos: TPoint;
    FDragging: Boolean;
    FMessage: string;
    FCardHeight, FHeaderHeight, FGap: Integer;
    FColorBackground, FColorColumn, FColorCard, FColorBorder, FColorText,
    FColorMuted, FColorSelection, FColorDanger: TColor;
    FOnSelect: TAIBoardCardEvent;
    FOnCardDblClick: TAIBoardCardEvent;
    FOnCardMove: TAIBoardMoveEvent;
    procedure SetSelected(AValue: Integer);
    procedure UpdateScrollBar;
    procedure ScrollChanged(Sender: TObject);
    function ColumnWidth: Integer;
    function ContentWidth: Integer;
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
    procedure ClearColumns;
    function AddColumn(const ACaption: string; AColor: TColor = clNone): Integer;
    function AddCard(const ACard: TAIBoardCard): Integer;
    procedure ScrollToColumn(ACol: Integer);
    function CardCount: Integer;
    function Card(I: Integer): TAIBoardCard;
    function ColumnCount: Integer;
    function IndexOfId(const AId: string): Integer;
    function ColumnRect(ACol: Integer): TRect;
    function ColumnAt(X: Integer): Integer;
    function CardRect(ACard: Integer): TRect;
    function CardAt(X, Y: Integer): Integer;
    function CardsInColumn(ACol: Integer): Integer;
    { o mesmo caminho do arraste: pergunta ao dono e move se aceito }
    function TryMoveCard(ACard, ANewColumn: Integer; out Reason: string): Boolean;
    property Selected: Integer read FSelected write SetSelected;
    property Message: string read FMessage write FMessage;
  published
    property Align;
    property Anchors;
    property Font;
    property ParentFont;
    property CardHeight: Integer read FCardHeight write FCardHeight default 66;
    property ColorBackground: TColor read FColorBackground write FColorBackground;
    property ColorColumn: TColor read FColorColumn write FColorColumn;
    property ColorCard: TColor read FColorCard write FColorCard;
    property ColorBorder: TColor read FColorBorder write FColorBorder;
    property ColorText: TColor read FColorText write FColorText;
    property ColorMuted: TColor read FColorMuted write FColorMuted;
    property ColorSelection: TColor read FColorSelection write FColorSelection;
    property ColorDanger: TColor read FColorDanger write FColorDanger;
    property OnSelect: TAIBoardCardEvent read FOnSelect write FOnSelect;
    property OnCardDblClick: TAIBoardCardEvent read FOnCardDblClick write FOnCardDblClick;
    property OnCardMove: TAIBoardMoveEvent read FOnCardMove write FOnCardMove;
  end;

function AIBoardCard(const AId, ATitle: string; AColumn: Integer): TAIBoardCard;

procedure Register;

implementation

const
  MARGIN = 10;
  MIN_COL_W = 176;

procedure Register;
begin
  RegisterComponents('AI Project', [TAIBoardView]);
end;

function AIBoardCard(const AId, ATitle: string; AColumn: Integer): TAIBoardCard;
begin
  Result.Id := AId;
  Result.Title := ATitle;
  Result.Subtitle := '';
  Result.Footer := '';
  Result.Badge := '';
  Result.Column := AColumn;
  Result.AccentColor := clNone;
  Result.BadgeColor := clNone;
  Result.Dashed := False;
  Result.Tag := 0;
end;

constructor TAIBoardView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  Width := 700; Height := 360;
  FCardHeight := 66; FHeaderHeight := 34; FGap := 8;
  FSelected := -1;
  FDragCard := -1;
  FColorBackground := RGBToColor(244, 246, 250);
  FColorColumn := RGBToColor(232, 236, 243);
  FColorCard := clWhite;
  FColorBorder := RGBToColor(203, 213, 225);
  FColorText := RGBToColor(15, 23, 42);
  FColorMuted := RGBToColor(100, 116, 139);
  FColorSelection := RGBToColor(37, 99, 235);
  FColorDanger := RGBToColor(220, 38, 38);
  FHBar := TScrollBar.Create(Self);
  FHBar.Kind := sbHorizontal;
  FHBar.Parent := Self;
  FHBar.Align := alBottom;
  FHBar.TabStop := False;
  FHBar.Visible := False;
  FHBar.OnChange := @ScrollChanged;
end;

function TAIBoardView.ColumnWidth: Integer;
begin
  if Length(FColumns) = 0 then Exit(MIN_COL_W);
  Result := Max(MIN_COL_W, (ClientWidth - MARGIN) div Length(FColumns) - MARGIN);
end;

function TAIBoardView.ContentWidth: Integer;
begin
  Result := MARGIN + Length(FColumns) * (ColumnWidth + MARGIN);
end;

procedure TAIBoardView.UpdateScrollBar;
begin
  if FHBar = nil then Exit;
  FHBar.Visible := ContentWidth > ClientWidth;
  if FHBar.Visible then
  begin
    FHBar.Max := ContentWidth;
    FHBar.PageSize := Max(1, ClientWidth);
    FScrollX := EnsureRange(FScrollX, 0, Max(0, ContentWidth - ClientWidth));
    FHBar.Position := FScrollX;
  end
  else
    FScrollX := 0;
end;

procedure TAIBoardView.ScrollChanged(Sender: TObject);
begin
  FScrollX := FHBar.Position;
  Invalidate;
end;

procedure TAIBoardView.Resize;
begin
  inherited Resize;
  UpdateScrollBar;
end;

procedure TAIBoardView.ScrollToColumn(ACol: Integer);
var R: TRect;
begin
  if (ACol < 0) or (ACol > High(FColumns)) then Exit;
  R := ColumnRect(ACol);
  if R.Right > ClientWidth then FScrollX := FScrollX + R.Right - ClientWidth + MARGIN
  else if R.Left < 0 then FScrollX := FScrollX + R.Left - MARGIN;
  UpdateScrollBar;
  Invalidate;
end;

procedure TAIBoardView.BeginUpdate;
begin
  Inc(FUpdating);
end;

procedure TAIBoardView.EndUpdate;
begin
  if FUpdating > 0 then Dec(FUpdating);
  if FUpdating = 0 then
  begin
    if FSelected > High(FCards) then FSelected := -1;
    UpdateScrollBar;
    Invalidate;
  end;
end;

procedure TAIBoardView.Clear;
begin
  FCards := nil;
  if FUpdating = 0 then Invalidate;
end;

procedure TAIBoardView.ClearColumns;
begin
  FColumns := nil;
end;

function TAIBoardView.AddColumn(const ACaption: string; AColor: TColor): Integer;
begin
  Result := Length(FColumns);
  SetLength(FColumns, Result + 1);
  FColumns[Result].Caption := ACaption;
  FColumns[Result].Color := AColor;
end;

function TAIBoardView.AddCard(const ACard: TAIBoardCard): Integer;
begin
  Result := Length(FCards);
  SetLength(FCards, Result + 1);
  FCards[Result] := ACard;
  if FUpdating = 0 then Invalidate;
end;

function TAIBoardView.CardCount: Integer;
begin
  Result := Length(FCards);
end;

function TAIBoardView.Card(I: Integer): TAIBoardCard;
begin
  Result := FCards[I];
end;

function TAIBoardView.ColumnCount: Integer;
begin
  Result := Length(FColumns);
end;

function TAIBoardView.IndexOfId(const AId: string): Integer;
var I: Integer;
begin
  for I := 0 to High(FCards) do
    if SameText(FCards[I].Id, AId) then Exit(I);
  Result := -1;
end;

function TAIBoardView.ColumnRect(ACol: Integer): TRect;
var W: Integer;
begin
  if Length(FColumns) = 0 then Exit(Rect(0, 0, 0, 0));
  W := ColumnWidth;
  Result.Left := MARGIN + ACol * (W + MARGIN) - FScrollX;
  Result.Right := Result.Left + W;
  Result.Top := MARGIN;
  Result.Bottom := ClientHeight - MARGIN;
  if (FHBar <> nil) and FHBar.Visible then Dec(Result.Bottom, FHBar.Height);
end;

function TAIBoardView.ColumnAt(X: Integer): Integer;
var I: Integer; R: TRect;
begin
  for I := 0 to High(FColumns) do
  begin
    R := ColumnRect(I);
    if (X >= R.Left - MARGIN div 2) and (X < R.Right + MARGIN div 2) then Exit(I);
  end;
  Result := -1;
end;

function TAIBoardView.CardsInColumn(ACol: Integer): Integer;
var I: Integer;
begin
  Result := 0;
  for I := 0 to High(FCards) do
    if FCards[I].Column = ACol then Inc(Result);
end;

function TAIBoardView.CardRect(ACard: Integer): TRect;
var I, K: Integer; C: TRect;
begin
  if (ACard < 0) or (ACard > High(FCards)) then Exit(Rect(0, 0, 0, 0));
  K := 0;
  for I := 0 to ACard - 1 do
    if FCards[I].Column = FCards[ACard].Column then Inc(K);
  C := ColumnRect(FCards[ACard].Column);
  Result.Left := C.Left + 6;
  Result.Right := C.Right - 6;
  Result.Top := C.Top + FHeaderHeight + K * (FCardHeight + FGap) - FScrollY;
  Result.Bottom := Result.Top + FCardHeight;
end;

function TAIBoardView.CardAt(X, Y: Integer): Integer;
var I: Integer;
begin
  for I := 0 to High(FCards) do
    if PtInRect(CardRect(I), Point(X, Y)) then Exit(I);
  Result := -1;
end;

procedure TAIBoardView.SetSelected(AValue: Integer);
begin
  if (AValue < -1) or (AValue > High(FCards)) then AValue := -1;
  if AValue = FSelected then Exit;
  FSelected := AValue;
  Invalidate;
  if Assigned(FOnSelect) then FOnSelect(Self, FSelected);
end;

function TAIBoardView.TryMoveCard(ACard, ANewColumn: Integer; out Reason: string): Boolean;
begin
  Reason := '';
  Result := False;
  if (ACard < 0) or (ACard > High(FCards)) or (ANewColumn < 0) or (ANewColumn > High(FColumns)) then
  begin
    Reason := 'cartao ou coluna inexistente';
    Exit;
  end;
  if FCards[ACard].Column = ANewColumn then Exit(True);
  Result := True;
  if Assigned(FOnCardMove) then FOnCardMove(Self, ACard, ANewColumn, Result, Reason);
  if Result then
  begin
    FCards[ACard].Column := ANewColumn;
    FMessage := '';
  end
  else
    FMessage := Reason;
  Invalidate;
end;

{ ---------------- pintura ---------------- }

procedure TAIBoardView.Paint;
var
  C, I, TY, BW: Integer;
  R, CR: TRect;
  S: string;
begin
  Canvas.Font.Assign(Font);
  Canvas.Brush.Color := FColorBackground;
  Canvas.FillRect(ClientRect);
  for C := 0 to High(FColumns) do
  begin
    R := ColumnRect(C);
    Canvas.Brush.Color := FColorColumn;
    Canvas.Pen.Color := FColorColumn;
    Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 10, 10);
    if FColumns[C].Color <> clNone then
    begin
      Canvas.Brush.Color := FColumns[C].Color;
      Canvas.FillRect(Rect(R.Left + 8, R.Top + 12, R.Left + 16, R.Top + 20));
    end;
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := FColorText;
    Canvas.TextOut(R.Left + 22, R.Top + 9, Format('%s  (%d)', [FColumns[C].Caption, CardsInColumn(C)]));
    Canvas.Font.Style := [];
    Canvas.Brush.Style := bsSolid;
  end;
  for I := 0 to High(FCards) do
  begin
    if FDragging and (I = FDragCard) then Continue;
    R := CardRect(I);
    CR := ColumnRect(FCards[I].Column);
    if (R.Bottom < CR.Top + FHeaderHeight) or (R.Top > CR.Bottom) then Continue;
    Canvas.ClipRect := Rect(CR.Left, CR.Top + FHeaderHeight - 4, CR.Right, CR.Bottom);
    Canvas.Clipping := True;
    Canvas.Brush.Color := FColorCard;
    if I = FSelected then begin Canvas.Pen.Color := FColorSelection; Canvas.Pen.Width := 2; end
    else begin Canvas.Pen.Color := FColorBorder; Canvas.Pen.Width := 1; end;
    if FCards[I].Dashed then Canvas.Pen.Style := psDash;
    Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;
    if FCards[I].AccentColor <> clNone then
    begin
      Canvas.Brush.Color := FCards[I].AccentColor;
      Canvas.FillRect(Rect(R.Left + 2, R.Top + 4, R.Left + 6, R.Bottom - 4));
    end;
    Canvas.Brush.Style := bsClear;
    Canvas.ClipRect := Rect(R.Left + 8, Max(R.Top, CR.Top + FHeaderHeight - 4), R.Right - 4, Min(R.Bottom, CR.Bottom));
    TY := R.Top + 5;
    { etiqueta no canto de cima; o titulo para antes dela }
    BW := 0;
    if FCards[I].Badge <> '' then
    begin
      S := FCards[I].Badge;
      Canvas.Font.Style := [];
      BW := Canvas.TextWidth(S) + 10;
      if FCards[I].BadgeColor <> clNone then Canvas.Font.Color := FCards[I].BadgeColor
      else Canvas.Font.Color := FColorMuted;
      Canvas.TextOut(R.Right - 8 - Canvas.TextWidth(S), TY, S);
    end;
    Canvas.ClipRect := Rect(R.Left + 8, Max(R.Top, CR.Top + FHeaderHeight - 4), R.Right - 4 - BW, Min(R.Bottom, CR.Bottom));
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := FColorText;
    Canvas.TextOut(R.Left + 10, TY, FCards[I].Title);
    Canvas.ClipRect := Rect(R.Left + 8, Max(R.Top, CR.Top + FHeaderHeight - 4), R.Right - 4, Min(R.Bottom, CR.Bottom));
    Canvas.Font.Style := [];
    Canvas.Font.Color := FColorMuted;
    Inc(TY, Canvas.TextHeight('Ag') + 1);
    Canvas.TextOut(R.Left + 10, TY, FCards[I].Subtitle);
    Inc(TY, Canvas.TextHeight('Ag') + 1);
    Canvas.TextOut(R.Left + 10, TY, FCards[I].Footer);
    Canvas.Brush.Style := bsSolid;
    Canvas.Clipping := False;
  end;
  { cartao sendo arrastado acompanha o mouse }
  if FDragging and (FDragCard >= 0) then
  begin
    R := CardRect(FDragCard);
    OffsetRect(R, FDragPos.X - FDragStart.X, FDragPos.Y - FDragStart.Y);
    Canvas.Brush.Color := FColorCard;
    Canvas.Pen.Color := FColorSelection;
    Canvas.Pen.Style := psDash;
    Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
    Canvas.Pen.Style := psSolid;
    Canvas.Brush.Style := bsClear;
    Canvas.Font.Style := [fsBold];
    Canvas.Font.Color := FColorText;
    Canvas.TextOut(R.Left + 10, R.Top + 5, FCards[FDragCard].Title);
    Canvas.Font.Style := [];
    Canvas.Brush.Style := bsSolid;
  end;
  if FMessage <> '' then
  begin
    Canvas.Font.Color := FColorDanger;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(MARGIN + 4, ClientHeight - MARGIN - Canvas.TextHeight('A') - 4, FMessage);
    Canvas.Brush.Style := bsSolid;
  end;
end;

{ ---------------- mouse ---------------- }

procedure TAIBoardView.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var N: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if CanFocus then SetFocus;
  if Button <> mbLeft then Exit;
  N := CardAt(X, Y);
  Selected := N;
  FDragCard := N;
  FDragStart := Point(X, Y);
  FDragPos := FDragStart;
  FDragging := False;
end;

procedure TAIBoardView.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FDragCard < 0 then Exit;
  FDragPos := Point(X, Y);
  if not FDragging and ((Abs(X - FDragStart.X) > 4) or (Abs(Y - FDragStart.Y) > 4)) then FDragging := True;
  if FDragging then Invalidate;
end;

procedure TAIBoardView.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var C: Integer; Reason: string;
begin
  inherited MouseUp(Button, Shift, X, Y);
  if FDragging and (FDragCard >= 0) then
  begin
    C := ColumnAt(X);
    FDragging := False;
    if C >= 0 then TryMoveCard(FDragCard, C, Reason);
    if C >= 0 then ScrollToColumn(C);
  end;
  FDragging := False;
  FDragCard := -1;
  Invalidate;
end;

procedure TAIBoardView.DblClick;
var P: TPoint; N: Integer;
begin
  inherited DblClick;
  P := ScreenToClient(Mouse.CursorPos);
  N := CardAt(P.X, P.Y);
  FDragCard := -1;
  FDragging := False;
  if (N >= 0) and Assigned(FOnCardDblClick) then FOnCardDblClick(Self, N);
end;

function TAIBoardView.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := True;
  if ssShift in Shift then
  begin
    FScrollX := EnsureRange(FScrollX - Sign(WheelDelta) * 60, 0, Max(0, ContentWidth - ClientWidth));
    UpdateScrollBar;
  end
  else
    FScrollY := Max(0, FScrollY - Sign(WheelDelta) * 40);
  Invalidate;
end;

initialization
  {$I aiboardview_icon.lrs}

end.
