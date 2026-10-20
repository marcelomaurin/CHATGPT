unit ainetworkview;

{ Lazarus AI Suite - AI Project
  TAINetworkView: diagrama de rede (PERT) generico, no estilo do Microsoft
  Project.

  - O dono preenche nos (AddNode) e vinculos (AddLink); a vista calcula o
    layout: camada = maior caminho desde as tarefas sem predecessora; grupos
    (cadeias) empilhados com titulo; ordem estavel pela insercao.
  - Caixa com titulo, ate tres linhas de detalhe e faixa de destaque;
    critica com borda vermelha, sugerida tracejada.
  - Selecionar um no realca as predecessoras e as sucessoras (caminho da
    tarefa).
  - Arrastar de um no ate outro dispara OnCreateLink (Alt informado).
  - Arrastar o fundo desloca; roda rola; Ctrl+roda amplia.
  - Cores sao propriedades. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Types, Controls, Graphics, Forms, LCLType, LResources;

type
  TAINetworkNode = record
    Id: string;
    Title: string;
    Lines: array of string;
    Group: Integer;
    Critical: Boolean;
    Dashed: Boolean;
    AccentColor: TColor;      // clNone = sem faixa
    Tag: PtrInt;
  end;

  TAINetworkLink = record
    FromNode, ToNode: Integer;
    Caption: string;          // ex.: "II+2h"; vazio no TI simples
  end;

  TAINetworkNodeEvent = procedure(Sender: TObject; ANode: Integer) of object;
  TAINetworkLinkEvent = procedure(Sender: TObject; AFromNode, AToNode: Integer;
    AAlt: Boolean) of object;

  TAINetworkView = class(TCustomControl)
  private
    FNodes: array of TAINetworkNode;
    FLinks: array of TAINetworkLink;
    FGroupTitles: array of string;
    FRects: array of TRect;      // em coordenadas do mundo (sem rolagem/zoom)
    FGroupTop: array of Integer;
    FLayoutValid: Boolean;
    FUpdating: Integer;
    FSelected: Integer;
    FHighlight: array of Integer;  // 0 nada, 1 predecessora, 2 sucessora
    FOffset: TPoint;
    FZoom: Double;
    FDragFrom: Integer;
    FDragPos: TPoint;
    FPanning: Boolean;
    FPanStart, FPanOffset: TPoint;
    FBoxWidth, FBoxHeight, FGapX, FGapY: Integer;
    FColorBackground, FColorBox, FColorBorder, FColorText, FColorMuted,
    FColorCritical, FColorSelection, FColorPred, FColorSucc, FColorLink,
    FColorGroup: TColor;
    FOnSelect: TAINetworkNodeEvent;
    FOnNodeDblClick: TAINetworkNodeEvent;
    FOnCreateLink: TAINetworkLinkEvent;
    procedure Layout;
    procedure ComputeHighlight;
    function W2S(const R: TRect): TRect;
    function S2W(const P: TPoint): TPoint;
    procedure SetSelected(AValue: Integer);
    procedure DrawArrow(X1, Y1, X2, Y2: Integer);
  protected
    procedure Paint; override;
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
    function AddNode(const ANode: TAINetworkNode): Integer;
    procedure AddLink(AFromNode, AToNode: Integer; const ACaption: string = '');
    procedure SetGroupTitle(AGroup: Integer; const ATitle: string);
    function NodeCount: Integer;
    function Node(I: Integer): TAINetworkNode;
    function IndexOfId(const AId: string): Integer;
    function NodeAt(X, Y: Integer): Integer;
    function NodeRect(I: Integer): TRect;   // em coordenadas da tela
    function NodeLayer(I: Integer): Integer;
    function HighlightOf(I: Integer): Integer;
    procedure FitAll;
    procedure Zoom(AFactor: Double);
    procedure ResetView;
    property Selected: Integer read FSelected write SetSelected;
  published
    property Align;
    property Anchors;
    property Font;
    property ParentFont;
    property BoxWidth: Integer read FBoxWidth write FBoxWidth default 180;
    property BoxHeight: Integer read FBoxHeight write FBoxHeight default 72;
    property ColorBackground: TColor read FColorBackground write FColorBackground;
    property ColorBox: TColor read FColorBox write FColorBox;
    property ColorBorder: TColor read FColorBorder write FColorBorder;
    property ColorText: TColor read FColorText write FColorText;
    property ColorMuted: TColor read FColorMuted write FColorMuted;
    property ColorCritical: TColor read FColorCritical write FColorCritical;
    property ColorSelection: TColor read FColorSelection write FColorSelection;
    property ColorPredecessor: TColor read FColorPred write FColorPred;
    property ColorSuccessor: TColor read FColorSucc write FColorSucc;
    property ColorLink: TColor read FColorLink write FColorLink;
    property ColorGroup: TColor read FColorGroup write FColorGroup;
    property OnSelect: TAINetworkNodeEvent read FOnSelect write FOnSelect;
    property OnNodeDblClick: TAINetworkNodeEvent read FOnNodeDblClick write FOnNodeDblClick;
    property OnCreateLink: TAINetworkLinkEvent read FOnCreateLink write FOnCreateLink;
  end;

function AINetworkNode(const AId, ATitle: string; AGroup: Integer = 0): TAINetworkNode;

procedure Register;

implementation

const
  GROUP_TITLE_H = 26;
  MARGIN = 16;

procedure Register;
begin
  RegisterComponents('AI Project', [TAINetworkView]);
end;

function AINetworkNode(const AId, ATitle: string; AGroup: Integer): TAINetworkNode;
begin
  Result.Id := AId;
  Result.Title := ATitle;
  Result.Lines := nil;
  Result.Group := AGroup;
  Result.Critical := False;
  Result.Dashed := False;
  Result.AccentColor := clNone;
  Result.Tag := 0;
end;

constructor TAINetworkView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  Width := 600; Height := 360;
  FBoxWidth := 180; FBoxHeight := 72; FGapX := 48; FGapY := 18;
  FZoom := 1;
  FSelected := -1;
  FDragFrom := -1;
  FColorBackground := RGBToColor(244, 246, 250);
  FColorBox := clWhite;
  FColorBorder := RGBToColor(203, 213, 225);
  FColorText := RGBToColor(15, 23, 42);
  FColorMuted := RGBToColor(100, 116, 139);
  FColorCritical := RGBToColor(220, 38, 38);
  FColorSelection := RGBToColor(37, 99, 235);
  FColorPred := RGBToColor(14, 165, 233);
  FColorSucc := RGBToColor(22, 163, 74);
  FColorLink := RGBToColor(100, 116, 139);
  FColorGroup := RGBToColor(71, 85, 105);
end;

procedure TAINetworkView.BeginUpdate;
begin
  Inc(FUpdating);
end;

procedure TAINetworkView.EndUpdate;
begin
  if FUpdating > 0 then Dec(FUpdating);
  if FUpdating = 0 then
  begin
    FLayoutValid := False;
    if (FSelected > High(FNodes)) then FSelected := -1;
    ComputeHighlight;
    Invalidate;
  end;
end;

procedure TAINetworkView.Clear;
begin
  FNodes := nil;
  FLinks := nil;
  FGroupTitles := nil;
  FHighlight := nil;
  FLayoutValid := False;
  if FUpdating = 0 then Invalidate;
end;

function TAINetworkView.AddNode(const ANode: TAINetworkNode): Integer;
begin
  Result := Length(FNodes);
  SetLength(FNodes, Result + 1);
  FNodes[Result] := ANode;
  FNodes[Result].Lines := Copy(ANode.Lines);
  if FNodes[Result].Group < 0 then FNodes[Result].Group := 0;
  FLayoutValid := False;
  if FUpdating = 0 then Invalidate;
end;

procedure TAINetworkView.AddLink(AFromNode, AToNode: Integer; const ACaption: string);
var N: Integer;
begin
  N := Length(FLinks);
  SetLength(FLinks, N + 1);
  FLinks[N].FromNode := AFromNode;
  FLinks[N].ToNode := AToNode;
  FLinks[N].Caption := ACaption;
  FLayoutValid := False;
  if FUpdating = 0 then Invalidate;
end;

procedure TAINetworkView.SetGroupTitle(AGroup: Integer; const ATitle: string);
begin
  if AGroup < 0 then Exit;
  if AGroup > High(FGroupTitles) then SetLength(FGroupTitles, AGroup + 1);
  FGroupTitles[AGroup] := ATitle;
  if FUpdating = 0 then Invalidate;
end;

function TAINetworkView.NodeCount: Integer;
begin
  Result := Length(FNodes);
end;

function TAINetworkView.Node(I: Integer): TAINetworkNode;
begin
  Result := FNodes[I];
end;

function TAINetworkView.IndexOfId(const AId: string): Integer;
var I: Integer;
begin
  for I := 0 to High(FNodes) do
    if SameText(FNodes[I].Id, AId) then Exit(I);
  Result := -1;
end;

{ ---------------- layout ---------------- }

var
  GLayer: array of Integer;

procedure TAINetworkView.Layout;
var
  N, I, K, G, MaxG, Moved, Pass, Y, L: Integer;
  Count: array of array of Integer;   // [grupo][camada] -> quantos ja colocados
  Rows: array of Integer;             // altura (em caixas) de cada grupo
begin
  N := Length(FNodes);
  SetLength(GLayer, N);
  for I := 0 to N - 1 do GLayer[I] := 0;
  { maior caminho: relaxa ate estabilizar (o grafo e aciclico; N passadas no maximo) }
  for Pass := 0 to N do
  begin
    Moved := 0;
    for K := 0 to High(FLinks) do
      with FLinks[K] do
        if (FromNode >= 0) and (FromNode < N) and (ToNode >= 0) and (ToNode < N) and
           (GLayer[ToNode] < GLayer[FromNode] + 1) then
        begin
          GLayer[ToNode] := GLayer[FromNode] + 1;
          Inc(Moved);
        end;
    if Moved = 0 then Break;
  end;
  MaxG := 0;
  for I := 0 to N - 1 do MaxG := Max(MaxG, FNodes[I].Group);
  SetLength(Count, MaxG + 1);
  for G := 0 to MaxG do Count[G] := nil;
  SetLength(FRects, N);
  { primeira passada: posicao dentro do grupo }
  for I := 0 to N - 1 do
  begin
    G := FNodes[I].Group;
    L := GLayer[I];
    if L > High(Count[G]) then SetLength(Count[G], L + 1);
    FRects[I] := Rect(L, Count[G][L], 0, 0);   // provisorio: (camada, linha)
    Inc(Count[G][L]);
  end;
  SetLength(Rows, MaxG + 1);
  for G := 0 to MaxG do
  begin
    Rows[G] := 0;
    for L := 0 to High(Count[G]) do Rows[G] := Max(Rows[G], Count[G][L]);
  end;
  { grupos empilhados; grupos vazios nao ocupam espaco }
  SetLength(FGroupTop, MaxG + 1);
  Y := MARGIN;
  for G := 0 to MaxG do
  begin
    FGroupTop[G] := Y;
    if Rows[G] > 0 then
      Inc(Y, GROUP_TITLE_H + Rows[G] * (FBoxHeight + FGapY) + FGapY);
  end;
  for I := 0 to N - 1 do
  begin
    G := FNodes[I].Group;
    L := FRects[I].Left;
    K := FRects[I].Top;
    FRects[I].Left := MARGIN + L * (FBoxWidth + FGapX);
    FRects[I].Top := FGroupTop[G] + GROUP_TITLE_H + K * (FBoxHeight + FGapY);
    FRects[I].Right := FRects[I].Left + FBoxWidth;
    FRects[I].Bottom := FRects[I].Top + FBoxHeight;
  end;
  FLayoutValid := True;
end;

function TAINetworkView.NodeLayer(I: Integer): Integer;
begin
  if not FLayoutValid then Layout;
  Result := GLayer[I];
end;

function TAINetworkView.W2S(const R: TRect): TRect;
begin
  Result.Left := Round(R.Left * FZoom) - FOffset.X;
  Result.Top := Round(R.Top * FZoom) - FOffset.Y;
  Result.Right := Round(R.Right * FZoom) - FOffset.X;
  Result.Bottom := Round(R.Bottom * FZoom) - FOffset.Y;
end;

function TAINetworkView.S2W(const P: TPoint): TPoint;
begin
  Result.X := Round((P.X + FOffset.X) / FZoom);
  Result.Y := Round((P.Y + FOffset.Y) / FZoom);
end;

function TAINetworkView.NodeRect(I: Integer): TRect;
begin
  if not FLayoutValid then Layout;
  Result := W2S(FRects[I]);
end;

function TAINetworkView.NodeAt(X, Y: Integer): Integer;
var I: Integer;
begin
  if not FLayoutValid then Layout;
  for I := 0 to High(FNodes) do
    if PtInRect(W2S(FRects[I]), Point(X, Y)) then Exit(I);
  Result := -1;
end;

procedure TAINetworkView.ComputeHighlight;
var
  I, K: Integer;
  Grew: Boolean;
begin
  SetLength(FHighlight, Length(FNodes));
  for I := 0 to High(FHighlight) do FHighlight[I] := 0;
  if (FSelected < 0) or (FSelected > High(FNodes)) then Exit;
  { predecessoras transitivas (1) e sucessoras transitivas (2) }
  repeat
    Grew := False;
    for K := 0 to High(FLinks) do
      with FLinks[K] do
      begin
        if (ToNode = FSelected) or ((ToNode >= 0) and (ToNode <= High(FHighlight)) and (FHighlight[ToNode] = 1)) then
          if (FromNode >= 0) and (FromNode <= High(FHighlight)) and (FHighlight[FromNode] = 0) and (FromNode <> FSelected) then
          begin FHighlight[FromNode] := 1; Grew := True; end;
        if (FromNode = FSelected) or ((FromNode >= 0) and (FromNode <= High(FHighlight)) and (FHighlight[FromNode] = 2)) then
          if (ToNode >= 0) and (ToNode <= High(FHighlight)) and (FHighlight[ToNode] = 0) and (ToNode <> FSelected) then
          begin FHighlight[ToNode] := 2; Grew := True; end;
      end;
  until not Grew;
end;

function TAINetworkView.HighlightOf(I: Integer): Integer;
begin
  if (I < 0) or (I > High(FHighlight)) then Result := 0 else Result := FHighlight[I];
end;

procedure TAINetworkView.SetSelected(AValue: Integer);
begin
  if (AValue < -1) or (AValue > High(FNodes)) then AValue := -1;
  if AValue = FSelected then Exit;
  FSelected := AValue;
  ComputeHighlight;
  Invalidate;
  if Assigned(FOnSelect) then FOnSelect(Self, FSelected);
end;

procedure TAINetworkView.FitAll;
var I: Integer; MaxX, MaxY: Integer;
begin
  if not FLayoutValid then Layout;
  MaxX := 1; MaxY := 1;
  for I := 0 to High(FRects) do
  begin
    MaxX := Max(MaxX, FRects[I].Right + MARGIN);
    MaxY := Max(MaxY, FRects[I].Bottom + MARGIN);
  end;
  FZoom := EnsureRange(Min(ClientWidth / MaxX, ClientHeight / MaxY), 0.3, 1.0);
  FOffset := Point(0, 0);
  Invalidate;
end;

procedure TAINetworkView.Zoom(AFactor: Double);
begin
  FZoom := EnsureRange(FZoom * AFactor, 0.25, 2.5);
  Invalidate;
end;

procedure TAINetworkView.ResetView;
begin
  FZoom := 1;
  FOffset := Point(0, 0);
  Invalidate;
end;

{ ---------------- pintura ---------------- }

procedure TAINetworkView.DrawArrow(X1, Y1, X2, Y2: Integer);
var XM: Integer; P: array[0..2] of TPoint;
begin
  XM := (X1 + X2) div 2;
  if X2 > X1 then
  begin
    Canvas.Line(X1, Y1, XM, Y1);
    Canvas.Line(XM, Y1, XM, Y2);
    Canvas.Line(XM, Y2, X2, Y2);
  end
  else
  begin
    { volta para tras (mesma camada ou anterior): passa por baixo }
    Canvas.Line(X1, Y1, X1 + 10, Y1);
    Canvas.Line(X1 + 10, Y1, X1 + 10, Max(Y1, Y2) + Round(FBoxHeight * FZoom * 0.6));
    Canvas.Line(X1 + 10, Max(Y1, Y2) + Round(FBoxHeight * FZoom * 0.6), X2 - 10, Max(Y1, Y2) + Round(FBoxHeight * FZoom * 0.6));
    Canvas.Line(X2 - 10, Max(Y1, Y2) + Round(FBoxHeight * FZoom * 0.6), X2 - 10, Y2);
    Canvas.Line(X2 - 10, Y2, X2, Y2);
  end;
  P[0] := Point(X2, Y2); P[1] := Point(X2 - 6, Y2 - 4); P[2] := Point(X2 - 6, Y2 + 4);
  Canvas.Polygon(P);
end;

procedure TAINetworkView.Paint;
var
  I, G, K, TY, LH: Integer;
  R, A, B: TRect;
  Col: TColor;
  S: string;
begin
  if not FLayoutValid then Layout;
  Canvas.Font.Assign(Font);
  Canvas.Font.Height := Round(Font.GetTextHeight('Ag') * FZoom);
  if Canvas.Font.Height = 0 then Canvas.Font.Size := Max(6, Round(9 * FZoom));
  Canvas.Brush.Color := FColorBackground;
  Canvas.FillRect(ClientRect);
  { titulos dos grupos }
  Canvas.Font.Color := FColorGroup;
  Canvas.Font.Style := [fsBold];
  Canvas.Brush.Style := bsClear;
  for G := 0 to High(FGroupTop) do
    if (G <= High(FGroupTitles)) and (FGroupTitles[G] <> '') then
    begin
      R := W2S(Rect(MARGIN, FGroupTop[G], MARGIN + 400, FGroupTop[G] + GROUP_TITLE_H));
      Canvas.TextOut(R.Left, R.Top + 4, FGroupTitles[G]);
    end;
  Canvas.Font.Style := [];
  { vinculos }
  for K := 0 to High(FLinks) do
    with FLinks[K] do
    begin
      if (FromNode < 0) or (ToNode < 0) or (FromNode > High(FNodes)) or (ToNode > High(FNodes)) then Continue;
      A := W2S(FRects[FromNode]);
      B := W2S(FRects[ToNode]);
      if FNodes[FromNode].Critical and FNodes[ToNode].Critical then Col := FColorCritical
      else Col := FColorLink;
      Canvas.Pen.Color := Col;
      Canvas.Brush.Color := Col;
      Canvas.Brush.Style := bsSolid;
      DrawArrow(A.Right, (A.Top + A.Bottom) div 2, B.Left, (B.Top + B.Bottom) div 2);
      if Caption <> '' then
      begin
        Canvas.Brush.Style := bsClear;
        Canvas.Font.Color := FColorMuted;
        Canvas.TextOut((A.Right + B.Left) div 2 + 3, (B.Top + B.Bottom) div 2 - Canvas.TextHeight('A') - 1, Caption);
      end;
    end;
  { caixas }
  LH := Canvas.TextHeight('Ag');
  for I := 0 to High(FNodes) do
  begin
    R := W2S(FRects[I]);
    if (R.Right < 0) or (R.Left > ClientWidth) or (R.Bottom < 0) or (R.Top > ClientHeight) then Continue;
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := FColorBox;
    if I = FSelected then Col := FColorSelection
    else if HighlightOf(I) = 1 then Col := FColorPred
    else if HighlightOf(I) = 2 then Col := FColorSucc
    else if FNodes[I].Critical then Col := FColorCritical
    else Col := FColorBorder;
    Canvas.Pen.Color := Col;
    if (I = FSelected) or (HighlightOf(I) > 0) or FNodes[I].Critical then Canvas.Pen.Width := 2
    else Canvas.Pen.Width := 1;
    if FNodes[I].Dashed then Canvas.Pen.Style := psDash;
    Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, 8, 8);
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;
    if FNodes[I].AccentColor <> clNone then
    begin
      Canvas.Brush.Color := FNodes[I].AccentColor;
      Canvas.FillRect(Rect(R.Left + 2, R.Top + 3, R.Left + 6, R.Bottom - 3));
    end;
    Canvas.Brush.Style := bsClear;
    Canvas.ClipRect := Rect(R.Left + 8, R.Top + 2, R.Right - 4, R.Bottom - 2);
    Canvas.Clipping := True;
    Canvas.Font.Color := FColorText;
    Canvas.Font.Style := [fsBold];
    TY := R.Top + 4;
    Canvas.TextOut(R.Left + 10, TY, FNodes[I].Title);
    Canvas.Font.Style := [];
    Canvas.Font.Color := FColorMuted;
    for K := 0 to Min(2, High(FNodes[I].Lines)) do
    begin
      Inc(TY, LH);
      S := FNodes[I].Lines[K];
      Canvas.TextOut(R.Left + 10, TY, S);
    end;
    Canvas.Clipping := False;
  end;
  { vinculo sendo arrastado }
  if FDragFrom >= 0 then
  begin
    A := W2S(FRects[FDragFrom]);
    Canvas.Pen.Color := FColorSelection;
    Canvas.Pen.Style := psDash;
    Canvas.Line(A.Right, (A.Top + A.Bottom) div 2, FDragPos.X, FDragPos.Y);
    Canvas.Pen.Style := psSolid;
  end;
  Canvas.Brush.Style := bsSolid;
end;

{ ---------------- mouse ---------------- }

procedure TAINetworkView.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var N: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if CanFocus then SetFocus;
  N := NodeAt(X, Y);
  if (Button = mbLeft) and (N >= 0) then
  begin
    Selected := N;
    FDragFrom := N;
    FDragPos := Point(X, Y);
  end
  else if (Button in [mbLeft, mbMiddle, mbRight]) and (N < 0) then
  begin
    if Button = mbLeft then Selected := -1;
    FPanning := True;
    FPanStart := Point(X, Y);
    FPanOffset := FOffset;
  end;
end;

procedure TAINetworkView.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseMove(Shift, X, Y);
  if FPanning then
  begin
    FOffset := Point(FPanOffset.X - (X - FPanStart.X), FPanOffset.Y - (Y - FPanStart.Y));
    Invalidate;
  end
  else if FDragFrom >= 0 then
  begin
    FDragPos := Point(X, Y);
    Invalidate;
  end;
end;

procedure TAINetworkView.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var N, F: Integer;
begin
  inherited MouseUp(Button, Shift, X, Y);
  FPanning := False;
  F := FDragFrom;
  FDragFrom := -1;
  if F >= 0 then
  begin
    N := NodeAt(X, Y);
    if (N >= 0) and (N <> F) and Assigned(FOnCreateLink) then
      FOnCreateLink(Self, F, N, ssAlt in Shift);
    Invalidate;
  end;
end;

procedure TAINetworkView.DblClick;
var P: TPoint; N: Integer;
begin
  inherited DblClick;
  P := ScreenToClient(Mouse.CursorPos);
  N := NodeAt(P.X, P.Y);
  FDragFrom := -1;
  if (N >= 0) and Assigned(FOnNodeDblClick) then FOnNodeDblClick(Self, N);
end;

function TAINetworkView.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
var W: TPoint;
begin
  Result := True;
  if ssCtrl in Shift then
  begin
    W := S2W(MousePos);
    if WheelDelta > 0 then FZoom := EnsureRange(FZoom * 1.15, 0.25, 2.5)
    else FZoom := EnsureRange(FZoom / 1.15, 0.25, 2.5);
    { mantem o ponto sob o mouse }
    FOffset := Point(Round(W.X * FZoom) - MousePos.X, Round(W.Y * FZoom) - MousePos.Y);
  end
  else if ssShift in Shift then FOffset.X := FOffset.X - Sign(WheelDelta) * 60
  else FOffset.Y := FOffset.Y - Sign(WheelDelta) * 60;
  Invalidate;
end;

initialization
  {$I ainetworkview_icon.lrs}

end.
