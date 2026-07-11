unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiposprinter, aiprinter_types, ailistprinters;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    btnRun: TButton;
    btnClearLog: TButton;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIPosPrinter: TAIPOSPrinter;
    FListPrinters: TAIListPrinters;
    
    // Dynamic controls
    cmbModel: TComboBox;
    cmbInterface: TComboBox;
    cmbProtocol: TComboBox;
    edtDevice: TEdit;
    edtPort: TEdit;
    
    btnBoldText: TButton;
    btnBarcode: TButton;
    btnQRCode: TButton;
    btnCut: TButton;
    btnDrawer: TButton;
    btnBeep: TButton;
    
    procedure cmbInterfaceChange(Sender: TObject);
    procedure cmbProtocolChange(Sender: TObject);
    procedure btnBoldTextClick(Sender: TObject);
    procedure btnBarcodeClick(Sender: TObject);
    procedure btnQRCodeClick(Sender: TObject);
    procedure btnCutClick(Sender: TObject);
    procedure btnDrawerClick(Sender: TObject);
    procedure btnBeepClick(Sender: TObject);
    
    procedure ApplySettings;
    procedure AddLog(const AMsg: string);
    procedure LogHexBytes(const ALabel: string; const ABytes: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  lblModel, lblInterface, lblProtocol, lblDevice, lblPort: TLabel;
begin
  pnlTop.Height := 200;
  AddLog('Posprinter Demo (aiposprinter) initialized.');
  
  FAIPosPrinter := TAIPOSPrinter.Create(Self);
  FListPrinters := TAIListPrinters.Create(Self);

  // Row 1 Layout Labels
  lblModel := TLabel.Create(Self);
  lblModel.Parent := pnlTop;
  lblModel.Left := 180;
  lblModel.Top := 50;
  lblModel.Caption := 'Printer Model:';
  
  lblInterface := TLabel.Create(Self);
  lblInterface.Parent := pnlTop;
  lblInterface.Left := 300;
  lblInterface.Top := 50;
  lblInterface.Caption := 'Interface:';

  lblProtocol := TLabel.Create(Self);
  lblProtocol.Parent := pnlTop;
  lblProtocol.Left := 410;
  lblProtocol.Top := 50;
  lblProtocol.Caption := 'Protocol:';
  
  lblDevice := TLabel.Create(Self);
  lblDevice.Parent := pnlTop;
  lblDevice.Left := 520;
  lblDevice.Top := 50;
  lblDevice.Caption := 'Port/IP:';

  lblPort := TLabel.Create(Self);
  lblPort.Parent := pnlTop;
  lblPort.Left := 650;
  lblPort.Top := 50;
  lblPort.Caption := 'Baud/Port:';

  // Row 1 Controls
  cmbModel := TComboBox.Create(Self);
  cmbModel.Parent := pnlTop;
  cmbModel.Left := 180;
  cmbModel.Top := 70;
  cmbModel.Width := 110;
  cmbModel.Style := csDropDownList;
  cmbModel.Items.Add('Elgin i9 (80mm)');
  cmbModel.Items.Add('QR203 (58mm)');
  cmbModel.Items.Add('Elgin L42DT (Label)');
  cmbModel.ItemIndex := 0;

  cmbInterface := TComboBox.Create(Self);
  cmbInterface.Parent := pnlTop;
  cmbInterface.Left := 300;
  cmbInterface.Top := 70;
  cmbInterface.Width := 100;
  cmbInterface.Style := csDropDownList;
  cmbInterface.Items.Add('Serial (COM)');
  cmbInterface.Items.Add('Ethernet (TCP)');
  cmbInterface.ItemIndex := 1; // Ethernet default
  cmbInterface.OnChange := @cmbInterfaceChange;

  cmbProtocol := TComboBox.Create(Self);
  cmbProtocol.Parent := pnlTop;
  cmbProtocol.Left := 410;
  cmbProtocol.Top := 70;
  cmbProtocol.Width := 100;
  cmbProtocol.Style := csDropDownList;
  cmbProtocol.Items.Add('ESC/POS');
  cmbProtocol.Items.Add('Native OS');
  cmbProtocol.Items.Add('EPL');
  cmbProtocol.Items.Add('ZPL');
  cmbProtocol.Items.Add('TSPL');
  cmbProtocol.ItemIndex := 0; // ESC/POS default
  cmbProtocol.OnChange := @cmbProtocolChange;

  edtDevice := TEdit.Create(Self);
  edtDevice.Parent := pnlTop;
  edtDevice.Left := 520;
  edtDevice.Top := 70;
  edtDevice.Width := 120;
  edtDevice.Text := '127.0.0.1';

  edtPort := TEdit.Create(Self);
  edtPort.Parent := pnlTop;
  edtPort.Left := 650;
  edtPort.Top := 70;
  edtPort.Width := 80;
  edtPort.Text := '9100';

  // Reposition existing main form controls
  btnRun.Left := 15;
  btnRun.Top := 115;
  btnRun.Width := 150;
  btnRun.Caption := 'Print Test Receipt';

  // New action buttons
  btnBoldText := TButton.Create(Self);
  btnBoldText.Parent := pnlTop;
  btnBoldText.Left := 175;
  btnBoldText.Top := 115;
  btnBoldText.Width := 90;
  btnBoldText.Caption := 'Test Bold';
  btnBoldText.OnClick := @btnBoldTextClick;

  btnBarcode := TButton.Create(Self);
  btnBarcode.Parent := pnlTop;
  btnBarcode.Left := 275;
  btnBarcode.Top := 115;
  btnBarcode.Width := 90;
  btnBarcode.Caption := 'Test Barcode';
  btnBarcode.OnClick := @btnBarcodeClick;

  btnQRCode := TButton.Create(Self);
  btnQRCode.Parent := pnlTop;
  btnQRCode.Left := 375;
  btnQRCode.Top := 115;
  btnQRCode.Width := 90;
  btnQRCode.Caption := 'Test QR Code';
  btnQRCode.OnClick := @btnQRCodeClick;

  btnCut := TButton.Create(Self);
  btnCut.Parent := pnlTop;
  btnCut.Left := 475;
  btnCut.Top := 115;
  btnCut.Width := 90;
  btnCut.Caption := 'Cut Paper';
  btnCut.OnClick := @btnCutClick;

  btnDrawer := TButton.Create(Self);
  btnDrawer.Parent := pnlTop;
  btnDrawer.Left := 575;
  btnDrawer.Top := 115;
  btnDrawer.Width := 95;
  btnDrawer.Caption := 'Open Drawer';
  btnDrawer.OnClick := @btnDrawerClick;

  btnBeep := TButton.Create(Self);
  btnBeep.Parent := pnlTop;
  btnBeep.Left := 680;
  btnBeep.Top := 115;
  btnBeep.Width := 80;
  btnBeep.Caption := 'Beep';
  btnBeep.OnClick := @btnBeepClick;

  btnClearLog.Left := 15;
  btnClearLog.Top := 155;
  btnClearLog.Width := 150;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.cmbInterfaceChange(Sender: TObject);
begin
  if cmbInterface.ItemIndex = 0 then
  begin
    edtDevice.Text := 'COM1';
    edtPort.Text := '9600';
  end
  else
  begin
    edtDevice.Text := '127.0.0.1';
    edtPort.Text := '9100';
  end;
end;

procedure TfrmMain.cmbProtocolChange(Sender: TObject);
var
  IsRaw: Boolean;
begin
  IsRaw := cmbProtocol.ItemIndex <> 1; // 1 is Native OS
  cmbInterface.Enabled := IsRaw;
  edtPort.Enabled := IsRaw;
  
  if not IsRaw then
  begin
    // For Native OS, pre-fill edtDevice with the default printer name
    if edtDevice.Text = '127.0.0.1' then
      edtDevice.Text := FListPrinters.DefaultPrinter;
  end
  else
  begin
    // For Raw protocols, if it has default printer name, restore default loopback IP
    if edtDevice.Text = FListPrinters.DefaultPrinter then
      edtDevice.Text := '127.0.0.1';
  end;
end;

procedure TfrmMain.ApplySettings;
begin
  case cmbModel.ItemIndex of
    0: FAIPosPrinter.PrinterModel := pmElginI9;
    1: FAIPosPrinter.PrinterModel := pmQR203;
    2: FAIPosPrinter.PrinterModel := pmElginL42DT;
  end;

  case cmbProtocol.ItemIndex of
    0: begin // ESC/POS
         FAIPosPrinter.Language := plEscPos;
         FAIPosPrinter.RenderMode := rmRawCommand;
       end;
    1: begin // Native OS
         FAIPosPrinter.RenderMode := rmNativeCanvas;
       end;
    2: begin // EPL
         FAIPosPrinter.Language := plEpl;
         FAIPosPrinter.RenderMode := rmRawCommand;
       end;
    3: begin // ZPL
         FAIPosPrinter.Language := plZpl;
         FAIPosPrinter.RenderMode := rmRawCommand;
       end;
    4: begin // TSPL
         FAIPosPrinter.Language := plTspl;
         FAIPosPrinter.RenderMode := rmRawCommand;
       end;
  end;

  if cmbInterface.ItemIndex = 0 then
  begin
    FAIPosPrinter.TransportKind := ptSerial;
    FAIPosPrinter.DeviceName := edtDevice.Text;
    FAIPosPrinter.SerialBaud := StrToIntDef(edtPort.Text, 9600);
  end
  else
  begin
    FAIPosPrinter.TransportKind := ptTcp9100;
    FAIPosPrinter.Host := edtDevice.Text;
    FAIPosPrinter.Port := StrToIntDef(edtPort.Text, 9100);
  end;
end;

procedure TfrmMain.LogHexBytes(const ALabel: string; const ABytes: string);
var
  S: string;
  I: Integer;
begin
  S := '';
  for I := 1 to Length(ABytes) do
  begin
    if S <> '' then S := S + ' ';
    S := S + Format('$%02X', [Byte(ABytes[I])]);
  end;
  AddLog('  ' + ALabel + ': ' + S);
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Printing Full Test Receipt/Label ---');
  try
    ApplySettings;
    
    FAIPosPrinter.Active := True;
    try
      if not FAIPosPrinter.BeginJob then
      begin
        AddLog('Error: BeginJob failed.');
        Exit;
      end;
      
      FAIPosPrinter.AlignCenter;
      FAIPosPrinter.PrintTextLine('DAILY PRODUCTION SUMMARY');
      FAIPosPrinter.SetBold(True);
      FAIPosPrinter.PrintTextLine('COMPLETED SUCCESSFULLY');
      FAIPosPrinter.SetBold(False);
      FAIPosPrinter.PrintTextLine('-------------------------');
      FAIPosPrinter.PrintTextLine('Count: 100 units');
      
      FAIPosPrinter.PrintQRCode('Hello World');
      FAIPosPrinter.CutPaper;
      
      FAIPosPrinter.EndJob;
      
      if FAIPosPrinter.PrintJob then
      begin
        AddLog('Job sent to printer successfully.');
        AddLog('Bytes sent: ' + IntToStr(FAIPosPrinter.LastBytesSent));
        if FAIPosPrinter.LastCommandHex <> '' then
          AddLog('Command Hex: ' + FAIPosPrinter.LastCommandHex);
      end
      else
        AddLog('Error: PrintJob failed. ' + FAIPosPrinter.LastError);
    finally
      FAIPosPrinter.Active := False;
    end;
  except
    on E: Exception do
    begin
      AddLog('Critical Error: ' + E.Message);
      lblStatus.Caption := 'Status: Execution Error';
    end;
  end;
  AddLog('--- Execution Finished ---');
end;

procedure TfrmMain.btnBoldTextClick(Sender: TObject);
begin
  AddLog('--- Testing Bold/Text Style ---');
  ApplySettings;
  FAIPosPrinter.Active := True;
  try
    FAIPosPrinter.BeginJob;
    FAIPosPrinter.SetBold(True);
    FAIPosPrinter.PrintTextLine('THIS IS BOLD');
    FAIPosPrinter.SetBold(False);
    FAIPosPrinter.EndJob;
    if FAIPosPrinter.PrintJob then
    begin
      AddLog('Bold text job sent.');
      if FAIPosPrinter.LastCommandHex <> '' then
        AddLog('Hex: ' + FAIPosPrinter.LastCommandHex);
    end
    else
      AddLog('Error sending bold job: ' + FAIPosPrinter.LastError);
  finally
    FAIPosPrinter.Active := False;
  end;
end;

procedure TfrmMain.btnBarcodeClick(Sender: TObject);
begin
  AddLog('--- Testing 1D Barcode ---');
  ApplySettings;
  FAIPosPrinter.Active := True;
  try
    FAIPosPrinter.BeginJob;
    FAIPosPrinter.PrintBarcode('123456');
    FAIPosPrinter.EndJob;
    if FAIPosPrinter.PrintJob then
    begin
      AddLog('Barcode job sent.');
      if FAIPosPrinter.LastCommandHex <> '' then
        AddLog('Hex: ' + FAIPosPrinter.LastCommandHex);
    end
    else
      AddLog('Error sending barcode job: ' + FAIPosPrinter.LastError);
  finally
    FAIPosPrinter.Active := False;
  end;
end;

procedure TfrmMain.btnQRCodeClick(Sender: TObject);
begin
  AddLog('--- Testing QR Code ---');
  ApplySettings;
  FAIPosPrinter.Active := True;
  try
    FAIPosPrinter.BeginJob;
    FAIPosPrinter.PrintQRCode('https://google.com');
    FAIPosPrinter.EndJob;
    if FAIPosPrinter.PrintJob then
    begin
      AddLog('QR Code job sent.');
      if FAIPosPrinter.LastCommandHex <> '' then
        AddLog('Hex: ' + FAIPosPrinter.LastCommandHex);
    end
    else
      AddLog('Error sending QR Code job: ' + FAIPosPrinter.LastError);
  finally
    FAIPosPrinter.Active := False;
  end;
end;

procedure TfrmMain.btnCutClick(Sender: TObject);
begin
  AddLog('--- Testing Paper Cut ---');
  ApplySettings;
  FAIPosPrinter.Active := True;
  try
    FAIPosPrinter.BeginJob;
    FAIPosPrinter.CutPaper;
    FAIPosPrinter.EndJob;
    if FAIPosPrinter.PrintJob then
    begin
      AddLog('Paper cut command sent.');
      if FAIPosPrinter.LastCommandHex <> '' then
        AddLog('Hex: ' + FAIPosPrinter.LastCommandHex);
    end
    else
      AddLog('Error sending paper cut job: ' + FAIPosPrinter.LastError);
  finally
    FAIPosPrinter.Active := False;
  end;
end;

procedure TfrmMain.btnDrawerClick(Sender: TObject);
begin
  AddLog('--- Testing Cash Drawer Kick ---');
  ApplySettings;
  FAIPosPrinter.Active := True;
  try
    FAIPosPrinter.BeginJob;
    FAIPosPrinter.OpenDrawer;
    FAIPosPrinter.EndJob;
    if FAIPosPrinter.PrintJob then
    begin
      AddLog('Cash drawer command sent.');
      if FAIPosPrinter.LastCommandHex <> '' then
        AddLog('Hex: ' + FAIPosPrinter.LastCommandHex);
    end
    else
      AddLog('Error sending cash drawer job: ' + FAIPosPrinter.LastError);
  finally
    FAIPosPrinter.Active := False;
  end;
end;

procedure TfrmMain.btnBeepClick(Sender: TObject);
begin
  AddLog('--- Testing Printer Beep ---');
  ApplySettings;
  FAIPosPrinter.Active := True;
  try
    FAIPosPrinter.BeginJob;
    FAIPosPrinter.Beep;
    FAIPosPrinter.EndJob;
    if FAIPosPrinter.PrintJob then
    begin
      AddLog('Beep command sent.');
      if FAIPosPrinter.LastCommandHex <> '' then
        AddLog('Hex: ' + FAIPosPrinter.LastCommandHex);
    end
    else
      AddLog('Error sending beep job: ' + FAIPosPrinter.LastError);
  finally
    FAIPosPrinter.Active := False;
  end;
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
end;

end.
