unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiposprinter, imp_generico;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    chkSimulation: TCheckBox;
    btnRun: TButton;
    btnClearLog: TButton;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIPosPrinter: TAIPOSPrinter;
    
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

procedure TfrmMain.ApplySettings;
begin
  case cmbModel.ItemIndex of
    0: FAIPosPrinter.PrinterModel := pmElginI9;
    1: FAIPosPrinter.PrinterModel := pmQR203;
    2: FAIPosPrinter.PrinterModel := pmElginL42DT;
  end;

  FAIPosPrinter.Protocol := TPrinterProtocol(cmbProtocol.ItemIndex);

  if cmbInterface.ItemIndex = 0 then
  begin
    FAIPosPrinter.InterfaceType := piSerial;
    FAIPosPrinter.DeviceName := edtDevice.Text;
    FAIPosPrinter.SerialBaud := StrToIntDef(edtPort.Text, 9600);
  end
  else
  begin
    FAIPosPrinter.InterfaceType := piEthernet;
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
    
    if chkSimulation.Checked then
    begin
      AddLog('Simulating printing:');
      AddLog('  Model: ' + cmbModel.Text);
      AddLog('  Protocol: ' + cmbProtocol.Text);
      
      case FAIPosPrinter.Protocol of
        ppNative:
        begin
          AddLog('Simulating Native OS Canvas Printing:');
          AddLog('  Canvas.TextOut: "DAILY PRODUCTION SUMMARY"');
          AddLog('  Canvas.TextOut: "COMPLETED SUCCESSFULLY"');
          AddLog('  Canvas.TextOut: "-------------------------"');
          AddLog('  Canvas.TextOut: "Count: 100 units"');
          AddLog('  Canvas.TextOut: "[QR Code: Hello World]"');
          AddLog('  Document sent to OS Print Spooler.');
        end;
        ppEpl:
        begin
          LogHexBytes('Clear Buffer (N)', #13#10'N'#10);
          AddLog('  A10,10,0,4,1,1,N,"DAILY PRODUCTION SUMMARY"');
          AddLog('  A10,40,0,4,1,1,N,"COMPLETED SUCCESSFULLY"');
          AddLog('  A10,70,0,4,1,1,N,"-------------------------"');
          AddLog('  A10,100,0,4,1,1,N,"Count: 100 units"');
          AddLog('  b10,130,Q,m2,g3,"Hello World"');
          LogHexBytes('Print label (P1)', 'P1'#10);
        end;
        ppZpl:
        begin
          AddLog('  ^XA');
          AddLog('  ^FO10,10^ADN,18,10^FDDAILY PRODUCTION SUMMARY^FS');
          AddLog('  ^FO10,40^ADN,18,10^FDCOMPLETED SUCCESSFULLY^FS');
          AddLog('  ^FO10,70^ADN,18,10^FD-------------------------^FS');
          AddLog('  ^FO10,100^ADN,18,10^FDCount: 100 units^FS');
          AddLog('  ^FO10,130^BQN,2,4^FDQA,Hello World^FS');
          AddLog('  ^XZ');
        end;
        ppTspl:
        begin
          AddLog('  SIZE 4,3');
          AddLog('  GAP 0,0');
          AddLog('  CLS');
          AddLog('  TEXT 10,10,"4",0,1,1,"DAILY PRODUCTION SUMMARY"');
          AddLog('  TEXT 10,40,"4",0,1,1,"COMPLETED SUCCESSFULLY"');
          AddLog('  TEXT 10,70,"4",0,1,1,"-------------------------"');
          AddLog('  TEXT 10,100,"4",0,1,1,"Count: 100 units"');
          AddLog('  QRCODE 10,130,L,4,A,0,"Hello World"');
          AddLog('  PRINT 1,1');
        end;
        else // ppEscPos
        begin
          LogHexBytes('Init Command', #27'@');
          LogHexBytes('Center Align', #27'a'#1);
          AddLog('  Print text: "DAILY PRODUCTION SUMMARY"');
          LogHexBytes('Bold Enable', #27'E'#1);
          AddLog('  Print bold text: "COMPLETED SUCCESSFULLY"');
          LogHexBytes('Normal Restore', #27'E'#0);
          AddLog('  Print text: "-------------------------"');
          AddLog('  Print text: "Count: 100 units"');
          
          if FAIPosPrinter.PrinterModel = pmElginI9 then
            LogHexBytes('Store/Print QR code', #29'(k'#4#0'1C'#49#0#29'(k'#3#0'1E'#6#29'(k' + Chr(15) + #0 + '1P0Hello World'#29'(k'#3#0'1Q0')
          else
            LogHexBytes('Chinese Mini QR code', #29'k'#11#3#1 + Chr(11) + 'Hello World');
            
          LogHexBytes('Cutter (Guilhotina)', #29'VB'#3);
        end;
      end;
      AddLog('Simulation complete.');
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
  if chkSimulation.Checked then
  begin
    case FAIPosPrinter.Protocol of
      ppNative: AddLog('  Canvas.Font.Style := [fsBold]');
      ppEpl:    AddLog('  Note: Multipliers/Fonts simulated for bold.');
      ppZpl:    AddLog('  Note: Styled fonts simulated.');
      ppTspl:   AddLog('  Note: TSPL text sizes simulated.');
      else
      begin
        LogHexBytes('Bold command', #27'E'#1);
        AddLog('  Simulated Bold Text: "THIS IS BOLD"');
        LogHexBytes('Normal command', #27'E'#0);
      end;
    end;
  end;
end;

procedure TfrmMain.btnBarcodeClick(Sender: TObject);
begin
  AddLog('--- Testing 1D Barcode ---');
  ApplySettings;
  if chkSimulation.Checked then
  begin
    case FAIPosPrinter.Protocol of
      ppNative: AddLog('  Canvas.TextOut: "[Barcode: 123456]"');
      ppEpl:    AddLog('  Simulated EPL2 Barcode: B10,10,0,3,3,6,80,B,"123456"');
      ppZpl:    AddLog('  Simulated ZPL Barcode: ^FO10,10^BY3^BCN,80,Y,N,N^FD123456^FS');
      ppTspl:   AddLog('  Simulated TSPL Barcode: BARCODE 10,10,"128",80,1,0,3,6,"123456"');
      else      LogHexBytes('Barcode command (Code 39)', #29'h'#80#29'w'#3#29'H'#2#29'k'#4'123456'#0);
    end;
  end;
end;

procedure TfrmMain.btnQRCodeClick(Sender: TObject);
begin
  AddLog('--- Testing QR Code ---');
  ApplySettings;
  if chkSimulation.Checked then
  begin
    case FAIPosPrinter.Protocol of
      ppNative: AddLog('  Canvas.TextOut: "[QR Code: https://google.com]"');
      ppEpl:    AddLog('  Simulated EPL2 QR Code: b10,10,Q,m2,g3,"https://google.com"');
      ppZpl:    AddLog('  Simulated ZPL QR Code: ^FO10,10^BQN,2,4^FDQA,https://google.com^FS');
      ppTspl:   AddLog('  Simulated TSPL QR Code: QRCODE 10,10,L,4,A,0,"https://google.com"');
      else
      begin
        if FAIPosPrinter.PrinterModel = pmElginI9 then
          LogHexBytes('Store/Print QR code', #29'(k'#4#0'1C'#49#0#29'(k'#3#0'1E'#6#29'(k' + Chr(18) + #0 + '1P0https://google.com'#29'(k'#3#0'1Q0')
        else
          LogHexBytes('Chinese Mini QR code', #29'k'#11#3#1 + Chr(18) + 'https://google.com');
      end;
    end;
  end;
end;

procedure TfrmMain.btnCutClick(Sender: TObject);
begin
  AddLog('--- Testing Paper Cut / Label Print ---');
  ApplySettings;
  if chkSimulation.Checked then
  begin
    case FAIPosPrinter.Protocol of
      ppNative: AddLog('  Simulated Native OS canvas print finished.');
      ppEpl:    AddLog('  Simulated EPL2 Print command: P1');
      ppZpl:    AddLog('  Simulated ZPL End command: ^XZ');
      ppTspl:   AddLog('  Simulated TSPL Print command: PRINT 1,1');
      else
      begin
        if FAIPosPrinter.PrinterModel = pmElginI9 then
          LogHexBytes('Guillotine command', #29'VB'#3)
        else
          AddLog('  Note: QR203 model does not support paper cut.');
      end;
    end;
  end;
end;

procedure TfrmMain.btnDrawerClick(Sender: TObject);
begin
  AddLog('--- Testing Cash Drawer Kick ---');
  ApplySettings;
  if chkSimulation.Checked then
  begin
    if FAIPosPrinter.Protocol = ppEscPos then
    begin
      if FAIPosPrinter.PrinterModel = pmElginI9 then
        LogHexBytes('Cash Drawer kick command', #16#20#1#0#8)
      else
        AddLog('  Note: Only Elgin i9 model supports drawer kick.');
    end
    else
      AddLog('  Note: Cash Drawer is only supported in ESC/POS mode.');
  end;
end;

procedure TfrmMain.btnBeepClick(Sender: TObject);
begin
  AddLog('--- Testing Printer Beep ---');
  ApplySettings;
  if chkSimulation.Checked then
  begin
    if FAIPosPrinter.Protocol = ppEscPos then
    begin
      if FAIPosPrinter.PrinterModel = pmElginI9 then
        LogHexBytes('Beep command', #27'(A'#5#0'add'#1'dd')
      else if FAIPosPrinter.PrinterModel = pmQR203 then
        LogHexBytes('Standard Bell beep', #7)
      else
        AddLog('  Note: Elgin L42DT does not support beep command.');
    end
    else
      AddLog('  Note: Beep is only supported in ESC/POS mode.');
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
