unit aillamacpplora;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
  aibase,
  aillamacppmodel;

type
  TAILlamaCppLoRA = class(TAIBaseComponent)
  private
    FAdapterFile: string;
    FScale: Double;
    FModel: TAILlamaCppModel;
    FApplied: Boolean;
    procedure SetModel(AValue: TAILlamaCppModel);
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function ValidateAdapterFile: Boolean;
    function Apply: Boolean;
    function Remove: Boolean;
    property Applied: Boolean read FApplied;
  published
    property Model: TAILlamaCppModel read FModel write SetModel;
    property AdapterFile: string read FAdapterFile write FAdapterFile;
    property Scale: Double read FScale write FScale;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI LlamaCpp', [TAILlamaCppLoRA]);
end;

constructor TAILlamaCppLoRA.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Category := ccModel;
  FScale := 1.0;
end;

function TAILlamaCppLoRA.ValidateAdapterFile: Boolean;
begin
  Result := False;
  if Trim(FAdapterFile) = '' then
  begin
    SetError('AdapterFile is empty. Select a LoRA GGUF file.');
    Exit;
  end;
  if not FileExists(FAdapterFile) then
  begin
    SetError('LoRA adapter file was not found: ' + FAdapterFile);
    Exit;
  end;
  if LowerCase(ExtractFileExt(FAdapterFile)) <> '.gguf' then
  begin
    SetError('Invalid LoRA adapter extension. Expected .gguf: ' +
      FAdapterFile);
    Exit;
  end;
  ClearError;
  Result := True;
end;

procedure TAILlamaCppLoRA.SetModel(AValue: TAILlamaCppModel);
begin
  if FModel = AValue then
    Exit;
  if Assigned(FModel) then
    FModel.RemoveFreeNotification(Self);
  FModel := AValue;
  FApplied := False;
  if Assigned(FModel) then
    FModel.FreeNotification(Self);
end;

procedure TAILlamaCppLoRA.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FModel) then
  begin
    FModel := nil;
    FApplied := False;
  end;
end;

function TAILlamaCppLoRA.Apply: Boolean;
begin
  Result := False;
  if FApplied then
    Exit(True);
  if not Assigned(FModel) then
  begin
    SetError('Model is not assigned.');
    Exit;
  end;
  if not ValidateAdapterFile then
    Exit;
  if FScale < 0 then
  begin
    SetError('LoRA scale cannot be negative.');
    Exit;
  end;
  if not FModel.Loaded and not FModel.Load then
  begin
    SetError(FModel.LastError);
    Exit;
  end;
  if not FModel.ApplyLoRA(FAdapterFile, FScale) then
  begin
    SetError(FModel.LastError);
    Exit;
  end;
  FApplied := True;
  ClearError;
  Log(llInfo, 'LoRA adapter applied to the native llama.cpp model.');
  Result := True;
end;

function TAILlamaCppLoRA.Remove: Boolean;
begin
  Result := False;
  if not FApplied then
    Exit(True);
  if not Assigned(FModel) then
  begin
    SetError('Model is not assigned.');
    Exit;
  end;
  if not FModel.RemoveLoRA then
  begin
    SetError(FModel.LastError);
    Exit;
  end;
  FApplied := False;
  ClearError;
  Log(llInfo, 'LoRA adapter removed from the native llama.cpp model.');
  Result := True;
end;

end.
