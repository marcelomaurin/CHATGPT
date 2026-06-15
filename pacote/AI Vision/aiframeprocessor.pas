unit aiframeprocessor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, LResources, Graphics, GraphType, IntfGraphics, FPimage;

type
  TAIColorChannel = (
    ccRed,
    ccGreen,
    ccBlue
  );

  TAIRGBChannelMode = (
    cmNone,
    cmExtractRed,
    cmExtractGreen,
    cmExtractBlue,
    cmKeepRedOnly,
    cmKeepGreenOnly,
    cmKeepBlueOnly,
    cmRemoveRed,
    cmRemoveGreen,
    cmRemoveBlue,
    cmSwapRB,
    cmSwapRG,
    cmSwapGB,
    cmRGBToBGR,
    cmInvertRGB,
    cmCustom
  );

  { TAIFrameProcessor }

  TAIFrameProcessor = class(TAIBaseComponent)
  private
    FScaleFactor: Double;
    FGrayscale: Boolean;

    FRGBChannelMode: TAIRGBChannelMode;

    FRedEnabled: Boolean;
    FGreenEnabled: Boolean;
    FBlueEnabled: Boolean;

    FRedGain: Double;
    FGreenGain: Double;
    FBlueGain: Double;

    FRedOffset: Integer;
    FGreenOffset: Integer;
    FBlueOffset: Integer;

    FInvertRed: Boolean;
    FInvertGreen: Boolean;
    FInvertBlue: Boolean;

    FNormalizeChannels: Boolean;

    function ClampByte(AValue: Integer): Byte;
    procedure ConvertToGray(IntfImg: TLazIntfImage);
    procedure ResizeBitmap(SrcImg, DestImg: TLazIntfImage; NewWidth, NewHeight: Integer);
  protected
    function ApplyRGBChannels(ABitmap: TBitmap): TBitmap;
  public
    constructor Create(AOwner: TComponent); override;
    function ProcessFrame(AFrame: TObject): TObject;
    function ProcessBitmap(ABitmap: TBitmap): TBitmap;
  published
    property ScaleFactor: Double read FScaleFactor write FScaleFactor;
    property Grayscale: Boolean read FGrayscale write FGrayscale default True;

    property RGBChannelMode: TAIRGBChannelMode read FRGBChannelMode write FRGBChannelMode default cmNone;

    property RedEnabled: Boolean read FRedEnabled write FRedEnabled default True;
    property GreenEnabled: Boolean read FGreenEnabled write FGreenEnabled default True;
    property BlueEnabled: Boolean read FBlueEnabled write FBlueEnabled default True;

    property RedGain: Double read FRedGain write FRedGain;
    property GreenGain: Double read FGreenGain write FGreenGain;
    property BlueGain: Double read FBlueGain write FBlueGain;

    property RedOffset: Integer read FRedOffset write FRedOffset default 0;
    property GreenOffset: Integer read FGreenOffset write FGreenOffset default 0;
    property BlueOffset: Integer read FBlueOffset write FBlueOffset default 0;

    property InvertRed: Boolean read FInvertRed write FInvertRed default False;
    property InvertGreen: Boolean read FInvertGreen write FInvertGreen default False;
    property InvertBlue: Boolean read FInvertBlue write FInvertBlue default False;

    property NormalizeChannels: Boolean read FNormalizeChannels write FNormalizeChannels default False;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Vision', [TAIFrameProcessor]);
end;

{ TAIFrameProcessor }

constructor TAIFrameProcessor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIFrameProcessor resizes, processes RGB channels, and filters image frames natively.';
  FScaleFactor := 1.0;
  FGrayscale := False;

  FRGBChannelMode := cmNone;

  FRedEnabled := True;
  FGreenEnabled := True;
  FBlueEnabled := True;

  FRedGain := 1.0;
  FGreenGain := 1.0;
  FBlueGain := 1.0;

  FRedOffset := 0;
  FGreenOffset := 0;
  FBlueOffset := 0;

  FInvertRed := False;
  FInvertGreen := False;
  FInvertBlue := False;

  FNormalizeChannels := False;

  ClearError;
end;

function TAIFrameProcessor.ClampByte(AValue: Integer): Byte;
begin
  if AValue < 0 then
    Result := 0
  else if AValue > 255 then
    Result := 255
  else
    Result := AValue;
end;

procedure TAIFrameProcessor.ConvertToGray(IntfImg: TLazIntfImage);
var
  x, y: Integer;
  C: TFPColor;
  Gray: Word;
begin
  for y := 0 to IntfImg.Height - 1 do
  begin
    for x := 0 to IntfImg.Width - 1 do
    begin
      C := IntfImg.Colors[x, y];
      Gray := (C.Red * 299 + C.Green * 587 + C.Blue * 114) div 1000;
      C.Red := Gray;
      C.Green := Gray;
      C.Blue := Gray;
      IntfImg.Colors[x, y] := C;
    end;
  end;
end;

procedure TAIFrameProcessor.ResizeBitmap(SrcImg, DestImg: TLazIntfImage; NewWidth, NewHeight: Integer);
var
  x, y: Integer;
  srcX, srcY: Integer;
begin
  for y := 0 to NewHeight - 1 do
  begin
    srcY := (y * SrcImg.Height) div NewHeight;
    for x := 0 to NewWidth - 1 do
    begin
      srcX := (x * SrcImg.Width) div NewWidth;
      DestImg.Colors[x, y] := SrcImg.Colors[srcX, srcY];
    end;
  end;
end;

function TAIFrameProcessor.ApplyRGBChannels(ABitmap: TBitmap): TBitmap;
var
  X, Y: Integer;
  C: TColor;
  R, G, B: Byte;
  T: Byte;
begin
  Result := ABitmap;

  if not Assigned(Result) then
    Exit;

  if FRGBChannelMode = cmNone then
    Exit;

  for Y := 0 to Result.Height - 1 do
  begin
    for X := 0 to Result.Width - 1 do
    begin
      C := ColorToRGB(Result.Canvas.Pixels[X, Y]);

      R := Red(C);
      G := Green(C);
      B := Blue(C);

      case FRGBChannelMode of
        cmExtractRed:
          begin
            G := R;
            B := R;
          end;

        cmExtractGreen:
          begin
            R := G;
            B := G;
          end;

        cmExtractBlue:
          begin
            R := B;
            G := B;
          end;

        cmKeepRedOnly:
          begin
            G := 0;
            B := 0;
          end;

        cmKeepGreenOnly:
          begin
            R := 0;
            B := 0;
          end;

        cmKeepBlueOnly:
          begin
            R := 0;
            G := 0;
          end;

        cmRemoveRed:
          R := 0;

        cmRemoveGreen:
          G := 0;

        cmRemoveBlue:
          B := 0;

        cmSwapRB,
        cmRGBToBGR:
          begin
            T := R;
            R := B;
            B := T;
          end;

        cmSwapRG:
          begin
            T := R;
            R := G;
            G := T;
          end;

        cmSwapGB:
          begin
            T := G;
            G := B;
            B := T;
          end;

        cmInvertRGB:
          begin
            R := 255 - R;
            G := 255 - G;
            B := 255 - B;
          end;

        cmCustom:
          begin
            if not FRedEnabled then R := 0;
            if not FGreenEnabled then G := 0;
            if not FBlueEnabled then B := 0;

            R := ClampByte(Round((R * FRedGain) + FRedOffset));
            G := ClampByte(Round((G * FGreenGain) + FGreenOffset));
            B := ClampByte(Round((B * FBlueGain) + FBlueOffset));

            if FInvertRed then R := 255 - R;
            if FInvertGreen then G := 255 - G;
            if FInvertBlue then B := 255 - B;
          end;
      end;

      Result.Canvas.Pixels[X, Y] := RGBToColor(R, G, B);
    end;
  end;
end;

function TAIFrameProcessor.ProcessBitmap(ABitmap: TBitmap): TBitmap;
var
  LWorkBitmap: TBitmap;
  IntfImg, DestIntf: TLazIntfImage;
  Desc: TRawImageDescription;
  NewW, NewH: Integer;
begin
  Result := ABitmap;
  if not Assigned(ABitmap) then
    Exit;

  LWorkBitmap := ABitmap;

  // 1. Crop (if implemented, not yet)
  // 2. Resize
  if (FScaleFactor <> 1.0) and (FScaleFactor > 0.0) then
  begin
    NewW := Round(LWorkBitmap.Width * FScaleFactor);
    NewH := Round(LWorkBitmap.Height * FScaleFactor);
    if (NewW > 0) and (NewH > 0) then
    begin
      IntfImg := TLazIntfImage.Create(0, 0);
      DestIntf := TLazIntfImage.Create(0, 0);
      try
        IntfImg.LoadFromBitmap(LWorkBitmap.Handle, LWorkBitmap.MaskHandle);
        Desc := IntfImg.DataDescription;
        Desc.Width := NewW;
        Desc.Height := NewH;
        DestIntf.DataDescription := Desc;

        ResizeBitmap(IntfImg, DestIntf, NewW, NewH);

        LWorkBitmap.Width := NewW;
        LWorkBitmap.Height := NewH;
        LWorkBitmap.LoadFromIntfImage(DestIntf);
      finally
        IntfImg.Free;
        DestIntf.Free;
      end;
    end;
  end;

  // 3. RGB Channels (MUST run before Grayscale)
  if FRGBChannelMode <> cmNone then
    LWorkBitmap := ApplyRGBChannels(LWorkBitmap);

  // 4. Grayscale
  if FGrayscale then
  begin
    IntfImg := TLazIntfImage.Create(0, 0);
    try
      IntfImg.LoadFromBitmap(LWorkBitmap.Handle, LWorkBitmap.MaskHandle);
      ConvertToGray(IntfImg);
      LWorkBitmap.LoadFromIntfImage(IntfImg);
    finally
      IntfImg.Free;
    end;
  end;

  Result := LWorkBitmap;
end;

function TAIFrameProcessor.ProcessFrame(AFrame: TObject): TObject;
begin
  Result := AFrame;
  if Assigned(AFrame) and (AFrame is TBitmap) then
  begin
    Result := ProcessBitmap(TBitmap(AFrame));
    Log(llDebug, 'Processed frame bitmap.');
  end
  else
  begin
    Log(llDebug, 'AFrame is not a TBitmap, returning unaltered.');
  end;
end;

initialization
  {$I aiframeprocessor_icon.lrs}

end.
