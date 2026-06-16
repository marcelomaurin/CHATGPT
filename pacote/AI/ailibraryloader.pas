unit ailibraryloader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DynLibs, aiplatform;

type
  TAILibraryLoader = class
  private
    FLastError: string;
  public
    property LastError: string read FLastError;
    function LoadLibraryFromPaths(const ABaseName: string; const ASearchPaths: array of string): TLibHandle;
    function GetProc(AHandle: TLibHandle; const AProcName: string): Pointer;
    procedure Unload(var AHandle: TLibHandle);
  end;

implementation

function TAILibraryLoader.LoadLibraryFromPaths(const ABaseName: string; const ASearchPaths: array of string): TLibHandle;
var
  I: Integer;
  LibName: string;
  Candidate: string;
begin
  Result := NilHandle;
  FLastError := '';
  LibName := AIGetLibraryFileName(ABaseName);

  for I := Low(ASearchPaths) to High(ASearchPaths) do
  begin
    if ASearchPaths[I] = '' then
      Continue;
    Candidate := AICombinePath(ASearchPaths[I], LibName);
    if FileExists(Candidate) then
    begin
      Result := LoadLibrary(Candidate);
      if Result <> NilHandle then
        Exit;
    end;
  end;

  Result := LoadLibrary(LibName);
  if Result = NilHandle then
    FLastError := 'Library not found or could not be loaded: ' + LibName;
end;

function TAILibraryLoader.GetProc(AHandle: TLibHandle; const AProcName: string): Pointer;
begin
  Result := nil;
  FLastError := '';
  if AHandle = NilHandle then
  begin
    FLastError := 'Invalid library handle.';
    Exit;
  end;
  Result := GetProcedureAddress(AHandle, AProcName);
  if Result = nil then
    FLastError := 'Procedure not found: ' + AProcName;
end;

procedure TAILibraryLoader.Unload(var AHandle: TLibHandle);
begin
  if AHandle <> NilHandle then
  begin
    UnloadLibrary(AHandle);
    AHandle := NilHandle;
  end;
end;

end.
