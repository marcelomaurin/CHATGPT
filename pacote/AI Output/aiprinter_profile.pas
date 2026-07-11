unit aiprinter_profile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiprinter_types;

type
  TPrinterLanguageSet = set of TPrinterLanguage;

  { TAIPrinterProfile }

  TAIPrinterProfile = class
  private
    FModelName: string;
    FPaperWidthMM: Integer;
    FDpi: Integer;
    FColumnsNormal: Integer;
    FSupportsReceipt: Boolean;
    FSupportsLabel: Boolean;
    FSupportsCut: Boolean;
    FSupportsDrawer: Boolean;
    FSupportsBeep: Boolean;
    FSupportedLanguages: TPrinterLanguageSet;
  public
    constructor Create(
      const AModelName: string;
      APaperWidthMM: Integer;
      ADpi: Integer;
      AColumnsNormal: Integer;
      ASupportsReceipt: Boolean;
      ASupportsLabel: Boolean;
      ASupportsCut: Boolean;
      ASupportsDrawer: Boolean;
      ASupportsBeep: Boolean;
      const ASupportedLanguages: TPrinterLanguageSet
    );
    
    property ModelName: string read FModelName;
    property PaperWidthMM: Integer read FPaperWidthMM;
    property Dpi: Integer read FDpi;
    property ColumnsNormal: Integer read FColumnsNormal;
    property SupportsReceipt: Boolean read FSupportsReceipt;
    property SupportsLabel: Boolean read FSupportsLabel;
    property SupportsCut: Boolean read FSupportsCut;
    property SupportsDrawer: Boolean read FSupportsDrawer;
    property SupportsBeep: Boolean read FSupportsBeep;
    property SupportedLanguages: TPrinterLanguageSet read FSupportedLanguages;
    
    class function GetProfile(AModel: string): TAIPrinterProfile;
  end;

implementation

{ TAIPrinterProfile }

constructor TAIPrinterProfile.Create(
  const AModelName: string;
  APaperWidthMM: Integer;
  ADpi: Integer;
  AColumnsNormal: Integer;
  ASupportsReceipt: Boolean;
  ASupportsLabel: Boolean;
  ASupportsCut: Boolean;
  ASupportsDrawer: Boolean;
  ASupportsBeep: Boolean;
  const ASupportedLanguages: TPrinterLanguageSet
);
begin
  inherited Create;
  FModelName := AModelName;
  FPaperWidthMM := APaperWidthMM;
  FDpi := ADpi;
  FColumnsNormal := AColumnsNormal;
  FSupportsReceipt := ASupportsReceipt;
  FSupportsLabel := ASupportsLabel;
  FSupportsCut := ASupportsCut;
  FSupportsDrawer := ASupportsDrawer;
  FSupportsBeep := ASupportsBeep;
  FSupportedLanguages := ASupportedLanguages;
end;

class function TAIPrinterProfile.GetProfile(AModel: string): TAIPrinterProfile;
begin
  if SameText(AModel, 'Elgin i9 (80mm)') or SameText(AModel, 'Elgin i9') then
    Result := TAIPrinterProfile.Create('Elgin i9', 80, 203, 48, True, False, True, True, True, [plEscPos])
  else if SameText(AModel, 'QR203 (58mm)') or SameText(AModel, 'QR203') then
    Result := TAIPrinterProfile.Create('QR203', 58, 203, 32, True, False, False, False, True, [plEscPos])
  else if SameText(AModel, 'Elgin L42DT (Label)') or SameText(AModel, 'Elgin L42DT') then
    Result := TAIPrinterProfile.Create('Elgin L42DT', 104, 203, 40, False, True, True, False, False, [plZpl, plTspl, plEpl])
  else if SameText(AModel, 'Generic ESC/POS 80mm') then
    Result := TAIPrinterProfile.Create('Generic ESC/POS 80mm', 80, 203, 48, True, False, True, True, True, [plEscPos])
  else if SameText(AModel, 'Generic ESC/POS 58mm') then
    Result := TAIPrinterProfile.Create('Generic ESC/POS 58mm', 58, 203, 32, True, False, False, False, False, [plEscPos])
  else if SameText(AModel, 'Generic ZPL Label') then
    Result := TAIPrinterProfile.Create('Generic ZPL Label', 104, 203, 40, False, True, False, False, False, [plZpl])
  else if SameText(AModel, 'Generic TSPL Label') then
    Result := TAIPrinterProfile.Create('Generic TSPL Label', 104, 203, 40, False, True, False, False, False, [plTspl])
  else
    Result := TAIPrinterProfile.Create('Generic ESC/POS 80mm', 80, 203, 48, True, False, True, True, True, [plEscPos]);
end;

end.
