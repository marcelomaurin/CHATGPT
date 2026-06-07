unit aiframediff;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, Graphics, GraphType, IntfGraphics, FPimage, LResources;

type
  { TAIFrameDiff }

  TAIFrameDiff = class(TAIBaseComponent)
  public
    constructor Create(AOwner: TComponent); override;

    function GenerateDiffBitmap(APrevious, ACurrent, ADest: TBitmap): Boolean;
    function GenerateDiffFile(const APrevFile, ACurrFile, ADestFile: string): Boolean;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Native Vision', [TAIFrameDiff]);
end;

{ TAIFrameDiff }

constructor TAIFrameDiff.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIFrameDiff computes absolute difference between two image frames natively.';
  ClearError;
end;

function TAIFrameDiff.GenerateDiffBitmap(APrevious, ACurrent, ADest: TBitmap): Boolean;
var
  LPendingPrev, LPendingCurr: TLazIntfImage;
  LDiffIntf: TLazIntfImage;
  x, y: Integer;
  CPres, CPrev, CDiff: TFPColor;
  Desc: TRawImageDescription;
begin
  Result := False;
  ClearError;

  if not Assigned(APrevious) or not Assigned(ACurrent) or not Assigned(ADest) then
  begin
    SetError('One or more bitmap parameters are nil.');
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
  LDiffIntf := TLazIntfImage.Create(0, 0);
  try
    try
      LPendingPrev.LoadFromBitmap(APrevious.Handle, APrevious.MaskHandle);
      LPendingCurr.LoadFromBitmap(ACurrent.Handle, ACurrent.MaskHandle);

      Desc := LPendingCurr.DataDescription;
      LDiffIntf.DataDescription := Desc;

      for y := 0 to LPendingCurr.Height - 1 do
      begin
        for x := 0 to LPendingCurr.Width - 1 do
        begin
          CPrev := LPendingPrev.Colors[x, y];
          CPres := LPendingCurr.Colors[x, y];

          CDiff.Red := Abs(Integer(CPres.Red) - Integer(CPrev.Red));
          CDiff.Green := Abs(Integer(CPres.Green) - Integer(CPrev.Green));
          CDiff.Blue := Abs(Integer(CPres.Blue) - Integer(CPrev.Blue));
          CDiff.Alpha := CPres.Alpha;

          LDiffIntf.Colors[x, y] := CDiff;
        end;
      end;

      ADest.Width := ACurrent.Width;
      ADest.Height := ACurrent.Height;
      ADest.LoadFromIntfImage(LDiffIntf);

      FLastResult := 'Generated difference bitmap successfully.';
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Failed to generate difference bitmap: ' + E.Message);
      end;
    end;
  finally
    LPendingPrev.Free;
    LPendingCurr.Free;
    LDiffIntf.Free;
  end;
end;

function TAIFrameDiff.GenerateDiffFile(const APrevFile, ACurrFile, ADestFile: string): Boolean;
var
  LPicPrev, LPicCurr: TPicture;
  LTempPrev, LTempCurr, LTempDest: TBitmap;
begin
  Result := False;
  ClearError;

  if (APrevFile = '') or (ACurrFile = '') or (ADestFile = '') then
  begin
    SetError('One or more file paths are empty.');
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
  LTempDest := TBitmap.Create;
  try
    try
      LPicPrev.LoadFromFile(APrevFile);
      LTempPrev.Assign(LPicPrev.Graphic);

      LPicCurr.LoadFromFile(ACurrFile);
      LTempCurr.Assign(LPicCurr.Graphic);

      if GenerateDiffBitmap(LTempPrev, LTempCurr, LTempDest) then
      begin
        LTempDest.SaveToFile(ADestFile);
        FLastResult := Format('Saved difference image to %s', [ADestFile]);
        FLastSuccess := True;
        Result := True;
      end;
    except
      on E: Exception do
      begin
        SetError('Failed to generate difference file: ' + E.Message);
      end;
    end;
  finally
    LPicPrev.Free;
    LPicCurr.Free;
    LTempPrev.Free;
    LTempCurr.Free;
    LTempDest.Free;
  end;
end;

initialization
  {$I aiframediff_icon.lrs}

end.
