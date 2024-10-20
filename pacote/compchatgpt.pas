unit compchatgpt;

interface

uses
  Classes, Controls, Graphics;

type
  TMyComponent = class(TCustomControl)
  private
    // Propriedades privadas
  protected
    // Sobrescreva o método Paint para definir como o componente será desenhado
    procedure Paint; override;
  public
    // Construtor ou métodos públicos, se necessário
  published
    // Propriedades visíveis no Inspector de Objetos
    property Width;
    property Height;
  end;

procedure Register;

implementation

procedure TMyComponent.Paint;
begin
  // Exemplo de pintura simples: um quadrado vermelho
  Canvas.Brush.Color := clRed;
  Canvas.FillRect(ClientRect);
end;

procedure Register;
begin
  // Registrar o componente na aba "Samples"
  RegisterComponents('Samples', [TMyComponent]);
end;

end.

