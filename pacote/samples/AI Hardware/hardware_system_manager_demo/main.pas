unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Math, StrUtils, Registry, aicpu, aimemory, aigpu, aidisk, aiso, ai_tasks;

type
  { TfrmHardwareSystemManagerDemo }

  TfrmHardwareSystemManagerDemo = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
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
    procedure BindComponents;
    procedure TaskFilterChange(Sender: TObject);
    procedure TaskOptionsChange(Sender: TObject);
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
    procedure TimerTick(Sender: TObject);
  public
  end;

var
  frmHardwareSystemManagerDemo: TfrmHardwareSystemManagerDemo;

implementation

{$R *.lfm}

procedure TfrmHardwareSystemManagerDemo.FormCreate(Sender: TObject);
begin
  BindComponents;
  FTasks.SortBy := sbCPU;
  FTasks.SortDescending := True;
  FTasks.ResetHistory;
  if Assigned(FTaskSortCombo) then
    FTaskSortCombo.ItemIndex := 0;
  RefreshAll;
end;

procedure TfrmHardwareSystemManagerDemo.FormDestroy(Sender: TObject);
begin
end;

procedure TfrmHardwareSystemManagerDemo.BindComponents;
begin
  FPageControl := TPageControl(FindComponent('FPageControl'));
  FTimer := TTimer(FindComponent('FTimer'));
  FCPU := TAICPU(FindComponent('FCPU'));
  FMemory := TAIMemory(FindComponent('FMemory'));
  FGPU := TAIGPU(FindComponent('FGPU'));
  FDisk := TAIDisk(FindComponent('FDisk'));
  FOS := TAIOS(FindComponent('FOS'));
  FTasks := TAITasks(FindComponent('FTasks'));
  FTabOverview := TTabSheet(FindComponent('FTabOverview'));
  FTabTasks := TTabSheet(FindComponent('FTabTasks'));
  FTabDevices := TTabSheet(FindComponent('FTabDevices'));
    FTabRaw := TTabSheet(FindComponent('FTabRaw'));
    FTabCPU := TTabSheet(FindComponent('FTabCPU'));
    FTabMemory := TTabSheet(FindComponent('FTabMemory'));
    FTabPCIe := TTabSheet(FindComponent('FTabPCIe'));
    FTabPCI := TTabSheet(FindComponent('FTabPCI'));
    FTaskTopPanel := TPanel(FindComponent('FTaskTopPanel'));
  FTaskFilterLabel := TLabel(FindComponent('FTaskFilterLabel'));
  FTaskFilterEdit := TEdit(FindComponent('FTaskFilterEdit'));
  FTaskOnlyCurrentUser := TCheckBox(FindComponent('FTaskOnlyCurrentUser'));
  FTaskSortLabel := TLabel(FindComponent('FTaskSortLabel'));
  FTaskSortCombo := TComboBox(FindComponent('FTaskSortCombo'));
    FOverviewMemo := TMemo(FindComponent('FOverviewMemo'));
    FCPUMemo := TMemo(FindComponent('FCPUMemo'));
    FMemoryMemo := TMemo(FindComponent('FMemoryMemo'));
    FPCIeMemo := TMemo(FindComponent('FPCIeMemo'));
    FPCIMemo := TMemo(FindComponent('FPCIMemo'));
  FTasksListView := TListView(FindComponent('FTasksListView'));
  FDevicesListView := TListView(FindComponent('FDevicesListView'));
  FRawMemo := TMemo(FindComponent('FRawMemo'));
  FCPUBar := TProgressBar(FindComponent('FCPUBar'));
  FMemoryBar := TProgressBar(FindComponent('FMemoryBar'));
  FTitleLabel := TLabel(FindComponent('FTitleLabel'));
  FSubtitleLabel := TLabel(FindComponent('FSubtitleLabel'));
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
  RefreshCPUPage;
  RefreshMemoryPage;
  RefreshPCIePage;
  RefreshPCIPage;
  RefreshOverview;
  RefreshTasks;
  RefreshDevices;
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
  CPUInfo := FCPU.RefreshInfo;
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
  MemInfo := FMemory.RefreshInfo;
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
    FPCIeMemo.Lines.Add(CollectPCIInventory('PCI\\'));
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
  I: Integer;
  Item: TListItem;
  T: TAITask;
  FilterText: string;
begin
  if not Assigned(FTasks) then Exit;
  FTasks.Refresh;
  FilterText := '';
  if Assigned(FTaskFilterEdit) then
    FilterText := Trim(LowerCase(FTaskFilterEdit.Text));
  FTasksListView.Items.BeginUpdate;
  try
    FTasksListView.Items.Clear;
    for I := 0 to FTasks.Count - 1 do
    begin
      T := FTasks.Tasks[I];
      if (FilterText <> '') and (Pos(FilterText, LowerCase(T.Name)) = 0) and
         (Pos(FilterText, LowerCase(T.CommandLine)) = 0) then
        Continue;
      Item := FTasksListView.Items.Add;
      Item.Caption := IntToStr(T.PID);
      Item.SubItems.Add(IntToStr(T.PPID));
      Item.SubItems.Add(T.Name);
      Item.SubItems.Add(FormatFloat('0.0', T.CPUPercent));
      Item.SubItems.Add(FormatFloat('0.0 MB', T.MemoryWorking));
      Item.SubItems.Add(T.StateStr);
      Item.SubItems.Add(T.User);
    end;
  finally
    FTasksListView.Items.EndUpdate;
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

end.
