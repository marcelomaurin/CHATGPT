unit aiprinter_transport;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  IAIPrinterTransport = interface
    ['{884FA3E2-EEA1-4BE5-A2B0-F3C2808E5F09}']
    function Open: Boolean;
    procedure Close;
    function WriteAll(const ABytes: TBytes): Boolean;
    function IsOpen: Boolean;
    function LastError: string;
    procedure SetTimeoutMs(AValue: Integer);
    function GetTimeoutMs: Integer;
  end;

implementation

end.
