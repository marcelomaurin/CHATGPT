# CHATGPT
Lazarus component for CHATGPT

Simple Script for Lazarus

uses ...,chatgpt;<br/>

Var<br/>
  FChatgpt : TCHATGPT;<br/>
  
  
Begin<br/>
  FChatgpt := TChatgpt.create(self); <br/>
  FChatgpt.TOKEN:=  'YOUR TOKEN'; //TOKEN <br/>
  FChatgpt.SendQuestion('Your Question');<br/>
  Response :=  FChatgpt.Response;  //Response of chatgpt<br/>
end.<br/>
<br/>
<br/>
TRY DEMO, complete program in folder ./demo<br/>
