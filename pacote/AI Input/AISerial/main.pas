unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Grids, ailistserialdevices;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    btnRefresh: TButton;
    chkAutoRefresh: TCheckBox;
    chkProbeOpenable: TCheckBox;
    gridDevices: TStringGrid;
    timerAutoRefresh: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure chkAutoRefreshChange(Sender: TObject);
    procedure chkProbeOpenableChange(Sender: TObject);
    procedure timerAutoRefreshTimer(Sender: TObject);
    procedure OnDeviceFound(Sender: TObject; Device: TAIListSerialDeviceItem);
    procedure OnDeviceRemoved(Sender: TObject; const ADeviceName: string);
    procedure OnDeviceChanged(Sender: TObject; Device: TAIListSerialDeviceItem);
    procedure OnDeviceIdentified(Sender: TObject; Device: TAIListSerialDeviceItem);
  private
    FAIListSerialDevices: TAIListSerialDevices;
    procedure UpdateGrid;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FAIListSerialDevices := TAIListSerialDevices.Create(Self);
  FAIListSerialDevices.OnDeviceFound := @OnDeviceFound;
  FAIListSerialDevices.OnDeviceRemoved := @OnDeviceRemoved;
  FAIListSerialDevices.OnDeviceChanged := @OnDeviceChanged;
  FAIListSerialDevices.OnDeviceIdentified := @OnDeviceIdentified;

  // Setup StringGrid
  gridDevices.ColCount := 11;
  gridDevices.RowCount := 1;
  gridDevices.Cells[0, 0] := 'Porta';
  gridDevices.Cells[1, 0] := 'Nome';
  gridDevices.Cells[2, 0] := 'Tipo';
  gridDevices.Cells[3, 0] := 'Disponível';
  gridDevices.Cells[4, 0] := 'Abrível';
  gridDevices.Cells[5, 0] := 'VID';
  gridDevices.Cells[6, 0] := 'PID';
  gridDevices.Cells[7, 0] := 'Fabricante';
  gridDevices.Cells[8, 0] := 'Produto';
  gridDevices.Cells[9, 0] := 'Confiança';
  gridDevices.Cells[10, 0] := 'Erro';

  // Apply default values
  chkProbeOpenable.Checked := FAIListSerialDevices.ProbeOpenable;
  chkAutoRefresh.Checked := FAIListSerialDevices.AutoRefresh;
  timerAutoRefresh.Interval := FAIListSerialDevices.AutoRefreshIntervalMs;
  timerAutoRefresh.Enabled := chkAutoRefresh.Checked;

  UpdateGrid;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // FAIListSerialDevices is owned by Self, will be freed automatically.
end;

procedure TfrmMain.btnRefreshClick(Sender: TObject);
begin
  FAIListSerialDevices.Refresh;
  UpdateGrid;
end;

procedure TfrmMain.chkAutoRefreshChange(Sender: TObject);
begin
  FAIListSerialDevices.AutoRefresh := chkAutoRefresh.Checked;
  timerAutoRefresh.Enabled := chkAutoRefresh.Checked;
end;

procedure TfrmMain.chkProbeOpenableChange(Sender: TObject);
begin
  FAIListSerialDevices.ProbeOpenable := chkProbeOpenable.Checked;
  FAIListSerialDevices.Refresh;
  UpdateGrid;
end;

procedure TfrmMain.timerAutoRefreshTimer(Sender: TObject);
begin
  if chkAutoRefresh.Checked then
  begin
    FAIListSerialDevices.Refresh;
    UpdateGrid;
  end;
end;

procedure TfrmMain.OnDeviceFound(Sender: TObject; Device: TAIListSerialDeviceItem);
begin
  // Handle log or status if needed
end;

procedure TfrmMain.OnDeviceRemoved(Sender: TObject; const ADeviceName: string);
begin
  // Handle log or status if needed
end;

procedure TfrmMain.OnDeviceChanged(Sender: TObject; Device: TAIListSerialDeviceItem);
begin
  // Handle log or status if needed
end;

procedure TfrmMain.OnDeviceIdentified(Sender: TObject; Device: TAIListSerialDeviceItem);
begin
  // Handle log or status if needed
end;

procedure TfrmMain.UpdateGrid;
var
  I: Integer;
  Device: TAIListSerialDeviceItem;
  KindStr: string;
begin
  gridDevices.RowCount := FAIListSerialDevices.Count + 1;
  for I := 0 to FAIListSerialDevices.Count - 1 do
  begin
    Device := FAIListSerialDevices.Devices[I];
    gridDevices.Cells[0, I + 1] := Device.DeviceName;
    gridDevices.Cells[1, I + 1] := Device.DisplayName;
    
    case Device.PortKind of
      spkUnknown: KindStr := 'Desconhecido';
      spkSystem: KindStr := 'Sistema';
      spkUSBSerial: KindStr := 'USB Serial';
      spkBluetooth: KindStr := 'Bluetooth';
      spkVirtual: KindStr := 'Virtual';
      spkArduinoCompatible: KindStr := 'Arduino';
    else
      KindStr := 'Desconhecido';
    end;
    
    gridDevices.Cells[2, I + 1] := KindStr;
    
    if Device.IsAvailable then
      gridDevices.Cells[3, I + 1] := 'Sim'
    else
      gridDevices.Cells[3, I + 1] := 'Não';

    if Device.IsOpenable then
      gridDevices.Cells[4, I + 1] := 'Sim'
    else
      gridDevices.Cells[4, I + 1] := 'Não';

    gridDevices.Cells[5, I + 1] := Device.VID;
    gridDevices.Cells[6, I + 1] := Device.PID;
    gridDevices.Cells[7, I + 1] := Device.Manufacturer;
    gridDevices.Cells[8, I + 1] := Device.Product;
    gridDevices.Cells[9, I + 1] := IntToStr(Device.Confidence);
    gridDevices.Cells[10, I + 1] := Device.LastError;
  end;
end;

end.
