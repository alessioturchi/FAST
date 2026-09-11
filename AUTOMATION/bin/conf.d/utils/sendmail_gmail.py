#!/usr/bin/python3

import sys,os,traceback
import time
from os.path import basename
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import COMMASPACE, formatdate

from googleapiclient.discovery import build
from google.auth.transport.requests import Request
import pickle
import base64

SCOPES = ['https://mail.google.com/']


HOMEPATH=os.path.expanduser('~')
CLIENT_SECRET_FILE = HOMEPATH+'/automation_python3/credentials.json'
TOKEN=HOMEPATH+'/automation_python3/token.pickle'
APPLICATION_NAME = 'Gmail API Automation'
SERVICE = None

FROM_MAIL='XXXXX@YYYY.it'

def get_credentials():
    creds = None
    if os.path.exists(TOKEN):
        with open(TOKEN, 'rb') as token:
            creds = pickle.load(token)
    else:
        print('ERROR: cannot find credentials: '+TOKEN)
        sys.exit(0)
    if creds.expired and creds.refresh_token:
        try:
            creds.refresh(Request())
        except:
            print('ERROR: cannot refresh credentials: '+TOKEN)
            sys.exit(0)

    return creds

def write_error(errormessage):
    try:
        out_file = open("error.out","a")
        out_file.write(errormessage+'\n')
        out_file.close()
    except:
        [timestamp_sys,date_string]=get_timestamp_date()
        print("!!!Error in writing error file on "+date_string)
        print(sys.exc_info())

def get_timestamp_date():
    timestamp_sys = int(time.time())
    time_date = time.gmtime(timestamp_sys)
    date_string = str(time_date[0])+'/'+str(time_date[1])+'/'+str(time_date[2])+'-'+str(time_date[3])+':'+str(time_date[4])+':'+str(time_date[5])
    return timestamp_sys,date_string

def send_email(subject_msg,string_msg,fromaddr,toaddrs,files=None):
    assert isinstance(toaddrs, list)
    if files is not None:
        assert isinstance(files, list)
    send_ok=0
    try:
        creds = get_credentials()
        service = build('gmail', 'v1', credentials=creds)

        [timestamp_sys,date_string]=get_timestamp_date()
        msg = MIMEMultipart()
        msg.attach(MIMEText(string_msg))
        msg['From'] = fromaddr
        msg['To'] = COMMASPACE.join(toaddrs)
        msg['Date'] = formatdate(localtime=True)
        msg['Subject'] = subject_msg

        for f in files or []:
            with open(f, "rb") as fil:
                part = MIMEApplication(
                    fil.read(),
                    Name=basename(f)
                )
            # After the file is closed
            part['Content-Disposition'] = 'attachment; filename="%s"' % basename(f)
            msg.attach(part)
        base64msg={'raw': base64.urlsafe_b64encode(msg.as_string().encode('utf-8')).decode('utf-8')}
        mess = (service.users().messages().send( userId='me', body=base64msg).execute())
        labels = mess.get('labels', [])
        if labels:
            print('Labels:')
            for label in labels:
                print(label['name'])
        send_ok=1
    except:
        [timestamp_sys,date_string]=get_timestamp_date()
        errormessage='!!!ERROR: error sending email on '+date_string
        print(errormessage)
#        write_error(errormessage)
        print(sys.exc_info())
#        write_error(str(sys.exc_info()))
    return send_ok


def main():
    subject_msg=str(sys.argv[1])
    string_msg=str(sys.argv[2])
    fromaddr=str(sys.argv[3])
#overwrite since other fields will not work
    fromaddr=FROM_MAIL
    toaddrs=[ str(sys.argv[4]) ]
    if (len(sys.argv) > 5):
        files=sys.argv[5:]
    else:
        files=None
    send_email(subject_msg,string_msg,fromaddr,toaddrs, files)

if __name__ == '__main__':
    try:
        main()
    except:
        [timestamp_sys,date_string]=get_timestamp_date()
        string_msg=traceback.format_exc()
        print(string_msg)
