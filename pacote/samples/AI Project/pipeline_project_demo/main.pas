unit main;

{$mode objfpc}{$H+}
{$M+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, chatgpt, aipipeline, aiproject_core;

type

  { TfrmPipelineProjectDemo }

  TfrmPipelineProjectDemo = class(TForm)
    pnlTop: TPanel;
    pnlLeft: TPanel;
    btnExecutarPipeline: TButton;
    btnGerarPrompt: TButton;
    btnClear: TButton;
    lblPrompt: TLabel;
    edtPrompt: TEdit;
    lblProject: TLabel;
    edtProjectName: TEdit;
    pcResults: TPageControl;
    tsResultado: TTabSheet;
    memResultado: TMemo;
    tsSystemPrompt: TTabSheet;
    memSystemPrompt: TMemo;
    tsLogs: TTabSheet;
    memLogs: TMemo;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnExecutarPipelineClick(Sender: TObject);
    procedure btnGerarPromptClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
  private
    FChatGPT: TCHATGPT;
    FPipeline: TAIPipeline;
    FAIProject: TAIProject;
    procedure SetupComponents;
  public

  end;

var
  frmPipelineProjectDemo: TfrmPipelineProjectDemo;

implementation

{$R *.lfm}

{ TfrmPipelineProjectDemo }

procedure TfrmPipelineProjectDemo.FormCreate(Sender: TObject);
begin
  SetupComponents;
end;

procedure TfrmPipelineProjectDemo.FormDestroy(Sender: TObject);
begin
  FPipeline.Free;
  FAIProject.Free;
  FChatGPT.Free;
end;

procedure TfrmPipelineProjectDemo.SetupComponents;
begin
  FChatGPT := TCHATGPT.Create(Self);
  FChatGPT.Prompt := 'Você é um assistente de arquitetura.';

  FPipeline := TAIPipeline.Create(Self);
  FPipeline.ChatGPT := FChatGPT;
  FPipeline.Mode := pmTextLLM;

  FAIProject := TAIProject.Create;
  FAIProject.Name := 'MNote2 Visual Studio IDE';
  FAIProject.Description := 'IDE Desktop com suporte a IA e componentes Lazarus.';
end;

procedure TfrmPipelineProjectDemo.btnGerarPromptClick(Sender: TObject);
begin
  memLogs.Lines.Add('Exibindo dados do projeto...');
  memSystemPrompt.Lines.Clear;
  memSystemPrompt.Lines.Add('Nome do Projeto: ' + FAIProject.Name);
  memSystemPrompt.Lines.Add('Descrição: ' + FAIProject.Description);
  memSystemPrompt.Lines.Add('Objetivo: ' + FAIProject.Goal);
  memSystemPrompt.Lines.Add('Escopo: ' + FAIProject.Scope);
  memSystemPrompt.Lines.Add('Restrições: ' + FAIProject.Constraints);
  pcResults.ActivePage := tsSystemPrompt;
  memLogs.Lines.Add('Dados do projeto gerados com sucesso.');
end;

procedure TfrmPipelineProjectDemo.btnExecutarPipelineClick(Sender: TObject);
begin
  if Trim(edtPrompt.Text) = '' then
  begin
    ShowMessage('Digite um prompt para o pipeline!');
    Exit;
  end;

  memLogs.Lines.Add('Executando Pipeline...');
  FPipeline.InputText := edtPrompt.Text;

  if FPipeline.Run then
  begin
    memResultado.Text := FPipeline.OutputText;
    pcResults.ActivePage := tsResultado;
    memLogs.Lines.Add('Pipeline executado com sucesso.');
  end
  else
  begin
    memResultado.Text := 'ERRO: ' + FPipeline.LastError;
    memLogs.Lines.Add('Erro no Pipeline: ' + FPipeline.LastError);
    ShowMessage('Erro: ' + FPipeline.LastError);
  end;
end;

procedure TfrmPipelineProjectDemo.btnClearClick(Sender: TObject);
begin
  memResultado.Clear;
  memSystemPrompt.Clear;
  memLogs.Clear;
end;

end.
