unit aivoiceclonetypes;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils;

type
  TAIVoiceCloneState = (vcsIdle, vcsPreparing, vcsSynthesizing,
    vcsCancelling, vcsCompleted, vcsError);

  TAIVoiceCloneProgressEvent = procedure(Sender: TObject; APercent: Integer;
    const AMessage: string) of object;
  TAIVoiceCloneErrorEvent = procedure(Sender: TObject; const AError: string) of object;
  TAIVoiceCloneFinishEvent = procedure(Sender: TObject; ASuccess: Boolean;
    const AOutputFile: string) of object;

  TAIVoiceProfile = class(TPersistent)
  private
    FID: string;
    FName: string;
    FReferenceAudio: string;
    FEngine: string;
    FModel: string;
    FLanguage: string;
    FConsentConfirmed: Boolean;
    FVoiceOwner: string;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
  published
    property ID: string read FID write FID;
    property Name: string read FName write FName;
    property ReferenceAudio: string read FReferenceAudio write FReferenceAudio;
    property Engine: string read FEngine write FEngine;
    property Model: string read FModel write FModel;
    property Language: string read FLanguage write FLanguage;
    property ConsentConfirmed: Boolean read FConsentConfirmed write FConsentConfirmed default False;
    property VoiceOwner: string read FVoiceOwner write FVoiceOwner;
  end;

  IAIVoiceCloneEngine = interface
    ['{F1C9BA17-BC08-4392-9B1A-E5C96DBA7F15}']
    function CreateVoice(AProfile: TAIVoiceProfile; out AError: string): Boolean;
    function Synthesize(AProfile: TAIVoiceProfile; const AText,
      AOutputFile: string; out ARealOutputFile, AError: string): Boolean;
    procedure Cancel;
  end;

implementation

constructor TAIVoiceProfile.Create;
begin inherited Create; FLanguage := 'pt'; end;

procedure TAIVoiceProfile.Assign(Source: TPersistent);
var P: TAIVoiceProfile;
begin
  if Source is TAIVoiceProfile then
  begin
    P := TAIVoiceProfile(Source);
    FID := P.ID; FName := P.Name; FReferenceAudio := P.ReferenceAudio;
    FEngine := P.Engine; FModel := P.Model; FLanguage := P.Language;
    FConsentConfirmed := P.ConsentConfirmed; FVoiceOwner := P.VoiceOwner;
  end
  else inherited Assign(Source);
end;

end.
