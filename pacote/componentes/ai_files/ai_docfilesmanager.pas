unit ai_docfilesmanager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, fpjson, jsonparser, contnrs;

type
  TAIDocFileEvent = procedure(
    Sender: TObject;
    const Grupo: string;
    const SubGrupo: string;
    const FileName: string
  ) of object;

  TAIDocMessageEvent = procedure(
    Sender: TObject;
    const Msg: string
  ) of object;

  { TAIDocGroup }
  TAIDocGroup = class
  public
    ID: Integer;
    Name: string;
    Path: string;
    constructor Create(AID: Integer; const AName, APath: string);
  end;

  { TAIDocSubGroup }
  TAIDocSubGroup = class
  public
    ID: Integer;
    GroupID: Integer;
    Name: string;
    Path: string;
    constructor Create(AID, AGroupID: Integer; const AName, APath: string);
  end;

  { TAI_DOCFILESMANAGER }
  TAI_DOCFILESMANAGER = class(TComponent)
  private
    FStoragePath: string;
    FGroups: TStrings;
    FAutoCreateDirs: Boolean;
    FAllowOverwrite: Boolean;
    FMaxGroupNameLength: Integer;
    FActive: Boolean;
    FLastError: string;

    // Internal manifest states
    FLastGroupId: Integer;
    FLastSubGroupId: Integer;
    FGroupsData: TObjectList;    // List of TAIDocGroup
    FSubGroupsData: TObjectList; // List of TAIDocSubGroup

    FOnError: TAIDocMessageEvent;
    FOnAfterInitialize: TNotifyEvent;
    FOnAfterAddGrupo: TAIDocMessageEvent;
    FOnAfterDelGrupo: TAIDocMessageEvent;
    FOnAfterAddSubGrupo: TAIDocMessageEvent;
    FOnAfterDelSubGrupo: TAIDocMessageEvent;
    FOnFileUploaded: TAIDocFileEvent;
    FOnFileDeleted: TAIDocFileEvent;
    FOnFileLoaded: TAIDocFileEvent;

    procedure SetStoragePath(const AValue: string);
    procedure SetGroups(AValue: TStrings);

    function ValidateName(const AName: string; const AMaxLen: Integer = 0): Boolean;
    function ValidateFileName(const AFileName: string): Boolean;
    function SafePathCombine(const Parts: array of string): string;
    function IsPathInsideStorage(const APath: string): Boolean;

    procedure SetError(const AMessage: string);
    procedure ClearError;

    function LoadManifest: Boolean;
    function SaveManifest: Boolean;
    procedure ClearManifestData;
    function SyncFromPhysicalFolders: Boolean;
    function DeleteDirectorySafe(const ADir: string; const Force: Boolean): Boolean;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Initialize: Boolean;

    function AddGrupo(const Nome: string): Integer;
    function DelGrupo(const Grupo: string; const Force: Boolean = False): Boolean; overload;
    function DelGrupo(const IdGrupo: Integer; const Force: Boolean = False): Boolean; overload;
    procedure ListGrupos(ALista: TStrings);
    function GrupoExists(const Grupo: string): Boolean; overload;
    function GrupoExists(const IdGrupo: Integer): Boolean; overload;
    function GetGrupoPath(const Grupo: string): string; overload;
    function GetGrupoPath(const IdGrupo: Integer): string; overload;
    function GetGrupoNameById(const IdGrupo: Integer): string;
    function GetGrupoIdByName(const Grupo: string): Integer;

    function AddSubGrupo(const IdGrupo: Integer; const SubGrupo: string): Integer; overload;
    function AddSubGrupo(const Grupo: string; const SubGrupo: string): Integer; overload;

    function DelSubGrupo(const Grupo: string; const SubGrupo: string; const Force: Boolean = False): Boolean; overload;
    function DelSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; const Force: Boolean = False): Boolean; overload;

    procedure ListSubGrupo(const Grupo: string; ALista: TStrings); overload;
    procedure ListSubGrupo(const IdGrupo: Integer; ALista: TStrings); overload;

    function SubGrupoExists(const Grupo: string; const SubGrupo: string): Boolean; overload;
    function SubGrupoExists(const IdGrupo: Integer; const IdSubGrupo: Integer): Boolean; overload;

    function GetSubGrupoPath(const Grupo: string; const SubGrupo: string): string; overload;
    function GetSubGrupoPath(const IdGrupo: Integer; const IdSubGrupo: Integer): string; overload;

    function GetSubGrupoNameById(const IdSubGrupo: Integer): string;
    function GetSubGrupoIdByName(const Grupo: string; const SubGrupo: string): Integer;

    function UploadSubGrupo(const Grupo: string; const SubGrupo: string; const SourceFile: string): Boolean; overload;
    function UploadSubGrupo(const Grupo: string; const SubGrupo: string; const SourceFile: string; const NewFileName: string): Boolean; overload;
    function UploadSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; const SourceFile: string): Boolean; overload;
    function UploadSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; const SourceFile: string; const NewFileName: string): Boolean; overload;

    function LoadSubGrupo(const Grupo: string; const SubGrupo: string; const FileName: string; const DestFile: string): Boolean; overload;
    function LoadSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; const FileName: string; const DestFile: string): Boolean; overload;

    procedure GetFilesSubGrupo(const Grupo: string; const SubGrupo: string; ALista: TStrings); overload;
    procedure GetFilesSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; ALista: TStrings); overload;

    function DelFileSubGrupo(const Grupo: string; const SubGrupo: string; const FileName: string): Boolean; overload;
    function DelFileSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; const FileName: string): Boolean; overload;

    function GetDocument(const Grupo: string; const SubGrupo: string; const FileName: string): string; overload;
    function GetDocument(const IdGrupo: Integer; const IdSubGrupo: Integer; const FileName: string): string; overload;

    // Compatibility implementation for GetFullDocument as specified:
    function GetFullDocument(const Grupo: string; const SubGrupo: string; const FileName: string): string; overload;
    function GetFullDocument(const IdGrupo: Integer; const IdSubGrupo: Integer; const FileName: string): string; overload;

  published
    property StoragePath: string read FStoragePath write SetStoragePath;
    property Groups: TStrings read FGroups write SetGroups;
    property AutoCreateDirs: Boolean read FAutoCreateDirs write FAutoCreateDirs default True;
    property AllowOverwrite: Boolean read FAllowOverwrite write FAllowOverwrite default False;
    property MaxGroupNameLength: Integer read FMaxGroupNameLength write FMaxGroupNameLength default 18;
    property Active: Boolean read FActive;
    property LastError: string read FLastError;

    property OnError: TAIDocMessageEvent read FOnError write FOnError;
    property OnAfterInitialize: TNotifyEvent read FOnAfterInitialize write FOnAfterInitialize;
    property OnAfterAddGrupo: TAIDocMessageEvent read FOnAfterAddGrupo write FOnAfterAddGrupo;
    property OnAfterDelGrupo: TAIDocMessageEvent read FOnAfterDelGrupo write FOnAfterDelGrupo;
    property OnAfterAddSubGrupo: TAIDocMessageEvent read FOnAfterAddSubGrupo write FOnAfterAddSubGrupo;
    property OnAfterDelSubGrupo: TAIDocMessageEvent read FOnAfterDelSubGrupo write FOnAfterDelSubGrupo;
    property OnFileUploaded: TAIDocFileEvent read FOnFileUploaded write FOnFileUploaded;
    property OnFileDeleted: TAIDocFileEvent read FOnFileDeleted write FOnFileDeleted;
    property OnFileLoaded: TAIDocFileEvent read FOnFileLoaded write FOnFileLoaded;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Files', [TAI_DOCFILESMANAGER]);
end;

{ TAIDocGroup }

constructor TAIDocGroup.Create(AID: Integer; const AName, APath: string);
begin
  inherited Create;
  ID := AID;
  Name := AName;
  Path := APath;
end;

{ TAIDocSubGroup }

constructor TAIDocSubGroup.Create(AID, AGroupID: Integer; const AName, APath: string);
begin
  inherited Create;
  ID := AID;
  GroupID := AGroupID;
  Name := AName;
  Path := APath;
end;

{ TAI_DOCFILESMANAGER }

constructor TAI_DOCFILESMANAGER.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FGroups := TStringList.Create;
  FAutoCreateDirs := True;
  FAllowOverwrite := False;
  FMaxGroupNameLength := 18;
  FActive := False;
  FLastError := '';

  FLastGroupId := 0;
  FLastSubGroupId := 0;
  FGroupsData := TObjectList.Create(True);
  FSubGroupsData := TObjectList.Create(True);
end;

destructor TAI_DOCFILESMANAGER.Destroy;
begin
  FGroups.Free;
  FGroupsData.Free;
  FSubGroupsData.Free;
  inherited Destroy;
end;

procedure TAI_DOCFILESMANAGER.SetStoragePath(const AValue: string);
begin
  if FStoragePath = AValue then Exit;
  FStoragePath := AValue;
  FActive := False; // Require re-initialization
end;

procedure TAI_DOCFILESMANAGER.SetGroups(AValue: TStrings);
begin
  FGroups.Assign(AValue);
end;

procedure TAI_DOCFILESMANAGER.SetError(const AMessage: string);
begin
  FLastError := AMessage;
  if Assigned(FOnError) then
    FOnError(Self, AMessage);
end;

procedure TAI_DOCFILESMANAGER.ClearError;
begin
  FLastError := '';
end;

function TAI_DOCFILESMANAGER.ValidateName(const AName: string; const AMaxLen: Integer = 0): Boolean;
var
  I: Integer;
const
  InvalidChars: set of Char = ['\', '/', ':', '*', '?', '"', '<', '>', '|'];
begin
  Result := False;
  if Trim(AName) = '' then Exit;
  if (AMaxLen > 0) and (Length(AName) > AMaxLen) then Exit;
  if Pos('..', AName) > 0 then Exit;

  for I := 1 to Length(AName) do
  begin
    if AName[I] in InvalidChars then Exit;
  end;
  Result := True;
end;

function TAI_DOCFILESMANAGER.ValidateFileName(const AFileName: string): Boolean;
var
  I: Integer;
const
  InvalidChars: set of Char = ['\', '/', ':', '*', '?', '"', '<', '>', '|'];
begin
  Result := False;
  if Trim(AFileName) = '' then Exit;
  if Pos('..', AFileName) > 0 then Exit;

  for I := 1 to Length(AFileName) do
  begin
    if AFileName[I] in InvalidChars then Exit;
  end;
  Result := True;
end;

function TAI_DOCFILESMANAGER.SafePathCombine(const Parts: array of string): string;
var
  I: Integer;
  Part: string;
begin
  Result := FStoragePath;
  for I := Low(Parts) to High(Parts) do
  begin
    Part := Parts[I];
    if Part <> '' then
    begin
      Part := StringReplace(Part, '/', PathDelim, [rfReplaceAll]);
      Part := StringReplace(Part, '\', PathDelim, [rfReplaceAll]);
      if (Part = '..') or (Pos('..' + PathDelim, Part) > 0) or (Pos(PathDelim + '..', Part) > 0) then
        raise Exception.Create('Path traversal attempt detected');
      Result := IncludeTrailingPathDelimiter(Result) + Part;
    end;
  end;
end;

function TAI_DOCFILESMANAGER.IsPathInsideStorage(const APath: string): Boolean;
var
  CanonicalStorage, CanonicalPath: string;
begin
  if FStoragePath = '' then Exit(False);
  CanonicalStorage := IncludeTrailingPathDelimiter(ExpandFileName(FStoragePath));
  CanonicalPath := IncludeTrailingPathDelimiter(ExpandFileName(APath));
  Result := SameText(Copy(CanonicalPath, 1, Length(CanonicalStorage)), CanonicalStorage);
end;

procedure TAI_DOCFILESMANAGER.ClearManifestData;
begin
  FGroupsData.Clear;
  FSubGroupsData.Clear;
  FLastGroupId := 0;
  FLastSubGroupId := 0;
end;

function TAI_DOCFILESMANAGER.LoadManifest: Boolean;
var
  ManifestPath, FileContent: string;
  StrList: TStringList;
  Parser: TJSONParser;
  Data: TJSONData;
  RootObj: TJSONObject;
  GroupsArr, SubGroupsArr: TJSONArray;
  I: Integer;
  GItem, SItem: TJSONObject;
begin
  Result := False;
  ClearManifestData;
  ManifestPath := SafePathCombine(['docfilesmanager.json']);
  if not FileExists(ManifestPath) then
  begin
    Result := True; // Valid state: manifest doesn't exist yet
    Exit;
  end;

  StrList := TStringList.Create;
  try
    try
      StrList.LoadFromFile(ManifestPath);
      FileContent := StrList.Text;
    except
      on E: Exception do
      begin
        SetError('Failed to read manifest file: ' + E.Message);
        Exit;
      end;
    end;
  finally
    StrList.Free;
  end;

  if Trim(FileContent) = '' then
  begin
    Result := True;
    Exit;
  end;

  Parser := TJSONParser.Create(FileContent);
  try
    try
      Data := Parser.Parse;
      if Data is TJSONObject then
      begin
        RootObj := TJSONObject(Data);
        FLastGroupId := RootObj.Get('last_group_id', 0);
        FLastSubGroupId := RootObj.Get('last_subgroup_id', 0);
        
        GroupsArr := RootObj.Find('groups') as TJSONArray;
        if GroupsArr <> nil then
        begin
          for I := 0 to GroupsArr.Count - 1 do
          begin
            if GroupsArr.Types[I] = jtObject then
            begin
              GItem := TJSONObject(GroupsArr.Objects[I]);
              FGroupsData.Add(TAIDocGroup.Create(
                GItem.Get('id', 0),
                GItem.Get('name', ''),
                GItem.Get('path', '')
              ));
            end;
          end;
        end;

        SubGroupsArr := RootObj.Find('subgroups') as TJSONArray;
        if SubGroupsArr <> nil then
        begin
          for I := 0 to SubGroupsArr.Count - 1 do
          begin
            if SubGroupsArr.Types[I] = jtObject then
            begin
              SItem := TJSONObject(SubGroupsArr.Objects[I]);
              FSubGroupsData.Add(TAIDocSubGroup.Create(
                SItem.Get('id', 0),
                SItem.Get('group_id', 0),
                SItem.Get('name', ''),
                SItem.Get('path', '')
              ));
            end;
          end;
        end;
        Result := True;
      end
      else
      begin
        SetError('Manifest JSON format is not a root object');
        Data.Free;
      end;
    except
      on E: Exception do
      begin
        SetError('Parser failed: ' + E.Message);
      end;
    end;
  finally
    Parser.Free;
  end;
end;

function TAI_DOCFILESMANAGER.SaveManifest: Boolean;
var
  RootObj: TJSONObject;
  GroupsArr, SubGroupsArr: TJSONArray;
  GItem, SItem: TJSONObject;
  I: Integer;
  Group: TAIDocGroup;
  SubGroup: TAIDocSubGroup;
  StrList: TStringList;
  ManifestPath: string;
begin
  Result := False;
  ManifestPath := SafePathCombine(['docfilesmanager.json']);
  RootObj := TJSONObject.Create;
  try
    RootObj.Add('version', '1.0');
    RootObj.Add('storage_path', FStoragePath);
    RootObj.Add('last_group_id', FLastGroupId);
    RootObj.Add('last_subgroup_id', FLastSubGroupId);

    GroupsArr := TJSONArray.Create;
    for I := 0 to FGroupsData.Count - 1 do
    begin
      Group := TAIDocGroup(FGroupsData[I]);
      GItem := TJSONObject.Create;
      GItem.Add('id', Group.ID);
      GItem.Add('name', Group.Name);
      GItem.Add('path', Group.Path);
      GroupsArr.Add(GItem);
    end;
    RootObj.Add('groups', GroupsArr);

    SubGroupsArr := TJSONArray.Create;
    for I := 0 to FSubGroupsData.Count - 1 do
    begin
      SubGroup := TAIDocSubGroup(FSubGroupsData[I]);
      SItem := TJSONObject.Create;
      SItem.Add('id', SubGroup.ID);
      SItem.Add('group_id', SubGroup.GroupID);
      SItem.Add('name', SubGroup.Name);
      SItem.Add('path', SubGroup.Path);
      SubGroupsArr.Add(SItem);
    end;
    RootObj.Add('subgroups', SubGroupsArr);

    StrList := TStringList.Create;
    try
      try
        StrList.Text := RootObj.FormatJSON();
        StrList.SaveToFile(ManifestPath);
        Result := True;
      except
        on E: Exception do
          SetError('Failed to save manifest file: ' + E.Message);
      end;
    finally
      StrList.Free;
    end;
  finally
    RootObj.Free;
  end;
end;

function TAI_DOCFILESMANAGER.SyncFromPhysicalFolders: Boolean;
var
  SearchRecGroup, SearchRecSub: TSearchRec;
  GroupPath: string;
  GroupID: Integer;
begin
  Result := True;
  // If manifest load was empty or not exist, we synchronize what exists physically
  if FindFirst(IncludeTrailingPathDelimiter(FStoragePath) + '*', faDirectory, SearchRecGroup) = 0 then
  begin
    repeat
      if ((SearchRecGroup.Attr and faDirectory) <> 0) and 
         (SearchRecGroup.Name <> '.') and (SearchRecGroup.Name <> '..') and 
         (ValidateName(SearchRecGroup.Name, FMaxGroupNameLength)) then
      begin
        if not GrupoExists(SearchRecGroup.Name) then
        begin
          Inc(FLastGroupId);
          FGroupsData.Add(TAIDocGroup.Create(FLastGroupId, SearchRecGroup.Name, SearchRecGroup.Name));
        end;

        GroupID := GetGrupoIdByName(SearchRecGroup.Name);
        GroupPath := SafePathCombine([SearchRecGroup.Name]);

        if FindFirst(IncludeTrailingPathDelimiter(GroupPath) + '*', faDirectory, SearchRecSub) = 0 then
        begin
          repeat
            if ((SearchRecSub.Attr and faDirectory) <> 0) and 
               (SearchRecSub.Name <> '.') and (SearchRecSub.Name <> '..') and 
               (ValidateName(SearchRecSub.Name)) then
            begin
              if not SubGrupoExists(GroupID, GetSubGrupoIdByName(SearchRecGroup.Name, SearchRecSub.Name)) then
              begin
                Inc(FLastSubGroupId);
                FSubGroupsData.Add(TAIDocSubGroup.Create(
                  FLastSubGroupId,
                  GroupID,
                  SearchRecSub.Name,
                  SearchRecGroup.Name + PathDelim + SearchRecSub.Name
                ));
              end;
            end;
          until FindNext(SearchRecSub) <> 0;
          FindClose(SearchRecSub);
        end;
      end;
    until FindNext(SearchRecGroup) <> 0;
    FindClose(SearchRecGroup);
  end;
end;

function TAI_DOCFILESMANAGER.Initialize: Boolean;
var
  I: Integer;
  GName: string;
begin
  Result := False;
  FActive := False;
  ClearError;

  if FStoragePath = '' then
  begin
    SetError('StoragePath is not configured');
    Exit;
  end;

  try
    if not DirectoryExists(FStoragePath) then
    begin
      if FAutoCreateDirs then
      begin
        if not ForceDirectories(FStoragePath) then
        begin
          SetError('Could not create base directory: ' + FStoragePath);
          Exit;
        end;
      end
      else
      begin
        SetError('Base directory does not exist and AutoCreateDirs is False');
        Exit;
      end;
    end;

    // Check read/write permission
    // A simple test: write a temp file
    try
      with TStringList.Create do
      begin
        Text := 'test';
        SaveToFile(SafePathCombine(['.permtest']));
        Free;
      end;
      DeleteFile(SafePathCombine(['.permtest']));
    except
      on E: Exception do
      begin
        SetError('No write permission to StoragePath: ' + E.Message);
        Exit;
      end;
    end;

    // Load or create manifest
    if not LoadManifest then
    begin
      // If load failed, do not activate
      Exit;
    end;

    // Synchronize physical directories with manifest
    SyncFromPhysicalFolders;

    // Validate and create any groups from Groups property
    for I := 0 to FGroups.Count - 1 do
    begin
      GName := Trim(FGroups[I]);
      if GName <> '' then
      begin
        if not GrupoExists(GName) then
        begin
          if AddGrupo(GName) < 0 then
          begin
            // SetError already prefilled
            Exit;
          end;
        end;
      end;
    end;

    SaveManifest;
    FActive := True;
    Result := True;

    if Assigned(FOnAfterInitialize) then
      FOnAfterInitialize(Self);
  except
    on E: Exception do
    begin
      SetError('Initialization failed: ' + E.Message);
    end;
  end;
end;

function TAI_DOCFILESMANAGER.AddGrupo(const Nome: string): Integer;
var
  GPath: string;
  NewGroup: TAIDocGroup;
begin
  Result := -1;
  ClearError;

  if not ValidateName(Nome, FMaxGroupNameLength) then
  begin
    SetError('Invalid group name: "' + Nome + '". Max length: ' + IntToStr(FMaxGroupNameLength) + ' chars.');
    Exit;
  end;

  if GrupoExists(Nome) then
  begin
    SetError('Group already exists: ' + Nome);
    Exit;
  end;

  try
    GPath := SafePathCombine([Nome]);
    if FAutoCreateDirs then
    begin
      if not ForceDirectories(GPath) then
      begin
        SetError('Failed to create group directory: ' + GPath);
        Exit;
      end;
    end;

    Inc(FLastGroupId);
    NewGroup := TAIDocGroup.Create(FLastGroupId, Nome, Nome);
    FGroupsData.Add(NewGroup);
    
    SaveManifest;
    Result := NewGroup.ID;

    if Assigned(FOnAfterAddGrupo) then
      FOnAfterAddGrupo(Self, Nome);
  except
    on E: Exception do
      SetError('AddGrupo error: ' + E.Message);
  end;
end;

function TAI_DOCFILESMANAGER.DeleteDirectorySafe(const ADir: string; const Force: Boolean): Boolean;
var
  SearchRec: TSearchRec;
  ItemPath: string;
begin
  Result := False;
  if not IsPathInsideStorage(ADir) then Exit;

  if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        if not Force then
        begin
          FindClose(SearchRec);
          Exit; // Not empty and not forcing
        end;

        ItemPath := IncludeTrailingPathDelimiter(ADir) + SearchRec.Name;
        if (SearchRec.Attr and faDirectory) <> 0 then
        begin
          if not DeleteDirectorySafe(ItemPath, True) then
          begin
            FindClose(SearchRec);
            Exit;
          end;
        end
        else
        begin
          if not DeleteFile(ItemPath) then
          begin
            FindClose(SearchRec);
            Exit;
          end;
        end;
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;

  Result := RemoveDir(ADir);
end;

function TAI_DOCFILESMANAGER.DelGrupo(const Grupo: string; const Force: Boolean = False): Boolean;
begin
  Result := DelGrupo(GetGrupoIdByName(Grupo), Force);
end;

function TAI_DOCFILESMANAGER.DelGrupo(const IdGrupo: Integer; const Force: Boolean = False): Boolean;
var
  I: Integer;
  Group: TAIDocGroup;
  GPath: string;
begin
  Result := False;
  ClearError;

  Group := nil;
  for I := 0 to FGroupsData.Count - 1 do
  begin
    if TAIDocGroup(FGroupsData[I]).ID = IdGrupo then
    begin
      Group := TAIDocGroup(FGroupsData[I]);
      Break;
    end;
  end;

  if Group = nil then
  begin
    SetError('Group ID ' + IntToStr(IdGrupo) + ' not found');
    Exit;
  end;

  try
    GPath := SafePathCombine([Group.Path]);
    if DirectoryExists(GPath) then
    begin
      if not DeleteDirectorySafe(GPath, Force) then
      begin
        SetError('Failed to remove group directory: ' + GPath + ' (ensure it is empty or force is True)');
        Exit;
      end;
    end;

    // Remove subgroups belonging to this group
    I := FSubGroupsData.Count - 1;
    while I >= 0 do
    begin
      if TAIDocSubGroup(FSubGroupsData[I]).GroupID = IdGrupo then
        FSubGroupsData.Delete(I);
      Dec(I);
    end;

    FGroupsData.Remove(Group);
    SaveManifest;
    Result := True;

    if Assigned(FOnAfterDelGrupo) then
      FOnAfterDelGrupo(Self, Group.Name);
  except
    on E: Exception do
      SetError('DelGrupo error: ' + E.Message);
  end;
end;

procedure TAI_DOCFILESMANAGER.ListGrupos(ALista: TStrings);
var
  I: Integer;
begin
  if ALista = nil then Exit;
  ALista.Clear;
  for I := 0 to FGroupsData.Count - 1 do
  begin
    ALista.Add(TAIDocGroup(FGroupsData[I]).Name);
  end;
end;

function TAI_DOCFILESMANAGER.GrupoExists(const Grupo: string): Boolean;
begin
  Result := GetGrupoIdByName(Grupo) >= 0;
end;

function TAI_DOCFILESMANAGER.GrupoExists(const IdGrupo: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FGroupsData.Count - 1 do
  begin
    if TAIDocGroup(FGroupsData[I]).ID = IdGrupo then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TAI_DOCFILESMANAGER.GetGrupoPath(const Grupo: string): string;
begin
  Result := GetGrupoPath(GetGrupoIdByName(Grupo));
end;

function TAI_DOCFILESMANAGER.GetGrupoPath(const IdGrupo: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FGroupsData.Count - 1 do
  begin
    if TAIDocGroup(FGroupsData[I]).ID = IdGrupo then
    begin
      Result := SafePathCombine([TAIDocGroup(FGroupsData[I]).Path]);
      Exit;
    end;
  end;
end;

function TAI_DOCFILESMANAGER.GetGrupoNameById(const IdGrupo: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FGroupsData.Count - 1 do
  begin
    if TAIDocGroup(FGroupsData[I]).ID = IdGrupo then
    begin
      Result := TAIDocGroup(FGroupsData[I]).Name;
      Exit;
    end;
  end;
end;

function TAI_DOCFILESMANAGER.GetGrupoIdByName(const Grupo: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FGroupsData.Count - 1 do
  begin
    if SameText(TAIDocGroup(FGroupsData[I]).Name, Grupo) then
    begin
      Result := TAIDocGroup(FGroupsData[I]).ID;
      Exit;
    end;
  end;
end;

function TAI_DOCFILESMANAGER.AddSubGrupo(const IdGrupo: Integer; const SubGrupo: string): Integer;
var
  Group: TAIDocGroup;
  SPath: string;
  NewSub: TAIDocSubGroup;
  I: Integer;
begin
  Result := -1;
  ClearError;

  if not ValidateName(SubGrupo) then
  begin
    SetError('Invalid subgroup name: ' + SubGrupo);
    Exit;
  end;

  Group := nil;
  for I := 0 to FGroupsData.Count - 1 do
  begin
    if TAIDocGroup(FGroupsData[I]).ID = IdGrupo then
    begin
      Group := TAIDocGroup(FGroupsData[I]);
      Break;
    end;
  end;

  if Group = nil then
  begin
    SetError('Parent Group ID ' + IntToStr(IdGrupo) + ' does not exist');
    Exit;
  end;

  if SubGrupoExists(IdGrupo, GetSubGrupoIdByName(Group.Name, SubGrupo)) then
  begin
    SetError('Subgroup already exists in this group');
    Exit;
  end;

  try
    SPath := SafePathCombine([Group.Path, SubGrupo]);
    if FAutoCreateDirs then
    begin
      if not ForceDirectories(SPath) then
      begin
        SetError('Failed to create subgroup directory: ' + SPath);
        Exit;
      end;
    end;

    Inc(FLastSubGroupId);
    NewSub := TAIDocSubGroup.Create(FLastSubGroupId, IdGrupo, SubGrupo, Group.Path + PathDelim + SubGrupo);
    FSubGroupsData.Add(NewSub);

    SaveManifest;
    Result := NewSub.ID;

    if Assigned(FOnAfterAddSubGrupo) then
      FOnAfterAddSubGrupo(Self, SubGrupo);
  except
    on E: Exception do
      SetError('AddSubGrupo error: ' + E.Message);
  end;
end;

function TAI_DOCFILESMANAGER.AddSubGrupo(const Grupo: string; const SubGrupo: string): Integer;
begin
  Result := AddSubGrupo(GetGrupoIdByName(Grupo), SubGrupo);
end;

function TAI_DOCFILESMANAGER.DelSubGrupo(const Grupo: string; const SubGrupo: string; const Force: Boolean = False): Boolean;
var
  GID, SID: Integer;
begin
  GID := GetGrupoIdByName(Grupo);
  SID := GetSubGrupoIdByName(Grupo, SubGrupo);
  Result := DelSubGrupo(GID, SID, Force);
end;

function TAI_DOCFILESMANAGER.DelSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; const Force: Boolean = False): Boolean;
var
  I: Integer;
  Sub: TAIDocSubGroup;
  SPath: string;
begin
  Result := False;
  ClearError;

  Sub := nil;
  for I := 0 to FSubGroupsData.Count - 1 do
  begin
    if (TAIDocSubGroup(FSubGroupsData[I]).ID = IdSubGrupo) and
       (TAIDocSubGroup(FSubGroupsData[I]).GroupID = IdGrupo) then
    begin
      Sub := TAIDocSubGroup(FSubGroupsData[I]);
      Break;
    end;
  end;

  if Sub = nil then
  begin
    SetError('Subgroup not found');
    Exit;
  end;

  try
    SPath := SafePathCombine([Sub.Path]);
    if DirectoryExists(SPath) then
    begin
      if not DeleteDirectorySafe(SPath, Force) then
      begin
        SetError('Failed to remove subgroup directory: ' + SPath + ' (ensure it is empty or force is True)');
        Exit;
      end;
    end;

    FSubGroupsData.Remove(Sub);
    SaveManifest;
    Result := True;

    if Assigned(FOnAfterDelSubGrupo) then
      FOnAfterDelSubGrupo(Self, Sub.Name);
  except
    on E: Exception do
      SetError('DelSubGrupo error: ' + E.Message);
  end;
end;

procedure TAI_DOCFILESMANAGER.ListSubGrupo(const Grupo: string; ALista: TStrings);
begin
  ListSubGrupo(GetGrupoIdByName(Grupo), ALista);
end;

procedure TAI_DOCFILESMANAGER.ListSubGrupo(const IdGrupo: Integer; ALista: TStrings);
var
  I: Integer;
begin
  if ALista = nil then Exit;
  ALista.Clear;
  for I := 0 to FSubGroupsData.Count - 1 do
  begin
    if TAIDocSubGroup(FSubGroupsData[I]).GroupID = IdGrupo then
    begin
      ALista.Add(TAIDocSubGroup(FSubGroupsData[I]).Name);
    end;
  end;
end;

function TAI_DOCFILESMANAGER.SubGrupoExists(const Grupo: string; const SubGrupo: string): Boolean;
begin
  Result := GetSubGrupoIdByName(Grupo, SubGrupo) >= 0;
end;

function TAI_DOCFILESMANAGER.SubGrupoExists(const IdGrupo: Integer; const IdSubGrupo: Integer): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FSubGroupsData.Count - 1 do
  begin
    if (TAIDocSubGroup(FSubGroupsData[I]).ID = IdSubGrupo) and
       (TAIDocSubGroup(FSubGroupsData[I]).GroupID = IdGrupo) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TAI_DOCFILESMANAGER.GetSubGrupoPath(const Grupo: string; const SubGrupo: string): string;
begin
  Result := GetSubGrupoPath(GetGrupoIdByName(Grupo), GetSubGrupoIdByName(Grupo, SubGrupo));
end;

function TAI_DOCFILESMANAGER.GetSubGrupoPath(const IdGrupo: Integer; const IdSubGrupo: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FSubGroupsData.Count - 1 do
  begin
    if (TAIDocSubGroup(FSubGroupsData[I]).ID = IdSubGrupo) and
       (TAIDocSubGroup(FSubGroupsData[I]).GroupID = IdGrupo) then
    begin
      Result := SafePathCombine([TAIDocSubGroup(FSubGroupsData[I]).Path]);
      Exit;
    end;
  end;
end;

function TAI_DOCFILESMANAGER.GetSubGrupoNameById(const IdSubGrupo: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FSubGroupsData.Count - 1 do
  begin
    if TAIDocSubGroup(FSubGroupsData[I]).ID = IdSubGrupo then
    begin
      Result := TAIDocSubGroup(FSubGroupsData[I]).Name;
      Exit;
    end;
  end;
end;

function TAI_DOCFILESMANAGER.GetSubGrupoIdByName(const Grupo: string; const SubGrupo: string): Integer;
var
  I: Integer;
  GID: Integer;
begin
  Result := -1;
  GID := GetGrupoIdByName(Grupo);
  if GID < 0 then Exit;

  for I := 0 to FSubGroupsData.Count - 1 do
  begin
    if (TAIDocSubGroup(FSubGroupsData[I]).GroupID = GID) and
       SameText(TAIDocSubGroup(FSubGroupsData[I]).Name, SubGrupo) then
    begin
      Result := TAIDocSubGroup(FSubGroupsData[I]).ID;
      Exit;
    end;
  end;
end;

function TAI_DOCFILESMANAGER.UploadSubGrupo(const Grupo: string; const SubGrupo: string; const SourceFile: string): Boolean;
begin
  Result := UploadSubGrupo(Grupo, SubGrupo, SourceFile, ExtractFileName(SourceFile));
end;

function TAI_DOCFILESMANAGER.UploadSubGrupo(const Grupo: string; const SubGrupo: string; const SourceFile: string; const NewFileName: string): Boolean;
var
  DestPath: string;
begin
  Result := False;
  ClearError;

  if not FActive then
  begin
    SetError('Component is not active');
    Exit;
  end;

  if not FileExists(SourceFile) then
  begin
    SetError('Source file does not exist: ' + SourceFile);
    Exit;
  end;

  if not ValidateFileName(NewFileName) then
  begin
    SetError('Invalid destination filename: ' + NewFileName);
    Exit;
  end;

  if not SubGrupoExists(Grupo, SubGrupo) then
  begin
    SetError('Subgroup "' + SubGrupo + '" in Group "' + Grupo + '" does not exist');
    Exit;
  end;

  try
    DestPath := SafePathCombine([TAIDocSubGroup(FSubGroupsData[GetSubGrupoIdByName(Grupo, SubGrupo)-1]).Path, NewFileName]);

    if not IsPathInsideStorage(DestPath) then
    begin
      SetError('Security Violation: Destination path is outside the storage directory.');
      Exit;
    end;

    if FileExists(DestPath) and not FAllowOverwrite then
    begin
      SetError('File already exists and AllowOverwrite is False: ' + NewFileName);
      Exit;
    end;

    if not CopyFile(SourceFile, DestPath) then
    begin
      SetError('Failed to copy file from "' + SourceFile + '" to "' + DestPath + '"');
      Exit;
    end;

    Result := True;
    if Assigned(FOnFileUploaded) then
      FOnFileUploaded(Self, Grupo, SubGrupo, NewFileName);
  except
    on E: Exception do
      SetError('UploadSubGrupo error: ' + E.Message);
  end;
end;

function TAI_DOCFILESMANAGER.UploadSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; const SourceFile: string): Boolean;
begin
  Result := UploadSubGrupo(IdGrupo, IdSubGrupo, SourceFile, ExtractFileName(SourceFile));
end;

function TAI_DOCFILESMANAGER.UploadSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; const SourceFile: string; const NewFileName: string): Boolean;
begin
  Result := UploadSubGrupo(
    GetGrupoNameById(IdGrupo),
    GetSubGrupoNameById(IdSubGrupo),
    SourceFile,
    NewFileName
  );
end;

function TAI_DOCFILESMANAGER.LoadSubGrupo(const Grupo: string; const SubGrupo: string; const FileName: string; const DestFile: string): Boolean;
var
  SourcePath: string;
begin
  Result := False;
  ClearError;

  if not FActive then
  begin
    SetError('Component is not active');
    Exit;
  end;

  if not SubGrupoExists(Grupo, SubGrupo) then
  begin
    SetError('Subgroup does not exist');
    Exit;
  end;

  if not ValidateFileName(FileName) then
  begin
    SetError('Invalid filename');
    Exit;
  end;

  try
    SourcePath := SafePathCombine([TAIDocSubGroup(FSubGroupsData[GetSubGrupoIdByName(Grupo, SubGrupo)-1]).Path, FileName]);
    if not FileExists(SourcePath) then
    begin
      SetError('File not found in subgroup: ' + FileName);
      Exit;
    end;

    // Create target directory if needed
    if not ForceDirectories(ExtractFilePath(DestFile)) then
    begin
      SetError('Failed to verify destination path directory: ' + DestFile);
      Exit;
    end;

    if not CopyFile(SourcePath, DestFile) then
    begin
      SetError('Failed to copy file from "' + SourcePath + '" to "' + DestFile + '"');
      Exit;
    end;

    Result := True;
    if Assigned(FOnFileLoaded) then
      FOnFileLoaded(Self, Grupo, SubGrupo, FileName);
  except
    on E: Exception do
      SetError('LoadSubGrupo error: ' + E.Message);
  end;
end;

function TAI_DOCFILESMANAGER.LoadSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; const FileName: string; const DestFile: string): Boolean;
begin
  Result := LoadSubGrupo(
    GetGrupoNameById(IdGrupo),
    GetSubGrupoNameById(IdSubGrupo),
    FileName,
    DestFile
  );
end;

procedure TAI_DOCFILESMANAGER.GetFilesSubGrupo(const Grupo: string; const SubGrupo: string; ALista: TStrings);
var
  SPath: string;
  SearchRec: TSearchRec;
begin
  if ALista = nil then Exit;
  ALista.Clear;

  if not SubGrupoExists(Grupo, SubGrupo) then Exit;
  SPath := GetSubGrupoPath(Grupo, SubGrupo);

  if FindFirst(IncludeTrailingPathDelimiter(SPath) + '*', faAnyFile and not faDirectory, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') and 
         ((SearchRec.Attr and faDirectory) = 0) then
      begin
        ALista.Add(SearchRec.Name);
      end;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

procedure TAI_DOCFILESMANAGER.GetFilesSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; ALista: TStrings);
begin
  GetFilesSubGrupo(
    GetGrupoNameById(IdGrupo),
    GetSubGrupoNameById(IdSubGrupo),
    ALista
  );
end;

function TAI_DOCFILESMANAGER.DelFileSubGrupo(const Grupo: string; const SubGrupo: string; const FileName: string): Boolean;
var
  FilePath: string;
begin
  Result := False;
  ClearError;

  if not FActive then
  begin
    SetError('Component is not active');
    Exit;
  end;

  if not SubGrupoExists(Grupo, SubGrupo) then
  begin
    SetError('Subgroup does not exist');
    Exit;
  end;

  if not ValidateFileName(FileName) then
  begin
    SetError('Invalid filename');
    Exit;
  end;

  try
    FilePath := SafePathCombine([TAIDocSubGroup(FSubGroupsData[GetSubGrupoIdByName(Grupo, SubGrupo)-1]).Path, FileName]);
    if not FileExists(FilePath) then
    begin
      SetError('File does not exist: ' + FileName);
      Exit;
    end;

    if not IsPathInsideStorage(FilePath) then
    begin
      SetError('Security Violation: File path is outside the storage directory.');
      Exit;
    end;

    if not DeleteFile(FilePath) then
    begin
      SetError('Failed to delete file: ' + FilePath);
      Exit;
    end;

    Result := True;
    if Assigned(FOnFileDeleted) then
      FOnFileDeleted(Self, Grupo, SubGrupo, FileName);
  except
    on E: Exception do
      SetError('DelFileSubGrupo error: ' + E.Message);
  end;
end;

function TAI_DOCFILESMANAGER.DelFileSubGrupo(const IdGrupo: Integer; const IdSubGrupo: Integer; const FileName: string): Boolean;
begin
  Result := DelFileSubGrupo(
    GetGrupoNameById(IdGrupo),
    GetSubGrupoNameById(IdSubGrupo),
    FileName
  );
end;

function TAI_DOCFILESMANAGER.GetDocument(const Grupo: string; const SubGrupo: string; const FileName: string): string;
var
  FilePath: string;
begin
  Result := '';
  ClearError;

  if not FActive then
  begin
    SetError('Component is not active');
    Exit;
  end;

  if not SubGrupoExists(Grupo, SubGrupo) then
  begin
    SetError('Subgroup does not exist');
    Exit;
  end;

  if not ValidateFileName(FileName) then
  begin
    SetError('Invalid filename');
    Exit;
  end;

  try
    FilePath := SafePathCombine([TAIDocSubGroup(FSubGroupsData[GetSubGrupoIdByName(Grupo, SubGrupo)-1]).Path, FileName]);
    if FileExists(FilePath) then
      Result := FileName
    else
      SetError('File not found: ' + FileName);
  except
    on E: Exception do
      SetError('GetDocument error: ' + E.Message);
  end;
end;

function TAI_DOCFILESMANAGER.GetDocument(const IdGrupo: Integer; const IdSubGrupo: Integer; const FileName: string): string;
begin
  Result := GetDocument(
    GetGrupoNameById(IdGrupo),
    GetSubGrupoNameById(IdSubGrupo),
    FileName
  );
end;

function TAI_DOCFILESMANAGER.GetFullDocument(const Grupo: string; const SubGrupo: string; const FileName: string): string;
var
  FilePath: string;
begin
  Result := '';
  ClearError;

  if not FActive then
  begin
    SetError('Component is not active');
    Exit;
  end;

  if not SubGrupoExists(Grupo, SubGrupo) then
  begin
    SetError('Subgroup does not exist');
    Exit;
  end;

  if not ValidateFileName(FileName) then
  begin
    SetError('Invalid filename');
    Exit;
  end;

  try
    FilePath := SafePathCombine([TAIDocSubGroup(FSubGroupsData[GetSubGrupoIdByName(Grupo, SubGrupo)-1]).Path, FileName]);
    if not IsPathInsideStorage(FilePath) then
    begin
      SetError('Security Violation: File path is outside the storage directory.');
      Exit;
    end;

    if FileExists(FilePath) then
      Result := FilePath
    else
      SetError('File not found: ' + FileName);
  except
    on E: Exception do
      SetError('GetFullDocument error: ' + E.Message);
  end;
end;

function TAI_DOCFILESMANAGER.GetFullDocument(const IdGrupo: Integer; const IdSubGrupo: Integer; const FileName: string): string;
begin
  Result := GetFullDocument(
    GetGrupoNameById(IdGrupo),
    GetSubGrupoNameById(IdSubGrupo),
    FileName
  );
end;

end.
