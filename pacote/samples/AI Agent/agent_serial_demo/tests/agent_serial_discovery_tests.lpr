program agent_serial_discovery_tests;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, aiagent, aiagentserial, aiserial;

type
  TMockAgentSerial = class(TAIAgentSerial)
  private
    FMockActive: Boolean;
    FSent: TStringList;
  protected
    function SerialIsActive: Boolean; override;
    function SerialOpenPort: Boolean; override;
    procedure SerialClosePort; override;
    function SerialWriteText(const AText: string): Boolean; override;
    procedure SerialPoll; override;
    function SerialErrorText: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function RunSend(const AText: string): string;
    function RunConnect: string;
    function RunDisconnect: string;
    property MockActive: Boolean read FMockActive write FMockActive;
    property Sent: TStringList read FSent;
  end;

  TEventSink = class
  public
    RejectedCount: Integer;
    LastRejectedCommand: string;
    procedure CommandRejected(Sender: TObject; const ACommand,
      AReason: string);
  end;

constructor TMockAgentSerial.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMockActive := True;
  FSent := TStringList.Create;
  RequireConfirmation := False;
end;

destructor TMockAgentSerial.Destroy;
begin
  FSent.Free;
  inherited Destroy;
end;

function TMockAgentSerial.SerialIsActive: Boolean;
begin
  Result := FMockActive;
end;

function TMockAgentSerial.SerialOpenPort: Boolean;
begin
  FMockActive := True;
  Result := True;
end;

procedure TMockAgentSerial.SerialClosePort;
begin
  FMockActive := False;
end;

function TMockAgentSerial.SerialWriteText(const AText: string): Boolean;
begin
  FSent.Add(AText);
  Result := True;
end;

procedure TMockAgentSerial.SerialPoll;
begin
end;

function TMockAgentSerial.SerialErrorText: string;
begin
  Result := 'mock serial error';
end;

function TMockAgentSerial.RunSend(const AText: string): string;
begin
  Result := ExecuteAction(aakSend, AText);
end;

function TMockAgentSerial.RunConnect: string;
begin
  Result := ExecuteAction(aakConnect, '');
end;

function TMockAgentSerial.RunDisconnect: string;
begin
  Result := ExecuteAction(aakDisconnect, '');
end;

procedure TEventSink.CommandRejected(Sender: TObject; const ACommand,
  AReason: string);
begin
  Inc(RejectedCount);
  LastRejectedCommand := ACommand;
end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then raise Exception.Create(AMessage);
end;

procedure CreateFixture(out Agent: TMockAgentSerial;
  out Catalog: TAIAgentAction; out Serial: TAISerialModem);
begin
  Catalog := TAIAgentAction.Create(nil);
  Serial := TAISerialModem.Create(nil);
  Agent := TMockAgentSerial.Create(nil);
  Agent.Serial := Serial;
  Agent.CommandCatalog := Catalog;
end;

procedure DestroyFixture(var Agent: TMockAgentSerial;
  var Catalog: TAIAgentAction; var Serial: TAISerialModem);
begin
  Agent.Free;
  Serial.Free;
  Catalog.Free;
  Agent := nil;
  Serial := nil;
  Catalog := nil;
end;

procedure TestManualSingleBlock;
var Agent: TMockAgentSerial; Catalog: TAIAgentAction; Serial: TAISerialModem;
begin
  CreateFixture(Agent, Catalog, Serial);
  try
    Agent.StartCommandDiscovery;
    Agent.AppendRX('MAN-BEGIN' + #10 +
      'COMMAND LEDON: turn LED on' + #10 +
      'COMMAND LEDOFF: turn LED off' + #10 + 'MAN-END' + #10);
    Check(Catalog.AllowedActions.Count = 2, 'single block: expected 2 commands');
    Check(Catalog.ParameterDefinitions[0] = 'LEDON: turn LED on',
      'single block: description not preserved');
    Check(Agent.CommandsKnown, 'single block: CommandsKnown=False');
    Check(Agent.DiscoveryState = scdsCompleted, 'single block: state not completed');
    Check(Agent.LastManual.Count = 4, 'single block: manual lines not preserved');
  finally DestroyFixture(Agent, Catalog, Serial); end;
end;

procedure TestFragmentedManual;
var Agent: TMockAgentSerial; Catalog: TAIAgentAction; Serial: TAISerialModem;
begin
  CreateFixture(Agent, Catalog, Serial);
  try
    Agent.StartCommandDiscovery;
    Agent.AppendRX('MAN-BE');
    Agent.AppendRX('GIN' + #10 + 'COMMAND LED');
    Agent.AppendRX('ON: turn LED on' + #10 + 'MAN-END' + #10);
    Check(Catalog.AllowedActions.Count = 1, 'fragmented: expected one command');
    Check(SameText(Catalog.AllowedActions[0], 'LEDON'), 'fragmented: LEDON missing');
  finally DestroyFixture(Agent, Catalog, Serial); end;
end;

procedure TestMultipleLines;
var Agent: TMockAgentSerial; Catalog: TAIAgentAction; Serial: TAISerialModem;
begin
  CreateFixture(Agent, Catalog, Serial);
  try
    Agent.StartCommandDiscovery;
    Agent.AppendRX('MAN-BEGIN' + #10 + 'COMMAND LEDON: on' + #10 +
      'COMMAND LEDOFF: off' + #10 + 'COMMAND LED?: state' + #10 +
      'MAN-END' + #10);
    Check(Catalog.AllowedActions.Count = 3, 'multiple lines: expected 3 commands');
  finally DestroyFixture(Agent, Catalog, Serial); end;
end;

procedure TestDuplicateCommand;
var Agent: TMockAgentSerial; Catalog: TAIAgentAction; Serial: TAISerialModem;
begin
  CreateFixture(Agent, Catalog, Serial);
  try
    Agent.StartCommandDiscovery;
    Agent.AppendRX('MAN-BEGIN' + #10 + 'COMMAND LEDON: on' + #10 +
      'COMMAND ledon: duplicate' + #10 + 'MAN-END' + #10);
    Check(Catalog.AllowedActions.Count = 1, 'duplicate: command duplicated');
    Check(Catalog.ParameterDefinitions.Count = 1, 'duplicate: definition duplicated');
  finally DestroyFixture(Agent, Catalog, Serial); end;
end;

procedure TestMissingManualEnd;
var Agent: TMockAgentSerial; Catalog: TAIAgentAction; Serial: TAISerialModem;
begin
  CreateFixture(Agent, Catalog, Serial);
  try
    Agent.StartCommandDiscovery;
    Agent.AppendRX('MAN-BEGIN' + #10 + 'COMMAND LEDON: on' + #10);
    Check(not Agent.CommandsKnown, 'missing end: catalog marked complete');
    Check(Agent.DiscoveryState = scdsReadingManual, 'missing end: wrong state');
  finally DestroyFixture(Agent, Catalog, Serial); end;
end;

procedure TestUnknownCommandRejected;
var
  Agent: TMockAgentSerial; Catalog: TAIAgentAction; Serial: TAISerialModem;
  Sink: TEventSink; SentBefore: Integer; Reply: string;
begin
  CreateFixture(Agent, Catalog, Serial);
  Sink := TEventSink.Create;
  try
    Agent.OnCommandRejected := @Sink.CommandRejected;
    Agent.StartCommandDiscovery;
    Agent.AppendRX('MAN-BEGIN' + #10 + 'COMMAND LEDON: on' + #10 +
      'MAN-END' + #10);
    SentBefore := Agent.Sent.Count;
    Reply := Agent.RunSend('FORMAT' + #10);
    Check(Pos('error:', Reply) = 1, 'unknown: no error returned');
    Check(Agent.Sent.Count = SentBefore, 'unknown: bytes were sent');
    Check(Sink.RejectedCount = 1, 'unknown: rejection event not fired');
  finally Sink.Free; DestroyFixture(Agent, Catalog, Serial); end;
end;

procedure TestAllowedCommandSent;
var
  Agent: TMockAgentSerial; Catalog: TAIAgentAction; Serial: TAISerialModem;
  SentBefore: Integer; Reply: string;
begin
  CreateFixture(Agent, Catalog, Serial);
  try
    Agent.StartCommandDiscovery;
    Agent.AppendRX('MAN-BEGIN' + #10 + 'COMMAND LEDON: on' + #10 +
      'MAN-END' + #10);
    SentBefore := Agent.Sent.Count;
    Reply := Agent.RunSend('LEDON' + #10);
    Check(Pos('sent ', Reply) = 1, 'allowed: send failed');
    Check(Agent.Sent.Count = SentBefore + 1, 'allowed: bytes not sent');
  finally DestroyFixture(Agent, Catalog, Serial); end;
end;

procedure TestAllowedCommandGetsLineEnding;
var
  Agent: TMockAgentSerial; Catalog: TAIAgentAction; Serial: TAISerialModem;
  SentBefore: Integer; Reply: string;
begin
  CreateFixture(Agent, Catalog, Serial);
  try
    Agent.StartCommandDiscovery;
    Agent.AppendRX('MAN-BEGIN' + #10 + 'COMMAND LEDOFF: off' + #10 +
      'MAN-END' + #10);
    SentBefore := Agent.Sent.Count;
    Reply := Agent.RunSend('LEDOFF');
    Check(Pos('sent ', Reply) = 1, 'line ending: send failed');
    Check(Agent.Sent.Count = SentBefore + 1, 'line ending: bytes not sent');
    Check(Agent.Sent[SentBefore] = 'LEDOFF' + LineEnding,
      'line ending: command was not terminated');
  finally DestroyFixture(Agent, Catalog, Serial); end;
end;

procedure TestReconnectCatalogPolicy;
var Agent: TMockAgentSerial; Catalog: TAIAgentAction; Serial: TAISerialModem;
begin
  CreateFixture(Agent, Catalog, Serial);
  try
    Agent.StartCommandDiscovery;
    Agent.AppendRX('MAN-BEGIN' + #10 + 'COMMAND LEDON: on' + #10 +
      'MAN-END' + #10);
    Agent.ClearCatalogOnDisconnect := True;
    Agent.RunDisconnect;
    Check(Catalog.AllowedActions.Count = 0, 'disconnect: catalog not cleared');

    Agent.MockActive := True;
    Agent.StartCommandDiscovery;
    Agent.AppendRX('MAN-BEGIN' + #10 + 'COMMAND LEDON: on' + #10 +
      'MAN-END' + #10);
    Agent.ClearCatalogOnDisconnect := False;
    Agent.RunDisconnect;
    Check(Catalog.AllowedActions.Count = 1, 'disconnect: catalog not preserved');
  finally DestroyFixture(Agent, Catalog, Serial); end;
end;

procedure TestConnectStartsOneDiscovery;
var
  Agent: TMockAgentSerial; Catalog: TAIAgentAction; Serial: TAISerialModem;
  SentAfterFirst: Integer;
begin
  CreateFixture(Agent, Catalog, Serial);
  try
    Agent.MockActive := False;
    Agent.RunConnect;
    Check(Agent.DiscoveryState = scdsWaitingBegin,
      'connect: discovery did not start');
    Check(Agent.Sent.Count = 1, 'connect: MAN was not sent');
    SentAfterFirst := Agent.Sent.Count;
    Agent.RunConnect;
    Check(Agent.Sent.Count = SentAfterFirst,
      'connect: overlapping discovery sent another MAN');
  finally DestroyFixture(Agent, Catalog, Serial); end;
end;

procedure RunTest(const AName: string; ATest: TProcedure);
begin
  Write(AName, ': ');
  ATest;
  WriteLn('OK');
end;

begin
  try
    RunTest('manual single block', @TestManualSingleBlock);
    RunTest('fragmented manual', @TestFragmentedManual);
    RunTest('multiple lines', @TestMultipleLines);
    RunTest('duplicate command', @TestDuplicateCommand);
    RunTest('missing MAN-END', @TestMissingManualEnd);
    RunTest('unknown command rejected', @TestUnknownCommandRejected);
    RunTest('allowed command sent', @TestAllowedCommandSent);
    RunTest('allowed command gets line ending', @TestAllowedCommandGetsLineEnding);
    RunTest('disconnect catalog policy', @TestReconnectCatalogPolicy);
    RunTest('connect starts one discovery', @TestConnectStartsOneDiscovery);
    WriteLn('ALL TESTS PASSED');
    ExitCode := 0;
  except
    on E: Exception do
    begin
      WriteLn('FAILED: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
