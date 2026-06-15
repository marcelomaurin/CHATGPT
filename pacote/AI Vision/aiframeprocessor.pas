unit aiframeprocessor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, LResources, Graphics, GraphType, IntfGraphics, FPimage, LCLIntf, TypInfo;

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
    FModifyInput: Boolean;

    FRGBChannelMode: TAIRGBChannelMode;
    FEnableChannelAdjustments: Boolean;

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

    FLastInputWidth: Integer;
    FLastInputHeight: Integer;
    FLastOutputWidth: Integer;
    FLastOutputHeight: Integer;
    FLastProcessingTimeMs: Int64;

    function ClampByte(AValue: Integer): Byte;
    procedure ConvertToGray(IntfImg: TLazIntfImage);
    procedure ResizeBitmap(SrcImg, DestImg: TLazIntfImage; NewWidth, NewHeight: Integer);
  protected
    function ApplyRGBChannels(ABitmap: TBitmap): TBitmap;
  public
    constructor Create(AOwner: TComponent); override;

    procedure ResetDefaults;

    function ProcessBitmap(ABitmap: TBitmap): TBitmap;
    function ProcessFrame(AFrame: TObject): TObject;

    function SaveBitmapToFile(ABitmap: TBitmap; const AFileName: string): Boolean;
    function GetDiagnosticReport: string;

  published
    property ScaleFactor: Double read FScaleFactor write FScaleFactor;
    property Grayscale: Boolean read FGrayscale write FGrayscale default False;
    property ModifyInput: Boolean read FModifyInput write FModifyInput default False;

    property RGBChannelMode: TAIRGBChannelMode read FRGBChannelMode write FRGBChannelMode default cmNone;
    property EnableChannelAdjustments: Boolean read FEnableChannelAdjustments write FEnableChannelAdjustments default False;

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

    property LastInputWidth: Integer read FLastInputWidth;
    property LastInputHeight: Integer read FLastInputHeight;
    property LastOutputWidth: Integer read FLastOutputWidth;
    property LastOutputHeight: Integer read FLastOutputHeight;
    property LastProcessingTimeMs: Int64 read FLastProcessingTimeMs;
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
  ResetDefaults;
end;

procedure TAIFrameProcessor.ResetDefaults;
begin
  FCategory := ccOther;
  FPrompt := 'Component TAIFrameProcessor preprocesses image frames natively. Supports resize, grayscale, RGB channel operations, channel gain, channel offset and RGB/BGR conversion.';

  FScaleFactor := 1.0;
  FGrayscale := False;
  FModifyInput := False;

  FRGBChannelMode := cmNone;
  FEnableChannelAdjustments := False;

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

  FLastInputWidth := 0;
  FLastInputHeight := 0;
  FLastOutputWidth := 0;
  FLastOutputHeight := 0;
  FLastProcessingTimeMs := 0;

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
      // Weighted grayscale integer equation
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

  for Y := 0 to Result.Height - 1 do
  begin
    for X := 0 to Result.Width - 1 do
    begin
      C := ColorToRGB(Result.Canvas.Pixels[X, Y]);

      R := Red(C);
      G := Green(C);
      B := Blue(C);

      // 1. Apply mode structural changes
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
        
        cmCustom, cmNone: ;
      end;

      // 2. Apply individual channel parameter modifications if custom mode OR enabled
      if FEnableChannelAdjustments or (FRGBChannelMode = cmCustom) then
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
  StartTime: QWord;
begin
  ClearError;
  FLastProcessingTimeMs := 0;

  if not Assigned(ABitmap) then
  begin
    SetError('Bitmap não informado.');
    Exit(nil);
  end;

  if (ABitmap.Width <= 0) or (ABitmap.Height <= 0) then
  begin
    SetError('Bitmap com tamanho inválido.');
    Exit(nil);
  end;

  if FScaleFactor <= 0.0 then
  begin
    SetError('ScaleFactor inválido.');
    Exit(nil);
  end;

  StartTime := GetTickCount64;
  FLastInputWidth := ABitmap.Width;
  FLastInputHeight := ABitmap.Height;

  // Clone handling
  if not FModifyInput then
  begin
    LWorkBitmap := TBitmap.Create;
    try
      LWorkBitmap.Assign(ABitmap);
    except
      on E: Exception do
      begin
        LWorkBitmap.Free;
        SetError('Erro ao clonar bitmap: ' + E.Message);
        Exit(nil);
      end;
    end;
  end
  else
    LWorkBitmap := ABitmap;

  // Resize
  if FScaleFactor <> 1.0 then
  begin
    NewW := Round(LWorkBitmap.Width * FScaleFactor);
    NewH := Round(LWorkBitmap.Height * FScaleFactor);
    if (NewW <= 0) or (NewH <= 0) then
    begin
      if not FModifyInput then LWorkBitmap.Free;
      SetError('Erro ao redimensionar imagem: dimensões resultantes inválidas.');
      Exit(nil);
    end;

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
    except
      on E: Exception do
      begin
        IntfImg.Free;
        DestIntf.Free;
        if not FModifyInput then LWorkBitmap.Free;
        SetError('Erro ao redimensionar imagem: ' + E.Message);
        Exit(nil);
      end;
    end;
    IntfImg.Free;
    DestIntf.Free;
  end;

  // RGB Channels
  try
    LWorkBitmap := ApplyRGBChannels(LWorkBitmap);
  except
    on E: Exception do
    begin
      if not FModifyInput then LWorkBitmap.Free;
      SetError('Erro ao aplicar canais RGB: ' + E.Message);
      Exit(nil);
    end;
  end;

  // Grayscale
  if FGrayscale then
  begin
    IntfImg := TLazIntfImage.Create(0, 0);
    try
      IntfImg.LoadFromBitmap(LWorkBitmap.Handle, LWorkBitmap.MaskHandle);
      ConvertToGray(IntfImg);
      LWorkBitmap.LoadFromIntfImage(IntfImg);
    except
      on E: Exception do
      begin
        IntfImg.Free;
        if not FModifyInput then LWorkBitmap.Free;
        SetError('Erro ao converter para grayscale: ' + E.Message);
        Exit(nil);
      end;
    end;
    IntfImg.Free;
  end;

  FLastOutputWidth := LWorkBitmap.Width;
  FLastOutputHeight := LWorkBitmap.Height;
  FLastProcessingTimeMs := GetTickCount64 - StartTime;
  FLastSuccess := True;

  Result := LWorkBitmap;
end;

function TAIFrameProcessor.ProcessFrame(AFrame: TObject): TObject;
begin
  ClearError;
  if Assigned(AFrame) and (AFrame is TBitmap) then
  begin
    Result := ProcessBitmap(TBitmap(AFrame));
  end
  else
  begin
    SetError('Tipo de frame não suportado.');
    Result := nil;
  end;
end;

function TAIFrameProcessor.SaveBitmapToFile(ABitmap: TBitmap; const AFileName: string): Boolean;
begin
  Result := False;
  ClearError;
  if not Assigned(ABitmap) then
  begin
    SetError('Bitmap nulo ao tentar salvar.');
    Exit;
  end;

  try
    ABitmap.SaveToFile(AFileName);
    Result := True;
  except
    on E: Exception do
      SetError('Erro ao salvar arquivo: ' + E.Message);
  end;
end;

function TAIFrameProcessor.GetDiagnosticReport: string;
begin
  Result := 'TAIFrameProcessor Diagnostic Report' + sLineBreak +
            'Input Size: ' + IntToStr(FLastInputWidth) + 'x' + IntToStr(FLastInputHeight) + sLineBreak +
            'Output Size: ' + IntToStr(FLastOutputWidth) + 'x' + IntToStr(FLastOutputHeight) + sLineBreak +
            'ScaleFactor: ' + FloatToStr(FScaleFactor) + sLineBreak +
            'Grayscale: ' + BoolToStr(FGrayscale, True) + sLineBreak +
            'RGBChannelMode: ' + GetEnumName(TypeInfo(TAIRGBChannelMode), Integer(FRGBChannelMode)) + sLineBreak +
            'EnableChannelAdjustments: ' + BoolToStr(FEnableChannelAdjustments, True) + sLineBreak +
            'RedGain: ' + FloatToStr(FRedGain) + sLineBreak +
            'GreenGain: ' + FloatToStr(FGreenGain) + sLineBreak +
            'BlueGain: ' + FloatToStr(FBlueGain) + sLineBreak +
            'RedOffset: ' + IntToStr(FRedOffset) + sLineBreak +
            'GreenOffset: ' + IntToStr(FGreenOffset) + sLineBreak +
            'BlueOffset: ' + IntToStr(FBlueOffset) + sLineBreak +
            'Processing Time: ' + IntToStr(FLastProcessingTimeMs) + ' ms' + sLineBreak +
            'LastError: ' + FLastError;
end;

initialization
  {$I aiframeprocessor_icon.lrs}

end.
