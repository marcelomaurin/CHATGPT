unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiimageinfo;

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
    FAIImageInfo: TAIImageInfo; FEditFile: TEdit;
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
  AddLog('Image Info Demo (aiimageinfo) initialized.');
  FAIImageInfo := TAIImageInfo.Create(Self);
  
  FEditFile := TEdit.Create(Self);
  FEditFile.Parent := pnlTop;
  FEditFile.Left := 15;
  FEditFile.Top := 115;
  FEditFile.Width := 300;
  FEditFile.Text := 'image.png';
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
  AddLog('Image Info Properties & Methods Demo:');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating header info lookup...');
    FAIImageInfo.LoadFromFile(FEditFile.Text);
    AddLog('Image Details (Simulated):');
    AddLog('  Width: 800 px');
    AddLog('  Height: 600 px');
    AddLog('  BitDepth: 24 bits');
    AddLog('  Format: PNG');
    AddLog('  HasAlpha: True');
  end
  else
  begin
    AddLog('Reading image file headers: ' + FEditFile.Text);
    try
      if FAIImageInfo.LoadFromFile(FEditFile.Text) then
      begin
        AddLog('Image loaded successfully.');
        AddLog('  Dimensions: ' + IntToStr(FAIImageInfo.Width) + 'x' + IntToStr(FAIImageInfo.Height));
        AddLog('  Format: ' + FAIImageInfo.FormatName);
      end
      else
        AddLog('Failed to read image header properties.');
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
