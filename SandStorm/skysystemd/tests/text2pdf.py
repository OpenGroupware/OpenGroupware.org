#!/usr/bin/env python

# $Id: text2pdf.py,v 1.1.1.1 2003/07/09 22:57:27 cvs Exp $

import xmlrpclib

url = 'http://localhost:21030/system/xmlrpc'

server = xmlrpclib.ServerProxy(url)
result = server.system.pdf.text2pdf('SKYRiX - The Power Of Collaboration')
file = open('result.pdf','w+')
file.write(result.data)
file.close()
