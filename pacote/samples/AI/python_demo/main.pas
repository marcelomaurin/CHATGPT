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
    lbDLLs: TListBox;
    btnToggleActive: TButton;
    chkProcessMode: TCheckBox;
    lblStatusText: TLabel;
    lblVersion: TLabel;
    
    pnlScript: TPanel;
    lblScript: TLabel;
    meScript: TMemo;
    btnExecute: TButton;
    
    pnlOutput: TPanel;
    lblOutput: TLabel;
    meOutput: TMemo;
    
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
    
    pnlLogs: TPanel;
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
var
  SR: TSearchRec;
  AppDir, Ext: string;
  ArchStr: string;
  I: Integer;
begin
  FConnector := TPythonConnector.Create(Self);

  // Detect platform bitness
  {$IFDEF CPU64}
  ArchStr := '64-bit';
  Ext := '.dll';
  {$ELSE}
  ArchStr := '32-bit';
  Ext := '.dll';
  {$ENDIF}

  lblDLLPath.Caption := 'Escolha a DLL do Python (' + ArchStr + '):';

  // Search and populate ListBox
  lbDLLs.Items.Clear;
  AppDir := ExtractFilePath(ParamStr(0));
  
  if FindFirst(AppDir + 'python*' + Ext, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory) = 0 then
        lbDLLs.Items.Add(AppDir + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;

  // Add default candidate paths
  {$IFDEF MSWINDOWS}
  lbDLLs.Items.Add('python3.dll');
  {$IFDEF CPU64}
  lbDLLs.Items.Add('python3_64.dll');
  {$ELSE}
  lbDLLs.Items.Add('python3_32.dll');
  {$ENDIF}
  lbDLLs.Items.Add('python312.dll');
  lbDLLs.Items.Add('python311.dll');
  lbDLLs.Items.Add('python310.dll');
  {$ELSE}
  lbDLLs.Items.Add('libpython3.so');
  lbDLLs.Items.Add('libpython3_64.so');
  lbDLLs.Items.Add('libpython3.12.so');
  lbDLLs.Items.Add('libpython3.11.so');
  {$ENDIF}

  // Deduplicate
  for I := lbDLLs.Items.Count - 1 downto 0 do
  begin
    if lbDLLs.Items.IndexOf(lbDLLs.Items[I]) < I then
      lbDLLs.Items.Delete(I);
  end;

  if lbDLLs.Items.Count > 0 then
    lbDLLs.ItemIndex := 0;

  UpdateStatusUI;
  LogMsg('Aplicativo iniciado. Plataforma detectada: ' + ArchStr);
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
var
  SelectedDLL: string;
begin
  try
    if FConnector.Active then
    begin
      FConnector.Active := False;
      LogMsg('Interpretador Python desativado.');
    end
    else
    begin
      SelectedDLL := 'python3.dll';
      if lbDLLs.ItemIndex >= 0 then
        SelectedDLL := lbDLLs.Items[lbDLLs.ItemIndex];

      FConnector.DLLPath := Trim(SelectedDLL);
      
      if chkProcessMode.Checked then
      begin
        FConnector.ExecutionMode := pemProcess;
        LogMsg('Modo de execução selecionado: Processo Externo (pemProcess)');
      end
      else
      begin
        FConnector.ExecutionMode := pemDLL;
        LogMsg('Modo de execução selecionado: Biblioteca Dinâmica (pemDLL)');
      end;
      
      LogMsg('Tentando iniciar/carregar o Python...');
      FConnector.Active := True;
      
      // Output diagnostic report to log memo
      LogMsg('=== RELATÓRIO DE DIAGNÓSTICO ===');
      FConnector.GetDiagnosticReport(meLogs.Lines);
      LogMsg('================================');
      
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

  meOutput.Clear;
  Code := meScript.Text;
  LogMsg('Executando script Python...');
  if FConnector.ExecString(Code) then
  begin
    LogMsg('Executado com sucesso!');
    meOutput.Text := FConnector.LastOutput;
  end
  else
  begin
    LogMsg('ERRO de execução: ' + FConnector.LastError);
    meOutput.Text := FConnector.LastOutput;
    if meOutput.Text <> '' then
      meOutput.Lines.Add('');
    meOutput.Lines.Add('=== ERRO DE EXECUÇÃO ===');
    meOutput.Lines.Add(FConnector.LastError);
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
