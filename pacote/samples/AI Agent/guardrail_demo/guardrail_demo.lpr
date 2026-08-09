program guardrail_demo;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, SysUtils, aiguardrails;

var
  Guardrail: TAIInputGuardrail;
  Decision: TAIGuardrailDecision;
  Reason: string;
begin
  Guardrail := TAIInputGuardrail.Create(nil);
  try
    Guardrail.BlockedPatterns.Add('senha');
    Guardrail.MarkedPatterns.Add('duvidoso');
    Guardrail.Evaluate('resultado duvidoso', Decision, Reason);
    Writeln('mark decision=', Ord(Decision), ' reason=', Reason);
    Guardrail.Evaluate('minha senha', Decision, Reason);
    Writeln('block decision=', Ord(Decision), ' reason=', Reason);
  finally Guardrail.Free; end;
end.
