unit aiagent_executors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, fpjson, fphttpclient, aibase,
  aicapturesource, aiaudio, aiwebserver, aisockets, aiserial, aiposprinter,
  aimodbus, aimqtt, aiemail, aimessenger, aiindustrial,
  aiinput, aioutput, aioutput_docs;

type
  TAIAgentResourceExecutor = class
  public
    class function CanExecute(AComponent: TComponent): Boolean; virtual;
    class function Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean; virtual;
  end;

  { TAIAgentDocsExecutor }
  TAIAgentDocsExecutor = class(TAIAgentResourceExecutor)
  public
    class function CanExecute(AComponent: TComponent): Boolean; override;
    class function Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean; override;
  end;

  { TAIAgentNetworkExecutor }
  TAIAgentNetworkExecutor = class(TAIAgentResourceExecutor)
  public
    class function CanExecute(AComponent: TComponent): Boolean; override;
    class function Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean; override;
  end;

  { TAIAgentIndustrialExecutor }
  TAIAgentIndustrialExecutor = class(TAIAgentResourceExecutor)
  public
    class function CanExecute(AComponent: TComponent): Boolean; override;
    class function Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean; override;
  end;

  { TAIAgentMessagingExecutor }
  TAIAgentMessagingExecutor = class(TAIAgentResourceExecutor)
  public
    class function CanExecute(AComponent: TComponent): Boolean; override;
    class function Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean; override;
  end;

  { TAIAgentHardwareExecutor }
  TAIAgentHardwareExecutor = class(TAIAgentResourceExecutor)
  public
    class function CanExecute(AComponent: TComponent): Boolean; override;
    class function Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean; override;
  end;

function DispatchResourceExecution(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean;

implementation

function DispatchResourceExecution(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean;
begin
  Result := False;
  ALog := '';
  if not Assigned(AComponent) then Exit;

  if TAIAgentDocsExecutor.CanExecute(AComponent) then
    Result := TAIAgentDocsExecutor.Execute(AComponent, AData, AParams, ALog)
  else if TAIAgentNetworkExecutor.CanExecute(AComponent) then
    Result := TAIAgentNetworkExecutor.Execute(AComponent, AData, AParams, ALog)
  else if TAIAgentIndustrialExecutor.CanExecute(AComponent) then
    Result := TAIAgentIndustrialExecutor.Execute(AComponent, AData, AParams, ALog)
  else if TAIAgentMessagingExecutor.CanExecute(AComponent) then
    Result := TAIAgentMessagingExecutor.Execute(AComponent, AData, AParams, ALog)
  else if TAIAgentHardwareExecutor.CanExecute(AComponent) then
    Result := TAIAgentHardwareExecutor.Execute(AComponent, AData, AParams, ALog);
end;

{ TAIAgentResourceExecutor }

class function TAIAgentResourceExecutor.CanExecute(AComponent: TComponent): Boolean;
begin
  Result := False;
end;

class function TAIAgentResourceExecutor.Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean;
begin
  Result := False;
  ALog := '';
end;

{ TAIAgentDocsExecutor }

class function TAIAgentDocsExecutor.CanExecute(AComponent: TComponent): Boolean;
begin
  Result := (AComponent is TAIPDFOutput) or
            (AComponent is TAIWordOutput) or
            (AComponent is TAIExcelOutput) or
            (AComponent is TAITXTOutput) or
            (AComponent is TAIOutputDocs);
end;

class function TAIAgentDocsExecutor.Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean;
begin
  Result := False;
  ALog := '';

  if AComponent is TAIPDFOutput then
  begin
    with (AComponent as TAIPDFOutput) do
    begin
      if FileName = '' then FileName := 'relatorio.pdf';
      StartDocument;
      AddPage;
      AddText('AGENT EXECUTION', 50, 50, 16);
      AddText('Timestamp: ' + DateTimeToStr(Now), 50, 80, 10);
      AddText(AData, 50, 110, 10);
      Result := SavePDF;
      if Result then
        ALog := 'PDF salvo com sucesso em: ' + FileName
      else
        ALog := 'Erro ao salvar PDF.';
    end;
  end
  else if AComponent is TAIWordOutput then
  begin
    with (AComponent as TAIWordOutput) do
    begin
      if FileName = '' then FileName := 'relatorio.docx';
      AddHeading('AGENT EXECUTION', 1);
      AddParagraph(AData);
      Result := SaveWord;
      if Result then
        ALog := 'Word (.docx) salvo com sucesso em: ' + FileName
      else
        ALog := 'Erro ao salvar Word.';
    end;
  end
  else if AComponent is TAIExcelOutput then
  begin
    with (AComponent as TAIExcelOutput) do
    begin
      if FileName = '' then FileName := 'dados.xlsx';
      SetCell(0, 0, 'Agent Data');
      SetCell(1, 0, AData);
      Result := SaveExcel;
      if Result then
        ALog := 'Excel (.xlsx) salvo com sucesso em: ' + FileName
      else
        ALog := 'Erro ao salvar Excel.';
    end;
  end
  else if AComponent is TAITXTOutput then
  begin
    with (AComponent as TAITXTOutput) do
    begin
      if FileName = '' then FileName := 'relatorio.txt';
      AddHeader('AGENT EXECUTION LOG');
      AddLine(AData);
      Result := SaveText;
      if Result then
        ALog := 'TXT salvo com sucesso em: ' + FileName
      else
        ALog := 'Erro ao salvar TXT.';
    end;
  end
  else if AComponent is TAIOutputDocs then
  begin
    with (AComponent as TAIOutputDocs) do
    begin
      Title := 'Relatório de Agente';
      AddHeading('AGENT EXECUTION', 1);
      AddParagraph(AData);
      Result := SaveAll('relatorio_agente');
      if Result then
        ALog := 'Todos os relatorios (.pdf, .docx, .xlsx, .txt) foram gerados com sucesso.'
      else
        ALog := 'Erro ao salvar relatorios unificados.';
    end;
  end;
end;

{ TAIAgentNetworkExecutor }

class function TAIAgentNetworkExecutor.CanExecute(AComponent: TComponent): Boolean;
begin
  Result := (AComponent is TAISocketTCP) or
            (AComponent is TAISocketUDP) or
            (AComponent is TAIWebAPIServer);
end;

class function TAIAgentNetworkExecutor.Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean;
begin
  Result := False;
  ALog := '';

  if AComponent is TAISocketTCP then
  begin
    with (AComponent as TAISocketTCP) do
    begin
      if not Active then Active := True;
      if Connect then
      begin
        Result := SendText(AData);
        Disconnect;
        if Result then
          ALog := 'Dados TCP enviados com sucesso.'
        else
          ALog := 'Falha ao enviar dados via TCP.';
      end
      else
        ALog := 'Falha ao conectar socket TCP.';
    end;
  end
  else if AComponent is TAISocketUDP then
  begin
    with (AComponent as TAISocketUDP) do
    begin
      if not Active then Active := True;
      Result := SendText(AData);
      if Result then
        ALog := 'Dados UDP enviados com sucesso.'
      else
        ALog := 'Falha ao enviar dados via UDP.';
    end;
  end
  else if AComponent is TAIWebAPIServer then
  begin
    with (AComponent as TAIWebAPIServer) do
    begin
      if not Active then StartServer;
      Result := True;
      ALog := 'Servidor WebAPI REST ativo na porta ' + IntToStr(Port);
    end;
  end;
end;

{ TAIAgentIndustrialExecutor }

class function TAIAgentIndustrialExecutor.CanExecute(AComponent: TComponent): Boolean;
begin
  Result := (AComponent is TAIModbusClient) or
            (AComponent is TAIMqttClient) or
            (AComponent is TAIIndustrialBridge);
end;

class function TAIAgentIndustrialExecutor.Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean;
var
  VVal: string;
begin
  Result := False;
  ALog := '';

  if AComponent is TAIModbusClient then
  begin
    with (AComponent as TAIModbusClient) do
    begin
      if not Active then Active := True;
      Result := True;
      ALog := 'Comando Modbus simulado/executado com sucesso.';
    end;
  end
  else if AComponent is TAIMqttClient then
  begin
    with (AComponent as TAIMqttClient) do
    begin
      if not Active then ConnectBroker;
      VVal := AParams.Values['topic'];
      if VVal = '' then VVal := 'agent/output';
      Result := Publish(VVal, AData);
      if Result then
        ALog := 'Mensagem MQTT publicada no tópico "' + VVal + '"'
      else
        ALog := 'Falha ao publicar mensagem MQTT.';
    end;
  end
  else if AComponent is TAIIndustrialBridge then
  begin
    with (AComponent as TAIIndustrialBridge) do
    begin
      if not Active then ConnectBridge;
      Result := True;
      ALog := 'Ponte Profinet/Profibus ativa: ' + IPAddress;
    end;
  end;
end;

{ TAIAgentMessagingExecutor }

class function TAIAgentMessagingExecutor.CanExecute(AComponent: TComponent): Boolean;
begin
  Result := (AComponent is TAIEmailClient) or
            (AComponent is TAIMessenger);
end;

class function TAIAgentMessagingExecutor.Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean;
var
  VVal, VKey: string;
begin
  Result := False;
  ALog := '';

  if AComponent is TAIEmailClient then
  begin
    with (AComponent as TAIEmailClient) do
    begin
      VVal := AParams.Values['recipient'];
      if VVal = '' then VVal := AParams.Values['to'];
      
      VKey := AParams.Values['subject'];
      if VKey = '' then VKey := 'Mensagem do Agente';

      Result := SendEmail(VVal, VKey, AData);
      if Result then
        ALog := 'E-mail enviado via TAIEmailClient para ' + VVal
      else
        ALog := 'Falha ao enviar e-mail via TAIEmailClient.';
    end;
  end
  else if AComponent is TAIMessenger then
  begin
    with (AComponent as TAIMessenger) do
    begin
      VVal := AParams.Values['recipient'];
      if VVal = '' then VVal := AParams.Values['to'];
      
      // TAIMessenger uses custom resource type if mapped or default
      Result := SendWhatsApp(VVal, AData);
      if Result then
        ALog := 'Mensagem enviada via TAIMessenger para ' + VVal
      else
        ALog := 'Falha ao enviar mensagem via TAIMessenger.';
    end;
  end;
end;

{ TAIAgentHardwareExecutor }

class function TAIAgentHardwareExecutor.CanExecute(AComponent: TComponent): Boolean;
begin
  Result := (AComponent is TAICaptureSource) or
            (AComponent is TAIAudioInput) or
            (AComponent is TAIPOSPrinter) or
            (AComponent is TAIOutputData) or
            (AComponent is TAIInputData);
end;

class function TAIAgentHardwareExecutor.Execute(AComponent: TComponent; const AData: string; AParams: TStrings; out ALog: string): Boolean;
begin
  Result := False;
  ALog := '';

  if AComponent is TAICaptureSource then
  begin
    with (AComponent as TAICaptureSource) do
    begin
      if not Active then StartCapture;
      Result := True;
      ALog := 'Dispositivo de captura unificado (TAICaptureSource) ativo. Mode: ' + GetEnumName(TypeInfo(TAICaptureSourceKind), Ord(SourceKind));
    end;
  end
  else if AComponent is TAIAudioInput then
  begin
    with (AComponent as TAIAudioInput) do
    begin
      Result := True;
      ALog := 'Suíte de sinais de áudio ativa.';
    end;
  end
  else if AComponent is TAIPOSPrinter then
  begin
    with (AComponent as TAIPOSPrinter) do
    begin
      if not Active then Active := True;
      Result := PrintText(AData);
      if Result then
        ALog := 'Recibo impresso com sucesso na impressora Esc/POS.'
      else
        ALog := 'Erro de impressão Esc/POS.';
    end;
  end
  else if AComponent is TAIOutputData then
  begin
    with (AComponent as TAIOutputData) do
    begin
      SoftMax;
      Result := True;
      ALog := 'Ativacao SoftMax executada: ' + ClassificationResult;
    end;
  end
  else if AComponent is TAIInputData then
  begin
    with (AComponent as TAIInputData) do
    begin
      Normalize;
      Result := True;
      ALog := 'Normalização linear executada.';
    end;
  end;
end;

end.
