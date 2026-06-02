program test_aiagentsafety;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, aiagentsafety;

type
  TTestSafetyRunner = class
  public
    ConfirmedByUser: Boolean;
    procedure HandleConfirmAction(Sender: TObject; const AActionName: string; AParams: TStrings; var AConfirmed: Boolean);
  end;

procedure TTestSafetyRunner.HandleConfirmAction(Sender: TObject; const AActionName: string; AParams: TStrings; var AConfirmed: Boolean);
begin
  AConfirmed := ConfirmedByUser;
end;

var
  Safety: TAIAgentSafety;
  Runner: TTestSafetyRunner;
  Err: string;

begin
  WriteLn('Running test_aiagentsafety...');
  Runner := TTestSafetyRunner.Create;
  Safety := TAIAgentSafety.Create(nil);
  try
    Safety.Enabled := True;
    Safety.RequireConfirmation := False;
    Safety.ReadOnlyMode := False;
    
    // Test 1: File Write Protection
    Safety.AllowFileWrite := False;
    if Safety.ValidateAction('WRITE_FILE', nil, Err) then
      raise Exception.Create('Test failed: Should have blocked WRITE_FILE action.');
    if Pos('Escrita de arquivos bloqueada', Err) <= 0 then
      raise Exception.Create('Test failed: Incorrect error message for blocked file write.');
      
    // Test 2: Network Access Check
    Safety.AllowNetwork := False;
    if Safety.ValidateAction('SEND_HTTP', nil, Err) then
      raise Exception.Create('Test failed: Should have blocked SEND_HTTP action.');
    if Pos('Acesso de rede bloqueado', Err) <= 0 then
      raise Exception.Create('Test failed: Incorrect error message for blocked network.');

    // Test 3: SafeBasePath Normalization
    Safety.AllowFileWrite := True;
    // Set SafeBasePath to a directory
    Safety.SafeBasePath := 'C:\temp';
    
    // Check path inside SafeBasePath
    if not Safety.ValidateFilePath('C:\temp\somefile.txt', Err) then
      raise Exception.Create('Test failed: C:\temp\somefile.txt should be allowed: ' + Err);
      
    // Check path outside SafeBasePath (like C:\temp_extra\file.txt)
    if Safety.ValidateFilePath('C:\temp_extra\file.txt', Err) then
      raise Exception.Create('Test failed: Should have blocked C:\temp_extra\file.txt outside safe path.');
    if Pos('fora do diretório seguro base', Err) <= 0 then
      raise Exception.Create('Test failed: Incorrect safe base path validation error message.');

    // Check directory traversal
    if Safety.ValidateFilePath('C:\temp\..\Windows\System32\cmd.exe', Err) then
      raise Exception.Create('Test failed: Should have blocked directory traversal path.');

    // Test 4: ValidateURL HTTPS fallback to 443
    Safety.AllowNetwork := True;
    Safety.AllowedPorts.Clear;
    Safety.AllowedPorts.Add('443'); // only allow HTTPS
    
    if not Safety.ValidateURL('https://api.site.com', Err) then
      raise Exception.Create('Test failed: https://api.site.com should be allowed on port 443: ' + Err);
      
    if Safety.ValidateURL('http://api.site.com', Err) then
      raise Exception.Create('Test failed: http://api.site.com (port 80) should be blocked.');

    // Test 5: RequireConfirmation interative confirmation
    Safety.RequireConfirmation := True;
    Safety.OnConfirmAction := @Runner.HandleConfirmAction;
    
    // User confirms
    Runner.ConfirmedByUser := True;
    if not Safety.ValidateAction('SOME_ACTION', nil, Err) then
      raise Exception.Create('Test failed: SOME_ACTION should be confirmed by user: ' + Err);
      
    // User rejects
    Runner.ConfirmedByUser := False;
    if Safety.ValidateAction('SOME_ACTION', nil, Err) then
      raise Exception.Create('Test failed: SOME_ACTION should be blocked when user rejects confirmation.');
    if Pos('rejeitada pelo usuário na confirmação', Err) <= 0 then
      raise Exception.Create('Test failed: Incorrect confirmation rejection message.');

  finally
    Safety.Free;
    Runner.Free;
  end;
  WriteLn('test_aiagentsafety COMPLETED SUCCESSFULLY.');
end.
