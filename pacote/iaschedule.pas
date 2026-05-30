unit iaschedule;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, LResources;

type
  TTaskStatus = (tsPending, tsDone);

  TIASchedule = class;

  { TScheduleTask }
  TScheduleTask = class(TCollectionItem)
  private
    FName: string;
    FDescription: string;
    FStatus: TTaskStatus;
    FParentName: string;
    FDependencies: TStringList;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure DependsOn(const ATaskName: string); overload;
    procedure DependsOn(ATask: TScheduleTask); overload;
    procedure MarkAsDone;
    procedure MarkAsPending;
    procedure Done;
    procedure Pending;
    function GetDependencies: TStringList;
    function ListDependencies: TStringList;
    function IsReady: Boolean;
  published
    property Name: string read FName write FName;
    property Description: string read FDescription write FDescription;
    property Status: TTaskStatus read FStatus write FStatus default tsPending;
    property ParentName: string read FParentName write FParentName;
  end;

  { TScheduleTasks }
  TScheduleTasks = class(TCollection)
  private
    FOwner: TComponent;
    function GetItem(Index: Integer): TScheduleTask;
    procedure SetItem(Index: Integer; Value: TScheduleTask);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TComponent);
    function Add: TScheduleTask;
    property Items[Index: Integer]: TScheduleTask read GetItem write SetItem; default;
  end;

  { TIASchedule }
  TIASchedule = class(TComponent)
  private
    FFileName: string;
    FTasks: TScheduleTasks;
    procedure SetTasks(AValue: TScheduleTasks);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function NewTask(const AName: string; const AParentName: string = ''): TScheduleTask;
    function FindTask(const AName: string): TScheduleTask;
    procedure Save;
    procedure Load;
  published
    property FileName: string read FFileName write FFileName;
    property Tasks: TScheduleTasks read FTasks write SetTasks;
  end;

  { TJSONGroupStorage }
  TJSONGroupStorage = class(TComponent)
  private
    FFileName: string;
    FActiveGroup: string;
    FRootObj: TJSONObject;
    FActiveGroupObj: TJSONObject;
    procedure SetFileName(const AValue: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Select(const AGroup: string);
    function Find(const AKey: string): string;
    procedure SetVal(const AKey, AValue: string);
    procedure Save;
    procedure Load;
  published
    property FileName: string read FFileName write SetFileName;
    property ActiveGroup: string read FActiveGroup;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Schedulle', [
    TJSONGroupStorage,
    TIASchedule
  ]);
end;

{ TScheduleTask }

constructor TScheduleTask.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FStatus := tsPending;
  FDependencies := TStringList.Create;
  FDependencies.Duplicates := dupIgnore;
  FDependencies.Sorted := True;
end;

destructor TScheduleTask.Destroy;
begin
  FDependencies.Free;
  inherited Destroy;
end;

procedure TScheduleTask.DependsOn(const ATaskName: string);
begin
  if Trim(ATaskName) <> '' then
    FDependencies.Add(ATaskName);
end;

procedure TScheduleTask.DependsOn(ATask: TScheduleTask);
begin
  if ATask <> nil then
    DependsOn(ATask.Name);
end;

procedure TScheduleTask.MarkAsDone;
begin
  FStatus := tsDone;
end;

procedure TScheduleTask.MarkAsPending;
begin
  FStatus := tsPending;
end;

procedure TScheduleTask.Done;
begin
  MarkAsDone;
end;

procedure TScheduleTask.Pending;
begin
  MarkAsPending;
end;

function TScheduleTask.GetDependencies: TStringList;
begin
  Result := FDependencies;
end;

function TScheduleTask.ListDependencies: TStringList;
begin
  Result := FDependencies;
end;

function TScheduleTask.IsReady: Boolean;
var
  I: Integer;
  DepName: string;
  DepTask: TScheduleTask;
begin
  Result := True;
  if FDependencies.Count = 0 then Exit;

  if (Collection <> nil) and (Collection.Owner <> nil) and (Collection.Owner is TIASchedule) then
  begin
    for I := 0 to FDependencies.Count - 1 do
    begin
      DepName := FDependencies[I];
      DepTask := TIASchedule(Collection.Owner).FindTask(DepName);
      if (DepTask <> nil) and (DepTask.Status <> tsDone) then
      begin
        Result := False;
        Exit;
      end;
    end;
  end;
end;

{ TScheduleTasks }

constructor TScheduleTasks.Create(AOwner: TComponent);
begin
  inherited Create(TScheduleTask);
  FOwner := AOwner;
end;

function TScheduleTasks.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

function TScheduleTasks.GetItem(Index: Integer): TScheduleTask;
begin
  Result := TScheduleTask(inherited GetItem(Index));
end;

procedure TScheduleTasks.SetItem(Index: Integer; Value: TScheduleTask);
begin
  inherited SetItem(Index, Value);
end;

function TScheduleTasks.Add: TScheduleTask;
begin
  Result := TScheduleTask(inherited Add);
end;

{ TIASchedule }

constructor TIASchedule.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTasks := TScheduleTasks.Create(Self);
end;

destructor TIASchedule.Destroy;
begin
  FTasks.Free;
  inherited Destroy;
end;

procedure TIASchedule.SetTasks(AValue: TScheduleTasks);
begin
  FTasks.Assign(AValue);
end;

function TIASchedule.NewTask(const AName: string; const AParentName: string = ''): TScheduleTask;
begin
  Result := FindTask(AName);
  if Result = nil then
  begin
    Result := FTasks.Add;
    Result.Name := AName;
  end;
  Result.ParentName := AParentName;
end;

function TIASchedule.FindTask(const AName: string): TScheduleTask;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FTasks.Count - 1 do
  begin
    if SameText(FTasks[I].Name, AName) then
    begin
      Result := FTasks[I];
      Exit;
    end;
  end;
end;

procedure TIASchedule.Save;
var
  RootArray: TJSONArray;
  TaskObj: TJSONObject;
  DepArray: TJSONArray;
  I, J: Integer;
  Task: TScheduleTask;
  Deps: TStringList;
  StrList: TStringList;
begin
  if FFileName = '' then Exit;

  RootArray := TJSONArray.Create;
  try
    for I := 0 to FTasks.Count - 1 do
    begin
      Task := FTasks[I];
      TaskObj := TJSONObject.Create;
      TaskObj.Add('name', Task.Name);
      TaskObj.Add('description', Task.Description);
      
      if Task.Status = tsDone then
        TaskObj.Add('status', 'done')
      else
        TaskObj.Add('status', 'pending');
        
      TaskObj.Add('parent', Task.ParentName);

      DepArray := TJSONArray.Create;
      Deps := Task.GetDependencies;
      for J := 0 to Deps.Count - 1 do
        DepArray.Add(Deps[J]);
        
      TaskObj.Add('dependencies', DepArray);
      RootArray.Add(TaskObj);
    end;

    StrList := TStringList.Create;
    try
      StrList.Text := RootArray.FormatJSON();
      StrList.SaveToFile(FFileName);
    finally
      StrList.Free;
    end;
  finally
    RootArray.Free;
  end;
end;

procedure TIASchedule.Load;
var
  Parser: TJSONParser;
  Data: TJSONData;
  RootArray: TJSONArray;
  TaskObj: TJSONObject;
  DepArray: TJSONArray;
  StrList: TStringList;
  FileContent: string;
  I, J: Integer;
  TName, TDesc, TParent, TStatusStr: string;
  T: TScheduleTask;
begin
  FTasks.Clear;
  if (FFileName = '') or not FileExists(FFileName) then Exit;

  StrList := TStringList.Create;
  try
    StrList.LoadFromFile(FFileName);
    FileContent := StrList.Text;
  finally
    StrList.Free;
  end;

  if Trim(FileContent) = '' then Exit;

  Parser := TJSONParser.Create(FileContent);
  try
    Data := Parser.Parse;
    if Data is TJSONArray then
    begin
      RootArray := TJSONArray(Data);
      // First pass: create all tasks
      for I := 0 to RootArray.Count - 1 do
      begin
        if RootArray.Types[I] = jtObject then
        begin
          TaskObj := TJSONObject(RootArray.Objects[I]);
          TName := TaskObj.Get('name', '');
          TDesc := TaskObj.Get('description', '');
          TParent := TaskObj.Get('parent', '');
          TStatusStr := TaskObj.Get('status', 'pending');

          T := NewTask(TName, TParent);
          T.Description := TDesc;
          if SameText(TStatusStr, 'done') then
            T.Status := tsDone
          else
            T.Status := tsPending;
        end;
      end;

      // Second pass: resolve dependencies
      for I := 0 to RootArray.Count - 1 do
      begin
        if RootArray.Types[I] = jtObject then
        begin
          TaskObj := TJSONObject(RootArray.Objects[I]);
          TName := TaskObj.Get('name', '');
          T := FindTask(TName);
          if T <> nil then
          begin
            DepArray := TaskObj.Find('dependencies') as TJSONArray;
            if DepArray <> nil then
            begin
              for J := 0 to DepArray.Count - 1 do
                T.DependsOn(DepArray.Strings[J]);
            end;
          end;
        end;
      end;
    end;
  finally
    Data.Free;
    Parser.Free;
  end;
end;

{ TJSONGroupStorage }

constructor TJSONGroupStorage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFileName := '';
  FActiveGroup := '';
  FRootObj := nil;
  FActiveGroupObj := nil;
end;

destructor TJSONGroupStorage.Destroy;
begin
  if FRootObj <> nil then
    FRootObj.Free;
  inherited Destroy;
end;

procedure TJSONGroupStorage.SetFileName(const AValue: string);
begin
  if FFileName = AValue then Exit;
  FFileName := AValue;
  // Free current cache to force reload on next action
  if FRootObj <> nil then
  begin
    FreeAndNil(FRootObj);
    FActiveGroupObj := nil;
  end;
end;

procedure TJSONGroupStorage.Select(const AGroup: string);
begin
  FActiveGroup := AGroup;
  if FRootObj = nil then
    Load;

  if FRootObj = nil then
    FRootObj := TJSONObject.Create;

  FActiveGroupObj := FRootObj.Find(FActiveGroup) as TJSONObject;
  if FActiveGroupObj = nil then
  begin
    FActiveGroupObj := TJSONObject.Create;
    FRootObj.Add(FActiveGroup, FActiveGroupObj);
  end;
end;

function TJSONGroupStorage.Find(const AKey: string): string;
var
  Data: TJSONData;
begin
  Result := '';
  if FActiveGroupObj = nil then
  begin
    if FActiveGroup <> '' then
      Select(FActiveGroup)
    else
      Exit;
  end;

  if FActiveGroupObj <> nil then
  begin
    Data := FActiveGroupObj.Find(AKey);
    if Data <> nil then
      Result := Data.AsString;
  end;
end;

procedure TJSONGroupStorage.SetVal(const AKey, AValue: string);
var
  Data: TJSONData;
begin
  if FActiveGroupObj = nil then
  begin
    if FActiveGroup <> '' then
      Select(FActiveGroup)
    else
      Exit;
  end;

  if FActiveGroupObj <> nil then
  begin
    Data := FActiveGroupObj.Find(AKey);
    if Data <> nil then
      Data.AsString := AValue
    else
      FActiveGroupObj.Add(AKey, AValue);
  end;
end;

procedure TJSONGroupStorage.Save;
var
  StrList: TStringList;
begin
  if (FFileName = '') or (FRootObj = nil) then Exit;

  StrList := TStringList.Create;
  try
    StrList.Text := FRootObj.FormatJSON();
    StrList.SaveToFile(FFileName);
  finally
    StrList.Free;
  end;
end;

procedure TJSONGroupStorage.Load;
var
  Parser: TJSONParser;
  Data: TJSONData;
  StrList: TStringList;
  FileContent: string;
begin
  if FRootObj <> nil then
    FreeAndNil(FRootObj);
  FActiveGroupObj := nil;

  if (FFileName <> '') and FileExists(FFileName) then
  begin
    StrList := TStringList.Create;
    try
      StrList.LoadFromFile(FFileName);
      FileContent := StrList.Text;
    finally
      StrList.Free;
    end;

    if Trim(FileContent) <> '' then
    begin
      Parser := TJSONParser.Create(FileContent);
      try
        Data := Parser.Parse;
        if Data is TJSONObject then
          FRootObj := TJSONObject(Data)
        else
        begin
          Data.Free;
          FRootObj := TJSONObject.Create;
        end;
      finally
        Parser.Free;
      end;
    end
    else
      FRootObj := TJSONObject.Create;
  end
  else
    FRootObj := TJSONObject.Create;

  if FActiveGroup <> '' then
    Select(FActiveGroup);
end;

initialization
  {$I iaschedule_icon.lrs}

end.
