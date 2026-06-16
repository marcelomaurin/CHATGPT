unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aipromptbuilder;

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
    FAIPromptBuilder: TAIPromptBuilder; FEditContext: TEdit; FEditRules: TEdit; FEditQuestion: TEdit;
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
  AddLog('Promptbuilder Demo (aipromptbuilder) initialized.');
  FAIPromptBuilder := TAIPromptBuilder.Create(Self);
  
  FEditContext := TEdit.Create(Self);
  FEditContext.Parent := pnlTop;
  FEditContext.Left := 15;
  FEditContext.Top := 115;
  FEditContext.Width := 300;
  FEditContext.Text := 'You are a helpful software engineer assistant.';
  
  FEditRules := TEdit.Create(Self);
  FEditRules.Parent := pnlTop;
  FEditRules.Left := 330;
  FEditRules.Top := 115;
  FEditRules.Width := 200;
  FEditRules.Text := 'Answer in bullet points.';
  
  FEditQuestion := TEdit.Create(Self);
  FEditQuestion.Parent := pnlTop;
  FEditQuestion.Left := 540;
  FEditQuestion.Top := 115;
  FEditQuestion.Width := 200;
  FEditQuestion.Text := 'Explain Pascal properties.';
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
  FAIPromptBuilder.IncludeComponentNames := True;
  FAIPromptBuilder.IncludeOnlyAIComponents := False;
  FAIPromptBuilder.Language := plEnglish;
  FAIPromptBuilder.OutputFormat := pofMarkdown;
  
  AddLog('Prompt Builder Properties:');
  AddLog('  IncludeComponentNames: ' + BoolToStr(FAIPromptBuilder.IncludeComponentNames, True));
  AddLog('  Language: plEnglish');
  AddLog('  OutputFormat: pofMarkdown');
  
  if chkSimulation.Checked then
  begin
    AddLog('Running in Simulated Mode...');
    AddLog('Generated System Prompt Context:');
    AddLog('System Prompt: [Context: ' + FEditContext.Text + ' | Rules: ' + FEditRules.Text + ']');
    AddLog('User Question: ' + FEditQuestion.Text);
    AddLog('LastPrompt property updated in background.');
    FAIPromptBuilder.LastPrompt := '[Simulated Prompt]';
    AddLog('Method BuildFromOwner called successfully.');
  end
  else
  begin
    AddLog('Running in Production Mode...');
    try
      FAIPromptBuilder.BuildFromOwner(Self);
      AddLog('LastPrompt: ' + FAIPromptBuilder.LastPrompt);
    except
      on E: Exception do
        AddLog('Error building prompt: ' + E.Message);
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
