unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aigraphvisualizer, aigraphmap;

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
    FAIGraphVisualizer: TAIGraphVisualizer; FAIGraphMap: TAIGraphMap;
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
  AddLog('Graph Visualizer Demo (aigraphvisualizer) initialized.');
  FAIGraphMap := TAIGraphMap.Create(Self);
  FAIGraphVisualizer := TAIGraphVisualizer.Create(Self);
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
    FAIGraphVisualizer.GraphMap := FAIGraphMap;
    FAIGraphVisualizer.MinWeight := 0.1;
    FAIGraphVisualizer.TopN := 50;
    
    AddLog('Graph Visualizer Properties:');
    AddLog('  MinWeight: 0.1');
    AddLog('  TopN: 50');
    
    if chkSimulation.Checked then
    begin
      AddLog('Simulating export to Mermaid Graph Flowchart...');
      AddLog('Mermaid Layout:');
      AddLog('graph TD');
      AddLog('  A[Input Layer] -->|w1=0.85| B(Hidden Node 1)');
      AddLog('  A -->|w2=-0.34| C(Hidden Node 2)');
      AddLog('  B -->|w3=0.91| D[Output Result]');
      AddLog('  C -->|w4=0.12| D');
      AddLog('Exported to visual Mermaid formatting successful.');
    end
    else
    begin
      AddLog('Generating graph layout visual details...');
      try
        FAIGraphVisualizer.ExportToMermaid('graph_visual.mmd');
        if FAIGraphVisualizer.LastSuccess then
          AddLog('Graph Layout written to graph_visual.mmd')
        else
          AddLog('Visual Generation failed: ' + FAIGraphVisualizer.LastError);
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
