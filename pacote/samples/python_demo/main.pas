unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  pythonconnector;

type

  { TfrmPythonDemo }

  TfrmPythonDemo = class(TForm)
    pnlConfig: TPanel;
    lblDLLPath: TLabel;
    edDLLPath: TEdit;
    btnToggleActive: TButton;
    lblStatusText: TLabel;
    lblVersion: TLabel;
    
    pnlScript: TPanel;
    lblScript: TLabel;
    meScript: TMemo;
    btnExecute: TButton;
    
    pnlVars: TPanel;
    lblVarsTitle: TLabel;
    lblVarName: TLabel;
    edVarName: TEdit;
    lblVarValue: TLabel;
    edVarValue: TEdit;
    btnSetVar: TButton;
    btnGetVar: TButton;
    
    pnlEval: TPanel;
    lblEvalTitle: TLabel;
    lblExpression: TLabel;
    edExpression: TEdit;
    btnEvaluate: TButton;
    lblResult: TLabel;
    edResult: TEdit;
    
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnToggleActiveClick(Sender: TObject);
    procedure btnExecuteClick(Sender: TObject);
    procedure btnSetVarClick(Sender: TObject);
    procedure btnGetVarClick(Sender: TObject);
    procedure btnEvaluateClick(Sender: TObject);
  private
    FConnector: TPythonConnector;
    procedure UpdateStatusUI;
    procedure LogMsg(const AMsg: string);
  public

  end;

var
  frmPythonDemo: TfrmPythonDemo;

implementation

{$R *.lfm}

{ TfrmPythonDemo }

procedure TfrmPythonDemo.FormCreate(Sender: TObject);
begin
  FConnector := TPythonConnector.Create(Self);
  edDLLPath.Text := 'python3.dll'; // DLL padrão copiada para a pasta
  UpdateStatusUI;
  LogMsg('Aplicativo iniciado. DLL padrão "python3.dll" e "python312.dll" copiadas na pasta do executável.');
end;

procedure TfrmPythonDemo.FormDestroy(Sender: TObject);
begin
  // O FConnector será destruído automaticamente pois tem o formulário como Owner (Self)
end;

procedure TfrmPythonDemo.UpdateStatusUI;
begin
  if FConnector.IsInitialized then
  begin
    lblStatusText.Caption := 'Status: ATIVO (Inicializado com sucesso)';
    lblStatusText.Font.Color := clGreen;
    lblVersion.Caption := 'Versão: ' + FConnector.Version;
    btnToggleActive.Caption := 'Desativar Python';
  end
  else
  begin
    lblStatusText.Caption := 'Status: INATIVO';
    lblStatusText.Font.Color := clRed;
    lblVersion.Caption := 'Versão: Desativado';
    btnToggleActive.Caption := 'Ativar interpretador Python';
  end;
end;

procedure TfrmPythonDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmPythonDemo.btnToggleActiveClick(Sender: TObject);
begin
  try
    if FConnector.Active then
    begin
      FConnector.Active := False;
      LogMsg('Interpretador Python desativado.');
    end
    else
    begin
      FConnector.DLLPath := Trim(edDLLPath.Text);
      LogMsg('Tentando carregar DLL do Python: ' + FConnector.DLLPath);
      FConnector.Active := True;
      if FConnector.IsInitialized then
      begin
        LogMsg('Python ativo e pronto.');
        LogMsg('Versão detectada: ' + FConnector.Version);
      end
      else
      begin
        LogMsg('ERRO ao inicializar Python: ' + FConnector.LastError);
        ShowMessage('Falha ao ativar Python: ' + FConnector.LastError);
      end;
    end;
  except
    on E: Exception do
    begin
      LogMsg('Exceção ao alterar estado: ' + E.Message);
      ShowMessage('Erro: ' + E.Message);
    end;
  end;
  UpdateStatusUI;
end;

procedure TfrmPythonDemo.btnExecuteClick(Sender: TObject);
var
  Code: string;
begin
  if not FConnector.IsInitialized then
  begin
    ShowMessage('Ative o interpretador Python antes de executar scripts!');
    Exit;
  end;

  Code := meScript.Text;
  LogMsg('Executando script Python...');
  if FConnector.ExecString(Code) then
    LogMsg('Executado com sucesso!')
  else
  begin
    LogMsg('ERRO de execução: ' + FConnector.LastError);
    ShowMessage('Erro de execução! Verifique o console ou a sintaxe: ' + FConnector.LastError);
  end;
end;

procedure TfrmPythonDemo.btnSetVarClick(Sender: TObject);
var
  VName, VValue: string;
begin
  if not FConnector.IsInitialized then
  begin
    ShowMessage('Ative o interpretador Python antes de gerenciar variáveis!');
    Exit;
  end;

  VName := Trim(edVarName.Text);
  VValue := edVarValue.Text;

  if VName = '' then
  begin
    ShowMessage('Informe o nome da variável!');
    Exit;
  end;

  FConnector.SetVar(VName, VValue);
  LogMsg('Variável "' + VName + '" injetada no Python com o valor: ' + VValue);
end;

procedure TfrmPythonDemo.btnGetVarClick(Sender: TObject);
var
  VName, VValue: string;
begin
  if not FConnector.IsInitialized then
  begin
    ShowMessage('Ative o interpretador Python antes de gerenciar variáveis!');
    Exit;
  end;

  VName := Trim(edVarName.Text);
  if VName = '' then
  begin
    ShowMessage('Informe o nome da variável!');
    Exit;
  end;

  VValue := FConnector.GetVar(VName);
  edVarValue.Text := VValue;
  LogMsg('Variável "' + VName + '" lida do Python. Valor retornado: ' + VValue);
end;

procedure TfrmPythonDemo.btnEvaluateClick(Sender: TObject);
var
  Expr, ResultVal: string;
begin
  if not FConnector.IsInitialized then
  begin
    ShowMessage('Ative o interpretador Python antes de avaliar expressões!');
    Exit;
  end;

  Expr := Trim(edExpression.Text);
  if Expr = '' then
  begin
    ShowMessage('Informe a expressão Python!');
    Exit;
  end;

  LogMsg('Avaliando expressão: ' + Expr);
  ResultVal := FConnector.Eval(Expr);
  edResult.Text := ResultVal;
  LogMsg('Resultado: ' + ResultVal);
end;

end.
