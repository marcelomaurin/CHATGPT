"""Text-free 24x24 palette pictograms. Pure Python; no fonts or imaging dependencies."""
import math

SIZE = 24
BACKGROUND = (192, 192, 192)  # Lazarus bitmap transparency key (bottom-left pixel).
INK = (43, 57, 75)
PAPER = (249, 251, 253)


class Canvas:
    def __init__(self, accent):
        self.scale = 3
        self.n = SIZE * self.scale
        self.pixels = [BACKGROUND] * (self.n * self.n)
        self.accent = tuple(accent)
        self.tint = tuple((channel + 3 * 255) // 4 for channel in accent)

    def paint(self, bounds, predicate, color):
        x0, y0, x1, y1 = bounds
        for y in range(max(0, int(y0*self.scale)-1), min(self.n, math.ceil(y1*self.scale)+1)):
            for x in range(max(0, int(x0*self.scale)-1), min(self.n, math.ceil(x1*self.scale)+1)):
                if predicate((x+.5)/self.scale, (y+.5)/self.scale):
                    self.pixels[y*self.n+x] = tuple(color)

    def line(self, x0, y0, x1, y1, color=INK, width=1.5):
        radius = width/2
        dx, dy = x1-x0, y1-y0
        length = dx*dx+dy*dy
        def hit(x,y):
            t = max(0,min(1,((x-x0)*dx+(y-y0)*dy)/length)) if length else 0
            return (x-x0-t*dx)**2+(y-y0-t*dy)**2 <= radius*radius
        self.paint((min(x0,x1)-radius,min(y0,y1)-radius,max(x0,x1)+radius,max(y0,y1)+radius),hit,color)

    def path(self, points, color=INK, width=1.5, close=False):
        points = list(points)
        for a,b in zip(points,points[1:]+([points[0]] if close else [])):
            self.line(*a,*b,color,width)

    def rect(self,x,y,w,h,fill=PAPER,stroke=INK,width=1.4):
        if fill is not None:
            self.paint((x,y,x+w,y+h),lambda px,py:x<=px<=x+w and y<=py<=y+h,fill)
        if stroke is not None:self.path([(x,y),(x+w,y),(x+w,y+h),(x,y+h)],stroke,width,True)

    def ellipse(self,x,y,rx,ry=None,fill=None,stroke=INK,width=1.4):
        ry = rx if ry is None else ry
        if fill is not None:
            self.paint((x-rx,y-ry,x+rx,y+ry),lambda px,py:((px-x)/rx)**2+((py-y)/ry)**2<=1,fill)
        if stroke is not None:
            self.arc(x,y,rx,ry,0,360,stroke,width)

    def arc(self,x,y,rx,ry,start,end,color=INK,width=1.5):
        steps=max(8,int(abs(end-start)/8))
        points=[(x+rx*math.cos(math.radians(start+(end-start)*i/steps)),
                 y+ry*math.sin(math.radians(start+(end-start)*i/steps))) for i in range(steps+1)]
        self.path(points,color,width)

    def arrow(self,x0,y0,x1,y1,color=None,width=1.6):
        color = color or self.accent
        self.line(x0,y0,x1,y1,color,width)
        angle=math.atan2(y1-y0,x1-x0)
        for side in (-1,1):
            a=angle+side*2.5
            self.line(x1,y1,x1+3*math.cos(a),y1+3*math.sin(a),color,width)

    def rgb(self):
        result=[]
        for y in range(SIZE):
            for x in range(SIZE):
                block=[self.pixels[(y*self.scale+dy)*self.n+x*self.scale+dx]
                       for dy in range(self.scale) for dx in range(self.scale)]
                result.extend(sum(p[i] for p in block)//len(block) for i in range(3))
        return result


def icon_spec(name):
    """Choose a functional symbol and an operation badge; never draw identifiers."""
    n=name.lower()
    exact={
        'tchatgpt':('chat','spark'), 'taichromespeech':('browser','wave'),
        'taicontinuouslistener':('ear','wave'), 'taispeakeridentifier':('person','wave'),
        'taiactivespeakermanager':('people','wave'), 'taipersonsessionmanager':('people','history'),
        'taidroonfq777':('drone',''), 'taidronefq777':('drone',''),
        'taiwifi':('wifi',''), 'taijoystick':('gamepad',''), 'taih264decoder':('film','play'),
        'taiwebrtcclient':('screens','network'), 'taiframebuffer':('image','stack'),
        'taiframediff':('image','compare'), 'taiframedecoder':('film','play'),
        'taiavatarlipsync':('face','wave'), 'taiskeletonrig':('skeleton','gear'),
        'taifirmwareflasher':('chip','bolt'), 'taicpu':('chip',''), 'taigpu':('chip','image'),
        'taimemory':('ram',''), 'taidisk':('disk',''), 'taios':('window','gear'),
        'tainumps':('matrix',''), 'tnumps':('matrix',''), 'tamatizcomponent':('matrix',''),
        'tamatrizcomponent':('matrix',''), 'tmycomponent':('shapes',''),
        'taipromptbuilder':('chat','gear'), 'taicodeassistant':('code','spark'),
        'taimodelregistry':('layers','list'), 'taimodelrouter':('route','spark'),
        'taiunifiedllm':('network','spark'), 'taillmjudge':('scales','spark'),
        'tairewardfunction':('medal',''), 'taisourceRollbackaction'.lower():('code','history'),
    }
    if n in exact:return exact[n]
    badge=''
    for token,mark in [('rollback','history'),('revisions','history'),('input','in'),('output','out'),
                       ('export','out'),('import','in'),('server','server'),('client','link'),
                       ('viewer','eye'),('visualizer','eye'),('config','gear'),('options','gear'),
                       ('manager','gear'),('controller','gear'),('recogn','search'),('detect','search'),
                       ('tracker','target'),('test','check'),('report','chart'),('generator','plus'),
                       ('builder','wrench'),('store','stack'),('storage','stack'),('registry','list')]:
        if token in n:badge=mark;break
    if any(t in n for t in ('guardrail','safety','risk')):return 'shield',badge or 'check'
    if 'a2a' in n:return 'agents',badge
    if 'mcp' in n or 'toolregistry' in n:return 'plug',badge
    if 'dictionary' in n or 'database' in n or 'dbase' in n:return 'database',badge or 'list'
    if any(t in n for t in ('modbus','industrial','arduino','pinmap','commandmap')):return 'circuit',badge
    if any(t in n for t in ('arm_robot','armrobot','robotagent','rosagent')):return 'robot',badge
    if 'drone' in n:return 'drone',badge
    if 'wifi' in n:return 'wifi',badge
    if 'usb' in n or 'serial' in n or 'modem' in n:return 'usb',badge
    if any(t in n for t in ('mqtt','socket','networkagent')):return 'network',badge
    if 'webrtc' in n:return 'screens',badge
    if 'joystick' in n:return 'gamepad',badge
    if any(t in n for t in ('rss','telegram')):return ('rss' if 'rss' in n else 'plane'),badge
    if 'email' in n:return 'mail',badge
    if 'youtube' in n:return 'film','play'
    if 'github' in n or 'gitlab' in n:return 'branch',badge
    if 'ssh' in n:return 'terminal','lock'
    if any(t in n for t in ('browser','chromium','webagent','webapi')):return 'browser',badge
    if any(t in n for t in ('whatsapp','facebook','messenger','telegram')):return 'chat',badge
    if any(t in n for t in ('gcode','marlin','posprinter','listprinter')):return 'printer',badge
    if any(t in n for t in ('multiplexer','averagefilter','highpass','lowpass')):return 'signal',badge
    if any(t in n for t in ('audio','speech','voice','whisper','f5tts')):
        if any(t in n for t in ('synth','tts','play','clone')):return 'speaker',badge or ('copy' if 'clone' in n else 'wave')
        return 'microphone',badge or 'wave'
    if any(t in n for t in ('skeleton','humanpose','poselibrary','kinect')):return ('camera' if any(t in n for t in ('color','depth','sensor')) else 'skeleton'),badge
    if 'avatar' in n or 'face' in n:return 'face',badge
    if 'scene' in n or '3d' in n or 'physics' in n:return 'cube',badge
    if any(t in n for t in ('image','opencv','yolo','frame','motiontracker','capture','filter','brightness','blur','binar','grayscale','negative','sobel','sharpen','erosion')):return 'image',badge or 'spark'
    if any(t in n for t in ('route','geojson','cityindex','speedprofile')):return 'map',badge
    if 'graph' in n or 'networkview' in n:return 'graph',badge
    if any(t in n for t in ('matrix','matriz','numps')):return 'matrix',badge
    if any(t in n for t in ('perceptron','neural','cnn','lstm','sommap','embedding','vector','llama','unifiedllm')):return 'network',badge or 'spark'
    if any(t in n for t in ('dataset','training','evaluation','lexical','regression')):return 'chart',badge
    if any(t in n for t in ('trace','stats','status')):return 'chart',badge
    if 'board' in n:return 'board',badge
    if 'gantt' in n or 'timeline' in n:return 'gantt',badge
    if 'schedule' in n or 'calendar' in n:return 'calendar',badge
    if 'presentation' in n:return 'presentation',badge
    if any(t in n for t in ('pdf','word','docx','document','txt','excel','docs','agile','specification','description')):return ('table' if 'excel' in n else 'document'),badge
    if 'disk' in n:return 'disk',badge
    if 'folder' in n or 'files' in n or 'scanner' in n:return 'folder',badge
    if 'source' in n or 'lazarusbuild' in n or 'projectbuild' in n or 'python' in n:return 'code',badge
    if 'rag' in n or 'retriev' in n or 'rerank' in n:return 'search',badge
    if 'person' in n:return 'people',badge
    if 'token' in n or 'groupresponse' in n:return 'list',badge
    if 'project' in n or 'task' in n or 'tasks' in n:return 'clipboard',badge
    if 'grid' in n or 'world' in n:return 'grid',badge
    if 'simulation' in n or 'scenario' in n or 'movement' in n or 'entity' in n or 'evolution' in n:return 'gears',badge
    if 'trigger' in n or 'actionexecutor' in n:return 'bolt',badge
    if 'rule' in n or 'decision' in n or 'classifier' in n:return 'flow',badge
    if 'pipeline' in n or 'orchestrator' in n:return 'flow',badge
    if 'topic' in n or 'conversation' in n or 'prompt' in n:return 'chat',badge
    if 'wizard' in n:return 'wand',badge
    if 'sensor' in n:return 'target',badge
    if 'agent' in n:return 'robot',badge
    if 'llm' in n or 'model' in n:return 'layers',badge
    if 'output' in n or 'input' in n:return 'arrows',badge
    return 'gear',badge


def draw_base(c,kind):
    a,t=c.accent,c.tint
    if kind in ('document','clipboard','list','table','chart'):
        c.rect(5,3,13,18,t)
        if kind=='clipboard':c.rect(8,2,7,3,PAPER)
        elif kind=='chart':
            for x,h in [(8,5),(12,9),(16,12)]:c.rect(x-1,19-h,2,h,a,None)
            c.line(7,19,17,19)
        elif kind=='table':
            for x in (9,14):c.line(x,6,x,19,a,1)
            for y in (8,12,16):c.line(6,y,17,y,a,1)
        else:
            for y,w in [(8,8),(12,8),(16,5)]:c.line(8,y,8+w,y,a,1.5)
    elif kind in ('chat','browser','window','terminal','code','screens'):
        c.rect(3,4,18,14,t)
        if kind in ('browser','window'):c.line(3,8,21,8);c.ellipse(5,6,.6,fill=a,stroke=None);c.line(9,6,18,6,a,1)
        elif kind=='chat':c.path([(7,18),(7,22),(12,18)],INK,1.4);c.line(7,10,17,10,a);c.line(7,14,13,14,a)
        elif kind in ('code','terminal'):
            c.path([(9,8),(6,11),(9,14)],a);c.path([(15,8),(18,11),(15,14)],a)
            if kind=='code':c.line(13,7,11,15)
        elif kind=='screens':c.rect(10,11,11,9,PAPER);c.line(13,22,19,22,a)
        if kind!='chat':c.line(12,18,12,21);c.line(8,21,16,21)
    elif kind in ('network','graph','agents'):
        nodes=[(5,6),(18,5),(12,12),(5,19),(20,18)]
        for i,j in [(0,2),(1,2),(2,3),(2,4),(0,3),(1,4)]:c.line(*nodes[i],*nodes[j],a,1.2)
        for i,(x,y) in enumerate(nodes):c.ellipse(x,y,2.4 if i==2 else 2,fill=PAPER,stroke=INK)
    elif kind=='database':
        c.rect(4,6,16,13,t,None);c.line(4,6,4,18);c.line(20,6,20,18)
        for y in (6,12,18):c.ellipse(12,y,8,3,fill=PAPER if y==6 else None,stroke=INK)
        c.arc(12,12,8,3,0,180,a)
    elif kind=='wifi':
        for r in (5,9,13):c.arc(12,21,r,r,220,320,a,2)
        c.ellipse(12,20,1.8,fill=INK,stroke=None)
    elif kind in ('microphone','ear','speaker'):
        if kind=='microphone':
            c.ellipse(10,8,3,5,fill=t);c.arc(10,10,6,6,0,180,a,1.7)
            c.line(10,16,10,21);c.line(6,21,14,21)
        elif kind=='speaker':
            c.rect(3,9,4,7,t);c.path([(7,9),(13,4),(13,21),(7,16)],a,1.8,True)
            c.arc(13,12.5,5,5,-65,65);c.arc(13,12.5,8,8,-60,60,a)
        else:
            c.arc(12,11,7,9,150,420,a,2);c.arc(12,11,3.5,5,200,380,INK)
            c.path([(16,12),(13,14),(13,18),(10,20)],a,2)
    elif kind in ('face','person','people'):
        if kind=='face':
            c.ellipse(12,12,8,9,fill=t);c.ellipse(9,10,1,fill=INK,stroke=None);c.ellipse(15,10,1,fill=INK,stroke=None)
            c.arc(12,13,4,4,20,160,a)
        else:
            c.ellipse(10,7,4,fill=PAPER);c.arc(10,21,8,9,180,360,a,2)
            if kind=='people':c.arc(18,7,3,4,240,480);c.arc(17,20,5,7,240,350,a)
    elif kind=='skeleton':
        c.ellipse(12,4,2,fill=t);c.path([(12,7),(12,14),(7,21)]);c.line(12,14,18,21)
        c.path([(4,9),(12,11),(20,8)],a,2)
        for x,y in [(12,11),(12,14),(7,21),(18,21)]:c.ellipse(x,y,1.1,fill=a,stroke=None)
    elif kind in ('robot','gamepad'):
        if kind=='robot':
            c.rect(5,7,14,12,t);c.line(12,7,12,3,a);c.ellipse(12,2.5,1,fill=a,stroke=None)
            c.rect(2,11,3,5,PAPER);c.rect(19,11,3,5,PAPER)
            c.ellipse(9,11,1,fill=INK,stroke=None);c.ellipse(15,11,1,fill=INK,stroke=None);c.line(9,16,15,16,a)
        else:
            c.path([(5,7),(19,7),(22,18),(18,20),(14,16),(10,16),(6,20),(2,18),(5,7)],INK,2)
            c.line(5,11,10,11,a,2);c.line(7.5,8.5,7.5,13.5,a,2)
            for x,y in [(16,10),(19,12)]:c.ellipse(x,y,1.1,fill=a,stroke=None)
    elif kind=='drone':
        for x,y in [(5,5),(19,5),(5,19),(19,19)]:
            c.line(12,12,x,y,INK,2);c.ellipse(x,y,3.2,fill=PAPER,stroke=a)
        c.rect(9,9,6,6,a)
    elif kind in ('chip','ram','circuit'):
        if kind=='ram':
            c.rect(3,6,18,12,t)
            for x in (6,11,16):c.rect(x,9,3,5,a,None)
            for x in range(5,20,3):c.line(x,18,x,21,INK)
        else:
            c.rect(6,6,12,12,t)
            for p in (8,12,16):
                c.line(p,3,p,6);c.line(p,18,p,21);c.line(3,p,6,p);c.line(18,p,21,p)
            if kind=='chip':c.rect(9,9,6,6,a,None)
            else:c.path([(8,14),(11,14),(11,10),(16,10)],a,1.6)
    elif kind=='disk':
        c.rect(4,3,16,18,t);c.ellipse(12,11,5,fill=PAPER);c.ellipse(12,11,1.5,fill=a,stroke=None)
        c.line(12,11,17,16,a,2);c.line(7,19,10,19,a)
    elif kind in ('cube','layers','shapes'):
        if kind=='layers':
            for y in (7,12,17):c.path([(3,y),(12,y-4),(21,y),(12,y+4)],a if y!=7 else INK,1.6,True)
        else:
            c.path([(4,7),(12,3),(20,7),(20,17),(12,21),(4,17)],INK,1.7,True)
            c.path([(4,7),(12,11),(20,7)],a);c.line(12,11,12,21,a)
    elif kind in ('gear','gears'):
        for i in range(8):
            angle=i*math.pi/4;c.line(12+7*math.cos(angle),12+7*math.sin(angle),12+10*math.cos(angle),12+10*math.sin(angle),INK,2.7)
        c.ellipse(12,12,7,fill=t,stroke=INK,width=2);c.ellipse(12,12,2.6,fill=PAPER,stroke=a)
    elif kind in ('image','camera','film'):
        c.rect(3,5,18,15,t)
        if kind=='camera':c.rect(7,2,8,3,a);c.ellipse(12,12,5,fill=PAPER,stroke=INK);c.ellipse(12,12,2,fill=a,stroke=None)
        elif kind=='film':
            for x in (5,10,15,19):c.rect(x,6,1,2,INK,None);c.rect(x,17,1,2,INK,None)
            c.path([(10,10),(16,13),(10,16)],a,1.6,True)
        else:
            c.ellipse(16,9,2,fill=a,stroke=None);c.path([(4,18),(9,11),(13,16),(16,13),(20,18)],a,1.7)
    elif kind in ('map','route','flow','branch'):
        if kind=='map':
            c.path([(3,5),(9,3),(15,6),(21,4),(21,19),(15,21),(9,18),(3,20)],INK,1.3,True)
            c.line(9,3,9,18,a);c.line(15,6,15,21,a);c.path([(5,15),(10,11),(17,14)],INK,2)
        else:
            c.path([(6,20),(6,5),(17,5),(17,17)],a,2)
            for x,y in [(6,20),(6,5),(17,5),(17,17)]:c.ellipse(x,y,2,fill=PAPER)
            if kind=='branch':c.path([(6,14),(12,14),(17,9)],a,2)
    elif kind in ('shield','scales','medal'):
        if kind=='shield':
            c.path([(4,4),(12,2),(20,4),(19,14),(16,19),(12,22),(8,19),(5,14)],INK,1.8,True)
            c.path([(7,11),(11,15),(17,7)],a,2.1)
        elif kind=='scales':
            c.line(12,3,12,21);c.line(5,6,19,6,a);c.line(7,21,17,21)
            for x in (5,19):c.path([(x,6),(x-3,13),(x+3,13),(x,6)],a,1.4)
        else:
            c.path([(7,3),(12,9),(17,3)],a,3);c.ellipse(12,15,6,fill=t);c.ellipse(12,15,2,fill=a,stroke=None)
    elif kind in ('calendar','board','gantt','grid','matrix'):
        c.rect(3,4,18,17,t)
        if kind=='calendar':
            c.line(3,9,21,9);c.line(7,2,7,6,a,2);c.line(17,2,17,6,a,2)
            for x,y in [(7,12),(12,12),(17,12),(7,17),(12,17)]:c.rect(x-1,y-1,2,2,a,None)
        elif kind=='gantt':
            for x,y,w in [(5,8,6),(8,13,9),(13,18,6)]:c.line(x,y,x+w,y,a,2.5)
        elif kind=='board':
            for x in (6,12,18):c.rect(x-1,7,2,8 if x!=12 else 12,a,None)
        else:
            for p in (9,15):c.line(p,5,p,20,a,1);c.line(4,p,20,p,a,1)
    elif kind in ('mail','folder','printer','presentation'):
        if kind=='mail':c.rect(3,6,18,14,t);c.path([(3,6),(12,14),(21,6)],a,1.7)
        elif kind=='folder':c.path([(3,7),(3,4),(10,4),(12,7),(21,7),(21,20),(3,20),(3,7)],INK,1.6)
        elif kind=='printer':
            c.rect(7,2,10,8,PAPER);c.rect(3,8,18,10,t);c.rect(6,14,12,8,PAPER);c.line(9,17,15,17,a)
            c.ellipse(18,11,1,fill=a,stroke=None)
        else:
            c.rect(3,3,18,13,t);c.line(12,16,12,22);c.line(12,18,6,22);c.line(12,18,18,22)
            c.path([(6,12),(10,8),(14,11),(18,6)],a,2)
    elif kind in ('usb','plug'):
        c.line(12,22,12,5,a,2);c.path([(9,5),(12,2),(15,5)],INK,1.4,True)
        c.path([(12,15),(6,12),(6,8)],INK,1.6);c.ellipse(6,6,1.5,fill=t)
        c.path([(12,18),(18,14),(18,10)],INK,1.6);c.rect(16.5,7,3,3,t)
    elif kind=='search':
        c.ellipse(10,10,6.5,fill=t,stroke=INK,width=2);c.line(15,15,21,21,a,3)
    elif kind=='target':
        for radius in (8,4):c.ellipse(12,12,radius,stroke=a)
        c.line(12,1,12,7);c.line(12,17,12,23);c.line(1,12,7,12);c.line(17,12,23,12)
    elif kind in ('signal','rss'):
        if kind=='rss':
            c.ellipse(5,19,1.7,fill=a,stroke=None)
            for r in (8,15):c.arc(5,19,r,r,270,360,a,2.5)
        else:
            c.path([(2,12),(5,12),(8,4),(11,20),(14,8),(17,15),(20,12),(22,12)],a,1.8)
    elif kind=='plane':
        c.path([(2,11),(22,2),(15,22),(11,14),(2,11)],INK,1.6);c.line(11,14,22,2,a,1.7)
    elif kind in ('bolt','wand'):
        c.path([(13,2),(5,13),(11,13),(9,22),(20,9),(13,9)],a,2,True)
    else:
        c.arrow(3,8,20,8);c.arrow(20,17,3,17,INK)


def draw_badge(c,badge):
    if not badge:return
    a=c.accent
    c.ellipse(19,19,4.5,fill=PAPER,stroke=None)
    if badge in ('in','out'):
        c.arrow(19,16 if badge=='in' else 22,19,22 if badge=='in' else 16,a,1.4)
    elif badge in ('search','eye','target'):
        c.ellipse(18.5,18.5,2.3,stroke=a,width=1.3);c.line(20.3,20.3,22,22,a,1.4)
    elif badge in ('gear','wrench','list'):
        for y,w in [(17,5),(19,3),(21,5)]:c.line(16.5,y,16.5+w,y,a,1.2)
    elif badge in ('plus','spark'):
        c.line(19,15.5,19,22.5,a,1.5);c.line(15.5,19,22.5,19,a,1.5)
        if badge=='spark':c.line(16.8,16.8,21.2,21.2,a,1);c.line(16.8,21.2,21.2,16.8,a,1)
    elif badge=='history':
        c.arc(19,19,3,3,200,510,a,1.3);c.path([(15.5,18),(16,21),(18,19.5)],a,1.2)
    elif badge in ('wave','network'):
        c.path([(16,20),(17.5,17),(19,21),(20.5,17),(22,19)],a,1.3)
    elif badge in ('check','lock'):
        c.path([(16,19),(18,21),(22,16.5)],a,1.6)
    elif badge in ('stack','copy','server'):
        c.rect(16,16,5,5,PAPER,a,1);c.rect(18,18,4,4,PAPER,a,1)
    elif badge=='chart':
        for x,h in [(16.5,2),(19,4),(21.5,6)]:c.line(x,22,x,22-h,a,1.5)
    elif badge=='play':c.path([(17,16),(22,19),(17,22)],a,1.5,True)
    elif badge=='link':c.path([(16,20),(18,17),(21,18),(19,21)],a,1.4)
    elif badge=='image':c.rect(16,16,6,6,PAPER,a,1);c.path([(16,21),(19,18),(22,21)],a,1)


def render_icon(component_name,accent):
    canvas=Canvas(accent)
    kind,badge=icon_spec(component_name)
    draw_base(canvas,kind)
    draw_badge(canvas,badge)
    return canvas.rgb()
