"""Bounded local transport; no GUI imports, file reads, or automatic grants."""
import hashlib
import json
import re
import socket
import struct
import threading
import time
import zlib
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlsplit

MAX_BYTES = 8 * 1024 * 1024
MAX_PIXELS = 16_000_000
TOKEN = re.compile(r'^[0-9a-fA-F]{64}$')

class PolicyError(Exception):
    def __init__(self, message, status=400, **details):
        super().__init__(message)
        self.status, self.details = status, details

def clean_token(value):
    if not isinstance(value, str) or not TOKEN.fullmatch(value):
        raise PolicyError('A 64 hexadecimal character pairing token is required.')
    return value.lower()

def clean_label(value):
    if not isinstance(value, str) or len(value) > 80 or any(ord(c) < 32 or ord(c) == 127 for c in value):
        raise PolicyError('The pairing label must be at most 80 characters without control characters.')
    return value or 'Light Engine addon'

def parse_uri(uri):
    if not isinstance(uri, str) or len(uri) > 1024:
        raise PolicyError('Invalid pairing URI.')
    parts = urlsplit(uri)
    if parts.scheme != 'lightengine-overlay' or parts.netloc != 'connect' or parts.path not in ('', '/') or parts.fragment:
        raise PolicyError('Only lightengine-overlay://connect pairing URIs are supported.')
    fields = parse_qs(parts.query, keep_blank_values=True, max_num_fields=3)
    if set(fields) - {'token', 'label'} or len(fields.get('token', [])) != 1 or len(fields.get('label', [])) > 1:
        raise PolicyError('Invalid pairing URI fields.')
    return clean_token(fields['token'][0]), clean_label(fields.get('label', ['Light Engine addon'])[0])

def validate_png(body):
    if len(body) > MAX_BYTES:
        raise PolicyError('PNG exceeds 8 MiB.', 413)
    if not body.startswith(b'\x89PNG\r\n\x1a\n'):
        raise PolicyError('An original PNG image is required.')
    offset, dimensions, seen_data, ended = 8, None, False, False
    compressed_parts=[]
    while offset < len(body):
        if offset + 12 > len(body): raise PolicyError('Truncated PNG chunk.')
        size = struct.unpack_from('!I', body, offset)[0]
        kind = body[offset+4:offset+8]
        end = offset + 12 + size
        if end > len(body) or not re.fullmatch(b'[A-Za-z]{4}', kind): raise PolicyError('Invalid PNG chunk.')
        data = body[offset+8:offset+8+size]
        crc = struct.unpack_from('!I', body, offset+8+size)[0]
        if zlib.crc32(kind+data) & 0xffffffff != crc: raise PolicyError('Invalid PNG checksum.')
        if dimensions is None:
            if kind != b'IHDR' or size != 13: raise PolicyError('PNG must begin with one IHDR.')
            width,height,depth,color,compression,filtering,interlace=struct.unpack('!IIBBBBB',data)
            depths={0:{1,2,4,8,16},2:{8,16},3:{1,2,4,8},4:{8,16},6:{8,16}}
            if not (0 < width <= 4096 and 0 < height <= 4096 and width*height <= MAX_PIXELS):
                raise PolicyError('PNG dimensions exceed 4096 per axis or 16 million pixels.',413)
            if depth not in depths.get(color,set()) or compression or filtering or interlace not in (0,1):
                raise PolicyError('Unsupported PNG header.')
            dimensions=(width,height)
        elif kind == b'IHDR': raise PolicyError('Duplicate PNG header.')
        if kind == b'IDAT': seen_data=True;compressed_parts.append(data)
        if kind == b'IEND':
            if size or not seen_data or end != len(body): raise PolicyError('Invalid PNG ending.')
            ended=True
        elif kind[0] < 97 and kind not in {b'IHDR',b'PLTE',b'IDAT'}:
            raise PolicyError('Unknown critical PNG chunk.')
        offset=end
    if not ended: raise PolicyError('PNG is missing its ending.')
    # Check bounded scanline decompression before passing data to Qt/libpng.
    channels={0:1,2:3,3:1,4:2,6:4}[color]
    passes=[(0,0,1,1)] if not interlace else [(0,0,8,8),(4,0,8,8),(0,4,4,8),(2,0,4,4),(0,2,2,4),(1,0,2,2),(0,1,1,2)]
    rows=[]
    for start_x,start_y,step_x,step_y in passes:
        pw=max(0,(width-start_x+step_x-1)//step_x);ph=max(0,(height-start_y+step_y-1)//step_y)
        if pw and ph:rows.extend([((pw*channels*depth+7)//8)+1]*ph)
    expected=sum(rows)
    decoder=zlib.decompressobj();expanded=0;row_index=0;row_remaining=0
    try:
        for part in compressed_parts:
            while part:
                output=decoder.decompress(part,min(65536,expected-expanded+1))
                expanded+=len(output)
                if expanded>expected:raise PolicyError('PNG scanlines exceed their declared dimensions.')
                position=0
                while position<len(output):
                    if row_remaining==0:
                        if output[position]>4:raise PolicyError('Invalid PNG scanline filter.')
                        row_remaining=rows[row_index];row_index+=1
                    consumed=min(row_remaining,len(output)-position)
                    position+=consumed;row_remaining-=consumed
                part=decoder.unconsumed_tail
                if decoder.unused_data:raise PolicyError('PNG contains trailing compressed data.')
        if not decoder.eof or expanded!=expected:raise PolicyError('Invalid or truncated PNG scanlines.')
    except zlib.error:raise PolicyError('Invalid PNG compression.')
    return dimensions

def geometry_values(values):
    if set(values)-{'x','y','width','height'}: raise PolicyError('Unknown geometry field.')
    result={}
    for key,value in values.items():
        if isinstance(value,str) and re.fullmatch(r'-?\d{1,6}',value): value=int(value)
        if type(value) is not int: raise PolicyError('Geometry values must be integers.')
        if key in ('width','height'):
            if not 1 <= value <= 4096: raise PolicyError('Overlay size must be between 1 and 4096.')
        elif not -100000 <= value <= 100000: raise PolicyError('Overlay position is out of bounds.')
        result[key]=value
    return result

class OverlayPolicy:
    def __init__(self, emit, clock=time.monotonic, unsupported=None):
        self.emit,self.clock,self.unsupported=emit,clock,unsupported
        self.lock=threading.RLock()
        self.grants=set();self.denied=[];self.pending_token=None;self.last_prompt=-float('inf')
        self.owner=None;self.revision=0;self.pending_image=False;self.closed=False

    def authorized(self,token):
        with self.lock: return not self.closed and token in self.grants

    def authorize(self,token):
        token=clean_token(token)
        with self.lock:
            if not self.authorized(token):
                raise PolicyError('Pairing consent is required.',403,pending=self.pending_token==token)
        return token

    def request_consent(self,token,label):
        token,label=clean_token(token),clean_label(label)
        with self.lock:
            if self.unsupported: raise PolicyError(self.unsupported,503)
            if self.closed: raise PolicyError('The companion is stopping.',503)
            if token in self.grants: return {'granted':True,'pending':False}
            if token in self.denied:return {'granted':False,'pending':False,'denied':True}
            if token==self.pending_token: return {'granted':False,'pending':True}
            if self.pending_token or self.clock()-self.last_prompt<3: raise PolicyError('Another pairing request is pending or was recently shown.',429)
            if len(self.grants)>=8: raise PolicyError('Stop existing sessions before adding another pairing.',429)
            self.pending_token=token;self.last_prompt=self.clock()
            self.emit({'kind':'consent','token':token,'label':label})
            return {'granted':False,'pending':True}

    def finish_consent(self,token,allowed):
        with self.lock:
            if self.closed or token!=self.pending_token:return False
            self.pending_token=None
            if allowed:self.grants.add(token)
            else:self.deny(token)
            return bool(allowed)

    def deny(self,token):
        if token and token not in self.denied:
            self.denied.append(token)
            if len(self.denied)>32:del self.denied[0]

    def submit(self,token,body,geometry):
        token=self.authorize(token)
        dimensions=validate_png(body);geometry=geometry_values(geometry)
        with self.lock:
            self.authorize(token)
            if self.owner and self.owner!=token:raise PolicyError('Another consented session owns the overlay.',409)
            if self.pending_image:raise PolicyError('An image update is already queued.',429)
            self.owner=token;self.revision+=1;self.pending_image=True
            self.emit({'kind':'image','token':token,'revision':self.revision,'bytes':body,'dimensions':dimensions,
                       'geometry':geometry,'sha256':hashlib.sha256(body).hexdigest()})
            return {'accepted':True,'displayed':False,'revision':self.revision}

    def current(self,token,revision):
        with self.lock:return self.owner==token and self.revision==revision and token in self.grants and not self.closed

    def finish_image(self,revision,displayed,reason=None):
        with self.lock:
            if revision!=self.revision:return
            self.pending_image=False
            if not displayed:self.owner=None

    def hide(self,token):
        token=self.authorize(token)
        with self.lock:
            if self.owner and self.owner!=token:raise PolicyError('Another session owns the overlay.',409)
            self.owner=None;self.pending_image=False;self.revision+=1
            self.emit({'kind':'hide','revision':self.revision})
            return {'accepted':True,'displayed':False}

    def revoke(self,token):
        token=clean_token(token)
        with self.lock:
            if self.closed or (token not in self.grants and token!=self.pending_token):
                raise PolicyError('No pending or granted session matches these credentials.',403)
            if token==self.pending_token:
                self.pending_token=None
                self.emit({'kind':'cancel_consent','token':token})
            self.grants.discard(token);self.deny(token)
            if self.owner==token:
                self.owner=None;self.pending_image=False;self.revision+=1
                self.emit({'kind':'hide','revision':self.revision})
            return {'accepted':True,'revoked':True,'displayed':False}

    def stop(self,close=False):
        with self.lock:
            for token in self.grants:self.deny(token)
            self.deny(self.pending_token)
            if self.pending_token:self.emit({'kind':'cancel_consent','token':self.pending_token})
            self.grants.clear();self.pending_token=None;self.owner=None;self.pending_image=False
            self.revision+=1;self.closed=close
            self.emit({'kind':'hide','revision':self.revision})

class DeadlineReader:
    def __init__(self,stream,connection):
        self.stream,self.connection=stream,connection
        stream.close()  # Avoid buffered reads which can silently reset per-recv timeouts.
        self.buffer=bytearray()
        self.deadline=time.monotonic()+3;self.header_bytes=0
    def before(self):
        remaining=self.deadline-time.monotonic()
        if remaining<=0:raise TimeoutError('Request deadline exceeded.')
        self.connection.settimeout(remaining)
    def read(self,size=-1):
        if size<0:raise ValueError('A bounded read size is required.')
        while len(self.buffer)<size:
            self.before();data=self.connection.recv(min(65536,size-len(self.buffer)))
            if not data:break
            self.buffer.extend(data)
        result=bytes(self.buffer[:size]);del self.buffer[:size]
        return result
    def readline(self,size=-1):
        limit=min(size if size>=0 else 16385,16385)
        while True:
            newline=self.buffer.find(b'\n')
            if newline>=0 or len(self.buffer)>=limit:
                count=min(newline+1 if newline>=0 else limit,limit);break
            self.before();data=self.connection.recv(min(4096,limit-len(self.buffer)))
            if not data:count=len(self.buffer);break
            self.buffer.extend(data)
        line=bytes(self.buffer[:count]);del self.buffer[:count]
        self.header_bytes+=len(line)
        if self.header_bytes>16384:raise PolicyError('Request headers exceed 16 KiB.',431)
        return line
    def close(self):self.buffer.clear();self.stream.close()

def make_server(policy,port=51874):
    class Handler(BaseHTTPRequestHandler):
        protocol_version='HTTP/1.0'
        def setup(self):
            super().setup();self.rfile=DeadlineReader(self.rfile,self.connection)
        def log_message(self,*args):pass  # Do not log pairing secrets or image bodies.
        def send_result(self,status,value):
            body=json.dumps(value,separators=(',',':')).encode()
            self.send_response(status);self.send_header('Content-Type','application/json')
            self.send_header('Content-Length',str(len(body)));self.send_header('Connection','close')
            self.end_headers();self.wfile.write(body);self.close_connection=True
        def body(self,limit):
            if self.headers.get('Transfer-Encoding'):raise PolicyError('Chunked bodies are unsupported.')
            length=self.headers.get('Content-Length')
            if length is None:raise PolicyError('Content-Length is required.',411)
            if not re.fullmatch(r'\d{1,10}',length):raise PolicyError('Invalid Content-Length.')
            length=int(length)
            if length>limit:raise PolicyError('Request body exceeds its limit.',413)
            pieces=[];remaining=length
            while remaining:
                piece=self.rfile.read(min(remaining,65536))
                if not piece:raise PolicyError('Truncated request body.')
                pieces.append(piece);remaining-=len(piece)
            return b''.join(pieces)
        def authenticated(self):
            auth=self.headers.get('Authorization','')
            if not auth.startswith('Bearer '):raise PolicyError('Pairing consent is required.',403,pending=False)
            try:return policy.authorize(auth[7:])
            except PolicyError as error:
                if error.status==400:raise PolicyError('Invalid pairing credentials.',403,pending=False)
                raise
        def route(self):
            if self.headers.get('Origin'):raise PolicyError('Browser-origin requests are not accepted.',403)
            parts=urlsplit(self.path)
            if parts.scheme or parts.netloc or parts.fragment:raise PolicyError('Only local API paths are supported.')
            if self.command=='POST' and parts.path=='/connect':
                if parts.query:raise PolicyError('Connect fields belong in the JSON body.')
                try:value=json.loads(self.body(1024))
                except (ValueError,UnicodeError):raise PolicyError('Invalid connect JSON.')
                if not isinstance(value,dict) or set(value)-{'token','label'}:raise PolicyError('Invalid connect fields.')
                result=policy.request_consent(value.get('token'),value.get('label','Light Engine addon'))
                self.send_result(202 if result.get('pending') else 200,result)
            elif self.command=='DELETE' and parts.path=='/connect':
                if parts.query:raise PolicyError('Release does not accept query fields.')
                auth=self.headers.get('Authorization','')
                if not auth.startswith('Bearer '):raise PolicyError('Pairing credentials are required.',403)
                try:result=policy.revoke(auth[7:])
                except PolicyError as error:
                    if error.status==400:raise PolicyError('Invalid pairing credentials.',403)
                    raise
                self.send_result(202,result)
            elif parts.path=='/image' and self.command in ('POST','DELETE'):
                token=self.authenticated()
                if self.command=='DELETE':
                    if parts.query:raise PolicyError('Delete does not accept geometry.')
                    self.send_result(202,policy.hide(token))
                else:
                    values=parse_qs(parts.query,keep_blank_values=True,max_num_fields=5)
                    if any(len(v)!=1 for v in values.values()):raise PolicyError('Duplicate geometry fields.')
                    geometry=geometry_values({k:v[0] for k,v in values.items()})
                    self.send_result(202,policy.submit(token,self.body(MAX_BYTES),geometry))
            else:raise PolicyError('Unknown endpoint.',404)
        def dispatch(self):
            try:self.route()
            except PolicyError as error:self.send_result(error.status,{'error':str(error),**error.details})
            except (ValueError,UnicodeError):self.send_result(400,{'error':'Invalid request fields.'})
            except (OSError,TimeoutError):self.close_connection=True
        do_POST=dispatch
        do_DELETE=dispatch
        def handle_one_request(self):
            try:super().handle_one_request()
            except (PolicyError,OSError,TimeoutError):self.close_connection=True
    # A single network worker bounds concurrent request bodies and connections.
    class Server(HTTPServer):
        allow_reuse_address=True
        request_queue_size=4
        def __init__(self,*args,**kwargs):
            self.request_lock=threading.Lock();self.active_connection=None
            super().__init__(*args,**kwargs)
        def get_request(self):
            connection,address=super().get_request()
            with self.request_lock:self.active_connection=connection
            return connection,address
        def close_request(self,connection):
            with self.request_lock:
                if self.active_connection is connection:self.active_connection=None
            super().close_request(connection)
        def interrupt_request(self):
            with self.request_lock:connection=self.active_connection
            if connection:
                try:connection.shutdown(socket.SHUT_RDWR)
                except OSError:pass
    return Server(('127.0.0.1',port),Handler)
