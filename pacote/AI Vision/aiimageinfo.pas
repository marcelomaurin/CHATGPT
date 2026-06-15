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

  TAIWatermarkMetadataSource = (
    wmsNone,
    wmsPNGText,
    wmsJPEGExif,
    wmsJPEGXMP,
    wmsJPEGIPTC,
    wmsGenericMetadata
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
    FSourceKind: TAIImageInfoSourceKind;
    FIsLoaded: Boolean;

    FHasMetadata: Boolean;
    FMetadataText: TStringList;

    FTitle: string;
    FAuthor: string;
    FArtist: string;
    FCreator: string;
    FCopyright: string;
    FDescription: string;
    FComment: string;
    FSoftware: string;

    FHasWatermarkInfo: Boolean;
    FWatermarkText: string;
    FWatermarkSource: TAIWatermarkMetadataSource;

    function DetectFormatFromFileName(const AFileName: string): string;
    procedure CalculateDerivedInfo;

    function ReadPNGMetadata(const AFileName: string): Boolean;
    function ReadJPEGMetadata(const AFileName: string): Boolean;

    procedure AddMetadata(const AName, AValue: string);
    procedure ParseKnownMetadataField(const AName, AValue: string);
    function FindWatermarkMetadata: Boolean;

    function OrientationAsString: string;
    function SourceKindAsString: string;
    function WatermarkSourceAsString: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ClearInfo;

    function LoadInfoFromFile(const AFileName: string): Boolean;
    function LoadInfoFromBitmap(ABitmap: TBitmap): Boolean;
    function LoadInfoFromPicture(APicture: TPicture): Boolean;

    function LoadMetadataFromFile(const AFileName: string): Boolean;

    function AsText: string;
    function AsJSON: string;
    function GetDiagnosticReport: string;

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
    property SourceKind: TAIImageInfoSourceKind read FSourceKind;
    property IsLoaded: Boolean read FIsLoaded;

    property HasMetadata: Boolean read FHasMetadata;
    property Title: string read FTitle;
    property Author: string read FAuthor;
    property Artist: string read FArtist;
    property Creator: string read FCreator;
    property Copyright: string read FCopyright;
    property Description: string read FDescription;
    property Comment: string read FComment;
    property Software: string read FSoftware;

    property HasWatermarkInfo: Boolean read FHasWatermarkInfo;
    property WatermarkText: string read FWatermarkText;
    property WatermarkSource: TAIWatermarkMetadataSource read FWatermarkSource;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Native Vision', [TAIImageInfo]);
end;

function GetFileSizeBytes(const AFileName: string): Int64;
var
  FS: TFileStream;
begin
  Result := 0;
  if not SysUtils.FileExists(AFileName) then
    Exit;
  try
    FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      Result := FS.Size;
    finally
      FS.Free;
    end;
  except
    // ignore
  end;
end;

{ TAIImageInfo }

constructor TAIImageInfo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIImageInfo extracts technical properties and metadata from images natively, such as format, aspect ratio, orientation, file size, and copyright watermark info.';
  FMetadataText := TStringList.Create;
  ClearInfo;
end;

destructor TAIImageInfo.Destroy;
begin
  FMetadataText.Free;
  inherited Destroy;
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
  FSourceKind := iskNone;
  FIsLoaded := False;

  FHasMetadata := False;
  FTitle := '';
  FAuthor := '';
  FArtist := '';
  FCreator := '';
  FCopyright := '';
  FDescription := '';
  FComment := '';
  FSoftware := '';

  FHasWatermarkInfo := False;
  FWatermarkText := '';
  FWatermarkSource := wmsNone;

  if Assigned(FMetadataText) then
    FMetadataText.Clear;

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

procedure TAIImageInfo.CalculateDerivedInfo;
begin
  if (FWidth > 0) and (FHeight > 0) then
  begin
    FPixelCount := Int64(FWidth) * FHeight;
    FAspectRatio := FWidth / FHeight;
    FMegaPixels := FPixelCount / 1000000.0;

    if FWidth = FHeight then
      FOrientation := ioSquare
    else if FWidth > FHeight then
      FOrientation := ioLandscape
    else
      FOrientation := ioPortrait;
  end
  else
  begin
    FAspectRatio := 0.0;
    FMegaPixels := 0.0;
    FOrientation := ioUnknown;
  end;
end;

function TAIImageInfo.ReadPNGMetadata(const AFileName: string): Boolean;
var
  FS: TFileStream;
  Signature: array[0..7] of Byte;
  LenBytes: array[0..3] of Byte;
  ChunkType: array[0..3] of AnsiChar;
  ChunkLen: Cardinal;
  Data: AnsiString;
  Key, Value: string;
  P: Integer;

  function ReadUInt32BE: Cardinal;
  begin
    FS.ReadBuffer(LenBytes, 4);
    Result :=
      (Cardinal(LenBytes[0]) shl 24) or
      (Cardinal(LenBytes[1]) shl 16) or
      (Cardinal(LenBytes[2]) shl 8) or
      Cardinal(LenBytes[3]);
  end;

begin
  Result := False;
  try
    FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      if FS.Size < 8 then
        Exit;

      FS.ReadBuffer(Signature, 8);

      while FS.Position < FS.Size do
      begin
        ChunkLen := ReadUInt32BE;
        FS.ReadBuffer(ChunkType, 4);

        SetLength(Data, ChunkLen);
        if ChunkLen > 0 then
          FS.ReadBuffer(Data[1], ChunkLen);

        // skip CRC (4 bytes)
        FS.Seek(4, soCurrent);

        if string(ChunkType) = 'tEXt' then
        begin
          P := Pos(#0, Data);
          if P > 0 then
          begin
            Key := Copy(string(Data), 1, P - 1);
            Value := Copy(string(Data), P + 1, MaxInt);
            AddMetadata(Key, Value);
            Result := True;
          end;
        end
        else if string(ChunkType) = 'iTXt' then
        begin
          AddMetadata('PNG_iTXt', string(Data));
          Result := True;
        end;

        if string(ChunkType) = 'IEND' then
          Break;
      end;
    finally
      FS.Free;
    end;
  except
    // ignore
  end;
end;

function TAIImageInfo.ReadJPEGMetadata(const AFileName: string): Boolean;
var
  FS: TFileStream;
  B1, B2: Byte;
  Marker: Byte;
  LenHi, LenLo: Byte;
  SegLen: Word;
  Data: AnsiString;
  S: string;
begin
  Result := False;
  try
    FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      if FS.Size < 4 then
        Exit;

      FS.ReadBuffer(B1, 1);
      FS.ReadBuffer(B2, 1);

      if not ((B1 = $FF) and (B2 = $D8)) then
        Exit;

      while FS.Position < FS.Size do
      begin
        FS.ReadBuffer(B1, 1);
        if B1 <> $FF then
          Continue;

        FS.ReadBuffer(Marker, 1);

        if Marker = $D9 then
          Break;

        if Marker = $DA then
          Break;

        FS.ReadBuffer(LenHi, 1);
        FS.ReadBuffer(LenLo, 1);

        SegLen := (Word(LenHi) shl 8) or LenLo;

        if SegLen < 2 then
          Break;

        SetLength(Data, SegLen - 2);
        if SegLen > 2 then
          FS.ReadBuffer(Data[1], SegLen - 2);

        S := string(Data);

        case Marker of
          $E1:
            begin
              if Pos('Exif', S) > 0 then
              begin
                AddMetadata('JPEG_EXIF', S);
                Result := True;
              end;

              if Pos('xmpmeta', LowerCase(S)) > 0 then
              begin
                AddMetadata('JPEG_XMP', S);
                Result := True;
              end;
            end;

          $ED:
            begin
              AddMetadata('JPEG_IPTC_APP13', S);
              Result := True;
            end;

          $FE:
            begin
              AddMetadata('JPEG_Comment', S);
              Result := True;
            end;
        end;
      end;
    finally
      FS.Free;
    end;
  except
    // ignore
  end;
end;

procedure TAIImageInfo.AddMetadata(const AName, AValue: string);
begin
  if Trim(AValue) = '' then
    Exit;

  FHasMetadata := True;
  FMetadataText.Values[AName] := AValue;
  ParseKnownMetadataField(AName, AValue);
end;

procedure TAIImageInfo.ParseKnownMetadataField(const AName, AValue: string);
var
  N, V: string;
begin
  N := LowerCase(AName);
  V := Trim(AValue);

  if V = '' then
    Exit;

  if (Pos('title', N) > 0) and (FTitle = '') then
    FTitle := V;

  if ((Pos('author', N) > 0) or (Pos('creator', N) > 0)) and (FAuthor = '') then
    FAuthor := V;

  if (Pos('artist', N) > 0) and (FArtist = '') then
    FArtist := V;

  if (Pos('creator', N) > 0) and (FCreator = '') then
    FCreator := V;

  if ((Pos('copyright', N) > 0) or (Pos('rights', N) > 0)) and (FCopyright = '') then
    FCopyright := V;

  if ((Pos('description', N) > 0) or (Pos('caption', N) > 0)) and (FDescription = '') then
    FDescription := V;

  if (Pos('comment', N) > 0) and (FComment = '') then
    FComment := V;

  if (Pos('software', N) > 0) and (FSoftware = '') then
    FSoftware := V;
end;

function TAIImageInfo.FindWatermarkMetadata: Boolean;
var
  S: string;
begin
  Result := False;

  S := LowerCase(
    FTitle + ' ' +
    FAuthor + ' ' +
    FArtist + ' ' +
    FCreator + ' ' +
    FCopyright + ' ' +
    FDescription + ' ' +
    FComment + ' ' +
    FSoftware + ' ' +
    FMetadataText.Text
  );

  if (Pos('watermark', S) > 0) or
     (Pos('marca d', S) > 0) or
     (Pos('copyright', S) > 0) or
     (Pos('rights', S) > 0) or
     (Pos('protected', S) > 0) or
     (Pos('confidential', S) > 0) or
     (Pos('preview', S) > 0) or
     (Pos('sample', S) > 0) then
  begin
    FHasWatermarkInfo := True;

    FWatermarkText := Trim(FCopyright);
    if FWatermarkText = '' then
      FWatermarkText := Trim(FComment);
    if FWatermarkText = '' then
      FWatermarkText := Trim(FDescription);
    if FWatermarkText = '' then
      FWatermarkText := 'Possible watermark metadata found.';

    FWatermarkSource := wmsGenericMetadata;
    Result := True;
  end;
end;

function TAIImageInfo.LoadMetadataFromFile(const AFileName: string): Boolean;
var
  Ext: string;
begin
  Result := False;
  Ext := LowerCase(ExtractFileExt(AFileName));

  if Ext = '.png' then
    Result := ReadPNGMetadata(AFileName)
  else if (Ext = '.jpg') or (Ext = '.jpeg') then
    Result := ReadJPEGMetadata(AFileName)
  else
    Result := False;
end;

function TAIImageInfo.LoadInfoFromFile(const AFileName: string): Boolean;
var
  LPic: TPicture;
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
  FFileSizeBytes := GetFileSizeBytes(AFileName);

  LPic := TPicture.Create;
  try
    try
      LPic.LoadFromFile(AFileName);
      FWidth := LPic.Width;
      FHeight := LPic.Height;
      CalculateDerivedInfo;
      
      LoadMetadataFromFile(AFileName);
      FindWatermarkMetadata;
      
      FIsLoaded := True;
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
  CalculateDerivedInfo;
  FIsLoaded := True;
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
  CalculateDerivedInfo;
  FIsLoaded := True;
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

function TAIImageInfo.WatermarkSourceAsString: string;
begin
  case FWatermarkSource of
    wmsPNGText: Result := 'PNGText';
    wmsJPEGExif: Result := 'JPEGExif';
    wmsJPEGXMP: Result := 'JPEGXMP';
    wmsJPEGIPTC: Result := 'JPEGIPTC';
    wmsGenericMetadata: Result := 'GenericMetadata';
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
            LineEnding +
            'Metadata' + LineEnding +
            'Has Metadata: ' + BoolToStr(FHasMetadata, True) + LineEnding +
            'Title: ' + FTitle + LineEnding +
            'Author: ' + FAuthor + LineEnding +
            'Artist: ' + FArtist + LineEnding +
            'Creator: ' + FCreator + LineEnding +
            'Copyright: ' + FCopyright + LineEnding +
            'Description: ' + FDescription + LineEnding +
            'Comment: ' + FComment + LineEnding +
            'Software: ' + FSoftware + LineEnding +
            LineEnding +
            'Watermark Metadata' + LineEnding +
            'Has Watermark Info: ' + BoolToStr(FHasWatermarkInfo, True) + LineEnding +
            'Watermark Text: ' + FWatermarkText + LineEnding +
            'Watermark Source: ' + WatermarkSourceAsString + LineEnding +
            LineEnding +
            'Raw Metadata' + LineEnding +
            FMetadataText.Text;
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
            '  "source": "' + SourceKindAsString + '",' + LineEnding +
            '  "hasMetadata": ' + BoolToStr(FHasMetadata, 'true', 'false') + ',' + LineEnding +
            '  "title": "' + StringReplace(FTitle, '"', '\"', [rfReplaceAll]) + '",' + LineEnding +
            '  "author": "' + StringReplace(FAuthor, '"', '\"', [rfReplaceAll]) + '",' + LineEnding +
            '  "copyright": "' + StringReplace(FCopyright, '"', '\"', [rfReplaceAll]) + '",' + LineEnding +
            '  "comment": "' + StringReplace(FComment, '"', '\"', [rfReplaceAll]) + '",' + LineEnding +
            '  "hasWatermarkInfo": ' + BoolToStr(FHasWatermarkInfo, 'true', 'false') + ',' + LineEnding +
            '  "watermarkText": "' + StringReplace(FWatermarkText, '"', '\"', [rfReplaceAll]) + '",' + LineEnding +
            '  "watermarkSource": "' + WatermarkSourceAsString + '"' + LineEnding +
            '}';
end;

function TAIImageInfo.GetDiagnosticReport: string;
begin
  Result := AsText;
end;

initialization
  {$I aiimageinfo_icon.lrs}

end.
