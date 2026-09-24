program test_listener_compile;
{ objfpc}{+}
uses
  Classes, SysUtils, aicontinuouslistener;
var
  L: TAIContinuousListener;
begin
  L := TAIContinuousListener.Create(nil);
  Writeln('State: ', Ord(L.State));
  L.Free;
  Writeln('OK');
end.
