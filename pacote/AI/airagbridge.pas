unit airagbridge;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  IAIRAGProvider = interface
    ['{E0D5EAFB-52CE-43C1-8A6D-52B2C4FCE0F7}']
    function BuildContext(const AQuestion: string): Boolean;
    function GetLastQuestion: string;
    function GetLastContext: string;
    function GetLastAnswer: string;
    function GetLastSources: TStrings;
  end;

implementation

end.
