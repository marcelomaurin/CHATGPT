program openai_stt_tests;
{$mode objfpc}{$H+}
uses SysUtils, aivoicerecognizer;
var R:TAIVoiceRecognizer;Text:string;Ok:Boolean;
begin
 DefaultSystemCodePage:=CP_UTF8;SetMultiByteConversionCodePage(CP_UTF8);
 R:=TAIVoiceRecognizer.Create(nil);
 try
  R.Engine:=vreOpenAIWhisper;R.Language:='pt-BR';
  R.OpenAIEndpoint:=ParamStr(1);R.ChatGPTToken:='fixture-chat-token';
  if ParamStr(3)='explicit' then R.OpenAIToken:='fixture-stt-token' else R.OpenAIToken:='';
  if ParamStr(3)='missing' then begin R.ChatGPTToken:='';end;
  if ParamStr(3)='chrome' then R.Engine:=vreChromeWebSpeech;
  Ok:=R.TranscribeFile(ParamStr(2),Text);
  if (ParamStr(3)='error') or (ParamStr(3)='missing') or (ParamStr(3)='chrome') then
  begin if Ok or (R.LastError='') then Halt(2);WriteLn('EXPECTED ERROR: ',R.LastError);end
  else begin if not Ok or (Text<>'Olá, professor!') then begin WriteLn(R.LastError);Halt(3);end;WriteLn('PASS: ',Text);end;
 finally R.Free;end;
end.
