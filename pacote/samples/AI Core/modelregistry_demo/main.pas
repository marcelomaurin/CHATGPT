unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aimodelregistry, chatgpt;

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
    FAIModelRegistry: TAIModelRegistry; FChatGPT: TCHATGPT; FCbProviders: TComboBox;
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
  AddLog('Modelregistry Demo (aimodelregistry) initialized.');
  FAIModelRegistry := TAIModelRegistry.Create(Self);
  FChatGPT := TCHATGPT.Create(Self);
  
  FCbProviders := TComboBox.Create(Self);
  FCbProviders.Parent := pnlTop;
  FCbProviders.Left := 15;
  FCbProviders.Top := 115;
  FCbProviders.Width := 200;
  FCbProviders.Style := csDropDownList;
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
  AddLog('Model Registry Properties & Methods Demo:');
  
  // Method 1: Register custom model
  FAIModelRegistry.RegisterModel('CustomProvider', 'custom-model-v1', 'Custom Friendly Model', 
    'https://api.custom.com/v1', 4096, 0.7, True, False, True, True, False);
  AddLog('Custom model registered: custom-model-v1 under CustomProvider');
  
  // Method 2: Get Providers
  FCbProviders.Items.Clear;
  FAIModelRegistry.GetProviders(FCbProviders.Items);
  AddLog('Providers registered in registry:');
  AddLog('  ' + FCbProviders.Items.CommaText);
  
  if FCbProviders.Items.Count > 0 then
    FCbProviders.ItemIndex := 0;
    
  if chkSimulation.Checked then
  begin
    AddLog('Running in Simulated Mode...');
    // Method 3: Apply model parameters
    FAIModelRegistry.ApplyModel('custom-model-v1', FChatGPT);
    AddLog('Applied model config custom-model-v1 to ChatClient');
    AddLog('ChatClient Model: ' + FChatGPT.TipoModelo);
  end
  else
  begin
    AddLog('Running in Production Mode...');
    if FCbProviders.Text <> '' then
    begin
      try
        FAIModelRegistry.ApplyModel(FCbProviders.Text, FChatGPT);
        AddLog('Applied model successfully.');
      except
        on E: Exception do AddLog('Error: ' + E.Message);
      end;
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
