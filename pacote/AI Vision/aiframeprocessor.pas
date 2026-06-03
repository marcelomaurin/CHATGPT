unit aiframeprocessor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase;

type
  { TAIFrameProcessor }

  TAIFrameProcessor = class(TAIBaseComponent)
  private
    FScaleFactor: Double;
    FGrayscale: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    function ProcessFrame(AFrame: TObject): TObject;
  published
    property ScaleFactor: Double read FScaleFactor write FScaleFactor;
    property Grayscale: Boolean read FGrayscale write FGrayscale default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Vision', [TAIFrameProcessor]);
end;

{ TAIFrameProcessor }

constructor TAIFrameProcessor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIFrameProcessor resizes and filters image frames. Properties: ScaleFactor, Grayscale. Methods: ProcessFrame.';
  FScaleFactor := 1.0;
  FGrayscale := True;
  ClearError;
end;

function TAIFrameProcessor.ProcessFrame(AFrame: TObject): TObject;
begin
  Result := AFrame;
  Log(llDebug, 'Processed frame.');
end;

end.
