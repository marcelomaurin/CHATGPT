{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit openai_voice;

{$warn 5023 off : no warning about unused units}
interface

uses
  aispeechtypes, aiwhisperengine, aispeechrecognizer, aivoiceclonetypes,
  aif5ttsengine, aivoiceclone, aivoiceassistant, aiaudioplayback,
  aivoicesynthesizer, aivoicerecognizer, soundfilters, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('aiwhisperengine', @aiwhisperengine.Register);
  RegisterUnit('aispeechrecognizer', @aispeechrecognizer.Register);
  RegisterUnit('aif5ttsengine', @aif5ttsengine.Register);
  RegisterUnit('aivoiceclone', @aivoiceclone.Register);
  RegisterUnit('aivoiceassistant', @aivoiceassistant.Register);
  RegisterUnit('aiaudioplayback', @aiaudioplayback.Register);
  RegisterUnit('aivoicesynthesizer', @aivoicesynthesizer.Register);
  RegisterUnit('aivoicerecognizer', @aivoicerecognizer.Register);
  RegisterUnit('soundfilters', @soundfilters.Register);
end;

initialization
  RegisterPackage('openai_voice', @Register);
end.
