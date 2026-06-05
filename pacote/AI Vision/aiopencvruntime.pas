unit aiopencvruntime;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DynLibs, fpjson, jsonparser, aiplatform, airuntimepaths;

type
  TStringArray = array of string;

function AIGetOpenCVPlatformFolder: string;
function AIGetOpenCVLibraryNames: TStringArray;
function AIFindOpenCVNativeLibrary(
  const AManualPath, AManualName: string;
  AUseBundled: Boolean;
  out AResolvedPath: string;
  out AError: string;
  out ALogOutput: string
): Boolean;
function AILoadOpenCVLibrary(const ALibraryPath: string; out AHandle: TLibHandle; out AError: string): Boolean;

implementation

function AIGetOpenCVPlatformFolder: string;
var
  LOS, LArch: string;
begin
  LOS := AIOSName;
  LArch := AIArchitectureName;
  if LOS = 'windows' then
    Result := 'windows/' + LArch + '/bin/'
  else
    Result := 'linux/' + LArch + '/lib/';
end;

function AIGetOpenCVLibraryNames: TStringArray;
begin
  {$IFDEF MSWINDOWS}
  SetLength(Result, 7);
  Result[0] := 'opencv_world.dll';
  Result[1] := 'opencv_world4110.dll';
  Result[2] := 'opencv_world4100.dll';
  Result[3] := 'opencv_world490.dll';
  Result[4] := 'opencv_world480.dll';
  Result[5] := 'opencv_world470.dll';
  Result[6] := 'opencv_world460.dll';
  {$ELSE}
  SetLength(Result, 7);
  Result[0] := 'libopencv_world.so';
  Result[1] := 'libopencv_world.so.411';
  Result[2] := 'libopencv_world.so.410';
  Result[3] := 'libopencv_world.so.409';
  Result[4] := 'libopencv_world.so.408';
  Result[5] := 'libopencv_world.so.407';
  Result[6] := 'libopencv_world.so.406';
  {$ENDIF}
end;

function ExtractVersionNumber(const AFileName: string): Integer;
var
  I: Integer;
  LNumStr: string;
begin
  Result := 0;
  LNumStr := '';
  for I := 1 to Length(AFileName) do
  begin
    if AFileName[I] in ['0'..'9'] then
      LNumStr := LNumStr + AFileName[I];
  end;
  if LNumStr <> '' then
    TryStrToInt(LNumStr, Result);
end;

function AIFindOpenCVNativeLibrary(
  const AManualPath, AManualName: string;
  AUseBundled: Boolean;
  out AResolvedPath: string;
  out AError: string;
  out ALogOutput: string
): Boolean;
var
  LPlatformFolder, LManifestPath, LSearchPath: string;
  LBaseDir, LCandidateDir, LFilePattern: string;
  LList: TStringList;
  I, LMaxVersion, LCurVersion: Integer;
  LSrc: TSearchRec;
  LPreferredName: string;
  LJsonData: TJSONData;
  LJsonObj: TJSONObject;
  LPrefObj: TJSONObject;
  LPlatformObj: TJSONObject;
  LFileContent: string;
  LJSONParser: TJSONParser;
  LTriedPaths: TStringList;
begin
  AResolvedPath := '';
  AError := '';
  ALogOutput := 'OpenCV runtime detection' + sLineBreak;
  ALogOutput := ALogOutput + 'Search mode: bundled runtime first' + sLineBreak;
  ALogOutput := ALogOutput + 'OS detected: ' + AIOSName + sLineBreak;
  ALogOutput := ALogOutput + 'CPU detected: ' + AIArchitectureName + sLineBreak;

  LTriedPaths := TStringList.Create;
  LList := TStringList.Create;
  try
    LPlatformFolder := AIGetOpenCVPlatformFolder;
    ALogOutput := ALogOutput + 'Expected runtime folder: runtime/opencv/' + LPlatformFolder + sLineBreak;

    // 1. Check manual configuration first if specified
    if (AManualPath <> '') and (AManualName <> '') then
    begin
      LSearchPath := AICombinePath(AManualPath, AManualName);
      if FileExists(LSearchPath) then
      begin
        AResolvedPath := LSearchPath;
        ALogOutput := ALogOutput + 'Resolved library (Manual override): ' + AResolvedPath + sLineBreak;
        Result := True;
        Exit;
      end
      else
        LTriedPaths.Add(LSearchPath);
    end;

    // 2. Find local runtime root by scanning up directories
    LBaseDir := ExtractFilePath(ParamStr(0));
    LManifestPath := '';
    for I := 0 to 5 do
    begin
      LCandidateDir := AICombinePath(LBaseDir, 'runtime' + DirectorySeparator + 'opencv' + DirectorySeparator);
      if DirectoryExists(LCandidateDir) then
      begin
        LManifestPath := LCandidateDir + 'manifest.json';
        LBaseDir := LCandidateDir;
        Break;
      end;
      LBaseDir := AICombinePath(LBaseDir, '..' + DirectorySeparator);
    end;

    LPreferredName := '';
    if (LManifestPath <> '') and FileExists(LManifestPath) then
    begin
      ALogOutput := ALogOutput + 'Manifest: ' + LManifestPath + sLineBreak;
      try
        with TStringList.Create do
        try
          LoadFromFile(LManifestPath);
          LFileContent := Text;
        finally
          Free;
        end;
        LJSONParser := TJSONParser.Create(LFileContent);
        try
          LJsonData := LJSONParser.Parse;
          if Assigned(LJsonData) and (LJsonData.JSONType = jtObject) then
          begin
            LJsonObj := TJSONObject(LJsonData);
            LPrefObj := LJsonObj.Find('preferred', jtObject) as TJSONObject;
            if Assigned(LPrefObj) then
            begin
              LPlatformObj := LPrefObj.Find(AIOSName, jtObject) as TJSONObject;
              if Assigned(LPlatformObj) then
                LPreferredName := LPlatformObj.Get(AIArchitectureName, '');
            end;
          end;
        finally
          LJSONParser.Free;
          if Assigned(LJsonData) then LJsonData.Free;
        end;
      except
        on E: Exception do
          ALogOutput := ALogOutput + 'Warning parsing manifest.json: ' + E.Message + sLineBreak;
      end;
    end;

    // 3. Search bundled folder
    if AUseBundled and (LManifestPath <> '') then
    begin
      LSearchPath := AICombinePath(LBaseDir, LPlatformFolder);
      if DirectoryExists(LSearchPath) then
      begin
        // If manifest specifies preferred and exists
        if (LPreferredName <> '') and FileExists(AICombinePath(LSearchPath, LPreferredName)) then
        begin
          AResolvedPath := AICombinePath(LSearchPath, LPreferredName);
          ALogOutput := ALogOutput + 'Preferred library from manifest: ' + LPreferredName + sLineBreak;
          ALogOutput := ALogOutput + 'Resolved library: ' + AResolvedPath + sLineBreak;
          Result := True;
          Exit;
        end;

        // Otherwise scan and find matching files with highest version
        {$IFDEF MSWINDOWS}
        LFilePattern := 'opencv_world*.dll';
        {$ELSE}
        LFilePattern := 'libopencv_world.so*';
        {$ENDIF}

        LMaxVersion := -1;
        LPreferredName := '';
        if FindFirst(LSearchPath + LFilePattern, faAnyFile, LSrc) = 0 then
        begin
          try
            repeat
              LCurVersion := ExtractVersionNumber(LSrc.Name);
              if LCurVersion > LMaxVersion then
              begin
                LMaxVersion := LCurVersion;
                LPreferredName := LSrc.Name;
              end
              else if (LCurVersion = LMaxVersion) and (LPreferredName = '') then
                LPreferredName := LSrc.Name;
            until FindNext(LSrc) <> 0;
          finally
            FindClose(LSrc);
          end;
        end;

        if LPreferredName <> '' then
        begin
          AResolvedPath := AICombinePath(LSearchPath, LPreferredName);
          ALogOutput := ALogOutput + 'Resolved library (highest version found): ' + AResolvedPath + sLineBreak;
          Result := True;
          Exit;
        end;
      end;
      LTriedPaths.Add(AICombinePath(LBaseDir, LPlatformFolder));
    end;

    // 4. Try executable directory as fallback
    LSearchPath := ExtractFilePath(ParamStr(0));
    for I := 0 to High(AIGetOpenCVLibraryNames) do
    begin
      LCandidateDir := AICombinePath(LSearchPath, AIGetOpenCVLibraryNames[I]);
      if FileExists(LCandidateDir) then
      begin
        AResolvedPath := LCandidateDir;
        ALogOutput := ALogOutput + 'Resolved library (beside executable): ' + AResolvedPath + sLineBreak;
        Result := True;
        Exit;
      end
      else
        LTriedPaths.Add(LCandidateDir);
    end;

    // 5. Try PATH / LD_LIBRARY_PATH or common directories
    for I := 0 to High(AIGetOpenCVLibraryNames) do
    begin
      {$IFDEF MSWINDOWS}
      LCandidateDir := AIGetOpenCVLibraryNames[I]; // system loader will search PATH
      {$ELSE}
      LCandidateDir := '/usr/lib/' + AIGetOpenCVLibraryNames[I];
      if not FileExists(LCandidateDir) then
        LCandidateDir := '/usr/local/lib/' + AIGetOpenCVLibraryNames[I];
      {$ENDIF}

      if FileExists(LCandidateDir) or (LCandidateDir = AIGetOpenCVLibraryNames[I]) then
      begin
        // Attempt trial load to check availability
        AResolvedPath := LCandidateDir;
        ALogOutput := ALogOutput + 'Resolved library (system candidate): ' + AResolvedPath + sLineBreak;
        Result := True;
        Exit;
      end
      else
        LTriedPaths.Add(LCandidateDir);
    end;

    // 6. Complete failure
    AError := 'OpenCV native library not found.' + sLineBreak;
    AError := AError + 'Tried folders/paths:' + sLineBreak;
    for I := 0 to LTriedPaths.Count - 1 do
      AError := AError + '  - ' + LTriedPaths.Strings[I] + sLineBreak;
    AError := AError + 'Configure OpenCVLibraryPath or copy correct library files to runtime/opencv/' + LPlatformFolder + sLineBreak;
    ALogOutput := ALogOutput + AError + sLineBreak;
    Result := False;

  finally
    LList.Free;
    LTriedPaths.Free;
  end;
end;

function AILoadOpenCVLibrary(const ALibraryPath: string; out AHandle: TLibHandle; out AError: string): Boolean;
var
  LSize: Int64;
  LSR: TSearchRec;
begin
  AHandle := NilHandle;
  AError := '';
  Result := False;

  LSize := 0;
  if FindFirst(ALibraryPath, faAnyFile, LSR) = 0 then
  begin
    LSize := LSR.Size;
    FindClose(LSR);
  end;

  if (LSize > 0) and (LSize < 102400) then
  begin
    AError := 'The file ' + ALibraryPath + ' is a placeholder/text file. Please download the real binary DLL/SO and overwrite it.';
    Exit;
  end;

  try
    AHandle := SafeLoadLibrary(ALibraryPath);
    if AHandle <> NilHandle then
      Result := True
    else
      AError := 'Failed to load OpenCV binary library: ' + ALibraryPath + ' (NilHandle). Ensure OS/Architecture match.';
  except
    on E: Exception do
      AError := 'Exception loading OpenCV library: ' + E.Message;
  end;
end;

end.
