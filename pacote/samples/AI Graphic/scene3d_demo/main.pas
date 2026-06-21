unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiscene2d3d;

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
    FAIScene: TAIScene2D3D; FEditObjects: TEdit;
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
  AddLog('Scene3D Demo (aiscene2d3d) initialized.');
  FAIScene := TAIScene2D3D.Create(Self);
  
  FEditObjects := TEdit.Create(Self);
  FEditObjects.Parent := pnlTop;
  FEditObjects.Left := 15;
  FEditObjects.Top := 115;
  FEditObjects.Width := 150;
  FEditObjects.Text := 'Cube, Sphere, Light';
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
  FAIScene.TargetFPS := 60;
  FAIScene.GridVisible := True;
  
  AddLog('Scene 3D Properties:');
  AddLog('  TargetFPS: ' + IntToStr(FAIScene.TargetFPS));
  AddLog('  GridVisible: ' + BoolToStr(FAIScene.GridVisible, True));
  
  // Methods to manipulate scene objects
  FAIScene.Clear;
  AddLog('Scene cleared.');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating adding items to scene hierarchy...');
    FAIScene.AddObject(TObject.Create);
    AddLog('Added simulated object.');
    AddLog('Dynamic objects added: 1 item');
    AddLog('Scene compiled structure created (Simulated).');
  end
  else
  begin
    AddLog('Configuring production parameters...');
    try
      FAIScene.Play;
      AddLog('Scene playing: ' + FAIScene.ExportStateJSON);
    except
      on E: Exception do AddLog('OpenGL Rendering Exception: ' + E.Message);
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
