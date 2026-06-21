unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aicodeassistant, chatgpt;

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
    FAICodeAssistant: TAICodeAssistant; FEditLang: TEdit; FMemoCode: TMemo;
    procedure AddLog(const AMsg: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  LBackgroundChatGPT: TCHATGPT;
begin
  AddLog('Codeassistant Demo (aicodeassistant) initialized.');
  FAICodeAssistant := TAICodeAssistant.Create(Self);
  LBackgroundChatGPT := TCHATGPT.Create(Self);
  FAICodeAssistant.ChatGPT := LBackgroundChatGPT;
  
  FEditLang := TEdit.Create(Self);
  FEditLang.Parent := pnlTop;
  FEditLang.Left := 15;
  FEditLang.Top := 115;
  FEditLang.Width := 150;
  FEditLang.Text := 'Object Pascal';
  
  FMemoCode := TMemo.Create(Self);
  FMemoCode.Parent := Self;
  FMemoCode.Left := 10;
  FMemoCode.Top := 150;
  FMemoCode.Width := 780;
  FMemoCode.Height := 150;
  FMemoCode.Lines.Text := 'procedure TForm1.Button1Click(Sender: TObject)'#13#10'begin'#13#10'  ShowMessage("Hello World");'#13#10'end;';
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
  if Assigned(FAICodeAssistant.ChatGPT) then
    FAICodeAssistant.ChatGPT.MaxTokens := 1024;
  
  AddLog('Code Assistant Properties:');
  AddLog('  Language: ' + FEditLang.Text);
  AddLog('  Context: Correct the quotes');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating code analysis...');
    AddLog('Analysis Result: Single quotes are required for strings in Object Pascal. Correct "Hello World" to ''Hello World''.');
    AddLog('Simulated corrected output written.');
  end
  else
  begin
    AddLog('Running actual code assistant...');
    try
      // Method 1: Optimize code
      AddLog('Result: ' + FAICodeAssistant.OptimizeCode(FMemoCode.Lines.Text));
    except
      on E: Exception do AddLog('Error: ' + E.Message);
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
