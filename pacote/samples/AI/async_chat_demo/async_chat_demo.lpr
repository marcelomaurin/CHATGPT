program async_chat_demo;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, main;

begin
  RequireDerivedFormResource := False;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TAsyncChatForm, AsyncChatForm);
  Application.Run;
end.
