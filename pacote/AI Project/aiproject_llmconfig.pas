unit aiproject_llmconfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiproject, aibase, chatgpt;

type
  { TAIProjectLLMConfig — stores and applies LLM configuration to a TAIProject }
  TAIProjectLLMConfig = class(TComponent)
  private
    FProject: TAIProject;
    FProvider: TAIProvider;
    FModel: string;
    FEndpoint: string;
    FToken: string;
    FSaveToken: Boolean;
    FTemperature: Double;
    FMaxTokens: Integer;
    FModelVersion: string;
  public
    constructor Create(AOwner: TComponent); override;

    { Applies current config properties to the linked TAIProject. }
    procedure ApplyToProject;

    { Reads current config from the linked TAIProject into this component. }
    procedure LoadFromProject;
  published
    property Project: TAIProject read FProject write FProject;

    property Provider: TAIProvider read FProvider write FProvider default AIP_OPENAI;
    property Model: string read FModel write FModel;
    property ModelVersion: string read FModelVersion write FModelVersion;
    property Endpoint: string read FEndpoint write FEndpoint;

    { API token. Never persisted unless SaveToken=True. }
    property Token: string read FToken write FToken;

    { If True the token is allowed to be written to disk. Default: False. }
    property SaveToken: Boolean read FSaveToken write FSaveToken default False;

    property Temperature: Double read FTemperature write FTemperature;
    property MaxTokens: Integer read FMaxTokens write FMaxTokens default 8000;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectLLMConfig]);
end;

constructor TAIProjectLLMConfig.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProvider := AIP_OPENAI;
  FModel := 'llama3.2';
  FEndpoint := 'http://localhost:11434';
  FTemperature := 0.2;
  FMaxTokens := 8000;
  FSaveToken := False;
  FModelVersion := '1.0';
end;

procedure TAIProjectLLMConfig.ApplyToProject;
begin
  if not Assigned(FProject) then Exit;
  FProject.DefaultProvider := FProvider;
  FProject.DefaultModel := FModel;
  FProject.LocalURL := FEndpoint;
  FProject.SaveToken := FSaveToken;
  // Only apply token to project — never persisted unless SaveToken=True
  FProject.Token := FToken;
end;

procedure TAIProjectLLMConfig.LoadFromProject;
begin
  if not Assigned(FProject) then Exit;
  FProvider := FProject.DefaultProvider;
  FModel := FProject.DefaultModel;
  FEndpoint := FProject.LocalURL;
  FSaveToken := FProject.SaveToken;
  FToken := FProject.Token;
end;

end.
