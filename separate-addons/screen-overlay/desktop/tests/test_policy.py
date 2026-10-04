import hashlib
import http.client
import json
import socket
import struct
import sys
import threading
import time
import unittest
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from overlay_policy import DeadlineReader, OverlayPolicy, PolicyError, make_server, parse_uri, validate_png

TOKEN = 'a' * 64
OTHER = 'b' * 64

def chunk(kind, body):
    return struct.pack('!I', len(body)) + kind + body + struct.pack('!I', zlib.crc32(kind + body) & 0xffffffff)

def png(width=2, height=2):
    header = struct.pack('!IIBBBBB', width, height, 8, 6, 0, 0, 0)
    pixels = b'\0' + bytes([255, 0, 0, 128, 0, 255, 0, 255])
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', header) + chunk(b'tEXt', b'original\0metadata') + chunk(b'IDAT', zlib.compress(pixels * 2)) + chunk(b'IEND', b'')

def bad_filter_png():
    header=struct.pack('!IIBBBBB',2,2,8,6,0,0,0)
    return b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',header)+chunk(b'IDAT',zlib.compress((b'\x05'+b'\0'*8)*2))+chunk(b'IEND',b'')

class PolicyTests(unittest.TestCase):
    def setUp(self):
        self.events = []
        self.time = 100.
        self.policy = OverlayPolicy(self.events.append, clock=lambda: self.time)

    def pair(self, token=TOKEN):
        self.policy.request_consent(token, 'Fixture mod')
        self.assertFalse(self.policy.authorized(token))
        self.policy.finish_consent(token, True)

    def test_pairing_needs_explicit_consent_and_denial_grants_nothing(self):
        self.policy.request_consent(TOKEN, 'Fixture')
        self.assertFalse(self.policy.authorized(TOKEN))
        self.policy.finish_consent(TOKEN, False)
        self.assertFalse(self.policy.authorized(TOKEN))
        with self.assertRaises(PolicyError): self.policy.submit(TOKEN, png(), {})
        self.time+=10
        result=self.policy.request_consent(TOKEN,'Fixture')
        self.assertFalse(result['pending']);self.assertTrue(result['denied']);self.assertEqual(len(self.events),1)

    def test_pending_consent_and_rate_are_bounded(self):
        self.policy.request_consent(TOKEN, 'Fixture')
        with self.assertRaises(PolicyError): self.policy.request_consent(OTHER, 'Other')
        self.assertEqual(len(self.events), 1)
        self.policy.finish_consent(TOKEN, False)
        with self.assertRaises(PolicyError): self.policy.request_consent(OTHER, 'Other')
        self.time += 4
        self.policy.request_consent(OTHER, 'Other')
        self.assertEqual(len(self.events), 2)

    def test_original_png_bytes_and_metadata_survive_queued_transport(self):
        self.pair(); original=png()
        result=self.policy.submit(TOKEN, original, {'x': -30, 'width': 200})
        event=self.events[-1]
        self.assertEqual(event['bytes'], original)
        self.assertEqual(event['sha256'], hashlib.sha256(original).hexdigest())
        self.assertTrue(result['accepted']); self.assertFalse(result['displayed'])
        with self.assertRaises(PolicyError): self.policy.submit(TOKEN, original, {})

    def test_hide_and_replacement_generations_prevent_late_redisplay(self):
        self.pair(); self.policy.submit(TOKEN, png(), {})
        old=self.events[-1]; self.policy.hide(TOKEN)
        self.assertFalse(self.policy.current(old['token'],old['revision']))
        self.policy.submit(TOKEN,png(),{}); newer=self.events[-1]
        self.policy.finish_image(old['revision'],False,'late failure')
        self.assertTrue(self.policy.current(newer['token'],newer['revision']))

    def test_stop_revokes_grants_and_pending_consent(self):
        self.pair();self.policy.submit(TOKEN,png(),{});event=self.events[-1]
        self.policy.stop()
        self.assertFalse(self.policy.authorized(TOKEN))
        self.assertFalse(self.policy.current(TOKEN,event['revision']))
        self.time+=10
        self.assertTrue(self.policy.request_consent(TOKEN,'Fixture')['denied'])

    def test_other_granted_token_cannot_replace_an_owned_overlay(self):
        self.pair();self.time+=4;self.pair(OTHER)
        self.policy.submit(TOKEN,png(),{})
        self.policy.finish_image(self.events[-1]['revision'],True)
        with self.assertRaises(PolicyError):self.policy.submit(OTHER,png(),{})

    def test_invalid_png_crc_dimensions_and_geometry_are_rejected(self):
        self.pair()
        for body in [b'not png', png()[:-1], png()+b'extra', png(4097,2), png(4096,4096)]:
            with self.assertRaises(PolicyError):validate_png(body)
        damaged=bytearray(png());damaged[35]^=1
        with self.assertRaises(PolicyError):validate_png(bytes(damaged))
        header=struct.pack('!IIBBBBB',2,2,8,6,0,0,0)
        for compressed in [b'not zlib',zlib.compress(b'\0'*100000),zlib.compress(b'\0'*3)]:
            malformed=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',header)+chunk(b'IDAT',compressed)+chunk(b'IEND',b'')
            with self.assertRaises(PolicyError):validate_png(malformed)
        with self.assertRaises(PolicyError):validate_png(bad_filter_png())
        for geometry in [{'width':0},{'x':'shell'},{'height':10000},{'x':True},{'file':'/etc/passwd'}]:
            with self.assertRaises(PolicyError):self.policy.submit(TOKEN,png(),geometry)

    def test_pair_uri_accepts_only_bounded_connect_token_and_label(self):
        self.assertEqual(parse_uri('lightengine-overlay://connect?token='+TOKEN+'&label=Mod%20Name'),(TOKEN,'Mod Name'))
        for uri in ['https://connect?token='+TOKEN,'lightengine-overlay://connect?token=short',
                    'lightengine-overlay://connect?token='+TOKEN+'&token='+OTHER,
                    'lightengine-overlay://connect?token='+TOKEN+'&label=%0Acontrol',
                    'lightengine-overlay://connect?token='+TOKEN+'&file=/etc/passwd']:
            with self.assertRaises(PolicyError):parse_uri(uri)

    def test_unsupported_platform_refuses_consent_and_image(self):
        policy=OverlayPolicy(self.events.append, unsupported='Wayland unsupported')
        with self.assertRaises(PolicyError) as error:policy.request_consent(TOKEN,'Fixture')
        self.assertEqual(error.exception.status,503)
    def test_released_sessions_free_slots_and_cannot_grant_late_pending_consent(self):
        for i in range(12):
            token=format(i+1,'064x');self.time+=4
            self.policy.request_consent(token,'Fixture');self.policy.finish_consent(token,True)
            self.policy.revoke(token)
            self.assertFalse(self.policy.authorized(token));self.assertEqual(len(self.policy.grants),0)
        self.time+=4;self.policy.request_consent(TOKEN,'Pending')
        self.policy.revoke(TOKEN)
        self.assertFalse(self.policy.finish_consent(TOKEN,True))
        self.assertTrue(self.policy.request_consent(TOKEN,'Dead script')['denied'])
    def test_release_of_other_grant_keeps_displayed_owner_and_generation(self):
        self.pair();self.policy.submit(TOKEN,png(),{});event=self.events[-1]
        self.policy.finish_image(event['revision'],True)
        self.time+=4;self.pair(OTHER);self.policy.revoke(OTHER)
        self.assertTrue(self.policy.current(TOKEN,event['revision']))
        self.assertFalse(self.policy.authorized(OTHER))

class DeadlineTests(unittest.TestCase):
    def test_slow_dripped_body_cannot_extend_absolute_three_second_deadline(self):
        receiving,sending=socket.socketpair();reader=DeadlineReader(receiving.makefile('rb'),receiving)
        def drip():
            try:
                for byte in b'{"x":0} ':time.sleep(.65);sending.send(bytes([byte]))
            except OSError:pass
        worker=threading.Thread(target=drip,daemon=True);worker.start();started=time.monotonic()
        try:
            with self.assertRaises(TimeoutError):reader.read(8)
            self.assertLess(time.monotonic()-started,3.7)
        finally:reader.close();receiving.close();sending.close();worker.join(1)

class HTTPTests(unittest.TestCase):
    def setUp(self):
        self.events=[];self.policy=OverlayPolicy(self.events.append)
        self.server=make_server(self.policy,port=0)
        self.thread=threading.Thread(target=self.server.serve_forever,daemon=True);self.thread.start()

    def tearDown(self):
        self.server.shutdown();self.server.server_close();self.thread.join(3)

    def request(self, method, path, body=None, headers=None):
        connection=http.client.HTTPConnection('127.0.0.1',self.server.server_port,timeout=3)
        try:
            connection.request(method,path,body=body,headers=headers or {})
            response=connection.getresponse();return response.status,json.loads(response.read())
        finally:connection.close()

    def test_loopback_auth_requires_grant_and_original_body_is_queued(self):
        self.assertEqual(self.server.server_address[0],'127.0.0.1')
        headers={'Authorization':'Bearer '+TOKEN,'Content-Type':'image/png'}
        self.assertEqual(self.request('POST','/image',png(),headers)[0],403)
        self.policy.request_consent(TOKEN,'Fixture');self.policy.finish_consent(TOKEN,True)
        status,result=self.request('POST','/image?x=-5&y=10&width=100',png(),headers)
        self.assertEqual(status,202);self.assertFalse(result['displayed'])
        self.assertEqual(self.events[-1]['bytes'],png())
        self.assertEqual(self.request('DELETE','/image',headers=headers)[0],202)

    def test_connect_is_pending_and_browser_origin_is_rejected(self):
        body=json.dumps({'token':TOKEN,'label':'Fixture'})
        status,result=self.request('POST','/connect',body,{'Content-Type':'application/json'})
        self.assertEqual(status,202);self.assertFalse(result['granted'])
        self.assertFalse(self.policy.authorized(TOKEN))
        self.assertEqual(self.request('POST','/connect',body,{'Origin':'https://example.com'})[0],403)

    def test_bad_length_duplicate_query_and_unauthenticated_delete(self):
        self.assertEqual(self.request('DELETE','/image')[0],403)
        self.policy.request_consent(TOKEN,'Fixture');self.policy.finish_consent(TOKEN,True)
        headers={'Authorization':'Bearer '+TOKEN}
        self.assertEqual(self.request('POST','/image?x=1&x=2',png(),headers)[0],400)
        self.assertEqual(self.request('POST','/image',b'bad',headers)[0],400)
        headers['Content-Length']=str(8*1024*1024+1)
        self.assertEqual(self.request('POST','/image',b'',headers)[0],413)
    def test_release_endpoint_cancels_pending_pair_without_accepting_unknown_token(self):
        self.policy.request_consent(TOKEN,'Pending')
        status,result=self.request('DELETE','/connect',headers={'Authorization':'Bearer '+TOKEN})
        self.assertEqual(status,202);self.assertTrue(result['revoked'])
        self.assertFalse(self.policy.finish_consent(TOKEN,True))
        self.assertEqual(self.request('DELETE','/connect',headers={'Authorization':'Bearer '+OTHER})[0],403)

if __name__=='__main__': unittest.main()
