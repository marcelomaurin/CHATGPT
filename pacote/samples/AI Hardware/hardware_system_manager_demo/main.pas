unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Math, StrUtils, Registry, aicpu, aimemory, aigpu, aidisk, aiso, ai_tasks;

type
  { TfrmHardwareSystemManagerDemo }

  TfrmHardwareSystemManagerDemo = class(TForm)
    FPageControl: TPageControl;
    FTimer: TTimer;
    FCPU: TAICPU;
    FMemory: TAIMemory;
    FGPU: TAIGPU;
    FDisk: TAIDisk;
    FOS: TAIOS;
    FTasks: TAITasks;
    FTabOverview: TTabSheet;
    FTabTasks: TTabSheet;
    FTabDevices: TTabSheet;
    FTabRaw: TTabSheet;
    FTabCPU: TTabSheet;
    FTabMemory: TTabSheet;
    FTabPCIe: TTabSheet;
    FTabPCI: TTabSheet;
    FTaskTopPanel: TPanel;
    FTaskFilterLabel: TLabel;
    FTaskFilterEdit: TEdit;
    FTaskOnlyCurrentUser: TCheckBox;
    FTaskSortLabel: TLabel;
    FTaskSortCombo: TComboBox;
    FOverviewMemo: TMemo;
    FCPUMemo: TMemo;
    FMemoryMemo: TMemo;
    FPCIeMemo: TMemo;
    FPCIMemo: TMemo;
    FTasksListView: TListView;
    FDevicesListView: TListView;
    FRawMemo: TMemo;
    FCPUBar: TProgressBar;
    FMemoryBar: TProgressBar;
    FTitleLabel: TLabel;
    FSubtitleLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TaskFilterChange(Sender: TObject);
    procedure TaskOptionsChange(Sender: TObject);
    procedure TimerTick(Sender: TObject);
  private
    function CollectPCIInventory(const ANeedle: string): string;
    procedure RefreshAll;
    procedure RefreshOverview;
    procedure RefreshCPUPage;
    procedure RefreshMemoryPage;
    procedure RefreshPCIePage;
    procedure RefreshPCIPage;
    procedure RefreshTasks;
    procedure RefreshDevices;
    procedure RefreshRawDetails;
  public
  end;

var
  frmHardwareSystemManagerDemo: TfrmHardwareSystemManagerDemo;

implementation

{$R *.lfm}

procedure TfrmHardwareSystemManagerDemo.FormCreate(Sender: TObject);
begin
  Self.DoubleBuffered := True;
  if Assigned(FTasksListView) then
    FTasksListView.DoubleBuffered := True;
  if Assigned(FDevicesListView) then
    FDevicesListView.DoubleBuffered := True;

  FTasks.SortBy := sbCPU;
  FTasks.SortDescending := True;
  FTasks.ResetHistory;
  if Assigned(FTaskSortCombo) then
    FTaskSortCombo.ItemIndex := 0;
  RefreshAll;
  if Assigned(FTimer) then
    FTimer.Enabled := True;
end;

procedure TfrmHardwareSystemManagerDemo.FormDestroy(Sender: TObject);
begin
end;

procedure TfrmHardwareSystemManagerDemo.TaskFilterChange(Sender: TObject);
begin
  RefreshTasks;
end;

procedure TfrmHardwareSystemManagerDemo.TaskOptionsChange(Sender: TObject);
begin
  if Assigned(FTasks) and Assigned(FTaskOnlyCurrentUser) then
    FTasks.OnlyCurrentUser := FTaskOnlyCurrentUser.Checked;
  case FTaskSortCombo.ItemIndex of
    1: FTasks.SortBy := sbMemory;
  else
    FTasks.SortBy := sbCPU;
  end;
  RefreshTasks;
end;

procedure TfrmHardwareSystemManagerDemo.TimerTick(Sender: TObject);
begin
  RefreshAll;
end;

procedure TfrmHardwareSystemManagerDemo.RefreshAll;
begin
  RefreshTasks;
  RefreshDevices;
  RefreshOverview;
  RefreshCPUPage;
  RefreshMemoryPage;
  RefreshPCIePage;
  RefreshPCIPage;
  RefreshRawDetails;
end;

function TfrmHardwareSystemManagerDemo.CollectPCIInventory(const ANeedle: string): string;
{$IFDEF MSWINDOWS}
var
  R: TRegistry;
  Keys: TStringList;
  I: Integer;
  KeyName, Title: string;
begin
  Result := '';
  R := TRegistry.Create;
  Keys := TStringList.Create;
  try
    R.RootKey := HKEY_LOCAL_MACHINE;
    if not R.OpenKeyReadOnly('SYSTEM\CurrentControlSet\Enum\PCI') then
    begin
      Result := 'Inventario PCI indisponivel nesta maquina.';
      Exit;
    end;
    R.GetKeyNames(Keys);
    for I := 0 to Keys.Count - 1 do
    begin
      KeyName := Keys[I];
      if (ANeedle <> '') and (Pos(UpperCase(ANeedle), UpperCase(KeyName)) = 0) then
        Continue;
      Title := KeyName;
      if Result <> '' then
        Result += LineEnding;
      Result += Title;
    end;
    if Result = '' then
      Result := 'Nenhum dispositivo encontrado.';
  finally
    Keys.Free;
    R.Free;
  end;
end;
{$ELSE}
begin
  Result := 'Inventario PCI indisponivel nesta plataforma.';
end;
{$ENDIF}

procedure TfrmHardwareSystemManagerDemo.RefreshCPUPage;
var
  CPUInfo: TAICPUInfo;
  I: Integer;
begin
  if not Assigned(FCPU) or not Assigned(FCPUMemo) then Exit;
  CPUInfo := FCPU.LastInfo;
  FCPUBar.Position := Trunc(CPUInfo.UsageTotalPercent);
  FCPUMemo.Lines.BeginUpdate;
  try
    FCPUMemo.Clear;
    FCPUMemo.Lines.Add('Informacoes do processador');
    FCPUMemo.Lines.Add(Format('  Processadores: %d', [CPUInfo.ProcessorCount]));
    FCPUMemo.Lines.Add(Format('  Logicos: %d', [CPUInfo.LogicalCount]));
    FCPUMemo.Lines.Add(Format('  Nucleos: %d', [CPUInfo.Cores]));
    FCPUMemo.Lines.Add(Format('  Cache line: %d', [CPUInfo.CacheLineSize]));
    FCPUMemo.Lines.Add(Format('  ID: %s', [CPUInfo.ProcessorId]));
    FCPUMemo.Lines.Add(Format('  Frequencia: %d MHz', [CPUInfo.FrequencyMHz]));
    FCPUMemo.Lines.Add(Format('  Uso total: %.1f %%', [CPUInfo.UsageTotalPercent]));
    for I := 0 to High(CPUInfo.CoreUsagePercent) do
      FCPUMemo.Lines.Add(Format('  Core %d: %.1f %%', [I, CPUInfo.CoreUsagePercent[I]]));
  finally
    FCPUMemo.Lines.EndUpdate;
  end;
end;

procedure TfrmHardwareSystemManagerDemo.RefreshMemoryPage;
var
  MemInfo: TAIMemoryInfo;
begin
  if not Assigned(FMemory) or not Assigned(FMemoryMemo) then Exit;
  MemInfo := FMemory.LastInfo;
  FMemoryBar.Position := Trunc(MemInfo.LoadPercent);
  FMemoryMemo.Lines.BeginUpdate;
  try
    FMemoryMemo.Clear;
    FMemoryMemo.Lines.Add('Informacoes da memoria');
    FMemoryMemo.Lines.Add(Format('  Tipo: %s', [MemInfo.MemoryType]));
    FMemoryMemo.Lines.Add(Format('  Total: %d MB', [MemInfo.TotalMB]));
    FMemoryMemo.Lines.Add(Format('  Disponivel: %d MB', [MemInfo.AvailableMB]));
    FMemoryMemo.Lines.Add(Format('  Usada: %d MB', [MemInfo.UsedMB]));
    FMemoryMemo.Lines.Add(Format('  Pentes: %d', [MemInfo.SlotCount]));
    FMemoryMemo.Lines.Add(Format('  Uso: %.1f %%', [MemInfo.LoadPercent]));
  finally
    FMemoryMemo.Lines.EndUpdate;
  end;
end;

procedure TfrmHardwareSystemManagerDemo.RefreshPCIePage;
begin
  if not Assigned(FPCIeMemo) then Exit;
  FPCIeMemo.Lines.BeginUpdate;
  try
    FPCIeMemo.Clear;
    FPCIeMemo.Lines.Add('Informacoes PCIe');
    FPCIeMemo.Lines.Add(CollectPCIInventory('PCI\'));
  finally
    FPCIeMemo.Lines.EndUpdate;
  end;
end;

procedure TfrmHardwareSystemManagerDemo.RefreshPCIPage;
begin
  if not Assigned(FPCIMemo) then Exit;
  FPCIMemo.Lines.BeginUpdate;
  try
    FPCIMemo.Clear;
    FPCIMemo.Lines.Add('Informacoes PCI');
    FPCIMemo.Lines.Add(CollectPCIInventory(''));
  finally
    FPCIMemo.Lines.EndUpdate;
  end;
end;

procedure TfrmHardwareSystemManagerDemo.RefreshOverview;
var
  CPUInfo: TAICPUInfo;
  MemInfo: TAIMemoryInfo;
  OSInfo: TAIOSInfo;
  I: Integer;
begin
  if not Assigned(FCPU) or not Assigned(FMemory) or not Assigned(FOS) or
     not Assigned(FOverviewMemo) then Exit;
  CPUInfo := FCPU.RefreshInfo;
  MemInfo := FMemory.RefreshInfo;
  OSInfo := FOS.RefreshInfo;

  FCPUBar.Position := Trunc(CPUInfo.UsageTotalPercent);
  FMemoryBar.Position := Trunc(MemInfo.LoadPercent);

  FOverviewMemo.Lines.BeginUpdate;
  try
    FOverviewMemo.Clear;
    FOverviewMemo.Lines.Add('CPU');
    FOverviewMemo.Lines.Add(Format('  Processadores: %d', [CPUInfo.ProcessorCount]));
    FOverviewMemo.Lines.Add(Format('  Logicos: %d', [CPUInfo.LogicalCount]));
    FOverviewMemo.Lines.Add(Format('  Nucleos: %d', [CPUInfo.Cores]));
    FOverviewMemo.Lines.Add(Format('  Cache line: %d', [CPUInfo.CacheLineSize]));
    FOverviewMemo.Lines.Add(Format('  ID: %s', [CPUInfo.ProcessorId]));
    FOverviewMemo.Lines.Add(Format('  Frequencia: %d MHz', [CPUInfo.FrequencyMHz]));
    FOverviewMemo.Lines.Add(Format('  Uso total: %.1f %%', [CPUInfo.UsageTotalPercent]));
    for I := 0 to High(CPUInfo.CoreUsagePercent) do
      FOverviewMemo.Lines.Add(Format('  Core %d: %.1f %%', [I, CPUInfo.CoreUsagePercent[I]]));

    FOverviewMemo.Lines.Add('');
    FOverviewMemo.Lines.Add('Memoria');
    FOverviewMemo.Lines.Add(Format('  Tipo: %s', [MemInfo.MemoryType]));
    FOverviewMemo.Lines.Add(Format('  Total: %d MB', [MemInfo.TotalMB]));
    FOverviewMemo.Lines.Add(Format('  Disponivel: %d MB', [MemInfo.AvailableMB]));
    FOverviewMemo.Lines.Add(Format('  Usada: %d MB', [MemInfo.UsedMB]));
    FOverviewMemo.Lines.Add(Format('  Pentes: %d', [MemInfo.SlotCount]));
    FOverviewMemo.Lines.Add(Format('  Uso: %.1f %%', [MemInfo.LoadPercent]));

    FOverviewMemo.Lines.Add('');
    FOverviewMemo.Lines.Add('Sistema operacional');
    FOverviewMemo.Lines.Add(Format('  Nome: %s', [OSInfo.OSName]));
    FOverviewMemo.Lines.Add(Format('  Versao: %s', [OSInfo.OSVersion]));
    FOverviewMemo.Lines.Add(Format('  Arquitetura: %s', [OSInfo.Architecture]));
    FOverviewMemo.Lines.Add(Format('  Bits: %s', [OSInfo.Bitness]));
    FOverviewMemo.Lines.Add(Format('  Memoria virtual usada: %d MB', [OSInfo.VirtualMemoryUsedMB]));
    FOverviewMemo.Lines.Add(Format('  Memoria virtual total: %d MB', [OSInfo.VirtualMemoryTotalMB]));
  finally
    FOverviewMemo.Lines.EndUpdate;
  end;
end;

procedure TfrmHardwareSystemManagerDemo.RefreshTasks;
var
  I, J: Integer;
  Item: TListItem;
  T: TAITask;
  FilterText: string;
  UsedMB: Double;
  PIDStr: string;
  Found: Boolean;
  ValPPID, ValName, ValCPU, ValMem, ValState, ValUser: string;

  procedure SetSubItem(AItem: TListItem; AIndex: Integer; const AValue: string);
  begin
    while AItem.SubItems.Count <= AIndex do
      AItem.SubItems.Add('');
    if AItem.SubItems[AIndex] <> AValue then
      AItem.SubItems[AIndex] := AValue;
  end;

begin
  if not Assigned(FTasks) then Exit;
  FTasks.Refresh;
  FilterText := '';
  if Assigned(FTaskFilterEdit) then
    FilterText := Trim(LowerCase(FTaskFilterEdit.Text));
  
  FTasksListView.Items.BeginUpdate;
  try
    // Mark all existing items as nil to track which ones need deletion
    for I := 0 to FTasksListView.Items.Count - 1 do
      FTasksListView.Items[I].Data := nil;

    for I := 0 to FTasks.Count - 1 do
    begin
      T := FTasks.Tasks[I];
      if (FilterText <> '') and (Pos(FilterText, LowerCase(T.Name)) = 0) and
         (Pos(FilterText, LowerCase(T.CommandLine)) = 0) then
        Continue;
        
      PIDStr := IntToStr(T.PID);
      Found := False;
      Item := nil;
      
      // Look for the PID in the table
      for J := 0 to FTasksListView.Items.Count - 1 do
      begin
        if FTasksListView.Items[J].Caption = PIDStr then
        begin
          Item := FTasksListView.Items[J];
          Found := True;
          Break;
        end;
      end;
      
      if not Found then
      begin
        Item := FTasksListView.Items.Add;
        Item.Caption := PIDStr;
      end;
      
      ValPPID := IntToStr(T.PPID);
      ValName := T.Name;
      ValCPU := FormatFloat('0.0', T.CPUPercent);
      UsedMB := T.MemoryWorking / 1024 / 1024;
      ValMem := FormatFloat('0.0 MB', UsedMB);
      ValState := T.StateStr;
      ValUser := T.User;
      
      SetSubItem(Item, 0, ValPPID);
      SetSubItem(Item, 1, ValName);
      SetSubItem(Item, 2, ValCPU);
      SetSubItem(Item, 3, ValMem);
      SetSubItem(Item, 4, ValState);
      SetSubItem(Item, 5, ValUser);
      
      // Mark as alive in this cycle
      Item.Data := Pointer(1);
    end;
    
    // Delete any items that were not found in this cycle
    for I := FTasksListView.Items.Count - 1 downto 0 do
    begin
      Item := FTasksListView.Items[I];
      if Item.Data = nil then
        Item.Delete
      else
        Item.Data := nil; // Reset for next refresh
    end;
  finally
    //FTasksListView.Items.EndUpdate;
  end;
end;

procedure TfrmHardwareSystemManagerDemo.RefreshDevices;
var
  I: Integer;
  Item: TListItem;
  D: TAIDiskInfo;
begin
  if not Assigned(FDisk) then Exit;
  FDevicesListView.Items.BeginUpdate;
  try
    FDevicesListView.Items.Clear;
    FDisk.RefreshInfo;
    for I := 0 to FDisk.DiskCount - 1 do
    begin
      D := FDisk.GetDiskInfo(I);
      Item := FDevicesListView.Items.Add;
      Item.Caption := D.Drive;
      Item.SubItems.Add(FormatFloat('0.0 MB', D.TotalMB));
      Item.SubItems.Add(FormatFloat('0.0 MB', D.UsedMB));
      Item.SubItems.Add(FormatFloat('0.0 MB', D.FreeMB));
    end;
  finally
    FDevicesListView.Items.EndUpdate;
  end;
end;

procedure TfrmHardwareSystemManagerDemo.RefreshRawDetails;
var
  GPUInfo: TAIGPUInfo;
  CPUInfo: TAICPUInfo;
  MemInfo: TAIMemoryInfo;
  OSInfo: TAIOSInfo;
  I: Integer;
begin
  if not Assigned(FGPU) or not Assigned(FCPU) or not Assigned(FMemory) or
     not Assigned(FOS) or not Assigned(FTasks) then Exit;
  GPUInfo := FGPU.RefreshInfo;
  CPUInfo := FCPU.LastInfo;
  MemInfo := FMemory.LastInfo;
  OSInfo := FOS.LastInfo;

  FRawMemo.Lines.BeginUpdate;
  try
    FRawMemo.Clear;
    FRawMemo.Lines.Add('GPU');
    FRawMemo.Lines.Add(Format('  Nome: %s', [GPUInfo.Name]));
    FRawMemo.Lines.Add(Format('  Memoria total: %d MB', [GPUInfo.MemoryTotalMB]));
    FRawMemo.Lines.Add(Format('  Memoria usada: %d MB', [GPUInfo.MemoryUsedMB]));
    FRawMemo.Lines.Add(Format('  Memoria livre: %d MB', [GPUInfo.MemoryFreeMB]));
    FRawMemo.Lines.Add(Format('  CUDA cores: %d', [GPUInfo.CUDACoreCount]));
    FRawMemo.Lines.Add(Format('  Uso: %.1f %%', [GPUInfo.UsagePercent]));

    FRawMemo.Lines.Add('');
    FRawMemo.Lines.Add('Discos');
    for I := 0 to FDisk.DiskCount - 1 do
    begin
      with FDisk.GetDiskInfo(I) do
      begin
        FRawMemo.Lines.Add(Format('  %s total=%dMB usado=%dMB livre=%dMB', [Drive, TotalMB, UsedMB, FreeMB]));
      end;
    end;

    FRawMemo.Lines.Add('');
    FRawMemo.Lines.Add('CPU');
    FRawMemo.Lines.Add(Format('  %s', [CPUInfo.ProcessorId]));
    FRawMemo.Lines.Add(Format('  Frequencia: %d MHz', [CPUInfo.FrequencyMHz]));
    FRawMemo.Lines.Add(Format('  Uso total: %.1f %%', [CPUInfo.UsageTotalPercent]));

    FRawMemo.Lines.Add('');
    FRawMemo.Lines.Add('Memoria');
    FRawMemo.Lines.Add(Format('  Tipo: %s', [MemInfo.MemoryType]));
    FRawMemo.Lines.Add(Format('  Pentes: %d', [MemInfo.SlotCount]));
    FRawMemo.Lines.Add(Format('  Total: %d MB', [MemInfo.TotalMB]));

    FRawMemo.Lines.Add('');
    FRawMemo.Lines.Add('SO');
    FRawMemo.Lines.Add(Format('  %s %s', [OSInfo.OSName, OSInfo.OSVersion]));
    FRawMemo.Lines.Add(Format('  %s / %s', [OSInfo.Architecture, OSInfo.Bitness]));

    FRawMemo.Lines.Add('');
    FRawMemo.Lines.Add('Tarefas em destaque');
    for I := 0 to Min(9, FTasks.Count - 1) do
      FRawMemo.Lines.Add(Format('  %s', [FTasks.Tasks[I].Name]));
  finally
    FRawMemo.Lines.EndUpdate;
  end;
end;

initialization
  RegisterClass(TAICPU);
  RegisterClass(TAIMemory);
  RegisterClass(TAIGPU);
  RegisterClass(TAIDisk);
  RegisterClass(TAIOS);
  RegisterClass(TAITasks);

end.
