#!/bin/env python
# $Id: http.py,v 1.1 2003/08/19 12:01:36 helge Exp $

from httplib import *
from base64  import *
import os;

user = 'donald';
pwd  = 'duck';

authText   = user + ':' + pwd;
authText   = encodestring(authText);
al         = len(authText);
if authText[al - 1] == '\12':
    authText = authText[0:-1];
authHeader = 'Basic ' + authText;

print "got " + authText;

def http_get():
    h = HTTP('ogo', 15053);
    h.putrequest('GET', '/test_jan.gif');
    h.putheader('Accept', '*/*');
    h.putheader('Authorization', authHeader);
                      
    h.endheaders();
    errcode, errmsg, headers = h.getreply();
    print errcode;
    print errmsg;
    print headers;
    
    f = h.getfile();
    data = f.read();
    f.close();

def http_put():
    f = open('/LOCAL/home/jan/tmp/test.jpg', 'r');
    data = f.read();
    lenStr = str(len(data));
    print lenStr;
    h = HTTP('ogo', 15053);
#    h.set_debuglevel(10);
    h.putrequest('PUT', '/test__put.jpg');
    h.putheader('Authorization', authHeader);
#    h.putheader('content-type', "image/jpg");
    h.putheader('content-length', lenStr);
    h.endheaders();
    
    h.send(data);

    errcode, errmsg, headers = h.getreply();
    print errcode;
    print errmsg;
    print headers;
    
def http_head():
    h = HTTP('ogo', 15053);
    h.putrequest('HEAD', '/test_jan.gif');
    h.putheader('Accept', '*/*');
    h.putheader('Authorization', authHeader);
                      
    h.endheaders();
    errcode, errmsg, headers = h.getreply();
    print errcode;
    print errmsg;
    print headers;
    

http_head();
