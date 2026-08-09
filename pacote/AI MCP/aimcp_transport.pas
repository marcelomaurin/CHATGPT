unit aimcp_transport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  IAIMCPTransport = interface
    ['{527F6B3F-BEED-4F96-A480-AE1388E14329}']
    function Connect(out AError: string): Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;
    function SendRequest(const ARequestJSON: string; out AResponseJSON,
      AError: string): Boolean;
  end;

  TAIMCPTransportRequestEvent = procedure(Sender: TObject;
    const ARequestJSON: string; out AResponseJSON, AError: string) of object;

  TAIMCPInMemoryTransport = class(TInterfacedObject, IAIMCPTransport)
  private
    FConnected: Boolean;
    FOnRequest: TAIMCPTransportRequestEvent;
  public
    function Connect(out AError: string): Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;
    function SendRequest(const ARequestJSON: string; out AResponseJSON,
      AError: string): Boolean;
    property OnRequest: TAIMCPTransportRequestEvent read FOnRequest write FOnRequest;
  end;

implementation

function TAIMCPInMemoryTransport.Connect(out AError: string): Boolean;
begin
  AError := '';
  FConnected := Assigned(FOnRequest);
  if not FConnected then AError := 'Handler do transporte em memoria nao associado.';
  Result := FConnected;
end;

procedure TAIMCPInMemoryTransport.Disconnect;
begin
  FConnected := False;
end;

function TAIMCPInMemoryTransport.IsConnected: Boolean;
begin
  Result := FConnected;
end;

function TAIMCPInMemoryTransport.SendRequest(const ARequestJSON: string;
  out AResponseJSON, AError: string): Boolean;
begin
  AResponseJSON := '';
  AError := '';
  if not FConnected then begin AError := 'Transporte MCP desconectado.'; Exit(False); end;
  try
    FOnRequest(Self, ARequestJSON, AResponseJSON, AError);
    Result := (AError = '') and (AResponseJSON <> '');
  except
    on E: Exception do begin AError := E.Message; Result := False; end;
  end;
end;

end.
