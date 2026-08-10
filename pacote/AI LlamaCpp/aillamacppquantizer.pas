unit aillamacppquantizer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils,
  aibase,
  aiprocessrunner,
  aillamacppruntime;

type
  TAILlamaQuantizationType = (
    lqtQ4_0,
    lqtQ4_1,
    lqtQ5_0,
    lqtQ5_1,
    lqtIQ2_XXS,
    lqtIQ2_XS,
    lqtIQ2_S,
    lqtIQ2_M,
    lqtIQ1_S,
    lqtIQ1_M,
    lqtTQ1_0,
    lqtTQ2_0,
    lqtQ2_K,
    lqtQ2_K_S,
    lqtIQ3_XXS,
    lqtIQ3_S,
    lqtIQ3_M,
    lqtIQ3_XS,
    lqtQ3_K_S,
    lqtQ3_K_M,
    lqtQ3_K_L,
    lqtIQ4_NL,
    lqtIQ4_XS,
    lqtQ4_K_S,
    lqtQ4_K_M,
    lqtQ5_K_S,
    lqtQ5_K_M,
    lqtQ6_K,
    lqtQ8_0,
    lqtF16,
    lqtBF16,
    lqtF32,
    lqtCopy
  );

  TAILlamaCppQuantizer = class(TAIBaseComponent)
  private
    FRuntime: TAILlamaCppRuntime;
    FSourceFile: string;
    FDestinationFile: string;
    FQuantizationType: TAILlamaQuantizationType;
    procedure SetRuntime(AValue: TAILlamaCppRuntime);
    procedure LogCapturedText(const AText: string; ALevel: TAILogLevel);
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    class function QuantizationTypeToString(
      AType: TAILlamaQuantizationType): string; static;
    procedure BuildParameters(AParameters: TStrings);
    function Execute: Boolean;
  published
    property Runtime: TAILlamaCppRuntime read FRuntime write SetRuntime;
    property SourceFile: string read FSourceFile write FSourceFile;
    property DestinationFile: string read FDestinationFile
      write FDestinationFile;
    property QuantizationType: TAILlamaQuantizationType
      read FQuantizationType write FQuantizationType default lqtQ4_K_M;
  end;

procedure Register;

implementation

constructor TAILlamaCppQuantizer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FQuantizationType := lqtQ4_K_M;
end;

class function TAILlamaCppQuantizer.QuantizationTypeToString(
  AType: TAILlamaQuantizationType): string;
const
  QUANTIZATION_NAMES: array[TAILlamaQuantizationType] of string = (
    'Q4_0', 'Q4_1', 'Q5_0', 'Q5_1',
    'IQ2_XXS', 'IQ2_XS', 'IQ2_S', 'IQ2_M',
    'IQ1_S', 'IQ1_M', 'TQ1_0', 'TQ2_0',
    'Q2_K', 'Q2_K_S', 'IQ3_XXS', 'IQ3_S', 'IQ3_M', 'IQ3_XS',
    'Q3_K_S', 'Q3_K_M', 'Q3_K_L', 'IQ4_NL', 'IQ4_XS',
    'Q4_K_S', 'Q4_K_M', 'Q5_K_S', 'Q5_K_M', 'Q6_K', 'Q8_0',
    'F16', 'BF16', 'F32', 'COPY'
  );
begin
  Result := QUANTIZATION_NAMES[AType];
end;

procedure TAILlamaCppQuantizer.BuildParameters(AParameters: TStrings);
begin
  if not Assigned(AParameters) then
    raise EArgumentNilException.Create('AParameters');
  AParameters.Clear;
  AParameters.Add(FSourceFile);
  AParameters.Add(FDestinationFile);
  AParameters.Add(QuantizationTypeToString(FQuantizationType));
end;

procedure TAILlamaCppQuantizer.SetRuntime(AValue: TAILlamaCppRuntime);
begin
  if FRuntime = AValue then
    Exit;
  if Assigned(FRuntime) then
    FRuntime.RemoveFreeNotification(Self);
  FRuntime := AValue;
  if Assigned(FRuntime) then
    FRuntime.FreeNotification(Self);
end;

procedure TAILlamaCppQuantizer.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FRuntime) then
    FRuntime := nil;
end;

procedure TAILlamaCppQuantizer.LogCapturedText(const AText: string;
  ALevel: TAILogLevel);
var
  I: Integer;
  LLines: TStringList;
begin
  if Trim(AText) = '' then
    Exit;
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    for I := 0 to LLines.Count - 1 do
      if Trim(LLines[I]) <> '' then
        Log(ALevel, LLines[I]);
  finally
    LLines.Free;
  end;
end;

function TAILlamaCppQuantizer.Execute: Boolean;
var
  I: Integer;
  LArguments: array of string;
  LParameters: TStringList;
  LRunner: TAIProcessRunner;
begin
  Result := False;
  if not Assigned(FRuntime) then
  begin
    SetError('Runtime is not assigned.');
    Exit;
  end;
  if not FileExists(FRuntime.GetQuantizePath) then
  begin
    SetError('Quantizer executable not found: ' + FRuntime.GetQuantizePath);
    Exit;
  end;
  if (Trim(FSourceFile) = '') or not FileExists(FSourceFile) then
  begin
    SetError('Source GGUF file not found: ' + FSourceFile);
    Exit;
  end;
  if LowerCase(ExtractFileExt(FSourceFile)) <> '.gguf' then
  begin
    SetError('Source file must use the .gguf extension.');
    Exit;
  end;
  if Trim(FDestinationFile) = '' then
  begin
    SetError('Destination GGUF file is empty.');
    Exit;
  end;
  if LowerCase(ExtractFileExt(FDestinationFile)) <> '.gguf' then
  begin
    SetError('Destination file must use the .gguf extension.');
    Exit;
  end;

  LParameters := TStringList.Create;
  LRunner := TAIProcessRunner.Create(nil);
  try
    BuildParameters(LParameters);
    SetLength(LArguments, LParameters.Count);
    for I := 0 to LParameters.Count - 1 do
      LArguments[I] := LParameters[I];
    LRunner.Executable := FRuntime.GetQuantizePath;
    LRunner.WorkingDirectory := FRuntime.LibraryPath;
    Result := LRunner.Execute(LArguments);
    FLastResult := Trim(LRunner.StdOutText);
    if Trim(LRunner.StdErrText) <> '' then
    begin
      if FLastResult <> '' then
        FLastResult := FLastResult + LineEnding;
      FLastResult := FLastResult + Trim(LRunner.StdErrText);
    end;
    LogCapturedText(LRunner.StdOutText, llInfo);
    if Result then
      LogCapturedText(LRunner.StdErrText, llInfo)
    else
      LogCapturedText(LRunner.StdErrText, llError);
    if Result then
      ClearError
    else
      SetError(LRunner.LastError);
  finally
    LRunner.Free;
    LParameters.Free;
  end;
end;

procedure Register;
begin
  RegisterComponents('AI LlamaCpp', [TAILlamaCppQuantizer]);
end;

end.
