unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, numps;

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
    FAINumps: TNumPS; FEditArr: TEdit;
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
  AddLog('Numps Demo (numps) initialized.');
  FAINumps := TNumPS.Create(Self);
  
  FEditArr := TEdit.Create(Self);
  FEditArr.Parent := pnlTop;
  FEditArr.Left := 15;
  FEditArr.Top := 115;
  FEditArr.Width := 300;
  FEditArr.Text := '1.2, 4.5, -2.3, 0.0, 8.1';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
  FAINumps.ArrayString := FEditArr.Text;
  
  AddLog('NumPS Array Properties:');
  AddLog('  Input Array String: ' + FAINumps.ArrayString);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating array statistic calculations...');
    AddLog('Parsed vector length: 5');
    AddLog('Array Min: -2.3');
    AddLog('Array Max: 8.1');
    AddLog('Array Mean: 2.3');
    AddLog('Standard Deviation: 3.75');
    AddLog('Simulation complete.');
  end
  else
  begin
    AddLog('Parsing array with NumPS utilities...');
    try
      FAINumps.ParseArray;
      AddLog('Parsed items count: ' + IntToStr(FAINumps.Count));
      AddLog('Mean: ' + FloatToStr(FAINumps.Mean));
    except
      on E: Exception do AddLog('Exception: ' + E.Message);
    end;
  end;
    lblStatus.Caption := 'Status: Completed Successfully';
  except
    on E: Exception do
    begin
      AddLog('Critical Error: ' + E.Message);
      lblStatus.Caption := 'Status: Execution Error';
    end;
  end;
  AddLog('--- Execution Finished ---');
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
