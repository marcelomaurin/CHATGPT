unit aiimageinfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, Graphics, LResources;

type
  { TAIImageInfo }

  TAIImageInfo = class(TAIBaseComponent)
  private
    FWidth: Integer;
    FHeight: Integer;
    FPixelCount: Int64;
    FFileName: string;
  public
    constructor Create(AOwner: TComponent); override;
    
    function LoadInfoFromFile(const AFileName: string): Boolean;
    function LoadInfoFromBitmap(ABitmap: TBitmap): Boolean;
    function AsText: string;
  published
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property PixelCount: Int64 read FPixelCount;
    property FileName: string read FFileName;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Native Vision', [TAIImageInfo]);
end;

{ TAIImageInfo }

constructor TAIImageInfo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIImageInfo extracts dimensions and pixel counts from images natively.';
  FWidth := 0;
  FHeight := 0;
  FPixelCount := 0;
  FFileName := '';
  ClearError;
end;

function TAIImageInfo.LoadInfoFromFile(const AFileName: string): Boolean;
var
  LPic: TPicture;
begin
  Result := False;
  ClearError;
  FFileName := '';
  FWidth := 0;
  FHeight := 0;
  FPixelCount := 0;

  if AFileName = '' then
  begin
    SetError('File name is empty.');
    Exit;
  end;

  if not FileExists(AFileName) then
  begin
    SetError('File does not exist: ' + AFileName);
    Exit;
  end;

  LPic := TPicture.Create;
  try
    try
      LPic.LoadFromFile(AFileName);
      FWidth := LPic.Width;
      FHeight := LPic.Height;
      FPixelCount := Int64(FWidth) * FHeight;
      FFileName := AFileName;
      FLastResult := Format('Loaded info for file: %s (%dx%d)', [AFileName, FWidth, FHeight]);
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Failed to load image info: ' + E.Message);
      end;
    end;
  finally
    LPic.Free;
  end;
end;

function TAIImageInfo.LoadInfoFromBitmap(ABitmap: TBitmap): Boolean;
begin
  Result := False;
  ClearError;
  FFileName := '';
  FWidth := 0;
  FHeight := 0;
  FPixelCount := 0;

  if not Assigned(ABitmap) then
  begin
    SetError('Bitmap is nil.');
    Exit;
  end;

  FWidth := ABitmap.Width;
  FHeight := ABitmap.Height;
  FPixelCount := Int64(FWidth) * FHeight;
  FLastResult := Format('Loaded info from bitmap (%dx%d)', [FWidth, FHeight]);
  FLastSuccess := True;
  Result := True;
end;

function TAIImageInfo.AsText: string;
begin
  if FWidth = 0 then
    Result := 'No image loaded.'
  else
    Result := Format('File: %s' + LineEnding +
                     'Width: %d' + LineEnding +
                     'Height: %d' + LineEnding +
                     'Pixel Count: %d', [FFileName, FWidth, FHeight, FPixelCount]);
end;

end.
