# CHATGPT
Lazarus component for CHATGPT

Simple Script for Lazarus

uses ...,chatgpt;

Var
  FChatgpt : TCHATGPT;
  
  
Begin
  FChatgpt := TChatgpt.create(self); 
  FChatgpt.TOKEN:=  'YOUR TOKEN'; //TOKEN 
  FChatgpt.SendQuestion('Your Question');
  Response :=  FChatgpt.Response;  //Response of chatgpt
end.

TRY DEMO, complete program in folder ./demo
