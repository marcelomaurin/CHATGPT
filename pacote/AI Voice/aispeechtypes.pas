unit aispeechtypes;

{$mode objfpc}{$H+}

interface

type
  TAISpeechState = (ssStopped, ssListening, ssProcessing, ssError);

  TAISpeechTextEvent = procedure(Sender: TObject; const AText: string) of object;
  TAISpeechErrorEvent = procedure(Sender: TObject; const AError: string) of object;
  TAISpeechFinishEvent = procedure(Sender: TObject; ASuccess: Boolean) of object;

  IAISpeechRecognitionEngine = interface
    ['{6E6E416C-7807-40A1-8752-0181489968D8}']
    function LoadModel(const AModelPath: string; AUseGPU: Boolean;
      AThreads: Integer; out AError: string): Boolean;
    function TranscribeFile(const AFileName, ALanguage: string;
      out AText, AError: string): Boolean;
    procedure Cancel;
  end;

implementation

end.
