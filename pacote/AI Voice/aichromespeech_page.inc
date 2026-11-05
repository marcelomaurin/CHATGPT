'<!doctype html>' + #10
+ '<html lang="pt-BR"><meta charset="utf-8"><meta name="viewport" content="width=device-width">' + #10
+ '<title>Microfone do Assistente</title>' + #10
+ '<style>' + #10
+ 'body{font:18px system-ui;background:#17202c;color:#edf2f8;max-width:700px;margin:50px auto;padding:24px}' + #10
+ 'button{font:inherit;padding:12px 20px;margin:8px 12px 8px 0;border:0;border-radius:6px;background:#42a5f5;color:#101820}' + #10
+ 'button:disabled{opacity:.45}#text{white-space:pre-wrap;background:#222f40;padding:18px;min-height:80px}' + #10
+ '</style>' + #10
+ '<h1>Microfone do Assistente</h1>' + #10
+ '<p>O Chrome reconhece sua fala e envia o texto ao Assistente neste computador.' + #10
+ 'O reconhecimento pode enviar seu áudio ao serviço do navegador e depender da internet.' + #10
+ 'Não é necessária uma chave de API. Mantenha esta janela aberta. O filtro preserva a faixa de 100 a 7000 Hz, reduz ruído e detecta pausas de silêncio.</p>' + #10
+ '<button id="start">Iniciar escuta</button><button id="stop" disabled>Parar</button>' + #10
+ '<p id="status" role="status">Conectando ao Assistente…</p><div id="text"></div>' + #10
+ '<script>' + #10
+ '''use strict'';' + #10
+ 'const start=document.getElementById(''start''), stop=document.getElementById(''stop'');' + #10
+ 'const status=document.getElementById(''status''), text=document.getElementById(''text'');' + #10
+ 'const Recognition=window.SpeechRecognition || window.webkitSpeechRecognition;' + #10
+ 'let state=null, wanted=false, rec=null, retryAt=0, lastEpoch=null, connected=false;' + #10
+ 'const errors={' + #10
+ ' ''not-allowed'':''Microfone negado. Autorize o microfone no Chrome e clique em Iniciar escuta.'',' + #10
+ ' ''service-not-allowed'':''Reconhecimento indisponível neste navegador. Use o Google Chrome.'',' + #10
+ ' ''audio-capture'':''Microfone indisponível. Verifique o dispositivo nas configurações do Chrome.'',' + #10
+ ' ''network'':''Falha de rede no reconhecimento. Verifique a internet e inicie novamente.'',' + #10
+ ' ''no-speech'':''Nenhuma fala detectada. Aguardando…'',' + #10
+ ' ''language-not-supported'':''Idioma não disponível no Chrome.''' + #10
+ '};' + #10
+ 'async function send(kind,value,epoch){' + #10
+ ' const response=await fetch(''event'',{method:''POST'',headers:{''Content-Type'':''application/json''},' + #10
+ '  body:JSON.stringify({kind,text:value,epoch}),cache:''no-store''});' + #10
+ ' if(!response.ok && response.status!==409) throw Error(''Falha ao entregar a fala ao Assistente.'');' + #10
+ '}' + #10
+ '// Microphone preprocessing is local; only its filtered track reaches recognition.' + #10
+ 'let audio=null, stream=null, filteredTrack=null, analyser=null, gate=null;' + #10
+ 'let meterTimer=null, voiceMs=0, quietMs=0, attackMs=0, noiseFloor=0, meterTime=0;' + #10
+ 'let epochVoiceMs=0;' + #10
+ 'function resetVAD(){voiceMs=0;quietMs=0;attackMs=0;epochVoiceMs=0;noiseFloor=0;}' + #10
+ 'function releaseAudio(){' + #10
+ ' clearInterval(meterTimer);meterTimer=null;' + #10
+ ' if(gate)gate.gain.value=0;' + #10
+ ' stream?.getTracks().forEach(t=>t.stop());stream=null;' + #10
+ ' filteredTrack?.stop();filteredTrack=null;' + #10
+ ' if(audio)audio.close().catch(()=>{});audio=null;analyser=null;gate=null;resetVAD();' + #10
+ '}' + #10
+ 'async function prepareAudio(){' + #10
+ ' const chrome=navigator.userAgent.match(/Chrome\/(\d+)/);' + #10
+ ' if(!chrome || Number(chrome[1])<135)throw Error(''Use Google Chrome 135 ou superior para reconhecer áudio filtrado.'');' + #10
+ ' releaseAudio();' + #10
+ ' stream=await navigator.mediaDevices.getUserMedia({audio:{channelCount:1,' + #10
+ '  echoCancellation:true,noiseSuppression:true,autoGainControl:true},video:false});' + #10
+ ' audio=new AudioContext({sampleRate:16000});await audio.resume();' + #10
+ ' const source=audio.createMediaStreamSource(stream);' + #10
+ ' const high=audio.createBiquadFilter(), low=audio.createBiquadFilter();' + #10
+ ' high.type=''highpass'';high.frequency.value=100;high.Q.value=Math.SQRT1_2;' + #10
+ ' low.type=''lowpass'';low.frequency.value=Math.min(7000,audio.sampleRate*.45);low.Q.value=Math.SQRT1_2;' + #10
+ ' analyser=audio.createAnalyser();analyser.fftSize=512;gate=audio.createGain();gate.gain.value=0;' + #10
+ ' const destination=audio.createMediaStreamDestination();' + #10
+ ' source.connect(high).connect(low).connect(analyser).connect(gate).connect(destination);' + #10
+ ' filteredTrack=destination.stream.getAudioTracks()[0];' + #10
+ ' const samples=new Float32Array(analyser.fftSize);meterTime=performance.now();' + #10
+ ' meterTimer=setInterval(()=>{' + #10
+ '  const now=performance.now(),dt=Math.min(100,now-meterTime);meterTime=now;' + #10
+ '  if(!wanted || !connected || !state?.enabled){gate.gain.value=0;return;}' + #10
+ '  analyser.getFloatTimeDomainData(samples);' + #10
+ '  const rms=Math.sqrt(samples.reduce((sum,x)=>sum+x*x,0)/samples.length);' + #10
+ '  const manual=state.voiceThreshold || .015;' + #10
+ '  if(!voiceMs && rms<manual)noiseFloor=.95*noiseFloor+.05*rms;' + #10
+ '  const onset=Math.max(manual,noiseFloor*3),offset=Math.min(onset*.8,Math.max(manual*.53,noiseFloor*1.8));' + #10
+ '  if(rms>=onset){attackMs+=dt;quietMs=0;epochVoiceMs+=dt;voiceMs+=dt;}' + #10
+ '  else {quietMs+=dt;if(quietMs>150)attackMs=0;}' + #10
+ '  // Keep the end of speech while waiting for a configurable silence interval.' + #10
+ '  gate.gain.setTargetAtTime((rms>=offset || (voiceMs>0 && quietMs<(state.silenceMs || 900)))?1:0,audio.currentTime,.005);' + #10
+ '  if(voiceMs>0 && quietMs>=(state.silenceMs || 900)){' + #10
+ '   if(rec && voiceMs>=(state.minSpeechMs || 250))rec.stop();' + #10
+ '   voiceMs=0;attackMs=0;' + #10
+ '  }' + #10
+ ' },20);' + #10
+ '}' + #10
+ '' + #10
+ 'function abort(){if(rec){const old=rec;rec=null;old.abort();}}' + #10
+ 'function begin(){' + #10
+ ' if(!wanted || !connected || !state?.enabled || !filteredTrack || rec || Date.now()<retryAt) return;' + #10
+ ' const current=new Recognition(), epoch=state.epoch;epochVoiceMs=0;' + #10
+ ' rec=current; current.lang=state.language;current.continuous=true;current.interimResults=true;' + #10
+ ' current.onstart=()=>{if(rec!==current)return;status.textContent=''Escutando…'';send(''state'',''Chrome escutando'',epoch).catch(()=>{});};' + #10
+ ' current.onresult=e=>{' + #10
+ '  if(rec!==current || !wanted || !state?.enabled || epoch!==state.epoch)return;' + #10
+ '  let interim='''';' + #10
+ '  for(let i=e.resultIndex;i<e.results.length;i++){' + #10
+ '   const value=e.results[i][0].transcript.trim();' + #10
+ '   if(e.results[i].isFinal && value && epochVoiceMs>=(state.minSpeechMs || 250)){' + #10
+ '    text.textContent=value;' + #10
+ '    // One utterance per assistant turn. Polling resumes after its pause epoch.' + #10
+ '    rec=null;current.abort();retryAt=Date.now()+750;' + #10
+ '    send(''text'',value,epoch).catch(err=>{wanted=false;status.textContent=err.message;start.disabled=false;stop.disabled=true;});' + #10
+ '    return;' + #10
+ '   }else interim+=value+'' '';' + #10
+ '  }' + #10
+ '  text.textContent=interim;' + #10
+ ' };' + #10
+ ' current.onerror=e=>{' + #10
+ '  if(rec!==current)return;' + #10
+ '  const message=errors[e.error] || (''Erro de reconhecimento: ''+e.error);' + #10
+ '  status.textContent=message;send(''state'',message,epoch).catch(()=>{});' + #10
+ '  if(![''no-speech'',''aborted''].includes(e.error)){' + #10
+ '   wanted=false;start.disabled=false;stop.disabled=true;abort();releaseAudio();' + #10
+ '  }' + #10
+ '  retryAt=Date.now()+1000;' + #10
+ ' };' + #10
+ ' current.onend=()=>{if(rec===current)rec=null;retryAt=Math.max(retryAt,Date.now()+300);};' + #10
+ ' try{current.start(filteredTrack);}catch(e){rec=null;wanted=false;releaseAudio();status.textContent=e.message;start.disabled=false;stop.disabled=true;}' + #10
+ '}' + #10
+ 'start.onclick=async()=>{' + #10
+ ' if(!Recognition){status.textContent=''Web Speech API indisponível. Abra esta página no Google Chrome.'';return;}' + #10
+ ' start.disabled=true;' + #10
+ ' try{await prepareAudio();wanted=true;retryAt=0;stop.disabled=false;begin();}' + #10
+ ' catch(e){releaseAudio();wanted=false;start.disabled=false;status.textContent=errors[e.name===''NotAllowedError''?''not-allowed'':''''] || e.message;}' + #10
+ '};' + #10
+ 'stop.onclick=()=>{' + #10
+ ' wanted=false;abort();releaseAudio();start.disabled=false;stop.disabled=true;status.textContent=''Escuta parada.'';' + #10
+ ' if(state?.enabled)send(''state'',''Escuta parada no Chrome. Clique em Iniciar escuta para retomar.'',state.epoch).catch(()=>{});' + #10
+ '};' + #10
+ 'async function poll(){' + #10
+ ' try{' + #10
+ '  const response=await fetch(''state'',{cache:''no-store''});if(!response.ok)throw Error(''Sessão encerrada'');' + #10
+ '  const next=await response.json();connected=true;' + #10
+ '  if(lastEpoch!==null && next.epoch!==lastEpoch){abort();resetVAD();}' + #10
+ '  state=next;lastEpoch=next.epoch;' + #10
+ '  if(!state.enabled){abort();status.textContent=''Escuta pausada pelo Assistente.'';}' + #10
+ '  else if(!wanted)status.textContent=Recognition?''Clique em Iniciar escuta para autorizar o microfone.'':''Abra esta página no Google Chrome: reconhecimento não disponível.'';' + #10
+ '  begin();' + #10
+ ' }catch(e){connected=false;abort();if(gate)gate.gain.value=0;status.textContent=''Assistente desconectado. Reabra a escuta pelo botão do microfone no aplicativo.'';}' + #10
+ ' setTimeout(poll,200);' + #10
+ '}' + #10
+ 'window.addEventListener(''pagehide'',()=>{wanted=false;abort();releaseAudio();});' + #10
+ 'poll();' + #10
+ '</script></html>' + #10