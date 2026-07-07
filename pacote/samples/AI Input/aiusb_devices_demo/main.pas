unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Grids, aiusb;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    btnRefresh: TButton;
    chkAutoRefresh: TCheckBox;
    lblInterval: TLabel;
    editInterval: TEdit;
    gridDevices: TStringGrid;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure chkAutoRefreshChange(Sender: TObject);
    procedure editIntervalChange(Sender: TObject);
    procedure OnDeviceConnected(Sender: TObject; Device: TAIUSBDeviceItem);
    procedure OnDeviceDisconnected(Sender: TObject; Device: TAIUSBDeviceItem);
    procedure OnDeviceChanged(Sender: TObject; Device: TAIUSBDeviceItem);
    procedure OnError(Sender: TObject; const Msg: string);
  private
    FAIUSB: TAIUSB;
    procedure UpdateGrid;
    procedure AddLog(const AMsg: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FAIUSB := TAIUSB.Create(Self);
  FAIUSB.OnDeviceConnected := @OnDeviceConnected;
  FAIUSB.OnDeviceDisconnected := @OnDeviceDisconnected;
  FAIUSB.OnDeviceChanged := @OnDeviceChanged;
  FAIUSB.OnError := @OnError;

  // Setup StringGrid
  gridDevices.ColCount := 10;
  gridDevices.RowCount := 1;
  gridDevices.Cells[0, 0] := 'DeviceID';
  gridDevices.Cells[1, 0] := 'VendorID';
  gridDevices.Cells[2, 0] := 'ProductID';
  gridDevices.Cells[3, 0] := 'Fabricante';
  gridDevices.Cells[4, 0] := 'Produto';
  gridDevices.Cells[5, 0] := 'Serial';
  gridDevices.Cells[6, 0] := 'Classe';
  gridDevices.Cells[7, 0] := 'Bus';
  gridDevices.Cells[8, 0] := 'Port';
  gridDevices.Cells[9, 0] := 'State';

  // Apply default values
  chkAutoRefresh.Checked := FAIUSB.AutoRefresh;
  editInterval.Text := IntToStr(FAIUSB.RefreshInterval);

  AddLog('AIUSB Demo Initialized.');
  UpdateGrid;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Managed by owner auto-free
end;

procedure TfrmMain.btnRefreshClick(Sender: TObject);
begin
  AddLog('Refreshing USB Devices...');
  FAIUSB.Refresh;
  UpdateGrid;
end;

procedure TfrmMain.chkAutoRefreshChange(Sender: TObject);
begin
  FAIUSB.AutoRefresh := chkAutoRefresh.Checked;
  AddLog('AutoRefresh set to ' + BoolToStr(chkAutoRefresh.Checked, True));
end;

procedure TfrmMain.editIntervalChange(Sender: TObject);
var
  Val: Integer;
begin
  if TryStrToInt(editInterval.Text, Val) then
  begin
    FAIUSB.RefreshInterval := Val;
    AddLog('RefreshInterval set to ' + IntToStr(Val) + ' ms');
  end;
end;

procedure TfrmMain.OnDeviceConnected(Sender: TObject; Device: TAIUSBDeviceItem);
begin
  AddLog(Format('[CONNECTED] VID=%s PID=%s Product=%s Manufacturer=%s DeviceID=%s', [
    Device.VendorID, Device.ProductID, Device.Product, Device.Manufacturer, Device.DeviceID
  ]));
  UpdateGrid;
end;

procedure TfrmMain.OnDeviceDisconnected(Sender: TObject; Device: TAIUSBDeviceItem);
begin
  AddLog(Format('[DISCONNECTED] VID=%s PID=%s Product=%s Manufacturer=%s DeviceID=%s', [
    Device.VendorID, Device.ProductID, Device.Product, Device.Manufacturer, Device.DeviceID
  ]));
  UpdateGrid;
end;

procedure TfrmMain.OnDeviceChanged(Sender: TObject; Device: TAIUSBDeviceItem);
begin
  AddLog(Format('[CHANGED] DeviceID=%s VID=%s PID=%s', [
    Device.DeviceID, Device.VendorID, Device.ProductID
  ]));
  UpdateGrid;
end;

procedure TfrmMain.OnError(Sender: TObject; const Msg: string);
begin
  AddLog('[ERROR] ' + Msg);
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Append(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + AMsg);
end;

procedure TfrmMain.UpdateGrid;
var
  I: Integer;
  Device: TAIUSBDeviceItem;
  StateStr: string;
begin
  gridDevices.RowCount := FAIUSB.Count + 1;
  for I := 0 to FAIUSB.Count - 1 do
  begin
    Device := FAIUSB.Devices[I];
    gridDevices.Cells[0, I + 1] := Device.DeviceID;
    gridDevices.Cells[1, I + 1] := Device.VendorID;
    gridDevices.Cells[2, I + 1] := Device.ProductID;
    gridDevices.Cells[3, I + 1] := Device.Manufacturer;
    gridDevices.Cells[4, I + 1] := Device.Product;
    gridDevices.Cells[5, I + 1] := Device.SerialNumber;
    gridDevices.Cells[6, I + 1] := Device.DeviceClass;
    gridDevices.Cells[7, I + 1] := Device.Bus;
    gridDevices.Cells[8, I + 1] := Device.Port;
    
    case Device.State of
      udsUnknown: StateStr := 'Unknown';
      udsConnected: StateStr := 'Connected';
      udsDisconnected: StateStr := 'Disconnected';
      udsChanged: StateStr := 'Changed';
      udsError: StateStr := 'Error';
    else
      StateStr := 'Unknown';
    end;
    
    gridDevices.Cells[9, I + 1] := StateStr;
  end;
end;

end.
