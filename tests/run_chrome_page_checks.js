// Test the embedded page's real JavaScript with deterministic Web Speech/Web
// Audio adapters. No browser microphone or remote service is used.
const fs=require('fs'),vm=require('vm'),assert=require('assert');
const inc=fs.readFileSync(process.argv[2],'utf8');
const html=inc.split(/\r?\n/).map(line=>{
 const start=line.indexOf("'"),end=line.lastIndexOf("'");
 return start<0?'':line.slice(start+1,end).replace(/''/g,"'");
}).join('\n');
const code=html.split('<script>')[1].split('</script>')[0];
const elements=Object.fromEntries(['start','stop','status','text'].map(k=>[k,{disabled:false,textContent:''}]));
let nextState={enabled:true,epoch:1,language:'pt-BR',voiceThreshold:.015,silenceMs:900,minSpeechMs:250};
let instances=[],posts=[],polls=[],meters=[],now=0,level=0,micCalls=0,stops=0,denied=false;
const filtered={kind:'audio',readyState:'live',stop(){stops++}};
class Recognition{
 constructor(){instances.push(this)}
 start(track){assert.strictEqual(track,filtered);this.track=track;this.onstart?.()}
 abort(){this.aborted=true;this.onend?.()}
 stop(){this.stopped=true;this.onend?.()}
}
function node(){return {connect(n){return n},frequency:{value:0},Q:{value:0}}}
class AudioContext{
 constructor(){this.sampleRate=16000;this.currentTime=0}
 async resume(){}async close(){}
 createMediaStreamSource(){return node()}
 createBiquadFilter(){return node()}
 createGain(){return {...node(),gain:{value:0,setTargetAtTime(v){this.value=v}}}}
 createAnalyser(){return {...node(),getFloatTimeDomainData(a){a.fill(level)}}}
 createMediaStreamDestination(){return {...node(),stream:{getAudioTracks(){return [filtered]}}}}
}
const context=vm.createContext({document:{getElementById:k=>elements[k]},
 window:{SpeechRecognition:Recognition,addEventListener(){}},
 navigator:{userAgent:'Chrome/155.0',mediaDevices:{async getUserMedia(){micCalls++;if(denied)throw Object.assign(Error('denied'),{name:'NotAllowedError'});return {getTracks(){return [{stop(){stops++}}]}}}}},
 AudioContext,Float32Array,Math,Date:{now:()=>now},performance:{now:()=>now},
 setInterval(fn){meters.push(fn);return fn},clearInterval(fn){meters=meters.filter(x=>x!==fn)},setTimeout(fn){polls.push(fn)},
 async fetch(url,options){if(url==='state')return {ok:true,json:async()=>({...nextState})};posts.push(JSON.parse(options.body));return {ok:true,status:200}},console});
const flush=()=>new Promise(resolve=>setImmediate(resolve));
function frames(count,amplitude){level=amplitude;for(let i=0;i<count;i++){now+=20;meters.forEach(f=>f())}}
(async()=>{
 vm.runInContext(code,context);await flush();
 assert.strictEqual(micCalls,0,'Page opened microphone without click');
 await elements.start.onclick();assert.strictEqual(micCalls,1);assert.strictEqual(instances.length,1);
 frames(20,0);assert.strictEqual(posts.filter(x=>x.kind==='text').length,0);
 frames(20,.08);
 const old=instances.at(-1);
 old.onresult({resultIndex:0,results:[Object.assign([{transcript:'Olá, professor!'}],{isFinal:true})]});await flush();
 assert.strictEqual(posts.filter(x=>x.kind==='text')[0].text,'Olá, professor!');
 nextState.enabled=false;nextState.epoch=2;await polls.shift()();await flush();
 const before=posts.length;old.onresult({resultIndex:0,results:[Object.assign([{transcript:'stale'}],{isFinal:true})]});
 assert.strictEqual(posts.length,before,'Stale results accepted after pause');
 now+=1000;nextState.enabled=true;nextState.epoch=3;await polls.shift()();await flush();
 assert.strictEqual(instances.length,2,'Recognition did not resume');
 frames(20,.08);frames(50,0);assert(instances.at(-1).stopped,'Silence did not stop utterance');
 elements.stop.onclick();assert(stops>=2,'Stop failed to release audio tracks');
 denied=true;await elements.start.onclick();assert.match(elements.status.textContent,/Microfone negado/);
 assert(!elements.start.disabled,'Permission denial prevents retry');
 console.log('PASS: embedded Chrome JS, explicit consent, filtered track, silence, final text, stale result rejection, pause/resume, audio release, permission denial');
})().catch(e=>{console.error(e);process.exitCode=1});
