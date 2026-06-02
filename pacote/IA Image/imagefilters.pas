unit imagefilters;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Graphics, GraphType, IntfGraphics, FPimage, Math, LResources;

type
  { TBaseImageFilter }
  TBaseImageFilter = class(TComponent)
  private
    FInputImage: TImage;
    FOutputImage: TImage;
    procedure SetInputImage(AValue: TImage);
    procedure SetOutputImage(AValue: TImage);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure ProcessImage(IntfImg: TLazIntfImage); virtual; abstract;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Apply; virtual;
  published
    property InputImage: TImage read FInputImage write SetInputImage;
    property OutputImage: TImage read FOutputImage write SetOutputImage;
  end;

  { TGrayscaleFilter }
  TGrayscaleFilter = class(TBaseImageFilter)
  protected
    procedure ProcessImage(IntfImg: TLazIntfImage); override;
  end;

  { TNegativeFilter }
  TNegativeFilter = class(TBaseImageFilter)
  protected
    procedure ProcessImage(IntfImg: TLazIntfImage); override;
  end;

  { TBrightnessContrastFilter }
  TBrightnessContrastFilter = class(TBaseImageFilter)
  private
    FBrightness: Integer;
    FContrast: Double;
  protected
    procedure ProcessImage(IntfImg: TLazIntfImage); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Brightness: Integer read FBrightness write FBrightness default 0;
    property Contrast: Double read FContrast write FContrast;
  end;

  { TBinarizationFilter }
  TBinarizationFilter = class(TBaseImageFilter)
  private
    FThreshold: Byte;
  protected
    procedure ProcessImage(IntfImg: TLazIntfImage); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Threshold: Byte read FThreshold write FThreshold default 128;
  end;

  { TBlurFilter }
  TBlurFilter = class(TBaseImageFilter)
  protected
    procedure ProcessImage(IntfImg: TLazIntfImage); override;
  end;

  { TSharpenFilter }
  TSharpenFilter = class(TBaseImageFilter)
  protected
    procedure ProcessImage(IntfImg: TLazIntfImage); override;
  end;

  { TSobelFilter }
  TSobelFilter = class(TBaseImageFilter)
  protected
    procedure ProcessImage(IntfImg: TLazIntfImage); override;
  end;

  TMorphOp = (moErosion, moDilation);

  { TErosionDilationFilter }
  TErosionDilationFilter = class(TBaseImageFilter)
  private
    FOperation: TMorphOp;
    FRadius: Integer;
  protected
    procedure ProcessImage(IntfImg: TLazIntfImage); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Operation: TMorphOp read FOperation write FOperation default moErosion;
    property Radius: Integer read FRadius write FRadius default 1;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Image', [
    TGrayscaleFilter,
    TNegativeFilter,
    TBrightnessContrastFilter,
    TBinarizationFilter,
    TBlurFilter,
    TSharpenFilter,
    TSobelFilter,
    TErosionDilationFilter
  ]);
end;

{ TBaseImageFilter }

constructor TBaseImageFilter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FInputImage := nil;
  FOutputImage := nil;
end;

procedure TBaseImageFilter.SetInputImage(AValue: TImage);
begin
  if FInputImage = AValue then Exit;
  FInputImage := AValue;
  if FInputImage <> nil then
    FInputImage.FreeNotification(Self);
end;

procedure TBaseImageFilter.SetOutputImage(AValue: TImage);
begin
  if FOutputImage = AValue then Exit;
  FOutputImage := AValue;
  if FOutputImage <> nil then
    FOutputImage.FreeNotification(Self);
end;

procedure TBaseImageFilter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FInputImage then
      FInputImage := nil;
    if AComponent = FOutputImage then
      FOutputImage := nil;
  end;
end;

procedure TBaseImageFilter.Apply;
var
  IntfImg: TLazIntfImage;
  TempBmp: TBitmap;
  OutBmp: TBitmap;
begin
  if (FInputImage = nil) or (FInputImage.Picture = nil) or (FOutputImage = nil) then Exit;
  if FInputImage.Picture.Graphic = nil then Exit;

  TempBmp := TBitmap.Create;
  IntfImg := TLazIntfImage.Create(0, 0);
  OutBmp := TBitmap.Create;
  try
    TempBmp.Assign(FInputImage.Picture.Graphic);
    IntfImg.LoadFromBitmap(TempBmp.Handle, TempBmp.MaskHandle);
    
    ProcessImage(IntfImg);
    
    OutBmp.Width := IntfImg.Width;
    OutBmp.Height := IntfImg.Height;
    OutBmp.LoadFromIntfImage(IntfImg);
    FOutputImage.Picture.Assign(OutBmp);
  finally
    TempBmp.Free;
    IntfImg.Free;
    OutBmp.Free;
  end;
end;

{ TGrayscaleFilter }

procedure TGrayscaleFilter.ProcessImage(IntfImg: TLazIntfImage);
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

{ TNegativeFilter }

procedure TNegativeFilter.ProcessImage(IntfImg: TLazIntfImage);
var
  x, y: Integer;
  C: TFPColor;
begin
  for y := 0 to IntfImg.Height - 1 do
  begin
    for x := 0 to IntfImg.Width - 1 do
    begin
      C := IntfImg.Colors[x, y];
      C.Red := 65535 - C.Red;
      C.Green := 65535 - C.Green;
      C.Blue := 65535 - C.Blue;
      IntfImg.Colors[x, y] := C;
    end;
  end;
end;

{ TBrightnessContrastFilter }

constructor TBrightnessContrastFilter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBrightness := 0;
  FContrast := 1.0;
end;

procedure TBrightnessContrastFilter.ProcessImage(IntfImg: TLazIntfImage);
var
  x, y: Integer;
  C: TFPColor;
  ValR, ValG, ValB: Double;
  BOffset: Double;
begin
  BOffset := FBrightness * 257.0;
  for y := 0 to IntfImg.Height - 1 do
  begin
    for x := 0 to IntfImg.Width - 1 do
    begin
      C := IntfImg.Colors[x, y];
      
      ValR := FContrast * (C.Red - 32768.0) + 32768.0 + BOffset;
      ValG := FContrast * (C.Green - 32768.0) + 32768.0 + BOffset;
      ValB := FContrast * (C.Blue - 32768.0) + 32768.0 + BOffset;
      
      C.Red := EnsureRange(Round(ValR), 0, 65535);
      C.Green := EnsureRange(Round(ValG), 0, 65535);
      C.Blue := EnsureRange(Round(ValB), 0, 65535);
      
      IntfImg.Colors[x, y] := C;
    end;
  end;
end;

{ TBinarizationFilter }

constructor TBinarizationFilter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FThreshold := 128;
end;

procedure TBinarizationFilter.ProcessImage(IntfImg: TLazIntfImage);
var
  x, y: Integer;
  C: TFPColor;
  YVal: Word;
  Th16: Word;
begin
  Th16 := FThreshold * 257;
  for y := 0 to IntfImg.Height - 1 do
  begin
    for x := 0 to IntfImg.Width - 1 do
    begin
      C := IntfImg.Colors[x, y];
      YVal := (C.Red * 299 + C.Green * 587 + C.Blue * 114) div 1000;
      if YVal >= Th16 then
      begin
        C.Red := 65535;
        C.Green := 65535;
        C.Blue := 65535;
      end
      else
      begin
        C.Red := 0;
        C.Green := 0;
        C.Blue := 0;
      end;
      IntfImg.Colors[x, y] := C;
    end;
  end;
end;

{ TBlurFilter }

procedure TBlurFilter.ProcessImage(IntfImg: TLazIntfImage);
var
  SrcImg: TLazIntfImage;
  x, y, dx, dy: Integer;
  SumR, SumG, SumB: Int64;
  Count: Integer;
  C: TFPColor;
  nx, ny: Integer;
begin
  SrcImg := TLazIntfImage.Create(0, 0);
  try
    SrcImg.Assign(IntfImg);
    for y := 0 to IntfImg.Height - 1 do
    begin
      for x := 0 to IntfImg.Width - 1 do
      begin
        SumR := 0; SumG := 0; SumB := 0;
        Count := 0;
        for dy := -1 to 1 do
        begin
          for dx := -1 to 1 do
          begin
            nx := x + dx;
            ny := y + dy;
            if (nx >= 0) and (nx < SrcImg.Width) and (ny >= 0) and (ny < SrcImg.Height) then
            begin
              C := SrcImg.Colors[nx, ny];
              SumR := SumR + C.Red;
              SumG := SumG + C.Green;
              SumB := SumB + C.Blue;
              Inc(Count);
            end;
          end;
        end;
        C.Red := SumR div Count;
        C.Green := SumG div Count;
        C.Blue := SumB div Count;
        IntfImg.Colors[x, y] := C;
      end;
    end;
  finally
    SrcImg.Free;
  end;
end;

{ TSharpenFilter }

procedure TSharpenFilter.ProcessImage(IntfImg: TLazIntfImage);
var
  SrcImg: TLazIntfImage;
  x, y: Integer;
  ValR, ValG, ValB: Int64;
  C: TFPColor;
  dx, dy: Integer;
  nx, ny: Integer;
  Weight: Integer;
begin
  SrcImg := TLazIntfImage.Create(0, 0);
  try
    SrcImg.Assign(IntfImg);
    for y := 0 to IntfImg.Height - 1 do
    begin
      for x := 0 to IntfImg.Width - 1 do
      begin
        ValR := 0; ValG := 0; ValB := 0;
        for dy := -1 to 1 do
        begin
          for dx := -1 to 1 do
          begin
            nx := EnsureRange(x + dx, 0, SrcImg.Width - 1);
            ny := EnsureRange(y + dy, 0, SrcImg.Height - 1);
            C := SrcImg.Colors[nx, ny];
            if (dx = 0) and (dy = 0) then
              Weight := 9
            else
              Weight := -1;
            ValR := ValR + C.Red * Weight;
            ValG := ValG + C.Green * Weight;
            ValB := ValB + C.Blue * Weight;
          end;
        end;
        C.Red := EnsureRange(ValR, 0, 65535);
        C.Green := EnsureRange(ValG, 0, 65535);
        C.Blue := EnsureRange(ValB, 0, 65535);
        IntfImg.Colors[x, y] := C;
      end;
    end;
  finally
    SrcImg.Free;
  end;
end;

{ TSobelFilter }

procedure TSobelFilter.ProcessImage(IntfImg: TLazIntfImage);
var
  SrcImg: TLazIntfImage;
  x, y: Integer;
  dx, dy: Integer;
  nx, ny: Integer;
  Luminance: array of array of Double;
  Gx, Gy, Mag: Double;
  C: TFPColor;
  GxKernel: array[-1..1, -1..1] of Integer = (
    (-1, 0, 1),
    (-2, 0, 2),
    (-1, 0, 1)
  );
  GyKernel: array[-1..1, -1..1] of Integer = (
    (-1, -2, -1),
    ( 0,  0,  0),
    ( 1,  2,  1)
  );
begin
  SrcImg := TLazIntfImage.Create(0, 0);
  try
    SrcImg.Assign(IntfImg);
    SetLength(Luminance, SrcImg.Width, SrcImg.Height);
    for y := 0 to SrcImg.Height - 1 do
    begin
      for x := 0 to SrcImg.Width - 1 do
      begin
        C := SrcImg.Colors[x, y];
        Luminance[x, y] := (C.Red * 0.299 + C.Green * 0.587 + C.Blue * 0.114);
      end;
    end;

    for y := 0 to IntfImg.Height - 1 do
    begin
      for x := 0 to IntfImg.Width - 1 do
      begin
        Gx := 0;
        Gy := 0;
        for dy := -1 to 1 do
        begin
          for dx := -1 to 1 do
          begin
            nx := EnsureRange(x + dx, 0, SrcImg.Width - 1);
            ny := EnsureRange(y + dy, 0, SrcImg.Height - 1);
            Gx := Gx + Luminance[nx, ny] * GxKernel[dy, dx];
            Gy := Gy + Luminance[nx, ny] * GyKernel[dy, dx];
          end;
        end;
        Mag := Sqrt(Gx*Gx + Gy*Gy);
        C.Red := EnsureRange(Round(Mag), 0, 65535);
        C.Green := C.Red;
        C.Blue := C.Red;
        IntfImg.Colors[x, y] := C;
      end;
    end;
  finally
    SrcImg.Free;
  end;
end;

{ TErosionDilationFilter }

constructor TErosionDilationFilter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FOperation := moErosion;
  FRadius := 1;
end;

procedure TErosionDilationFilter.ProcessImage(IntfImg: TLazIntfImage);
var
  SrcImg: TLazIntfImage;
  x, y, dx, dy, nx, ny: Integer;
  MinR, MinG, MinB: Word;
  MaxR, MaxG, MaxB: Word;
  C: TFPColor;
begin
  if FRadius < 1 then Exit;
  SrcImg := TLazIntfImage.Create(0, 0);
  try
    SrcImg.Assign(IntfImg);
    for y := 0 to IntfImg.Height - 1 do
    begin
      for x := 0 to IntfImg.Width - 1 do
      begin
        MinR := 65535; MinG := 65535; MinB := 65535;
        MaxR := 0; MaxG := 0; MaxB := 0;
        
        for dy := -FRadius to FRadius do
        begin
          for dx := -FRadius to FRadius do
          begin
            nx := x + dx;
            ny := y + dy;
            if (nx >= 0) and (nx < SrcImg.Width) and (ny >= 0) and (ny < SrcImg.Height) then
            begin
              C := SrcImg.Colors[nx, ny];
              if C.Red < MinR then MinR := C.Red;
              if C.Green < MinG then MinG := C.Green;
              if C.Blue < MinB then MinB := C.Blue;
              
              if C.Red > MaxR then MaxR := C.Red;
              if C.Green > MaxG then MaxG := C.Green;
              if C.Blue > MaxB then MaxB := C.Blue;
            end;
          end;
        end;
        
        if FOperation = moErosion then
        begin
          C.Red := MinR;
          C.Green := MinG;
          C.Blue := MinB;
        end
        else
        begin
          C.Red := MaxR;
          C.Green := MaxG;
          C.Blue := MaxB;
        end;
        IntfImg.Colors[x, y] := C;
      end;
    end;
  finally
    SrcImg.Free;
  end;
end;

initialization
  {$I imagefilters_icon.lrs}

end.
