unit main;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, Forms, Controls, StdCtrls, aiwebrtc_client, aiwebrtc_libdatachannel;
type
 TMainForm=class(TForm)
 private
  W:TAIWebRTCClient; Log,SDP,ICE,Msg:TMemo; BtnConnect,BtnOffer,BtnAnswer,BtnRemote,BtnSend:TButton;
  procedure AddLog(const S:string); procedure ConnectClick(Sender:TObject); procedure OfferClick(Sender:TObject);
  procedure AnswerClick(Sender:TObject); procedure RemoteClick(Sender:TObject); procedure SendClick(Sender:TObject);
  procedure LocalDesc(Sender:TObject;const A,T:string); procedure Candidate(Sender:TObject;const C,M:string);
  procedure State(Sender:TObject; S:TrtcState); procedure Message(Sender:TObject;const S:RawByteString);
  procedure Opened(Sender:TObject); procedure Closed(Sender:TObject); procedure Err(Sender:TObject;const S:RawByteString);
 public constructor Create(AOwner:TComponent); override;
 end;
var MainForm:TMainForm;
implementation
constructor TMainForm.Create(AOwner:TComponent);
 procedure B(var X:TButton;const C:string;L:Integer;H:TNotifyEvent);
 begin X:=TButton.Create(Self);X.Parent:=Self;X.Caption:=C;X.Left:=L;X.Top:=8;X.OnClick:=H; end;
begin inherited CreateNew(AOwner,1); Caption:='WebRTC DataChannel Demo';Width:=1000;Height:=700;
 B(BtnConnect,'Conectar',8,@ConnectClick);B(BtnOffer,'Criar Offer',100,@OfferClick);B(BtnAnswer,'Criar Answer',200,@AnswerClick);B(BtnRemote,'Aplicar SDP remoto',310,@RemoteClick);B(BtnSend,'Enviar',460,@SendClick);
 SDP:=TMemo.Create(Self);SDP.Parent:=Self;SDP.SetBounds(8,48,480,260); SDP.ScrollBars:=ssAutoBoth;
 ICE:=TMemo.Create(Self);ICE.Parent:=Self;ICE.SetBounds(500,48,480,260);ICE.ScrollBars:=ssAutoBoth;
 Msg:=TMemo.Create(Self);Msg.Parent:=Self;Msg.SetBounds(8,320,480,80);Msg.Text:='Olá via WebRTC';
 Log:=TMemo.Create(Self);Log.Parent:=Self;Log.SetBounds(8,410,972,240);Log.ScrollBars:=ssAutoBoth;
 W:=TAIWebRTCClient.Create(Self);W.OnLocalDescription:=@LocalDesc;W.OnLocalCandidate:=@Candidate;W.OnState:=@State;W.OnMessage:=@Message;W.OnDataChannelOpen:=@Opened;W.OnDataChannelClosed:=@Closed;W.OnError:=@Err;
end;
procedure TMainForm.AddLog(const S:string);begin Log.Lines.Add(FormatDateTime('hh:nn:ss.zzz',Now)+' '+S);end;
procedure TMainForm.ConnectClick(Sender:TObject);begin if W.Connect then AddLog('Peer criado') else AddLog(W.LastError);end;
procedure TMainForm.OfferClick(Sender:TObject);begin if W.DataChannelId<0 then W.CreateDataChannel('chatgpt');if not W.CreateOffer then AddLog(W.LastError);end;
procedure TMainForm.AnswerClick(Sender:TObject);begin if not W.CreateAnswer then AddLog(W.LastError);end;
procedure TMainForm.RemoteClick(Sender:TObject);var T:string;begin T:=InputBox('SDP remoto','Tipo: offer ou answer','offer');if W.SetRemoteDescription(SDP.Text,T) then AddLog('SDP remoto aplicado') else AddLog(W.LastError);end;
procedure TMainForm.SendClick(Sender:TObject);begin if W.SendText(RawByteString(Msg.Text)) then AddLog('TX: '+Msg.Text) else AddLog(W.LastError);end;
procedure TMainForm.LocalDesc(Sender:TObject;const A,T:string);begin SDP.Text:=A;AddLog('SDP local: '+T);end;
procedure TMainForm.Candidate(Sender:TObject;const C,M:string);begin ICE.Lines.Add(M+'|'+C);AddLog('ICE local: '+M);end;
procedure TMainForm.State(Sender:TObject;S:TrtcState);begin AddLog('Estado='+IntToStr(Ord(S)));end;
procedure TMainForm.Message(Sender:TObject;const S:RawByteString);begin AddLog('RX: '+string(S));end;
procedure TMainForm.Opened(Sender:TObject);begin AddLog('DataChannel aberto');end;
procedure TMainForm.Closed(Sender:TObject);begin AddLog('DataChannel fechado');end;
procedure TMainForm.Err(Sender:TObject;const S:RawByteString);begin AddLog('ERRO: '+string(S));end;
end.
