unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aitrainingexporter, aigraphmap;

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
    FAITrainingExporter: TAITrainingExporter; FAIGraphMap: TAIGraphMap; FEditFile: TEdit;
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
  AddLog('Training Exporter Demo (aitrainingexporter) initialized.');
  FAIGraphMap := TAIGraphMap.Create(Self);
  FAITrainingExporter := TAITrainingExporter.Create(Self);
  
  FEditFile := TEdit.Create(Self);
  FEditFile.Parent := pnlTop;
  FEditFile.Left := 15;
  FEditFile.Top := 115;
  FEditFile.Width := 300;
  FEditFile.Text := 'exported_training.csv';
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
  // Bind training exporter parameters
  FAITrainingExporter.FileName := FEditFile.Text;
  FAITrainingExporter.GraphMap := FAIGraphMap;
  
  AddLog('Training Exporter Properties:');
  AddLog('  FileName: ' + FAITrainingExporter.FileName);
  AddLog('  GraphMap Reference Assigned: ' + BoolToStr(FAITrainingExporter.GraphMap <> nil, True));
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating export of graph map dataset...');
    AddLog('Graph contains: 5 nodes, 8 connections.');
    AddLog('Saving dataset vector pairings to simulated CSV:');
    AddLog('  "Node1","Node2",0.85');
    AddLog('  "Node2","Node3",0.42');
    AddLog('Export successful (Simulated).');
  end
  else
  begin
    AddLog('Exporting dataset weights...');
    try
      if FAITrainingExporter.ExportToCSV then
        AddLog('Dataset CSV exported to: ' + FAITrainingExporter.FileName)
      else
        AddLog('Export failed: ' + FAITrainingExporter.LastError);
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
