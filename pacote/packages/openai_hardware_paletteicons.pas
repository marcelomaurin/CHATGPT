unit openai_hardware_paletteicons;

{ Palette resources are loaded by the package, keeping runtime units pure FPC. }
{$mode objfpc}{$H+}
interface
implementation
uses LResources;
initialization
  {$I openai_hardware_paletteicons.lrs}
end.
