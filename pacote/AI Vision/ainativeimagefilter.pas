unit ainativeimagefilter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, Graphics, GraphType, IntfGraphics, FPimage, LResources;

type
  TAINativeImageFilterType = (niftNone, niftGray, niftThreshold, niftInvert, niftResize, niftBlurBox);

  { TAINativeImageFilter }

  TAINativeImageFilter = class(TAIBaseComponent)
  private
    FFilterType: TAINativeImageFilterType;
    FThresholdValue: Byte;
    FResizeWidth: Integer;
    FResizeHeight: Integer;
  public
    constructor Create(AOwner: TComponent); override;

    function ApplyToBitmap(ABitmap: TBitmap): Boolean;
    function ApplyFile(const AInputFile, AOutputFile: string): Boolean;

    // Direct filters using TLazIntfImage
    procedure ConvertToGray(IntfImg: TLazIntfImage);
    procedure ApplyThreshold(IntfImg: TLazIntfImage; AThreshold: Byte);
    procedure InvertColors(IntfImg: TLazIntfImage);
    procedure ResizeBitmap(SrcImg, DestImg: TLazIntfImage; NewWidth, NewHeight: Integer);
    procedure BlurBox(IntfImg: TLazIntfImage);
  published
    property FilterType: TAINativeImageFilterType read FFilterType write FFilterType default niftNone;
    property ThresholdValue: Byte read FThresholdValue write FThresholdValue default 128;
    property ResizeWidth: Integer read FResizeWidth write FResizeWidth default 320;
    property ResizeHeight: Integer read FResizeHeight write FResizeHeight default 240;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Native Vision', [TAINativeImageFilter]);
end;

{ TAINativeImageFilter }

constructor TAINativeImageFilter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAINativeImageFilter processes bitmaps natively without Python dependencies.';
  FFilterType := niftNone;
  FThresholdValue := 128;
  FResizeWidth := 320;
  FResizeHeight := 240;
  ClearError;
end;

function TAINativeImageFilter.ApplyToBitmap(ABitmap: TBitmap): Boolean;
var
  IntfImg, DestIntf: TLazIntfImage;
  Desc: TRawImageDescription;
begin
  Result := False;
  ClearError;

  if not Assigned(ABitmap) then
  begin
    SetError('Bitmap is nil.');
    Exit;
  end;

  if FFilterType = niftNone then
  begin
    FLastResult := 'Filter type is None. No changes applied.';
    FLastSuccess := True;
    Result := True;
    Exit;
  end;

  IntfImg := TLazIntfImage.Create(0, 0);
  try
    try
      IntfImg.LoadFromBitmap(ABitmap.Handle, ABitmap.MaskHandle);

      case FFilterType of
        niftGray:
          ConvertToGray(IntfImg);
        niftThreshold:
          ApplyThreshold(IntfImg, FThresholdValue);
        niftInvert:
          InvertColors(IntfImg);
        niftBlurBox:
          BlurBox(IntfImg);
        niftResize:
          begin
            if (FResizeWidth <= 0) or (FResizeHeight <= 0) then
            begin
              SetError('Resize dimensions must be greater than zero.');
              Exit;
            end;

            DestIntf := TLazIntfImage.Create(0, 0);
            try
              Desc := IntfImg.DataDescription;
              Desc.Width := FResizeWidth;
              Desc.Height := FResizeHeight;
              DestIntf.DataDescription := Desc;

              ResizeBitmap(IntfImg, DestIntf, FResizeWidth, FResizeHeight);

              ABitmap.Width := FResizeWidth;
              ABitmap.Height := FResizeHeight;
              ABitmap.LoadFromIntfImage(DestIntf);
            finally
              DestIntf.Free;
            end;

            FLastResult := Format('Applied resize filter to bitmap (%dx%d)', [FResizeWidth, FResizeHeight]);
            FLastSuccess := True;
            Result := True;
            Exit;
          end;
      end;

      if FFilterType <> niftResize then
      begin
        ABitmap.LoadFromIntfImage(IntfImg);
      end;

      FLastResult := 'Applied filter to bitmap successfully.';
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Failed to apply filter to bitmap: ' + E.Message);
      end;
    end;
  finally
    IntfImg.Free;
  end;
end;

function TAINativeImageFilter.ApplyFile(const AInputFile, AOutputFile: string): Boolean;
var
  LPic: TPicture;
  LTempBmp: TBitmap;
begin
  Result := False;
  ClearError;

  if (AInputFile = '') or (AOutputFile = '') then
  begin
    SetError('Input or output file path is empty.');
    Exit;
  end;

  if not FileExists(AInputFile) then
  begin
    SetError('Input file does not exist: ' + AInputFile);
    Exit;
  end;

  LPic := TPicture.Create;
  LTempBmp := TBitmap.Create;
  try
    try
      LPic.LoadFromFile(AInputFile);
      LTempBmp.Assign(LPic.Graphic);

      if ApplyToBitmap(LTempBmp) then
      begin
        LTempBmp.SaveToFile(AOutputFile);
        FLastResult := Format('Successfully processed file from %s to %s', [AInputFile, AOutputFile]);
        FLastSuccess := True;
        Result := True;
      end;
    except
      on E: Exception do
      begin
        SetError('Failed processing file: ' + E.Message);
      end;
    end;
  finally
    LPic.Free;
    LTempBmp.Free;
  end;
end;

procedure TAINativeImageFilter.ConvertToGray(IntfImg: TLazIntfImage);
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
      // Grayscale calculation using standard NTSC weights
      Gray := (C.Red * 299 + C.Green * 587 + C.Blue * 114) div 1000;
      C.Red := Gray;
      C.Green := Gray;
      C.Blue := Gray;
      IntfImg.Colors[x, y] := C;
    end;
  end;
end;

procedure TAINativeImageFilter.ApplyThreshold(IntfImg: TLazIntfImage; AThreshold: Byte);
var
  x, y: Integer;
  C: TFPColor;
  YVal: Word;
  Th16: Word;
begin
  Th16 := AThreshold * 257; // Scale 0..255 to 0..65535
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

procedure TAINativeImageFilter.InvertColors(IntfImg: TLazIntfImage);
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

procedure TAINativeImageFilter.ResizeBitmap(SrcImg, DestImg: TLazIntfImage; NewWidth, NewHeight: Integer);
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

procedure TAINativeImageFilter.BlurBox(IntfImg: TLazIntfImage);
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

end.
