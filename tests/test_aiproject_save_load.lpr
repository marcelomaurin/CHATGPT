program test_aiproject_save_load;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, aiproject, fpjson, jsonparser;

var
  Proj: TAIProject;
  TempFile: string;
  List: TStringList;
  Data: TJSONData;
  Obj: TJSONObject;
begin
  WriteLn('Running test_aiproject_save_load...');
  TempFile := ExpandFileName('temp_test_project.json');
  
  // Clean up if temp file exists
  if FileExists(TempFile) then
    DeleteFile(TempFile);

  Proj := TAIProject.Create(nil);
  try
    Proj.ProjectName := 'Test Suite Project';
    Proj.Description := 'A project for unit testing';
    Proj.Token := 'sk-SecretAPIKeyPlaceholder';
    Proj.LocalURL := 'http://localhost:8080';
    Proj.SafeMode := True;
    
    // Save with SaveToken = False (default)
    Proj.SaveToken := False;
    Proj.SaveToFile(TempFile);
    
    if not FileExists(TempFile) then
      raise Exception.Create('Test failed: Configuration file was not created.');
      
    // Load and check that Token is missing
    List := TStringList.Create;
    try
      List.LoadFromFile(TempFile);
      Data := GetJSON(List.Text);
      try
        if Data.JSONType <> jtObject then
          raise Exception.Create('Test failed: Saved JSON is not an object.');
        Obj := TJSONObject(Data);
        if Obj.IndexOfName('Token') >= 0 then
          raise Exception.Create('Test failed: API Key Token was leaked and saved in JSON!');
        if Obj.Strings['ProjectName'] <> 'Test Suite Project' then
          raise Exception.Create('Test failed: ProjectName was not saved correctly.');
        if not Obj.Booleans['SafeMode'] then
          raise Exception.Create('Test failed: SafeMode was not saved correctly.');
      finally
        Data.Free;
      end;
    finally
      List.Free;
    end;
    
    // Save with SaveToken = True
    Proj.SaveToken := True;
    Proj.SaveToFile(TempFile);
    
    // Load and check that Token is present
    List := TStringList.Create;
    try
      List.LoadFromFile(TempFile);
      Data := GetJSON(List.Text);
      try
        Obj := TJSONObject(Data);
        if Obj.IndexOfName('Token') < 0 then
          raise Exception.Create('Test failed: Token was not saved even with SaveToken=True.');
        if Obj.Strings['Token'] <> 'sk-SecretAPIKeyPlaceholder' then
          raise Exception.Create('Test failed: Loaded token does not match.');
      finally
        Data.Free;
      end;
    finally
      List.Free;
    end;

    // Test LoadFromFile
    Proj.Token := '';
    Proj.LoadFromFile(TempFile);
    if Proj.Token <> 'sk-SecretAPIKeyPlaceholder' then
      raise Exception.Create('Test failed: Token was not loaded correctly.');
    if Proj.ProjectName <> 'Test Suite Project' then
      raise Exception.Create('Test failed: Loaded ProjectName mismatch.');

  finally
    Proj.Free;
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
  WriteLn('test_aiproject_save_load COMPLETED SUCCESSFULLY.');
end.
