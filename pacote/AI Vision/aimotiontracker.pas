unit aimotiontracker;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, Graphics, GraphType, IntfGraphics, FPimage, LResources;

type
  { TAIMotionTracker }

  TAIMotionTracker = class(TAIBaseComponent)
  private
    FThreshold: Byte;
    FMinMotionPercent: Double;
    FMotionPercent: Double;
    FLastMotionDetected: Boolean;
    FLastDifferencePixels: Int64;
  public
    constructor Create(AOwner: TComponent); override;
    
    function DetectMotion(APrevious, ACurrent: TBitmap): Boolean;
    function DetectMotionFromFiles(const APrevFile, ACurrFile: string): Boolean;
    function GetMotionPercent: Double;
  published
    property Threshold: Byte read FThreshold write FThreshold default 15;
    property MinMotionPercent: Double read FMinMotionPercent write FMinMotionPercent;
    property MotionPercent: Double read FMotionPercent;
    property LastMotionDetected: Boolean read FLastMotionDetected;
    property LastDifferencePixels: Int64 read FLastDifferencePixels;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Native Vision', [TAIMotionTracker]);
end;

{ TAIMotionTracker }

constructor TAIMotionTracker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIMotionTracker detects motion difference between two frames natively.';
  FThreshold := 15;
  FMinMotionPercent := 1.5;
  FMotionPercent := 0.0;
  FLastMotionDetected := False;
  FLastDifferencePixels := 0;
  ClearError;
end;

function TAIMotionTracker.DetectMotion(APrevious, ACurrent: TBitmap): Boolean;
var
  LPendingPrev, LPendingCurr: TLazIntfImage;
  x, y: Integer;
  CPrev, CCurr: TFPColor;
  L1, L2, LDiff: Word;
  LDiffCount, LTotalCount: Int64;
  Th16: Word;
begin
  Result := False;
  FLastMotionDetected := False;
  FMotionPercent := 0.0;
  FLastDifferencePixels := 0;
  ClearError;

  if not Assigned(APrevious) or not Assigned(ACurrent) then
  begin
    SetError('One or both bitmap parameters are nil.');
    Exit;
  end;

  if (APrevious.Width <> ACurrent.Width) or (APrevious.Height <> ACurrent.Height) then
  begin
    SetError(Format('Bitmap dimensions do not match: Previous(%dx%d), Current(%dx%d).',
      [APrevious.Width, APrevious.Height, ACurrent.Width, ACurrent.Height]));
    Exit;
  end;

  LPendingPrev := TLazIntfImage.Create(0, 0);
  LPendingCurr := TLazIntfImage.Create(0, 0);
  try
    try
      LPendingPrev.LoadFromBitmap(APrevious.Handle, APrevious.MaskHandle);
      LPendingCurr.LoadFromBitmap(ACurrent.Handle, ACurrent.MaskHandle);

      LDiffCount := 0;
      LTotalCount := Int64(LPendingCurr.Width) * LPendingCurr.Height;
      Th16 := FThreshold * 257; // scale 0..255 to 0..65535

      for y := 0 to LPendingCurr.Height - 1 do
      begin
        for x := 0 to LPendingCurr.Width - 1 do
        begin
          CPrev := LPendingPrev.Colors[x, y];
          CCurr := LPendingCurr.Colors[x, y];

          // Calculate luminance for each pixel
          L1 := (CPrev.Red * 299 + CPrev.Green * 587 + CPrev.Blue * 114) div 1000;
          L2 := (CCurr.Red * 299 + CCurr.Green * 587 + CCurr.Blue * 114) div 1000;

          LDiff := Abs(Integer(L2) - Integer(L1));
          if LDiff >= Th16 then
          begin
            Inc(LDiffCount);
          end;
        end;
      end;

      FLastDifferencePixels := LDiffCount;
      if LTotalCount > 0 then
        FMotionPercent := (LDiffCount * 100.0) / LTotalCount
      else
        FMotionPercent := 0.0;

      FLastMotionDetected := FMotionPercent >= FMinMotionPercent;
      Result := FLastMotionDetected;

      FLastResult := Format('Motion check: %f%% difference (threshold: %f%%). Detected: %s',
        [FMotionPercent, FMinMotionPercent, BoolToStr(FLastMotionDetected, True)]);
      FLastSuccess := True;
    except
      on E: Exception do
      begin
        SetError('Failed to detect motion: ' + E.Message);
      end;
    end;
  finally
    LPendingPrev.Free;
    LPendingCurr.Free;
  end;
end;

function TAIMotionTracker.DetectMotionFromFiles(const APrevFile, ACurrFile: string): Boolean;
var
  LPicPrev, LPicCurr: TPicture;
  LTempPrev, LTempCurr: TBitmap;
begin
  Result := False;
  ClearError;

  if (APrevFile = '') or (ACurrFile = '') then
  begin
    SetError('One or both file paths are empty.');
    Exit;
  end;

  if not FileExists(APrevFile) then
  begin
    SetError('Previous file does not exist: ' + APrevFile);
    Exit;
  end;

  if not FileExists(ACurrFile) then
  begin
    SetError('Current file does not exist: ' + ACurrFile);
    Exit;
  end;

  LPicPrev := TPicture.Create;
  LPicCurr := TPicture.Create;
  LTempPrev := TBitmap.Create;
  LTempCurr := TBitmap.Create;
  try
    try
      LPicPrev.LoadFromFile(APrevFile);
      LTempPrev.Assign(LPicPrev.Graphic);

      LPicCurr.LoadFromFile(ACurrFile);
      LTempCurr.Assign(LPicCurr.Graphic);

      Result := DetectMotion(LTempPrev, LTempCurr);
    except
      on E: Exception do
      begin
        SetError('Failed to run motion detection from files: ' + E.Message);
      end;
    end;
  finally
    LPicPrev.Free;
    LPicCurr.Free;
    LTempPrev.Free;
    LTempCurr.Free;
  end;
end;

function TAIMotionTracker.GetMotionPercent: Double;
begin
  Result := FMotionPercent;
end;

initialization
  {$I aimotiontracker_icon.lrs}

end.

