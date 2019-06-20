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
    default: 30
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
    default: 10
    ini:
      - section: persistent_connection
        key: command_timeout
    env:
      - name: ANSIBLE_PERSISTENT_COMMAND_TIMEOUT
    vars:
      - name: ansible_command_timeout
  s3_bucket:
    description: S3 bucket name for storing SSM stdout/stderr
    env:
      - name: ANSIBLE_SSM_S3_BUCKET
    vars:
      - name: ansible_ssm_s3_bucket
  s3_bucket_prefix:
    description: Optional prefix for SSM command outputs
    default: ansible-ssm
    env:
      - name: ANSIBLE_SSM_S3_BUCKET_PREFIX
    vars:
      - name: ansible_ssm_s3_bucket_prefix
'''

from ansible.plugins.connection import ConnectionBase, NetworkConnectionBase

import boto3
import time
import base64
import zipfile

class Connection(NetworkConnectionBase):
    transport = 'ssm'
    module_implementation_preferences = ('.ps1', '.exe', '')
    become_methods = ['runas']
    allow_executable = False
    has_pipelining = True
    allow_extras = True

    def __init__(self, play_context, new_stdin, *args, **kwargs):
        # nicked from winrm plugin
        #self.always_pipeline_modules = True
        self.has_native_async = True

        self.protocol = None
        self.shell_id = None
        self.delegate = None
        self._shell_type = 'powershell'

        self._ssm = boto3.client('ssm')
        self._s3 = boto3.client('s3')
        self._poll_interval = 1
        # TODO: if it's a Win host, run PowerShell, otherwise Shell
        self._document = 'AWS-RunPowerShellScript'
        super(Connection, self).__init__(play_context, new_stdin, *args, **kwargs)

    def exec_command(self, cmd, in_data=None, sudoable=False):
        """Run a command on the remote host"""
        #return super(Connection, self).exec_command(cmd, in_data=in_data, sudoable=sudoable)
        self._display.vvvv("RUNNING `%s`" % cmd)
        self._s3_bucket = self.get_option('s3_bucket')
        self._s3_bucket_prefix = self.get_option('s3_bucket_prefix')

        resp = self._ssm.send_command(InstanceIds=[self.get_option('host')],
                DocumentName=self._document,
                Parameters={'commands': [cmd]},
                OutputS3BucketName=self._s3_bucket,
                OutputS3KeyPrefix=self._s3_bucket_prefix,
                )['Command']
        while True:
            time.sleep(self._poll_interval)
            status = self._ssm.list_command_invocations(CommandId=resp['CommandId'], Details=True)['CommandInvocations'][0]
            if status['Status'] in ('Success', 'Failed'):
                break
        self._display.vvvv("Command exit with %s" % status['Status'])
        run_result = status['CommandPlugins'][0]

        self._display.vvvv("Command output:\n%s" % run_result['Output'])
        return (run_result['ResponseCode'], self._s3_url_to_output(run_result['StandardOutputUrl']), self._s3_url_to_output(run_result['StandardErrorUrl']))

    def put_file(self, in_path, out_path):
        # TODO make compatible with Linux
        # TODO support files > 64kb compressed
        out_path = out_path.replace('\'', '')
        with zipfile.ZipFile(in_path + '.zip', 'w', zipfile.ZIP_DEFLATED) as ZIP:
            ZIP.write(in_path, out_path.split('\\')[-1])
        with open(in_path + '.zip', 'rb') as IN:
            e = self.exec_command("[System.Convert]::FromBase64String('%s') | Set-Content '%s.zip' -Encoding Byte; Expand-Archive -LiteralPath '%s.zip' -DestinationPath '%s'" % (base64.b64encode(IN.read()).decode('ascii'), out_path, out_path, out_path.rsplit('\\', 1)[0]))

    def close(self):
        self._ssm.terminate_session(self._session_data['SessionId'])
        super(Connection, self).close()

    def _s3_url_to_output(self, url):
        bucket, key = url.split('/', 4)[3:5]
        try:
            out = self._s3.get_object(Bucket=bucket, Key=key)['Body'].read()
        except self._s3.exceptions.NoSuchKey:
            out = ''
        return out

