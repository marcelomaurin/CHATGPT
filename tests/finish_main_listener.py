import os

path = r'P:\maurinsoft\Assistente\src\main.pas'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. uses
uses_old = 'aivoicerecognizer, aiaudio,'
uses_new = 'aivoicerecognizer, aicontinuouslistener, aiaudio,'
if uses_old in text:
    text = text.replace(uses_old, uses_new, 1)
    print('1. Added aicontinuouslistener to uses')

# 2. OnVoiceSpeechEnd
speech_end_old = '''procedure Tfrmmain.OnVoiceSpeechEnd(Sender: TObject);
begin
  if FAvatar3D <> nil then
    FAvatar3D.SetState(avIdle);
  if FPublicViewMode = pvmPresentation then
    SetProfessorState('presenting')
  else if FPublicViewMode = pvmContent then
    SetProfessorState('showing_content')
  else
    SetProfessorState('idle');
end;'''

speech_end_new = '''procedure Tfrmmain.OnVoiceSpeechEnd(Sender: TObject);
begin
  FAssistantSpeaking := False;
  if FContinuousListener <> nil then
    FContinuousListener.NotifyAssistantSpeechEnd;

  if FAvatar3D <> nil then
    FAvatar3D.SetState(avIdle);
  if FPublicViewMode = pvmPresentation then
    SetProfessorState('presenting')
  else if FPublicViewMode = pvmContent then
    SetProfessorState('showing_content')
  else if (FContinuousListener <> nil) and FContinuousListener.Enabled then
    SetProfessorState('listening')
  else
    SetProfessorState('idle');
end;'''

if speech_end_old in text:
    text = text.replace(speech_end_old, speech_end_new, 1)
    print('2. Updated OnVoiceSpeechEnd')

# 3. FormClose cleanup
form_close_old = '''procedure Tfrmmain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ShutdownKinect;'''

form_close_new = '''procedure Tfrmmain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if Assigned(FContinuousListener) then
    FContinuousListener.StopListening;
  ShutdownKinect;'''

if form_close_old in text:
    text = text.replace(form_close_old, form_close_new, 1)
    print('3. Updated FormClose')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Done finish_main_listener.py')
