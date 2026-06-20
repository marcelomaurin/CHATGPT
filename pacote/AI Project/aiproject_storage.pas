unit aiproject_storage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject, fpjson, jsonparser;

type
  { TAIProjectStorage }
  TAIProjectStorage = class(TComponent)
  private
    FProject: TAIProject;
    FSaveToken: Boolean;
    FConfigFileName: string;
    FProjectFileName: string;
    FLastError: string;
  public
    constructor Create(AOwner: TComponent); override;

    { Saves project to .aiproj.json file. Token only saved if SaveToken=True. }
    function SaveProjectToFile(const AFileName: string): Boolean;

    { Loads project from .aiproj.json file. }
    function LoadProjectFromFile(const AFileName: string): Boolean;

    { Saves LLM configuration (without token unless SaveToken=True). }
    function SaveConfig: Boolean;

    { Loads LLM configuration from ConfigFileName. }
    function LoadConfig: Boolean;

    property LastError: string read FLastError;
  published
    property Project: TAIProject read FProject write FProject;

    { If True, API token is saved to disk. Default: False (security). }
    property SaveToken: Boolean read FSaveToken write FSaveToken default False;

    { Path to LLM config file (e.g. llm_config.json). }
    property ConfigFileName: string read FConfigFileName write FConfigFileName;

    { Path to project file (e.g. myproject.aiproj.json). }
    property ProjectFileName: string read FProjectFileName write FProjectFileName;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectStorage]);
end;

constructor TAIProjectStorage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSaveToken := False;
  FConfigFileName := 'llm_config.json';
  FProjectFileName := 'project.aiproj.json';
end;

function TAIProjectStorage.SaveProjectToFile(const AFileName: string): Boolean;
var
  TokenBackup: string;
begin
  Result := False;
  FLastError := '';
  if not Assigned(FProject) then
  begin
    FLastError := 'No project linked to TAIProjectStorage.';
    Exit;
  end;

  // Temporarily hide token if SaveToken=False
  TokenBackup := FProject.Token;
  if not FSaveToken then
    FProject.Token := '';

  try
    Result := FProject.SaveProjectToFile(AFileName);
    if not Result then
      FLastError := FProject.LastError;
  finally
    // Restore token in memory
    FProject.Token := TokenBackup;
  end;
end;

function TAIProjectStorage.LoadProjectFromFile(const AFileName: string): Boolean;
begin
  Result := False;
  FLastError := '';
  if not Assigned(FProject) then
  begin
    FLastError := 'No project linked to TAIProjectStorage.';
    Exit;
  end;
  Result := FProject.LoadProjectFromFile(AFileName);
  if not Result then
    FLastError := FProject.LastError;
end;

function TAIProjectStorage.SaveConfig: Boolean;
var
  TokenBackup: string;
begin
  Result := False;
  FLastError := '';
  if not Assigned(FProject) then
  begin
    FLastError := 'No project linked to TAIProjectStorage.';
    Exit;
  end;

  FProject.ConfigFileName := FConfigFileName;
  FProject.SaveToken := FSaveToken;

  TokenBackup := FProject.Token;
  if not FSaveToken then
    FProject.Token := '';

  try
    Result := FProject.SaveConfig;
    if not Result then
      FLastError := FProject.LastError;
  finally
    FProject.Token := TokenBackup;
  end;
end;

function TAIProjectStorage.LoadConfig: Boolean;
begin
  Result := False;
  FLastError := '';
  if not Assigned(FProject) then
  begin
    FLastError := 'No project linked to TAIProjectStorage.';
    Exit;
  end;
  FProject.ConfigFileName := FConfigFileName;
  Result := FProject.LoadConfig;
  if not Result then
    FLastError := FProject.LastError;
end;

end.
