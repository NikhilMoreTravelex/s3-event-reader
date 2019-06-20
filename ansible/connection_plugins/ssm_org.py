# Use AWS SSM session manager to connect to an instance
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

DOCUMENTATION = '''
---
connection: ssm
short_description: Connect via AWS SSM session manager
options:
  host:
    description:
      - Specifies the remote device FQDN or IP address to establish the HTTP(S)
        connection to.
    default: inventory_hostname
    vars:
      - name: ansible_host
  network_os:
    description:
      - Configures the device platform network operating system.  This value is
        used to load the correct SSM document to communicate with the remote host 
    vars:
      - name: ansible_network_os
  remote_user:
    description:
      - The username used to authenticate to the remote device when the API
        connection is first established.  If the remote_user is not specified,
        the connection will use the username of the logged in user.
      - Can be configured from the CLI via the C(--user) or C(-u) options.
    ini:
      - section: defaults
        key: remote_user
    env:
      - name: ANSIBLE_REMOTE_USER
    vars:
      - name: ansible_user
  password:
    description:
      - Configures the user password used to authenticate to the remote device
        when needed for the device API.
    vars:
      - name: ansible_password
  timeout:
    type: int
    description:
      - Sets the connection time, in seconds, for communicating with the
        remote device.  This timeout is used as the default timeout value for
        commands when issuing a command to the network CLI.  If the command
        does not return in timeout seconds, an error is generated.
    default: 120
  become:
    type: boolean
    description:
      - The become option will instruct the CLI session to attempt privilege
        escalation on platforms that support it.  Normally this means
        transitioning from user mode to C(enable) mode in the CLI session.
        If become is set to True and the remote device does not support
        privilege escalation or the privilege has already been elevated, then
        this option is silently ignored.
      - Can be configured from the CLI via the C(--become) or C(-b) options.
    default: False
    ini:
      - section: privilege_escalation
        key: become
    env:
      - name: ANSIBLE_BECOME
    vars:
      - name: ansible_become
  become_method:
    description:
      - This option allows the become method to be specified in for handling
        privilege escalation.  Typically the become_method value is set to
        C(enable) but could be defined as other values.
    default: sudo
    ini:
      - section: privilege_escalation
        key: become_method
    env:
      - name: ANSIBLE_BECOME_METHOD
    vars:
      - name: ansible_become_method
  persistent_connect_timeout:
    type: int
    description:
      - Configures, in seconds, the amount of time to wait when trying to
        initially establish a persistent connection.  If this value expires
        before the connection to the remote device is completed, the connection
        will fail.
    default: 60
    ini:
      - section: persistent_connection
        key: connect_timeout
    env:
      - name: ANSIBLE_PERSISTENT_CONNECT_TIMEOUT
  persistent_command_timeout:
    type: int
    description:
      - Configures, in seconds, the amount of time to wait for a command to
        return from the remote device.  If this timer is exceeded before the
        command returns, the connection plugin will raise an exception and
        close.
    default: 60
    ini:
      - section: persistent_connection
        key: command_timeout
    env:
      - name: ANSIBLE_PERSISTENT_COMMAND_TIMEOUT
    vars:
      - name: ansible_command_timeout
'''

from ansible.plugins.connection import ConnectionBase

import boto3
import pyte
import json
import base64
import zipfile
from io import StringIO
import re
import uuid
import textwrap

class Connection(ConnectionBase):
    transport = 'ssm'
    module_implementation_preferences = ('.ps1', '.exe', '')
    become_methods = ['runas']
    allow_executable = False
    has_pipelining = True
    allow_extras = True

    def __init__(self, play_context, *args, **kwargs):
        # nicked from winrm plugin
        #self.always_pipeline_modules = True
        self.has_native_async = True

        self.protocol = None
        self.shell_id = None
        self.delegate = None
        self._shell_type = 'powershell'

        self._websocket = None
        self._screen = RipScreen(256, 128)
        self._stream = pyte.Stream(self._screen)
        self._connected = False
        super(Connection, self).__init__(play_context, *args, **kwargs)

    def _connect(self):
        self._websocket = SSMSocket(self.get_option('host'), self._screen.columns, self._screen.lines)
        self._websocket.connect(timeout=self.get_option('persistent_connect_timeout'))
        self._websocket.send_ssm('Remove-Module -Name PSReadLine\r\n')
        self._connected = True
        super(Connection, self)._connect()

    def exec_command(self, cmd, in_data=None, sudoable=False):
        """Run a command on the remote host"""
        #return super(Connection, self).exec_command(cmd, in_data=in_data, sudoable=sudoable)
        if not self._connected:
            self._connect()
        self._display.vvvv("RUNNING `%s`" % cmd)
        cmd_uuid = uuid.uuid4()
        # NB. needs two crlf if cmd has a multi-line string in it
        self._websocket.send_ssm('Write-Output ("--%s--" + "START--"); %s; Write-Output ("--%s--" + "EXIT--${LASTEXITCODE}--")\r\n\r\n' % (cmd_uuid, cmd, cmd_uuid))

        self._screen.reset()
        exit_line = '--%s--EXIT--' % cmd_uuid
        while exit_line not in '\n'.join(self._screen.display):
            # TODO make this behave more like expect
            ssm_data = self._websocket.recv_ssm(timeout=self.get_option('persistent_command_timeout'))
            self._stream.feed(ssm_data['data'].decode('utf8'))
        #print(repr(self._websocket._recv_buffer))
        raw_output = self._screen.getripped()
        output = raw_output.split('--%s--START--' % cmd_uuid)[-1].split('--%s--EXIT--' % cmd_uuid)[0]
        self._display.vvvv("---- whole screen ----\n%s\n---- parsed output ----\n%s\n---- end ----" % (raw_output, output))

        status = int(raw_output.split('--%s--EXIT--' % cmd_uuid)[-1].split('--')[0])

        self._display.vvvv("Command output (%d):\n%s" % (status, output))
        # TODO stderr
        return (status, output, StringIO())

    def put_file(self, in_path, out_path):
        # TODO make compatible with Linux
        out_path = out_path.replace('\'', '')
        with zipfile.ZipFile(in_path + '.zip', 'w', zipfile.ZIP_DEFLATED) as ZIP:
            ZIP.write(in_path, out_path.split('\\')[-1])
        with open(in_path + '.zip', 'rb') as IN:
            e = self.exec_command("[System.Convert]::FromBase64String('%s') | Set-Content '%s.zip' -Encoding Byte; Expand-Archive -LiteralPath '%s.zip' -DestinationPath '%s'" % ('\r\n'.join(textwrap.wrap(base64.b64encode(IN.read()).decode('ascii'), self._screen.columns)), out_path, out_path, out_path.rsplit('\\', 1)[0]))

    def fetch_file(self, in_path, out_path):
        # TODO also win-specific
        e = self.exec_command("[Convert]::ToBase64String([IO.File]::ReadAllBytes('%s'))" % in_path.replace("'", "\\'"))[1]
        with open(out_path, 'wb') as OUT:
            OUT.write(base64.b64decode(e))

    def close(self):
        if self._websocket:
            try:
                self._websocket.send_ssm('exit\r\n')
            finally:
                self._websocket.close()
            self._websocket = None
        self._connected = False
        super(Connection, self).close()


# raw w/s format...
# ACK # 295+ bytes
# -- t --|------------------------
# 00000074000000000000000000000000 ...t............
# ----------- type ---------------
# 00000000000000000061636b6e6f776c .........acknowl
# -------|-- 1 --|-- 0 --|- ms --|
# 6564676500000001000000000eb0c53e edge...........>
# ----- seq -----|------ 0 ------|
# 000000000000001f0000000000000000 ................
# -- uuid_lsb ---|-- uuid_msb ---|
# ee028e703a0d44beae7cb868881b4251 ...p:.D..|.h..BQ
# |---------- sha256 -------------
# 39313462363432393061626131643866 914b64290aba1d8f
# -------------------------------|
# 39653533383239386662363763643234 9e538298fb67cd24
# -- 1 --|- len -|---- data ----->
# 00000001000000b17b2241636b6e6f77 ........{"Acknow
# 6c65646765644d657373616765547970 ledgedMessageTyp
# 65223a226f75747075745f7374726561 e":"output_strea
# 6d5f64617461222c2241636b6e6f776c m_data","Acknowl
# 65646765644d6573736167654964223a edgedMessageId":
# 2234303538623432352d666336662d34 "4058b425-fc6f-4
# 6664352d626334352d36386262643136 fd5-bc45-68bbd16
# 3666336361222c2241636b6e6f776c65 6f3ca","Acknowle
# 646765644d6573736167655365717565 dgedMessageSeque
# 6e63654e756d626572223a33312c2249 nceNumber":31,"I
# 7353657175656e7469616c4d65737361 sSequentialMessa
# 6765223a747275657d               ge":true}

# {"AcknowledgedMessageType":"output_stream_data","AcknowledgedMessageId": "4058b425-fc6f-4fd5-bc45-68bbd166f3ca","AcknowledgedMessageSequenceNumber":31,"IsSequentialMessage":true}


# SEND
# 00000074000000000000000000000000 ...t............
# 000000696e7075745f73747265616d5f ...input_stream_
# 6461746100000001000000000eb1bc07 data............
# 000000000000001b0000000000000000 ................
# ba46fd680aca41c7a5b6c883d94383af .F.h..A......C..
# 31343864653963356137613434643139 148de9c5a7a44d19
# 65353663643961653161353534626636 e56cd9ae1a554bf6
# 000000010000000170               ........p

# STARTPUB # 133 bytes
# 0000007073746172745f7075626c6963 ...pstart_public
# 6174696f6e0000000000000000000000 ation...........
# 00000000000000010000016814de06dd .......1...h....
# 00000000000000010000000000000003 .......1.......3
# bdf9403bd93577d2ef277d72cdb3446e uuid
# e3b0c44298fc1c149afbf4c8996fb924 sha
# 27ae41e4649b934ca495991b7852b855 sha
# 0000001173746172745f7075626c6963 ....start_public
# 6174696f6e                       ation

# PAUSEPUB # 260 bytes
# 0000007070617573655f7075626c6963 ...ppause_public
# 6174696f6e0000000000000000000000 ation...........
# 00000000000000010000016814de067e .......1..1h...~
# 00000000000000010000000000000003 .......1.......3
# bc1cd6d2b9c7b86917f480e06be64e3e uuid
# 323348286ce3ff9b5853a0eb8231e439 sha
# 68df9683e1aa87c839631d8e8dce732f sha
# 000000907b224d657373616765547970 ....{"MessageTyp
# 65223a2270617573655f7075626c6963 e":"pause_public
# 6174696f6e222c22536368656d615665 ation","SchemaVe
# 7273696f6e223a312c224d6573736167 rsion":1,"Messag
# 654964223a2231376634383065302d36 eId":"17f480e0-6
# 6265362d346533652d626331632d6436 be6-4e3e-bc1c-d6
# 64326239633762383639222c22437265 d2b9c7b869","Cre
# 61746544617461223a22323031392d30 ateData":"2019-0
# 312d30335431373a35383a34312e3533 1-03T17:58:41.53
# 345a227d                         4Z"}

# TIMEOUT FROM SERVER
# 000000706368616e6e656c5f636c6f73 ...pchannel_clos
# 65640000000000000000000000000000 ed..............
# 000000000000000100000168195ca08a ...........h.\..
# 00000000000000010000000000000003 ................
# bf142405a987ef460b79ffe153da4d87 ..$....F.y..S.M.
# f56e3e40c77192693291a346731841e3 .n>@.q.i2..Fs.A.
# 6ec49574cde62e82ac32275113bfdf25 n..t.....2'Q...%
# 0000013d7b224d657373616765496422 ...={"MessageId"
# 3a2230623739666665312d353364612d :"0b79ffe1-53da-
# 346438372d626631342d323430356139 4d87-bf14-2405a9
# 383765663436222c2243726561746564 87ef46","Created
# 44617465223a22323031392d30312d30 Date":"2019-01-0
# 345431343a35353a32372e3337305a22 4T14:55:27.370Z"
# 2c2244657374696e6174696f6e496422 ,"DestinationId"
# 3a2235643535653136332d656435332d :"5d55e163-ed53-
# 346562302d383964382d376265356134 4eb0-89d8-7be5a4
# 646537646634222c2253657373696f6e de7df4","Session
# 4964223a2263687269732e776573742d Id":"chris.west-
# 30396130623435373962653763366437 09a0b4579be7c6d7
# 63222c224d6573736167655479706522 c","MessageType"
# 3a226368616e6e656c5f636c6f736564 :"channel_closed
# 222c22536368656d6156657273696f6e ","SchemaVersion
# 223a312c224f7574707574223a22596f ":1,"Output":"Yo
# 75722073657373696f6e2074696d6564 ur session timed
# 206f75742064756520746f20696e6163  out due to inac
# 74697669747920616e64206861732062 tivity and has b
# 65656e207465726d696e617465642e22 een terminated."
# 7d                               }


# INPUT W/ TERMINAL SIZE
# 00000074000000000000000000000000 ...t............
# 000000696e7075745f73747265616d5f ...input_stream_
# 6461746100000001000000001a12e310 data............
# 00000000000000010000000000000000 ................
# 708e379310384caf822331ac3a1b4d51 p.7..8L..#1.:.MQ
# 37353035333435613963666337303036 7505345a9cfc7006
# 36643538383531666439633933643434 6d58851fd9c93d44
# 00000003000000167b22636f6c73223a ........{"cols":
# 3130362c22726f7773223a35307d     106,"rows":50}


# SEQUENCE
# ^ auth
# v 133 byte  start_publication
# ^ output {rows, cols} # 1
# v ack 1
# v 311 byte something ??? # 2
# ^ ack 2
# v 311 byte something ??? # 3
# ^ ack 3

# FIELDS
# t: 4 bytes; header length
# type: 32 bytes; input_stream_data, output_stream_data, acknowledge
#       (strip nulls and spaces)
# 1: 4 bytes; always "1", may be major version number?
# 0: 4 bytes; 0 or 360, may be minor version number?
# ms: 4 bytes; integer time in ms since ???; set by the client and tracked by
#     the server???
# seq: 8 bytes; integer sequence number (increment from 0, ACK messages have
#      sequence numbers that match the message they're acknowledging)
# 0: 8 bytes; 0 for {in,out}put_stream_data; acknowledge
#             3 for {start,pause}_publication; channel_closed
# uuid_lsb: 8 bytes; second half of the message uuid
# uuid_msb: 8 bytes; first half of the message uuid (why are they back-to-front?!?!)
# sha256: 32 bytes; sha256(PAYLOAD.encode()).hexdigest()[:32]
# 1: 4 bytes; "1" for {in,out}put_stream, may be "IsSequentialMessage": true ?
#             "3" for sending rows/cols info
#             missing if {start,pause}_publication
# len: 4 bytes; length of payload
# data: N bytes; payload (utf-8 ?)

import websocket
import struct
import datetime
import hashlib
import time
import uuid
import json
import threading
class SSMSocket(websocket.WebSocketApp):
    """provide a high-ish level interface around an SSM session manager websocket"""
    MAJOR_VERSION = 1
    MINOR_VERSION = 0
    RECV_TIMEOUT = 30
    RECV_POLL = 0.2
    PING_INTERVAL = 180

    def __init__(self, host, cols=80, rows=24):
        self._ssm = boto3.client('ssm')
        self._ssm_session = self._ssm.start_session(Target=host)
        super(SSMSocket, self).__init__(
                self._ssm_session['StreamUrl'],
                on_message=self.recv
                )
        self._seq = 0
        self._app_thread = None
        self._start = datetime.datetime.utcnow()
        self._start_offset = 0
        self._recv_buffer = {}
        self._recv_queues = {}
        self._pty_cols = cols
        self._pty_rows = rows
 
    def connect(self, timeout=None):
        self._recv_default_timeout = timeout or self.RECV_TIMEOUT
        self._app_thread = threading.Thread(target=self.run_forever)
        self._app_thread.start()
        time.sleep(0.5)  # TODO don't fix race conditions with sleep()
        self._send_auth()
        self._send_size(self._pty_cols, self._pty_rows)

    def close(self):
        try:
            super(SSMSocket, self).close()
            if self._app_thread:
                self._app_thread.join()
        finally:
            if self._ssm_session:
                self._ssm.terminate_session(SessionId=self._ssm_session['SessionId'])
                self._ssm_session = None

    def _send_auth(self):
        message_id = uuid.uuid4()
        #print("SEND AUTH (%s)" % (message_id))
        data = {
                'MessageSchemaVersion': '%d.%d' % (self.MAJOR_VERSION, self.MINOR_VERSION),
                'RequestId': str(message_id),
                'TokenValue': self._ssm_session['TokenValue'],
                }
        self.send(json.dumps(data, separators=(',', ':')))

    def _send_size(self, cols=80, rows=24):
        data = {
            'cols': cols,
            'rows': rows,
            }
        # yes, this uses the same input_stream_data protocol that normal input
        # does (it's possible that is_sequential is some kind of type field)
        self.send_ssm(json.dumps(data, separators=(',', ':')), is_sequential=3)

    def _send_ping(self):
        self.send('__ping__')  # NB. text, not binary

    def _send_ack(self, message_id, message_type='output_stream_data', seq=None, is_sequential=1):
        #print(_send_ack, self._app_thread.is_alive())
        print("_send_ack %s" % message_id)
        if seq is None:
            seq = self._seq
        data = {
               'AcknowledgedMessageType': message_type.strip(),
               'AcknowledgedMessageId': str(message_id),
               'AcknowledgedMessageSequenceNumber': seq,
               'IsSequentialMessage': bool(is_sequential)
               }
        self._send_ssm(json.dumps(data, separators=(',', ':')).encode('utf8'), 'acknowledge', message_id, seq, is_sequential)

    def send_ssm(self, data, message_type='input_stream_data', is_sequential=1):
        """send some SSM data"""
        data_utf8 = data.encode('utf8')
        message_id = uuid.uuid4()
        try:
            print('send_ssm', message_id)
            print('send_ssm', self._app_thread.is_alive())
            print('send_ssm', self._app_thread.is_alive())
            self._send_ssm(data_utf8, message_type, message_id, self._seq, is_sequential)
            time.sleep(0.5)
            print('after _send_ssm return')
        finally:
            self._seq += 1

        if message_type in ('input_stream_data',):
            print('send_ssm b4 calling rec_ssm',message_id,message_type)
            self.recv_ssm('acknowledge', message_id)
            print('send_ssm after calling recv_ssm', message_id,message_type)
       
        return len(data)

    def _send_ssm(self, data_utf8, message_type, message_id, seq, is_sequential):
        print("SEND %s (%s)" % (message_type, message_id))
        payload_header = struct.pack(
            '! I 32s I I I Q Q 8s 8s 32s I I',
            116,
            message_type.encode('utf8').rjust(32, b'\0'), # 32 bytes of message type
            self.MAJOR_VERSION,
            self.MINOR_VERSION,
            int((datetime.datetime.utcnow() - self._start).total_seconds()*1000 + self._start_offset),
            seq,
            0,
            message_id.bytes[8:],
            message_id.bytes[:8],
            hashlib.sha256(data_utf8).hexdigest()[:32].encode('utf8'),
            is_sequential,
            len(data_utf8)
            )
        print("%s" % (payload_header+data_utf8))
        #print('_send_ssm', message_id, self._app_thread.is_alive(),payload_header)
        return self.send(payload_header + data_utf8, websocket.ABNF.OPCODE_BINARY)

    def recv(self, data):
        """called on receipt of a message from socket"""
        payload_header = struct.unpack_from('! I 32s I I I Q Q Q Q 32s I I', data)
        recv_message_id = uuid.UUID(int=(payload_header[8] << 64) + payload_header[7])
        recv_message_type = payload_header[1].decode('utf8').strip()
        print("RECV %s (%s)" % (payload_header[1].decode('utf8'), recv_message_id))
        print(payload_header)
        print(data)
        #print('recv', self_app.thread.is_alive())
        if self._start_offset == 0:
            # sync our clock with the remote
            self._start_offset = payload_header[4]

        if recv_message_id in self._recv_buffer:
            # this is a duplicate; ignore (?!)
            pass
        else:
            self._recv_buffer[recv_message_id] = {
                    'raw': data,
                    'len': len(data),
                    'header': payload_header,
                    'data': data[payload_header[0]+4:]
                    }
            if not recv_message_type in self._recv_queues:
                self._recv_queues[recv_message_type] = []
            self._recv_queues[recv_message_type].append(recv_message_id)

        if recv_message_type in ('output_stream_data',):
            self._send_ack(recv_message_id, recv_message_type, payload_header[5], payload_header[11])

    def recv_ssm(self, message_type='output_stream_data', message_id=None, timeout=None):
        """wait for a particular message to come back, or the next of a given type"""
        # TODO this should be a generator
        attempts = 0.0
        while attempts < (timeout or self._recv_default_timeout):
            if message_id in self._recv_buffer:
                #self._display.vvvv(message_id)
                print(message_id)
                print('recv_ssm ', self._app_thread.is_alive())
                return self._recv_buffer[message_id]
            elif message_type in self._recv_queues and len(self._recv_queues[message_type]) > 0:
                #self._display.vvvv(message_id)
                print(message_id)
                return self._recv_buffer[self._recv_queues[message_type].pop(0)]
            time.sleep(self.RECV_POLL)
            attempts += self.RECV_POLL
            if attempts % self.PING_INTERVAL < 0.001:
                self._send_ping()
        print(self._recv_buffer)
        print(self._recv_queues)
        raise websocket.WebSocketException("No SSM message (%s/%s) in %ds" % (message_type, message_id, timeout or self._recv_default_timeout))


class RipScreen(pyte.Screen):
    def __init__(self, columns, lines):
        self.ripped = None  # super.__init__() calls reset() anyway
        super(RipScreen, self).__init__(columns, lines)

    def reset(self):
        super(RipScreen, self).reset()
        self.ripped = StringIO()

    def linefeed(self):
        # https://github.com/selectel/pyte/blob/master/pyte/screens.py#L491
        self.ripped.write(self.display[self.cursor.y].rstrip())
        if self.display[self.cursor.y][-1] == self.default_char.data:
            # assume if the last char on the line is an empty terminal char, we
            # should insert a crlf (this is a terrible assumption)
            self.ripped.write('\n')

        super(RipScreen, self).linefeed()

    def getripped(self):
        return self.ripped.getvalue() + self.display[self.cursor.y].rstrip()
