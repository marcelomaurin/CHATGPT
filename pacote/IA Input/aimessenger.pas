unit aimessenger;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, opensslsockets, LResources;

type
  { TAIMessenger }

  TAIMessenger = class(TComponent)
  private
    FPrompt: string;
    FSMSApiURL: string;
    FSMSApiKey: string;
    FWhatsAppApiURL: string;
    FWhatsAppToken: string;
  public
    constructor Create(AOwner: TComponent); override;
    
    function SendSMS(const ANumber, AText: string): Boolean;
    function SendWhatsApp(const ANumber, AText: string): Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property SMSApiURL: string read FSMSApiURL write FSMSApiURL;
    property SMSApiKey: string read FSMSApiKey write FSMSApiKey;
    property WhatsAppApiURL: string read FWhatsAppApiURL write FWhatsAppApiURL;
    property WhatsAppToken: string read FWhatsAppToken write FWhatsAppToken;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Input', [TAIMessenger]);
end;

{ TAIMessenger }

constructor TAIMessenger.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIMessenger wraps WhatsApp (REST API gateway) and SMS messaging. Properties: APIKey: string, PhoneNumber: string, Active: Boolean. Methods: SendWhatsApp(const ATo, AMessage: string): Boolean, SendSMS(const ATo, AMessage: string): Boolean. AI Agent: Use this to send critical real-time alerts or reports to mobile devices via WhatsApp or cellular networks.';
  FSMSApiURL := 'https://api.sms-gateway-service.com/send';
  FSMSApiKey := '';
  FWhatsAppApiURL := 'https://graph.facebook.com/v17.0/YOUR_PHONE_NUMBER_ID/messages';
  FWhatsAppToken := '';
end;

function TAIMessenger.SendSMS(const ANumber, AText: string): Boolean;
var
  HTTP: TFPHTTPClient;
  JSONPayload: string;
  Response: string;
begin
  Result := False;
  HTTP := TFPHTTPClient.Create(nil);
  try
    HTTP.AddHeader('Content-Type', 'application/json');
    if FSMSApiKey <> '' then
      HTTP.AddHeader('Authorization', 'Bearer ' + FSMSApiKey);
      
    // Format JSON Payload
    JSONPayload := Format('{"to": "%s", "message": "%s"}', [ANumber, AText]);
    
    try
      HTTP.RequestBody := TStringStream.Create(JSONPayload);
      Response := HTTP.Post(FSMSApiURL);
      // Basic check: if HTTP response status is 200 or 201
      Result := (HTTP.ResponseStatusCode = 200) or (HTTP.ResponseStatusCode = 201);
    except
      on E: Exception do
      begin
        // Quietly fail or log during execution
      end;
    end;
  finally
    if Assigned(HTTP.RequestBody) then
      HTTP.RequestBody.Free;
    HTTP.Free;
  end;
end;

function TAIMessenger.SendWhatsApp(const ANumber, AText: string): Boolean;
var
  HTTP: TFPHTTPClient;
  JSONPayload: string;
  Response: string;
begin
  Result := False;
  HTTP := TFPHTTPClient.Create(nil);
  try
    HTTP.AddHeader('Content-Type', 'application/json');
    if FWhatsAppToken <> '' then
      HTTP.AddHeader('Authorization', 'Bearer ' + FWhatsAppToken);
      
    // Format official WhatsApp Graph API JSON payload
    JSONPayload := Format(
      '{"messaging_product": "whatsapp", "to": "%s", "type": "text", "text": {"body": "%s"}}',
      [ANumber, AText]
    );
    
    try
      HTTP.RequestBody := TStringStream.Create(JSONPayload);
      Response := HTTP.Post(FWhatsAppApiURL);
      Result := (HTTP.ResponseStatusCode = 200) or (HTTP.ResponseStatusCode = 201);
    except
      on E: Exception do
      begin
        // Handle error gracefully
      end;
    end;
  finally
    if Assigned(HTTP.RequestBody) then
      HTTP.RequestBody.Free;
    HTTP.Free;
  end;
end;

initialization
  {$I aimessenger_icon.lrs}

end.
