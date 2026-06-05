unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, ai3dmodelviewer, aimodel3d;

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
    FAI3DViewer: TAI3DModelViewer; FAIModel3D: TAIModel3D; FEditRotation: TEdit;
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
  AddLog('Model3D Viewer Demo (ai3dmodelviewer) initialized.');
  FAIModel3D := TAIModel3D.Create(Self);
  FAI3DViewer := TAI3DModelViewer.Create(Self);
  FAI3DViewer.Model := FAIModel3D;
  
  FEditRotation := TEdit.Create(Self);
  FEditRotation.Parent := pnlTop;
  FEditRotation.Left := 15;
  FEditRotation.Top := 115;
  FEditRotation.Width := 100;
  FEditRotation.Text := '45';
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
    AddLog('3D Model Viewer & Model 3D Properties:');
    AddLog('  Rotation: ' + FEditRotation.Text + ' degrees');
    
    if chkSimulation.Checked then
    begin
      AddLog('Simulating 3D Model load...');
      FAIModel3D.LoadFromFile('sample_part.stl');
      AddLog('Model details (Simulated):');
      AddLog('  Vertices: 1424');
      AddLog('  Faces: 2848');
      AddLog('Rotated 3D view by ' + FEditRotation.Text + ' degrees.');
      AddLog('View rendered successfully.');
    end
    else
    begin
      AddLog('Loading actual model coordinates...');
      try
        if FileExists('sample_part.stl') then
        begin
          FAIModel3D.LoadFromFile('sample_part.stl');
          AddLog('Model loaded successfully.');
          FAIModel3D.Rotate(StrToIntDef(FEditRotation.Text, 45), 0, 0);
          FAI3DViewer.Invalidate;
          AddLog('Invalidate redraw method executed.');
        end
        else
          AddLog('Model file not found: sample_part.stl');
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
