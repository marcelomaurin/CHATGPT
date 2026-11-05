program chrome_speech_demo;
{$mode objfpc}{$H+}
{$codepage utf8}
uses {$IFDEF UNIX}cthreads,{$ENDIF} Classes, SysUtils, aichromespeech;
type TConsole = class
  procedure TextReceived(Sender: TObject; const Text: string);
  procedure StateChanged(Sender: TObject; const Text: string);
end;
procedure TConsole.TextReceived(Sender: TObject; const Text: string);
begin WriteLn('Texto reconhecido: ', Text); end;
procedure TConsole.StateChanged(Sender: TObject; const Text: string);
begin WriteLn('Estado: ', Text); end;
var Speech: TAIChromeSpeech; Console: TConsole; Listening: Boolean;
    Seconds: Integer; Deadline: QWord;
begin
  Listening := ParamStr(1) = '--listen';
  Seconds := StrToIntDef(ParamStr(2), 60);
  if (Seconds < 1) or (Seconds > 600) then raise Exception.Create('Duração deve estar entre 1 e 600 segundos.');
  Speech := TAIChromeSpeech.Create(nil); Console := TConsole.Create;
  try
    Speech.Language := 'pt-BR'; Speech.OnText := @Console.TextReceived;
    Speech.OnState := @Console.StateChanged;
    Speech.BrowserExecutable := GetEnvironmentVariable('CHROME_EXECUTABLE');
    Speech.Start;
    if not Speech.Active then raise Exception.Create('Ponte de voz não iniciou.');
    if Listening then
    begin
      WriteLn('Abra a página no Chrome e clique em Iniciar para autorizar o microfone.');
      WriteLn('Sessão: ', Speech.URL);
      Speech.OpenBrowser;
      Deadline := GetTickCount64 + QWord(Seconds) * 1000;
      while GetTickCount64 < Deadline do begin Speech.Poll; Sleep(10); end;
    end
    else
    begin
      Speech.SetPaused(True); Speech.Poll;
      Speech.SetPaused(False); Speech.Poll;
      WriteLn('Modo local: ponte iniciada, pausada e retomada.');
      WriteLn('Use --listen 60 para abrir o Chrome e reconhecer voz durante 60 segundos.');
    end;
    Speech.Stop;
    if Speech.Active then raise Exception.Create('Ponte permaneceu ativa.');
    WriteLn('PASS: sessão encerrada e recursos liberados.');
  finally Speech.Free; Console.Free; end;
end.
