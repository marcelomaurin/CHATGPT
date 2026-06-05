unit aifacetracker;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, Graphics, GraphType, IntfGraphics, FPimage, Math, LResources;

type
  { TAIFaceTracker }

  TAIFaceTracker = class(TAIBaseComponent)
  private
    FSearchRadius: Integer;
    FMatchThreshold: Double;
    FLastX: Integer;
    FLastY: Integer;
    FLastWidth: Integer;
    FLastHeight: Integer;
    FTemplate: TLazIntfImage;
    FTemplateWidth: Integer;
    FTemplateHeight: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function SetTemplateFromBitmap(ABitmap: TBitmap; X, Y, W, H: Integer): Boolean;
    function TrackInBitmap(ABitmap: TBitmap; var X, Y: Integer): Boolean;
    procedure ClearTemplate;

    function TrackFace(AFrame: TObject; var AX, AY, AW, AH: Integer): Boolean;
  published
    property SearchRadius: Integer read FSearchRadius write FSearchRadius default 30;
    property MatchThreshold: Double read FMatchThreshold write FMatchThreshold;
    property LastX: Integer read FLastX;
    property LastY: Integer read FLastY;
    property LastWidth: Integer read FLastWidth;
    property LastHeight: Integer read FLastHeight;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Native Vision', [TAIFaceTracker]);
end;

{ TAIFaceTracker }

constructor TAIFaceTracker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIFaceTracker performs template-matching tracking natively without external Python processes.';
  FSearchRadius := 30;
  FMatchThreshold := 50.0;
  FLastX := 0;
  FLastY := 0;
  FLastWidth := 0;
  FLastHeight := 0;
  FTemplate := nil;
  FTemplateWidth := 0;
  FTemplateHeight := 0;
  ClearError;
end;

destructor TAIFaceTracker.Destroy;
begin
  ClearTemplate;
  inherited Destroy;
end;

procedure TAIFaceTracker.ClearTemplate;
begin
  if Assigned(FTemplate) then
  begin
    FreeAndNil(FTemplate);
  end;
  FTemplateWidth := 0;
  FTemplateHeight := 0;
end;

function TAIFaceTracker.SetTemplateFromBitmap(ABitmap: TBitmap; X, Y, W, H: Integer): Boolean;
var
  LTemp: TLazIntfImage;
  Desc: TRawImageDescription;
  tx, ty: Integer;
begin
  Result := False;
  ClearError;

  if not Assigned(ABitmap) then
  begin
    SetError('Bitmap is nil.');
    Exit;
  end;

  if (W <= 0) or (H <= 0) then
  begin
    SetError('Template dimensions must be greater than zero.');
    Exit;
  end;

  if (X < 0) or (Y < 0) or (X + W > ABitmap.Width) or (Y + H > ABitmap.Height) then
  begin
    SetError(Format('Template bounds out of bitmap range: X=%d, Y=%d, W=%d, H=%d, Bitmap=%dx%d',
      [X, Y, W, H, ABitmap.Width, ABitmap.Height]));
    Exit;
  end;

  ClearTemplate;

  LTemp := TLazIntfImage.Create(0, 0);
  try
    try
      LTemp.LoadFromBitmap(ABitmap.Handle, ABitmap.MaskHandle);
      Desc := LTemp.DataDescription;
      Desc.Width := W;
      Desc.Height := H;

      FTemplate := TLazIntfImage.Create(0, 0);
      FTemplate.DataDescription := Desc;

      for ty := 0 to H - 1 do
      begin
        for tx := 0 to W - 1 do
        begin
          FTemplate.Colors[tx, ty] := LTemp.Colors[X + tx, Y + ty];
        end;
      end;

      FTemplateWidth := W;
      FTemplateHeight := H;
      FLastX := X;
      FLastY := Y;
      FLastWidth := W;
      FLastHeight := H;
      FLastSuccess := True;
      Result := True;
      FLastResult := Format('Template set successfully at (%d,%d) with size %dx%d.', [X, Y, W, H]);
    except
      on E: Exception do
      begin
        ClearTemplate;
        SetError('Failed to capture template: ' + E.Message);
      end;
    end;
  finally
    LTemp.Free;
  end;
end;

function TAIFaceTracker.TrackInBitmap(ABitmap: TBitmap; var X, Y: Integer): Boolean;
var
  LImg: TLazIntfImage;
  MinX, MaxX, MinY, MaxY: Integer;
  sx, sy, tx, ty: Integer;
  LImgVal, LTmpVal: Word;
  SAD, BestSAD: Int64;
  BestX, BestY: Integer;
  BestScore: Double;
  CImg, CTmp: TFPColor;
begin
  Result := False;
  ClearError;

  if not Assigned(ABitmap) then
  begin
    SetError('Bitmap parameter is nil.');
    Exit;
  end;

  if not Assigned(FTemplate) or (FTemplateWidth = 0) or (FTemplateHeight = 0) then
  begin
    SetError('No template has been set for tracking.');
    Exit;
  end;

  LImg := TLazIntfImage.Create(0, 0);
  try
    try
      LImg.LoadFromBitmap(ABitmap.Handle, ABitmap.MaskHandle);

      // Define local search window around LastX/LastY using SearchRadius
      MinX := Max(0, FLastX - FSearchRadius);
      MaxX := Min(LImg.Width - FTemplateWidth, FLastX + FSearchRadius);
      MinY := Max(0, FLastY - FSearchRadius);
      MaxY := Min(LImg.Height - FTemplateHeight, FLastY + FSearchRadius);

      // If search window is collapsed or invalid, search the whole image
      if (MinX >= MaxX) or (MinY >= MaxY) then
      begin
        MinX := 0;
        MaxX := LImg.Width - FTemplateWidth;
        MinY := 0;
        MaxY := LImg.Height - FTemplateHeight;
      end;

      BestSAD := -1;
      BestX := FLastX;
      BestY := FLastY;

      for sy := MinY to MaxY do
      begin
        for sx := MinX to MaxX do
        begin
          SAD := 0;
          for ty := 0 to FTemplateHeight - 1 do
          begin
            for tx := 0 to FTemplateWidth - 1 do
            begin
              CImg := LImg.Colors[sx + tx, sy + ty];
              CTmp := FTemplate.Colors[tx, ty];

              LImgVal := (CImg.Red * 299 + CImg.Green * 587 + CImg.Blue * 114) div 1000;
              LTmpVal := (CTmp.Red * 299 + CTmp.Green * 587 + CTmp.Blue * 114) div 1000;

              SAD := SAD + Abs(Integer(LImgVal) - Integer(LTmpVal));
            end;
          end;

          if (BestSAD = -1) or (SAD < BestSAD) then
          begin
            BestSAD := SAD;
            BestX := sx;
            BestY := sy;
          end;
        end;
      end;

      if BestSAD <> -1 then
      begin
        // Compute average pixel difference, scaled to 0..255 range
        BestScore := (BestSAD / (FTemplateWidth * FTemplateHeight)) / 257.0;

        if BestScore <= FMatchThreshold then
        begin
          FLastX := BestX;
          FLastY := BestY;
          X := BestX;
          Y := BestY;
          FLastSuccess := True;
          Result := True;
          FLastResult := Format('Tracked template at (%d, %d) with score %f (threshold: %f)',
            [BestX, BestY, BestScore, FMatchThreshold]);
        end;
      end;

      if not Result then
      begin
        SetError(Format('Lost track. Best score was %f, threshold is %f', [BestScore, FMatchThreshold]));
      end;
    except
      on E: Exception do
      begin
        SetError('Failed tracking in bitmap: ' + E.Message);
      end;
    end;
  finally
    LImg.Free;
  end;
end;

function TAIFaceTracker.TrackFace(AFrame: TObject; var AX, AY, AW, AH: Integer): Boolean;
var
  LBmp: TBitmap;
  TX, TY: Integer;
begin
  Result := False;
  AX := 0; AY := 0; AW := 0; AH := 0;
  if not Assigned(AFrame) then Exit;
  if not (AFrame is TBitmap) then Exit;

  LBmp := TBitmap(AFrame);
  if not Assigned(FTemplate) then
  begin
    // Auto-initialize a mock template at the center of the image to start tracking if not set
    TX := LBmp.Width div 3;
    TY := LBmp.Height div 3;
    if not SetTemplateFromBitmap(LBmp, TX, TY, LBmp.Width div 3, LBmp.Height div 3) then
      Exit;
  end;

  TX := FLastX;
  TY := FLastY;
  if TrackInBitmap(LBmp, TX, TY) then
  begin
    AX := TX;
    AY := TY;
    AW := FLastWidth;
    AH := FLastHeight;
    Result := True;
  end;
end;

initialization
  {$I aifacetracker_icon.lrs}

end.

