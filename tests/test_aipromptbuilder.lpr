program test_aipromptbuilder;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, aipromptbuilder, aibase, aimodbus, fpjson, jsonparser;

type
  TMockOwner = class(TComponent)
  end;

var
  Owner: TMockOwner;
  Modbus: TAIModbusClient;
  Builder: TAIPromptBuilder;
  PromptText: string;
  JSONData: TJSONData;
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  CompObj: TJSONObject;
begin
  WriteLn('Running test_aipromptbuilder...');
  try
    Owner := TMockOwner.Create(nil);
    try
      // Create test components attached to Owner
      Modbus := TAIModbusClient.Create(Owner);
      Modbus.Name := 'Modbus1';
      Modbus.IPAddress := '192.168.1.50';
      Modbus.Port := 502;
      Modbus.Prompt := 'Component for Modbus communication.';
      
      Builder := TAIPromptBuilder.Create(nil);
      try
        // Test 1: Default Text Output in Portuguese
        Builder.Language := plPortuguese;
        Builder.OutputFormat := pofText;
        Builder.IncludeProperties := True;
        
        PromptText := Builder.BuildFromOwner(Owner);
        if Pos('Você tem disponíveis os seguintes componentes:', PromptText) <= 0 then
          raise Exception.Create('Test failed: Incorrect language header for Portuguese.');
        if Pos('[Modbus1]', PromptText) <= 0 then
          raise Exception.Create('Test failed: Component Modbus1 name was not found in prompt.');
        if Pos('IPAddress: 192.168.1.50', PromptText) <= 0 then
          raise Exception.Create('Test failed: Property IPAddress was not printed.');
        if Pos('Port: 502', PromptText) <= 0 then
          raise Exception.Create('Test failed: Property Port was not printed.');
          
        // Test 2: English Markdown Output
        Builder.Language := plEnglish;
        Builder.OutputFormat := pofMarkdown;
        
        PromptText := Builder.BuildFromOwner(Owner);
        if Pos('The following components are available to you:', PromptText) <= 0 then
          raise Exception.Create('Test failed: Incorrect language header for English.');
        if Pos('### Modbus1 (`TAIModbusClient`)', PromptText) <= 0 then
          raise Exception.Create('Test failed: Markdown header mismatch.');
        if Pos('| IPAddress | 192.168.1.50 |', PromptText) <= 0 then
          raise Exception.Create('Test failed: Markdown properties table was not printed correctly.');
          
        // Test 3: JSON Format
        Builder.Language := plSpanish;
        Builder.OutputFormat := pofJSON;
        
        PromptText := Builder.BuildFromOwner(Owner);
        JSONData := GetJSON(PromptText);
        try
          if JSONData.JSONType <> jtObject then
            raise Exception.Create('Test failed: JSON prompt is not an object.');
          JSONObj := TJSONObject(JSONData);
          if Pos('Tiene disponibles los siguientes componentes:', JSONObj.Strings['instruction']) <= 0 then
            raise Exception.Create('Test failed: JSON instruction header mismatch.');
            
          JSONArray := JSONObj.Arrays['components'];
          if JSONArray.Count <> 1 then
            raise Exception.Create('Test failed: JSON components array count should be 1.');
            
          CompObj := JSONArray.Objects[0];
          if CompObj.Strings['name'] <> 'Modbus1' then
            raise Exception.Create('Test failed: Component name mismatch in JSON.');
          if CompObj.Strings['type'] <> 'TAIModbusClient' then
            raise Exception.Create('Test failed: Component type mismatch in JSON.');
          if CompObj.Strings['category'] <> 'Input' then
            raise Exception.Create('Test failed: Category mismatch in JSON.');
            
          if CompObj.Objects['properties'].Strings['IPAddress'] <> '192.168.1.50' then
            raise Exception.Create('Test failed: Component properties mismatch in JSON.');
        finally
          JSONData.Free;
        end;

      finally
        Builder.Free;
      end;
    finally
      Owner.Free;
    end;
    WriteLn('test_aipromptbuilder COMPLETED SUCCESSFULLY.');
  except
    on E: Exception do
    begin
      WriteLn('EXCEPTION IN TEST: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
