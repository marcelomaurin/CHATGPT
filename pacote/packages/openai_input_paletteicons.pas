unit openai_input_paletteicons;

{ Palette resources are loaded by the package, keeping runtime units pure FPC. }
{$mode objfpc}{$H+}
interface
implementation
uses LResources;
initialization
  {$I openai_input_paletteicons.lrs}
end.
