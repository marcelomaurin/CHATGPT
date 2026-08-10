program a2a_client_demo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, aia2a;

var
  Client: TAIA2AClient;
  Answer: string;
begin
  Client := TAIA2AClient.Create(nil);
  try
    Client.ProtocolVersion := '1.0';
    Client.Binding := a2abHTTPJSON;
    Client.AutoDiscover := True;

    if ParamCount = 0 then
    begin
      WriteLn('A2A client demo - Lazarus/Free Pascal');
      WriteLn('Usage: a2a_client_demo <base-url> [message]');
      Halt(0);
    end;

    Client.BaseURL := ParamStr(1);
    if not Client.Discover then
    begin
      WriteLn(StdErr, 'Discovery error: ', Client.LastError);
      Halt(1);
    end;

    WriteLn('Agent: ', Client.AgentCard.Name);
    WriteLn('Version: ', Client.AgentCard.Version);
    WriteLn('Endpoint: ', Client.SelectedURL);

    if ParamCount >= 2 then
    begin
      if Client.SendText(ParamStr(2), Answer) then
        WriteLn('Answer: ', Answer)
      else
      begin
        WriteLn(StdErr, 'Send error: ', Client.LastError);
        Halt(2);
      end;
    end;
  finally
    Client.Free;
  end;
end.
