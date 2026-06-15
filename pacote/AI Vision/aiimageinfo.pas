unit aiimageinfo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, Graphics, LResources;

type
  TAIImageOrientation = (
    ioUnknown,
    ioSquare,
    ioLandscape,
    ioPortrait
  );

  TAIImageInfoSourceKind = (
    iskNone,
    iskFile,
    iskBitmap,
    iskPicture
  );

  { TAIImageInfo }

  TAIImageInfo = class(TAIBaseComponent)
  private
    FWidth: Integer;
    FHeight: Integer;
    FPixelCount: Int64;
    FFileName: string;

    FFileExists: Boolean;
    FFileSizeBytes: Int64;
    FExtension: string;
    FFormatName: string;

    FAspectRatio: Double;
    FMegaPixels: Double;
    FOrientation: TAIImageOrientation;

    FIsLoaded: Boolean;
    FSourceKind: TAIImageInfoSourceKind;

    function DetectFormatFromFileName(const AFileName: string): string;
    procedure CalculateMetrics;
  public
    constructor Create(AOwner: TComponent); override;

    procedure ClearInfo;

    function LoadInfoFromFile(const AFileName: string): Boolean;
    function LoadInfoFromBitmap(ABitmap: TBitmap): Boolean;
    function LoadInfoFromPicture(APicture: TPicture): Boolean;

    function AsText: string;
    function AsJSON: string;
    function GetDiagnosticReport: string;

    function OrientationAsString: string;
    function SourceKindAsString: string;

  published
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property PixelCount: Int64 read FPixelCount;
    property FileName: string read FFileName;

    property FileExists: Boolean read FFileExists;
    property FileSizeBytes: Int64 read FFileSizeBytes;
    property Extension: string read FExtension;
    property FormatName: string read FFormatName;

    property AspectRatio: Double read FAspectRatio;
    property MegaPixels: Double read FMegaPixels;
    property Orientation: TAIImageOrientation read FOrientation;

    property IsLoaded: Boolean read FIsLoaded;
    property SourceKind: TAIImageInfoSourceKind read FSourceKind;
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
  FPrompt := 'Component TAIImageInfo extracts technical properties from images natively, such as format, aspect ratio, orientation, and file size.';
  ClearInfo;
end;

procedure TAIImageInfo.ClearInfo;
begin
  FWidth := 0;
  FHeight := 0;
  FPixelCount := 0;
  FFileName := '';
  FFileExists := False;
  FFileSizeBytes := 0;
  FExtension := '';
  FFormatName := '';
  FAspectRatio := 0.0;
  FMegaPixels := 0.0;
  FOrientation := ioUnknown;
  FIsLoaded := False;
  FSourceKind := iskNone;
  ClearError;
  FLastSuccess := False;
end;

function TAIImageInfo.DetectFormatFromFileName(const AFileName: string): string;
var
  Ext: string;
begin
  Ext := LowerCase(ExtractFileExt(AFileName));

  if Ext = '.png' then Result := 'PNG'
  else if (Ext = '.jpg') or (Ext = '.jpeg') then Result := 'JPEG'
  else if Ext = '.bmp' then Result := 'BMP'
  else if Ext = '.gif' then Result := 'GIF'
  else if (Ext = '.tif') or (Ext = '.tiff') then Result := 'TIFF'
  else if Ext = '.webp' then Result := 'WEBP'
  else Result := 'Unknown';
end;

procedure TAIImageInfo.CalculateMetrics;
begin
  FPixelCount := Int64(FWidth) * FHeight;
  if FHeight > 0 then
    FAspectRatio := FWidth / FHeight
  else
    FAspectRatio := 0.0;
    
  FMegaPixels := FPixelCount / 1000000.0;

  if FWidth = FHeight then
    FOrientation := ioSquare
  else if FWidth > FHeight then
    FOrientation := ioLandscape
  else
    FOrientation := ioPortrait;

  FIsLoaded := True;
end;

function TAIImageInfo.LoadInfoFromFile(const AFileName: string): Boolean;
var
  LPic: TPicture;
  SR: TSearchRec;
begin
  Result := False;
  ClearInfo;
  FSourceKind := iskFile;

  if AFileName = '' then
  begin
    SetError('Caminho do arquivo vazio.');
    Exit;
  end;

  if not SysUtils.FileExists(AFileName) then
  begin
    SetError('Arquivo não existe: ' + AFileName);
    Exit;
  end;

  FFileName := AFileName;
  FFileExists := True;
  FExtension := ExtractFileExt(AFileName);
  FFormatName := DetectFormatFromFileName(AFileName);

  // File size
  if FindFirst(AFileName, faAnyFile, SR) = 0 then
  begin
    FFileSizeBytes := SR.Size;
    FindClose(SR);
  end;

  LPic := TPicture.Create;
  try
    try
      LPic.LoadFromFile(AFileName);
      FWidth := LPic.Width;
      FHeight := LPic.Height;
      CalculateMetrics;
      FLastResult := Format('Loaded info for file: %s (%dx%d)', [AFileName, FWidth, FHeight]);
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Erro ao carregar cabeçalho de imagem: ' + E.Message);
      end;
    end;
  finally
    LPic.Free;
  end;
end;

function TAIImageInfo.LoadInfoFromBitmap(ABitmap: TBitmap): Boolean;
begin
  Result := False;
  ClearInfo;
  FSourceKind := iskBitmap;

  if not Assigned(ABitmap) then
  begin
    SetError('Bitmap não informado.');
    Exit;
  end;

  FWidth := ABitmap.Width;
  FHeight := ABitmap.Height;
  FFormatName := 'BMP';
  CalculateMetrics;
  FLastResult := Format('Loaded info from bitmap (%dx%d)', [FWidth, FHeight]);
  FLastSuccess := True;
  Result := True;
end;

function TAIImageInfo.LoadInfoFromPicture(APicture: TPicture): Boolean;
begin
  Result := False;
  ClearInfo;
  FSourceKind := iskPicture;

  if not Assigned(APicture) then
  begin
    SetError('Picture não informada.');
    Exit;
  end;

  FWidth := APicture.Width;
  FHeight := APicture.Height;
  FFormatName := 'Picture';
  CalculateMetrics;
  FLastResult := Format('Loaded info from picture (%dx%d)', [FWidth, FHeight]);
  FLastSuccess := True;
  Result := True;
end;

function TAIImageInfo.OrientationAsString: string;
begin
  case FOrientation of
    ioSquare: Result := 'Square';
    ioLandscape: Result := 'Landscape';
    ioPortrait: Result := 'Portrait';
    else Result := 'Unknown';
  end;
end;

function TAIImageInfo.SourceKindAsString: string;
begin
  case FSourceKind of
    iskFile: Result := 'File';
    iskBitmap: Result := 'Bitmap';
    iskPicture: Result := 'Picture';
    else Result := 'None';
  end;
end;

function TAIImageInfo.AsText: string;
begin
  if not FIsLoaded then
  begin
    Result := 'No image loaded.';
    Exit;
  end;

  Result := 'Image Info' + LineEnding +
            'File: ' + FFileName + LineEnding +
            'Format: ' + FFormatName + LineEnding +
            'Extension: ' + FExtension + LineEnding +
            'File Size: ' + IntToStr(FFileSizeBytes) + ' bytes' + LineEnding +
            'Width: ' + IntToStr(FWidth) + LineEnding +
            'Height: ' + IntToStr(FHeight) + LineEnding +
            'Pixel Count: ' + IntToStr(FPixelCount) + LineEnding +
            'MegaPixels: ' + FormatFloat('0.00', FMegaPixels) + ' MP' + LineEnding +
            'Aspect Ratio: ' + FormatFloat('0.0000', FAspectRatio) + LineEnding +
            'Orientation: ' + OrientationAsString + LineEnding +
            'Source: ' + SourceKindAsString;
end;

function TAIImageInfo.AsJSON: string;
begin
  if not FIsLoaded then
  begin
    Result := '{}';
    Exit;
  end;

  Result := '{' + LineEnding +
            '  "fileName": "' + StringReplace(FFileName, '\', '\\', [rfReplaceAll]) + '",' + LineEnding +
            '  "format": "' + FFormatName + '",' + LineEnding +
            '  "extension": "' + FExtension + '",' + LineEnding +
            '  "fileSizeBytes": ' + IntToStr(FFileSizeBytes) + ',' + LineEnding +
            '  "width": ' + IntToStr(FWidth) + ',' + LineEnding +
            '  "height": ' + IntToStr(FHeight) + ',' + LineEnding +
            '  "pixelCount": ' + IntToStr(FPixelCount) + ',' + LineEnding +
            '  "megaPixels": ' + FormatFloat('0.00', FMegaPixels) + ',' + LineEnding +
            '  "aspectRatio": ' + FormatFloat('0.0000', FAspectRatio) + ',' + LineEnding +
            '  "orientation": "' + OrientationAsString + '",' + LineEnding +
            '  "source": "' + SourceKindAsString + '"' + LineEnding +
            '}';
end;

function TAIImageInfo.GetDiagnosticReport: string;
begin
  Result := AsText;
end;

initialization
  {$I aiimageinfo_icon.lrs}

end.
