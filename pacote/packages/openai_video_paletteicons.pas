unit openai_video_paletteicons;

{ Palette resources are loaded by the package, keeping runtime units pure FPC. }
{$mode objfpc}{$H+}
interface
implementation
uses LResources;
initialization
  {$I openai_video_paletteicons.lrs}
end.
