#!/usr/bin/env python

import sys, string, StringIO, os, mimetools, xmlrpclib, syslog, base64
import SocketServer, BaseHTTPServer, getopt, multifile, re

# TODO:
# - put all the functions into an application class (easier handling)

class Mail:
    """ generic email class, used for all mails who don't match one
        of the subclasses """

    def __init__(self, mail):
        self.mail = mail;
        self.body = mail;
        self.extension  = '.mail'
        self.attributes = {}
        self.message = mimetools.Message(StringIO.StringIO(mail))
        subject = self.message.getheader('subject')
        self.attributes['NSFileSubject']       = rehashSubject(subject)

        # To is not always set (e.g. newsgroup posting inside emails)
        to = self.message.getheader('to')
        if to != None:
          self.attributes['To']                = to

        self.attributes['From']                = self.message.getheader('from')
        self.attributes['Source-Content-Type'] = self.message.gettype()
        self.attributes['Message-ID']          = self.message.getheader(
                                                 'message-id')
        self.attributes['Received-Date']       = self.message.getheader('date')
        self.attributes['mailclass']           = 'mail'

class TextMail(Mail):
    """ normal text mail """

    def __init__(self,mail,body):
        Mail.__init__(self,mail)
        self.body = body
        self.extension = ''
        self.attributes['mailclass'] = 'textmail'

def rehashSubject(subject):
    """ remove the square brackets and 'Fwd:' comments from the subject """

    print '[-] rehashing subject'

    # Mozilla forward comments
    if subject[0] == '[' and subject[-1] == ']':
      try:
        subject=subject[string.find(subject,':')+2:-1]
        return subject
      except IndexError:
        return subject

    # forward comments created by mutt
    elif string.find(subject,'(fwd)') == 0:
        return subject[4:]

    else:
      return subject

def createFilename(subject):
    """ create filename by shortening the topic and removing special chars """

    print '[-] creating filename'
    subject = rehashSubject(subject)[0:15]
    for char in [' ','/','\\','.',':','\'','?','!',',']:
      subject = string.replace(subject,char,'_')
    return string.replace(subject,'"','')

def createFilePath(subject):
    """ create sub file path by shortening the topic and removing special chars """

    print '[-] creating filename'
    subject = rehashSubject(subject)
    for char in [' ','\\',':','\'','?','!',',']:
      subject = string.replace(subject,char,'_')
    return string.replace(subject,'"','')

def createFileDir(subject):
    """ create sub file directory by shortening the topic and removing special chars """

    print '[-] creating filedir'
    subject = rehashSubject(subject)
    for char in [' ','\\',':','\'','?','!',',']:
      subject = string.replace(subject,char,'_')
    subject = string.replace(subject,'"','')
    dir = ''
    for element in string.split(subject,'/')[0:-1]:
        dir = os.path.join(dir,element)
    dir = '/'+dir
    return dir

def createMappingList(server,project,debug):
    """ parse the mapping list from the project """

    print '[-] creating mapping list'

    fileName = '/logaliases.txt'
    mapping = {}

    if server.exists(project,[fileName,]).value == 0:
      print '[!] mapping file does not exist !'
      raise "MappingFileNotFoundException",77

    print '[-] loading mapping file'
    mappingFile = server.loadDocument(project,fileName).data

    for line in string.split(mappingFile,'\n'):
        elements = string.split(string.split(line,'#')[0],'=')
        if line[:1] != '#' and len(line) != 1 and len(elements) == 2:
            mapping[string.strip(elements[0])] = string.strip(elements[1])
    return mapping

def extract_mime_part_matching(stream, mimetype):
    """ extract the first <mimetype> part found in <stream> """

    print '[+] get matching mimepart for %s' % mimetype
    msg = mimetools.Message(stream)
    msgtype = msg.gettype()
    params = msg.getplist()

    data = StringIO.StringIO()
    if msgtype[:10] == "multipart/":

        file = multifile.MultiFile(stream)
        file.push(msg.getparam("boundary"))
        while file.next():
            submsg = mimetools.Message(file)
            try:
                data = StringIO.StringIO()
                mimetools.decode(file, data, submsg.getencoding())
            except ValueError:
                continue
            if submsg.gettype() == mimetype:
                file.pop()
                return data.getvalue()
        file.pop()
        return None
    return data.getvalue()

def getMailForContentType(ctype,mail):
    """ get mail object depending on the mail type """

    print '[+] get mail for content type %s' % ctype

    ioMail = StringIO.StringIO(mail)

    # plain text messages
    if ctype == 'text/plain':

        # no mimeparsing needed, the mail is the part we want
        part = mail
        
        # split the headers
        elements = string.split(part,'\n\n')
        part = string.join(elements[1:],'\n\n')

        # split the signature
        part = string.split(part,'-- \n')[0]

        # check what type of text this is (could be either a
        # single URL or some text
        part = string.strip(part)
        if not '\n' in part:
            if string.find(part,'http://') != -1:
                return URLMail(mail, part)
        return TextMail(mail, part)

    # all the other weird formats out there
    else:
        return Mail(mail)

def getMappingForElement(element,mapping):
    """ get the mapping for the selected target address """

    print '[+] get mapping for element %s' % element
    elements = string.split(element,'+')
   
    if not mapping.has_key(elements[0]):
        return None
    
    if len(elements) == 1:
        return mapping[elements[0]]
    return os.path.join(mapping[elements[0]],elements[1])

def main(mail,server,project):
    """ main function """

    print '[+] entering main loop'
    mailIO = StringIO.StringIO(mail)
    message = mimetools.Message(mailIO)

    print '[+] getting TO address'
    mailTo  = message.getheader('to')

    if mailTo == None:
        print '[!] no mailheader "TO" set'
        raise "TargetAddressNotNotFoundException",77        

    if '<' in mailTo:
        mailTo = string.split(mailTo,'<')[1][:-1]

    print '[+] getting subject'
    mailSubject = message.getheader('subject').encode('iso-8859-1')

    if mailSubject == None:
        print '[!] no mailheader "SUBJECT" set'
        raise "SubjectNotNotFoundException",77                
  
    mailPath = createFilePath(mailSubject)

    if debug == 1:
        print '[+] mail subject : %s' % mailSubject
        print '[+] mail to      : %s' % mailTo

    mapping = createMappingList(server,project, debug)
    path = getMappingForElement(string.split(mailTo,"@")[0],mapping)

    if debug == 1:
        print '[+] mail path    : %s' % path

    if path == None:
        syslog.syslog('%s: ERROR(%d): no mapping for %s' % (
                      sys.argv[0],67,mailTo))

        if debug == 1:
            print '[!] No mapping for user found !'
        sys.exit(67)

    print '[-] checking if dir exists'
    currentPath = ''
    for element in string.split(path,'/')[1:]:
        currentPath = os.path.join(currentPath,element)
    currentPath = '/'+currentPath+createFileDir(mailSubject)
    try:
      os.listdir(currentPath)
      if debug == 1:
          print '[+] dir %s exist' % currentPath
    except OSError:
      if debug == 1:
          print '[+] creating dir %s' % currentPath
      os.makedirs(currentPath)

    mail = getMailForContentType(message.gettype(),mail)

    print '[-] creating target path'
    path = os.path.join(getMappingForElement(string.split(mailTo,"@")[0],
                        mapping),mailPath)

    print '[-] checking if path exists'
    try:
      os.listdir(path)
      f=open(path, 'w')
      if debug == 1:
          print '[+] path %s exist' % path
    except OSError:
      if debug == 1:
          print '[+] creating path %s' % path
      f=open(path, 'w')

    if debug == 1:
        print '[+] complete path : %s' % path
        
    mailBody = mail.body
    mailBody = unicode(mailBody, 'latin-1')
    try:
      f.write(mailBody)
      f.close()
      if debug == 1:
          print '[=] Mail insert successful'
    except IOError:
      if debug == 1:
          print '[!] Mail insert failed'
      f.close()
    raise "MailInsertFailedException",77

def usage():
    """ print how to use this nice little tool """

    print
    print '%s - a mail gateway to SKYRiX' % string.split(sys.argv[0],'/')[-1]
    print
    print 'Available options :'
    print
    print '--[h]elp      - print the help you are reading right now'
    print '--[t]arget    - target SKYRiX project'
    print '--[h]ost      - xmlrpc server (http://<host>:<port>/<uri>)'
    print '--[u]ser      - xmlrpc user'
    print '--[p]assword  - xmlrpc password'
    print '--[f]rom      - mail from'
    print '--[r]ecipient - mail to'
    print '--[m]ailuser  - mail user'
    print
    print 'Daemon mode :'
    print
    print '--[d]aemon    - daemon port'
    print '--[l]ocalhost - bind only to localhost'
    print
    print 'Debugging :'
    print 
    print '--[v]erbose   - be somewhat more verbose'

class RequestHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    def do_POST(self):
        try:
            data = self.rfile.read(int(self.headers["content-length"]))
            params, method = xmlrpclib.loads(data)

            try:
                response = self.call(method, params)
                if type(response) != type(()):
                    response = (response,)
            except:
                response = xmlrpclib.dumps(
                    xmlrpclib.Fault(sys.exc_value,sys.exc_type)
		    )
            else:
                response = xmlrpclib.dumps(
		    response,
		    methodresponse=1
		    )
        except:
            self.send_response(500)
            self.end_headers()
	else:
            self.send_response(200)
            self.send_header("Content-type", "text/xml")
            self.send_header("Content-length", str(len(response)))
            self.end_headers()
            self.wfile.write(response)
            self.wfile.flush()
            self.connection.shutdown(1)

    def call(self, method, params):

        mailfrom = params[0]
        mailto   = params[1]
        mailuser = params[2]
        mail     = params[3]

        print '[+] connecting to server at %s (user: %s)' % (url, user)
        print '[+] current project ID: %s' % project

        server = xmlrpclib.Server(url,login=user,password=password).project

        print '[+] parsing mail '
        mailDecoded =  base64.decodestring(mail)
        print mailDecoded

        return main(mailDecoded,server,project)

if __name__ == "__main__":
    daemon = 0
    debug = 0
    host = ''

    try:
        opts, args = getopt.getopt(sys.argv[1:],'t:h:u:p:d:f:r:m:lv',
                                   ['target=','host=','user=','password=',
                                    'daemon=','from=','recipient=',
                                    'mailuser=','localhost','help','verbose'])
    except getopt.GetoptError,e:
        sys.stderr.write(str(e))
        sys.exit(69)

    if len(sys.argv) == 1:
        usage()
        sys.exit(2)
    
    for o, a in opts:
        if o == "--help":
            usage()
            sys.exit(2)
        if o in ("-t", "--target"):
            project = a
        if o in ("-h", "--host"):
            url = a
        if o in ("-u", "--user"):
            user = a
        if o in ("-p", "--password"):
            password = a
        if o in ("-f", "--from"):
            mailfrom = a
        if o in ("-r", "--recipient"):
            mailto = a
        if o in ("-m", "--mailuser"):
            mailuser = a            
        if o in ("-d", "--daemon"):
            daemon = 1
            port   = a
        if o in ("-l", "--localhost"):
            host = 'localhost'
        if o in ("-v", "--verbose"):
            debug = 1           

    # script mode
    if daemon == 0:
        try:
            server = xmlrpclib.Server(url,login=user,password=password).project
            mail   = base64.decodestring(sys.stdin.read())
            main(mail,server,project)
        except:
            sys.stderr.write(str(sys.exc_info()[0]))
            sys.stderr.write('\n')
            sys.exit(70)

    # daemon standalone mode
    else:
        if debug == 1:
            if host == '':
                print 'Starting daemon on port %s' % port
            else:
                print 'Starting daemon on localhost port %s' % port

        SocketServer.TCPServer.allow_reuse_address = 1
        server = SocketServer.TCPServer((host, int(port)), RequestHandler)
        server.serve_forever()
