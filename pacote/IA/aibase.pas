unit aibase;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  { TAIBaseComponent }

  TAIBaseComponent = class(TComponent)
  protected
    FPrompt: string;
    FLastError: string;
    FLastResult: string;
    FLastSuccess: Boolean;
    procedure ClearError;
    procedure SetError(const AMessage: string);
  public
    constructor Create(AOwner: TComponent); override;
    property LastSuccess: Boolean read FLastSuccess;
  published
    property Prompt: string read FPrompt write FPrompt;
    property LastError: string read FLastError;
    property LastResult: string read FLastResult;
  end;

implementation

{ TAIBaseComponent }

constructor TAIBaseComponent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := '';
  FLastError := '';
  FLastResult := '';
  FLastSuccess := True;
end;

procedure TAIBaseComponent.ClearError;
begin
  FLastError := '';
  FLastSuccess := True;
end;

procedure TAIBaseComponent.SetError(const AMessage: string);
begin
  FLastError := AMessage;
  FLastSuccess := False;
end;

end.
