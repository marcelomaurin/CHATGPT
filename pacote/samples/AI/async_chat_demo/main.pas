unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, LazUTF8, chatgpt;

type
  TAsyncChatForm = class(TForm)
  private
    FChat: TCHATGPT;
    FProvider: TComboBox;
    FEndpoint: TEdit;
    FModel: TEdit;
    FToken: TEdit;
    FTemperature: TEdit;
    FPrompt: TMemo;
    FResponse: TMemo;
    FState: TLabel;
    FSend: TButton;
    FCancel: TButton;
    procedure SendClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure StreamStart(Sender: TObject);
    procedure StreamData(Sender: TObject; const AData: WideString);
    procedure StreamEnd(Sender: TObject);
    procedure StateChange(Sender: TObject; AState: TAILLMRequestState);
    procedure RequestComplete(Sender: TObject; ASuccess: Boolean);
    function NewEdit(AParent: TWinControl; const AText: string;
      ALeft, ATop, AWidth: Integer): TEdit;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  AsyncChatForm: TAsyncChatForm;

implementation

function StateName(AState: TAILLMRequestState): string;
begin
  case AState of
    lrsIdle: Result := 'Idle';
    lrsConnecting: Result := 'Connecting';
    lrsReceiving: Result := 'Receiving';
    lrsCompleted: Result := 'Completed';
    lrsCancelled: Result := 'Cancelled';
    lrsError: Result := 'Error';
  end;
end;

function TAsyncChatForm.NewEdit(AParent: TWinControl; const AText: string;
  ALeft, ATop, AWidth: Integer): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, 28);
  Result.Text := AText;
end;

constructor TAsyncChatForm.Create(AOwner: TComponent);
var
  TopPanel: TPanel;
begin
  inherited CreateNew(AOwner, 1);
  Caption := 'Async / streaming TCHATGPT';
  SetBounds(100, 100, 850, 610);

  TopPanel := TPanel.Create(Self);
  TopPanel.Parent := Self;
  TopPanel.Align := alTop;
  TopPanel.Height := 115;

  FProvider := TComboBox.Create(Self);
  FProvider.Parent := TopPanel;
  FProvider.SetBounds(8, 8, 170, 28);
  FProvider.Items.Add('OpenAI');
  FProvider.Items.Add('OpenRouter');
  FProvider.Items.Add('Cerebras');
  FProvider.Items.Add('Ollama');
  FProvider.Items.Add('Gemini');
  FProvider.Items.Add('Claude');
  FProvider.Items.Add('DeepSeek');
  FProvider.Items.Add('OpenAI-compatible');
  FProvider.Items.Add('llama.cpp');
  FProvider.Items.Add('neural-api');
  FProvider.ItemIndex := 7;
  FEndpoint := NewEdit(TopPanel, 'http://localhost:8000/v1/chat/completions', 185, 8, 420);
  FModel := NewEdit(TopPanel, 'custom-model', 612, 8, 220);
  FToken := NewEdit(TopPanel, '', 8, 43, 300);
  FToken.PasswordChar := '*';
  FTemperature := NewEdit(TopPanel, '0.7', 315, 43, 80);

  FSend := TButton.Create(Self);
  FSend.Parent := TopPanel;
  FSend.SetBounds(405, 43, 120, 30);
  FSend.Caption := 'Enviar async';
  FSend.OnClick := @SendClick;
  FCancel := TButton.Create(Self);
  FCancel.Parent := TopPanel;
  FCancel.SetBounds(535, 43, 100, 30);
  FCancel.Caption := 'Cancelar';
  FCancel.Enabled := False;
  FCancel.OnClick := @CancelClick;
  FState := TLabel.Create(Self);
  FState.Parent := TopPanel;
  FState.SetBounds(645, 50, 180, 24);
  FState.Caption := 'Estado: Idle';

  FPrompt := TMemo.Create(Self);
  FPrompt.Parent := Self;
  FPrompt.Align := alTop;
  FPrompt.Height := 130;
  FPrompt.Text := 'Explique streaming em uma frase.';
  FResponse := TMemo.Create(Self);
  FResponse.Parent := Self;
  FResponse.Align := alClient;
  FResponse.ReadOnly := True;
  FResponse.ScrollBars := ssAutoVertical;

  FChat := TCHATGPT.Create(Self);
  FChat.Streaming := True;
  FChat.OnStreamStart := @StreamStart;
  FChat.OnStreamData := @StreamData;
  FChat.OnStreamEnd := @StreamEnd;
  FChat.OnStateChange := @StateChange;
  FChat.OnRequestComplete := @RequestComplete;
end;

procedure TAsyncChatForm.SendClick(Sender: TObject);
var
  Temp: Double;
begin
  FResponse.Clear;
  FChat.Provider := GetAIProviderFromIndex(FProvider.ItemIndex);
  FChat.URL := UTF8ToUTF16(FEndpoint.Text);
  FChat.CustomModel := UTF8ToUTF16(FModel.Text);
  FChat.TOKEN := UTF8ToUTF16(FToken.Text);
  if TryStrToFloat(FTemperature.Text, Temp) then
    FChat.Temperature := Temp;
  FSend.Enabled := False;
  FCancel.Enabled := True;
  if not FChat.SendQuestionAsync(UTF8ToUTF16(FPrompt.Text)) then
  begin
    FResponse.Text := FChat.LastError;
    FSend.Enabled := True;
    FCancel.Enabled := False;
  end;
end;

procedure TAsyncChatForm.CancelClick(Sender: TObject);
begin
  FChat.Cancel;
  FCancel.Enabled := False;
end;

procedure TAsyncChatForm.StreamStart(Sender: TObject);
begin
  FResponse.Clear;
end;

procedure TAsyncChatForm.StreamData(Sender: TObject; const AData: WideString);
begin
  FResponse.SelStart := Length(FResponse.Text);
  FResponse.SelText := UTF16ToUTF8(AData);
end;

procedure TAsyncChatForm.StreamEnd(Sender: TObject);
begin
  FCancel.Enabled := False;
end;

procedure TAsyncChatForm.StateChange(Sender: TObject; AState: TAILLMRequestState);
begin
  FState.Caption := 'Estado: ' + StateName(AState);
end;

procedure TAsyncChatForm.RequestComplete(Sender: TObject; ASuccess: Boolean);
begin
  FSend.Enabled := True;
  FCancel.Enabled := False;
  if (not ASuccess) and (FChat.RequestState = lrsError) then
    FResponse.Text := FChat.LastError;
end;

end.
