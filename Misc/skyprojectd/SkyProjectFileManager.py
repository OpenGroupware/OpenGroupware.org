# $Id: SkyProjectFileManager.py,v 1.1 2003/08/19 12:01:56 helge Exp $

import sys,base64,getpass,httplib,string
from pprint import pprint

class SkyProjectFolderDataSource:
    
    def __init__(self, fileManager, path):
        self.fm   = fileManager
        self.path = path
    
    def fetchObjects(self):
        results = []
        onlyNames = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n" + \
                    "<D:propfind xmlns:N=\"http://www.skyrix.com/" +\
                    "NSFileSchema/\">\n<N:NSFilePath/>\n" +\
                    "</D:propfind>\n";
        if (len(self.path) == 0):
            print "Wrong path";
            return None;
        http = self.fm._http('PROPFIND', self.path);
        http.putheader('Authorization', self.fm.auth);
        http.putheader('Accept', '*/*');
        http.putheader('content-length', str(len(onlyNames)));
        http.endheaders();
        http.send(onlyNames);
        
        errcode, errmsg, headers = http.getreply();
        
        if (errcode != 207):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return None;
        
        f = http.getfile();
        data = f.read();
        f.close();
        data = self.fm._removeXMLHeader(data);
        if data == None:
            print "got unexpected data";
            return None;
        
        lines = string.split(data, "\n")
        inResponse = 0
        inPropStat = 0
        inProp     = 0
        attrs      = {}
        href       = ""
        
        for line in lines:
            if line[:12] == "</D:response":
                inResponse = 0
                inPropStat = 0
                inProp     = 0
                if len(href) > 0:
                    if href != self.path:
                        intKeys = ( "NSFileSize", "SkyOwnerId", "projectId" )
                        for ik in intKeys:
                            if attrs.has_key(ik):
                                attrs[ik] = int(attrs[ik])
                        results.append(attrs)
                attrs = {}
                continue
            if line[:13] == "</D:propstat>":
                inPropStat = 0
                inProp     = 0
                continue
            if line[:9] == "</D:prop>":
                inProp     = 0
                #pprint(attrs)
                continue
            
            if line[:11] == "<D:response":
                inResponse = 1
                continue
            if not inResponse:
                continue
            
            if line[:8] == "<D:href>":
                tstart = string.find(line, ">")
                tfin   = string.rfind(line, "</")
                href   = line[tstart+1:tfin]
                attrs['href'] = href
                continue
            
            if line[:11] == "<D:propstat":
                inPropStat = 1
                continue
            if not inPropStat:
                continue
            
            if line[:7] == "<D:prop":
                inProp = 1
                continue
            if not inProp:
                continue
            
            if line[:3] != "<D:":
                continue
            
            # properties follow
            tstart    = string.find(line, ":")
            tfin      = string.find(line, ">")
            propName  = line[tstart + 1:tfin]
            tstart    = tfin + 1
            tfin      = string.rfind(line, "</")
            propValue = line[tstart:tfin]
            propValue = string.replace(propValue, '&amp;','&');
            propValue = string.replace(propValue, '&lt;', '<');
            propValue = string.replace(propValue, '&gt;', '>');
            
            attrs[propName] = propValue
        #for
        
        return results

class SkyProjectFileManager:
    """
    SkyProjectFileManager

    A SkyProjectFileManager allows to connect to a skyprojectd using HTTP. To
    access a skyprojectd, you need to know the host it runs on, the port it
    runs on and a login/pwd to log into the server.

    Setup:

      fm = SkyProjectFileManager('donald', 'xxxx', 'test.skyrix.com', 10000)

    Note that the connection isn't setup immediatly and therefore the
    parameters are not checked immediatly !
    """
    
    def __init__(self, login=None, pwd=None, host='localhost', port=15056):
        """
        SkyProjectFileManager([login],[pwd],[host],[port]
        
        If any of the parameters isn't provided, it will be asked for.
        """
        if login is None:
            sys.stdout.write("SKYRiX %s:%i login: " % ( host, port ))
            sys.stdout.flush()
            login = sys.stdin.readline()
            if len(login) > 0:
                login = login[:-1] # cut off newline
        
        if pwd is None:
            pwd = getpass.getpass("Password: ")
        
        self.host  = host;
        self.port  = int(port);
        authText   = login + ':' + pwd;
        authText   = base64.encodestring(authText);
        al         = len(authText);
        if authText[al - 1] == '\12':
            authText = authText[0:-1];
            authText = 'Basic ' + authText;
        self.auth = authText;
    
    def _http(self, _method, _path):
        http = httplib.HTTP(self.host, self.port);
        http.putrequest(_method, _path);
        http.putheader('User-Agent', 'SKYRiX-FileManager');
        return http;

    def _removeXMLHeader(self, _s):
        xmlStart = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n" + \
                   "<D:multistatus xmlns:D=\"DAV:\">\n";

        if string.find(_s, xmlStart) == 0:
            return _s[len(xmlStart):len(_s)];
        return None;

    def _fileAttrsDictFromXML(self, _s):
        lines = string.split(_s, "\n")
        inResponse = 0
        inPropStat = 0
        inProp     = 0
        attrs      = {}
        href       = ""
        hrefToAttrs= {}
        
        for line in lines:
            if line[:12] == "</D:response":
                inResponse = 0
                inPropStat = 0
                inProp     = 0
                if len(href) > 0:
                    hrefToAttrs[href] = attrs
                attrs = {}
                continue
            if line[:13] == "</D:propstat>":
                inPropStat = 0
                inProp     = 0
                continue
            if line[:9] == "</D:prop>":
                inProp     = 0
                pprint(attrs)
                continue
            
            if line[:11] == "<D:response":
                inResponse = 1
                continue
            if not inResponse:
                continue
            
            if line[:8] == "<D:href>":
                tstart = string.find(line, ">")
                tfin   = string.rfind(line, "</")
                href   = line[tstart+1:tfin]
                attrs['href'] = href
                continue
            
            if line[:11] == "<D:propstat":
                inPropStat = 1
                continue
            if not inPropStat:
                continue
            
            if line[:7] == "<D:prop":
                inProp = 1
                continue
            if not inProp:
                continue
            
            if line[:3] != "<D:":
                continue
            
            # properties follow
            tstart    = string.find(line, ":")
            tfin      = string.find(line, ">")
            propName  = line[tstart + 1:tfin]
            tstart    = tfin + 1
            tfin      = string.rfind(line, "</")
            propValue = line[tstart:tfin]
            propValue = string.replace(propValue, '&amp;','&');
            propValue = string.replace(propValue, '&lt;', '<');
            propValue = string.replace(propValue, '&gt;', '>');
            
            attrs[propName] = propValue
        #for
        
        rest = ""
        return ( rest, attrs )
        
    def _OLD_fileAttrsDictFromXML(self, _s):
        isOk     = 1;
        xmlStart = "<D:response>\n<D:propstat>\n" + \
                   "<D:prop xmlns:N=\"http://www.skyrix.com/NSFileSchema/\">\n";
        xmlEnd   = "</D:prop>\n<D:status>HTTP/1.1 200 OK</D:status>\n" \
                   "</D:propstat>\n</D:response>\n";
        
        keyBStart = "<N:";
        keyBEnd   = ">\n";
        keyEStart = "</N:";
        keyEEnd   = ">\n";
        
        if string.find(_s, xmlStart) != 0:
            return (_s, None);
        
        _s   = _s[len(xmlStart):len(_s)];
        dict = {};
        while string.find(_s, xmlEnd) != 0:
            if (_s[0] == ' '):
                _s = _s[1:];
            
            if string.find(_s, keyBStart) != 0:
                print 'didn`t find keyBStart ', keyBStart;
                isOk = 0;
                break;
            _s = _s[len(keyBStart):len(_s)];
            
            keyLen  = string.find(_s, keyBEnd);
            key     = _s[0:keyLen];
            _s      = _s[len(keyBEnd)+keyLen:len(_s)];
            vEndTag = keyEStart + key + keyEEnd;
            vEnd    = string.find(_s, vEndTag);
            if (vEnd == -1):
                print "couldn`t find end tag";
                isOk = 0;
                break;

            value   = _s[0:vEnd - 1]; # remove \n
            _s      = _s[len(vEndTag) + vEnd:len(_s)];
            
            s = str(value);
            s = string.replace(s, '&amp;','&');
            s = string.replace(s, '&lt;', '<');
            s = string.replace(s, '&gt;', '>');

            dict[key] = s;

        if isOk == 0:
            return (None, None);
        
        _s = _s[len(xmlEnd):len(_s)];
        return (_s, dict);
        
    
    def contentsAtPath(self, _path):
        """
        contentsAtPath(path)
        
        Returns the contents of the file at 'path' as a Python string object.
        
        Sample:
          s = fm.contentsAtPath('/test.txt')
        """
        if (len(_path) == 0):
            print "wrong path";
            return None;
        http = self._http('GET', _path);
        http.putheader('Accept', '*/*');
        http.putheader('Authorization', self.auth);
        http.endheaders();
        errcode, errmsg, headers = http.getreply();
        if (errcode != 200):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return None;
        f = http.getfile();
        data = f.read();
        f.close();
        return data;
    
    def writeContentsAtPath(self, _content, _path):
        """
        writeContentsAtPath(content, path)
        
        Write the Python String 'content' to the file at 'path'. Returns 0
        on error and 1 on success.
        
        Sample:
          if not fm.writeContentsAtPath('Hello World !', '/test.txt'):
            print 'write failed ...'
        """
        if (len(_path) == 0):
            print "Wrong path";
            return 0;
        lenStr = str(len(_content));
        http = self._http('PUT', _path);
        http.putheader('Authorization', self.auth);
        http.putheader('content-length', lenStr);
        http.endheaders();
        http.send(_content);
        errcode, errmsg, headers = http.getreply();
        if (errcode != 204 and errcode != 201):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return 0;
        return 1;
    
    def attributesAtPath(self, _path):
        """
        attributesAtPath(path)

        Returns as a Python dictionary the file attributes of the file at
        path. Returns 0 on error.

        Sample:
          dict = fm.attributesAtPath('/test.txt')
          print dict['color']
        """
        onlyAttrs = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n" + \
                    "<D:propfind xmlns:N=\"http://www.skyrix.com/" +\
                    "NSFileSchema/\">\n<N:NSFileAttributes/>\n" +\
                    "</D:propfind>\n";
        if (len(_path) == 0):
            print "Wrong path";
            return 0;
        http = self._http('PROPFIND', _path);
        http.putheader('Authorization', self.auth);
        http.putheader('Accept', '*/*');
        http.putheader('content-length', str(len(onlyAttrs)));
        http.endheaders();
        http.send(onlyAttrs);
        
        errcode, errmsg, headers = http.getreply();
        
        if (errcode != 207):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return 0;
        
        f = http.getfile();
        data = f.read();
        f.close();
        data = self._removeXMLHeader(data);
        if data == None:
            print "got unexpected data";
            return None;
        
        lines = string.split(data, "\n")
        inResponse = 0
        inPropStat = 0
        inProp     = 0
        attrs      = {}
        href       = ""
        
        for line in lines:
            if line[:12] == "</D:response":
                inResponse = 0
                inPropStat = 0
                inProp     = 0
                if len(href) > 0:
                    break
                attrs = {}
                continue
            if line[:13] == "</D:propstat>":
                inPropStat = 0
                inProp     = 0
                continue
            if line[:9] == "</D:prop>":
                inProp     = 0
                pprint(attrs)
                continue
            
            if line[:11] == "<D:response":
                inResponse = 1
                continue
            if not inResponse:
                continue
            
            if line[:8] == "<D:href>":
                tstart = string.find(line, ">")
                tfin   = string.rfind(line, "</")
                href   = line[tstart+1:tfin]
                attrs['href'] = href
                continue
            
            if line[:11] == "<D:propstat":
                inPropStat = 1
                continue
            if not inPropStat:
                continue
            
            if line[:7] == "<D:prop":
                inProp = 1
                continue
            if not inProp:
                continue
            
            if line[:3] != "<D:":
                continue
            
            # properties follow
            tstart    = string.find(line, ":")
            tfin      = string.find(line, ">")
            propName  = line[tstart + 1:tfin]
            tstart    = tfin + 1
            tfin      = string.rfind(line, "</")
            propValue = line[tstart:tfin]
            propValue = string.replace(propValue, '&amp;','&');
            propValue = string.replace(propValue, '&lt;', '<');
            propValue = string.replace(propValue, '&gt;', '>');
            
            attrs[propName] = propValue
        #for
        
        return attrs
    
    def writeAttributesAtPath(self, _path, _attrs):
        attrsBegin = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n" + \
                     "<D:propertyupdate xmlns:D=\"DAV\" " + \
                     "xmlns:N=\"http://www.skyrix.com/" +\
                     "NSFileSchema/\">\n<D:set> <D:prop>\n";

        attrsEnd   =  "</D:prop></D:set></D:propertyupdate>";

        keys = _attrs.keys()

        attrs = attrsBegin;
        
        for key in keys:
            attrs = attrs + "<N:";
            attrs = attrs + key;
            attrs = attrs + ">";

            s = str(_attrs[key]);
            s = string.replace(s, '&', '&amp;');
            s = string.replace(s, '<', '&lt;');
            s = string.replace(s, '>', '&gt;');

            attrs = attrs + s;
            attrs = attrs + "</N:";
            attrs = attrs + key;
            attrs = attrs + ">\n";

        attrs = attrs + attrsEnd;
            

        if (len(_path) == 0):
            print "Wrong path";
            return 0;
        http = self._http('PROPPATCH', _path);
        http.putheader('Authorization', self.auth);
        http.putheader('Accept', '*/*');
        http.putheader('content-length', str(len(attrs)));
        http.endheaders();
        http.send(attrs);
        errcode, errmsg, headers = http.getreply();
        if (errcode != 200):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return 0;
        return 1;

    def deleteAttributesAtPath(self, _path, _attrs):
        attrsBegin = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n" + \
                     "<D:propertyupdate xmlns:D=\"DAV\" " + \
                     "xmlns:N=\"http://www.skyrix.com/" +\
                     "NSFileSchema/\">\n<D:remove> <D:prop>\n";

        attrsEnd   =  "</D:prop></D:remove></D:propertyupdate>";

        keys = _attrs

        attrs = attrsBegin;
        
        for key in keys:
            attrs = attrs + "<N:";
            attrs = attrs + key;
            attrs = attrs + ">";
            attrs = attrs + "</N:";
            attrs = attrs + key;
            attrs = attrs + ">\n";

        attrs = attrs + attrsEnd;
            

        if (len(_path) == 0):
            print "Wrong path";
            return 0;
        http = self._http('PROPPATCH', _path);
        http.putheader('Authorization', self.auth);
        http.putheader('Accept', '*/*');
        http.putheader('content-length', str(len(attrs)));
        http.endheaders();
        http.send(attrs);
        errcode, errmsg, headers = http.getreply();
        if (errcode != 200):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return 0;
        return 1;
    
    def directoryContentsAtPath(self, _path):
        """
        directoryContentsAtPath(path)
        
        Returns the contents of the directory at 'path' as a Python sequence.
        
        Sample:
          for p in fm.directoryContentsAtPath('/'):
            print p
        """
        onlyNames = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n" + \
                    "<D:propfind xmlns:N=\"http://www.skyrix.com/" +\
                    "NSFileSchema/\">\n<N:NSFilePath/>\n" +\
                    "</D:propfind>\n";
        if (len(_path) == 0):
            print "Wrong path";
            return 0;
        http = self._http('PROPFIND', _path);
        http.putheader('Authorization', self.auth);
        http.putheader('Accept', '*/*');
        http.putheader('content-length', str(len(onlyNames)));
        http.endheaders();
        http.send(onlyNames);
        
        errcode, errmsg, headers = http.getreply();
        
        if (errcode != 204 and errcode != 201 and errcode != 207):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return 0;
        
        if (errcode == 207):
            f = http.getfile();
            data = f.read();
            f.close();
            data = self._removeXMLHeader(data);
            if data == None:
                print "got unexpected data";
                return None;
            array = [];
            
            lines = string.split(data, "\n")
            for line in lines:
                if line[:8] == "<D:href>":
                    tstart = string.find(line, ">")
                    tfin   = string.rfind(line, "</")
                    href   = line[tstart+1:tfin]
                    if href != _path:
                        if href[-1:] == "/":
                            href = href[:-1]
                        if len(href) == 0:
                            continue
                        sep = string.rfind(href, "/")
                        if sep != -1:
                            href = href[sep + 1:]
                        array.append(href)
                    continue
            return array;
        return None;
        
    
    def createDirectoryAtPath(self, _path):
        if (len(_path) == 0):
            print "Wrong path";
            return 0;
        http = self._http('MKCOL', _path);
        http.putheader('Authorization', self.auth);
        http.putheader('content-length', '0');
        http.endheaders();
        errcode, errmsg, headers = http.getreply();
        if (errcode != 201):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return 0;
        return 1;


    def removeFileAtPath(self, _path):
        if (len(_path) == 0):
            print "Wrong path";
            return 0;
        http = self._http('DELETE', _path);
        http.putheader('Authorization', self.auth);
        http.putheader('content-length', '0');
        http.endheaders();
        errcode, errmsg, headers = http.getreply();
        if (errcode != 204):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return 0;
        return 1;
        

    def copyPathToPath(self, _path, _dest):
        if (len(_path) == 0):
            print "Wrong path";
            return 0;
        http = self._http('COPY', _path);
        http.putheader('Destination', _dest);
        http.putheader('Authorization', self.auth);
        http.putheader('content-length', '0');
        http.endheaders();
        errcode, errmsg, headers = http.getreply();
        if (errcode != 201):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return 0;
        return 1;
        

    def movePathToPath(self, _path, _dest):
        if (len(_path) == 0):
            print "Wrong path";
            return 0;
        http = self._http('MOVE', _path);
        http.putheader('Destination', _dest);
        http.putheader('Authorization', self.auth);
        http.putheader('content-length', '0');
        http.endheaders();
        errcode, errmsg, headers = http.getreply();
        if (errcode != 201):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return 0;
        return 1;
        

    def fileExistsAtPath(self, _path):
        """
        fileExistsAtPath(path)
        
        Checks whether a file or directory exists at path. Returns 1 if it
        does and 0 if no file exists at the specified path.
        """
        xmlContent = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n" + \
                     "<D:propfind xmlns:N=\"http://www.skyrix.com/" +\
                     "NSFileSchema/\">\n<N:NSFilePath/><N:NSFileAttributes/>\n" +\
                     "</D:propfind>\n";
        if (len(_path) == 0):
            print "Wrong path";
            return 0;
        http = self._http('PROPFIND', _path);
        http.putheader('Authorization', self.auth);
        http.putheader('Accept', '*/*');
        http.putheader('content-length', str(len(xmlContent)));
        http.endheaders();
        http.send(xmlContent);
        
        errcode, errmsg, headers = http.getreply();
        
        if (errcode != 207  and errcode != 404):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return 0;
        if (errcode == 404):
            return 0;
        return 1;

    def fileExistsAtPathIsDirectory(self, _path):
        """
        fileExistsAtPathIsDirectory(path)
        
        Checks whether a directory exists at path. Returns 1 if it
        does and 0 if no directory exists at the specified path.
        """
        xmlContent = "<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n" + \
                     "<D:propfind xmlns:N=\"http://www.skyrix.com/" +\
                     "NSFileSchema/\">\n<N:NSFileAttributes/>\n" +\
                     "</D:propfind>\n";
        if (len(_path) == 0):
            print "Wrong path";
            return 0;
        http = self._http('PROPFIND', _path);
        http.putheader('Authorization', self.auth);
        http.putheader('Accept', '*/*');
        http.putheader('content-length', str(len(xmlContent)));
        http.endheaders();
        http.send(xmlContent);
        
        errcode, errmsg, headers = http.getreply();
        
        if (errcode != 207 and errcode != 404):
            print "got error: ", errcode, " text ", errmsg, " header " , headers;
            return 0;
        
        if (errcode == 404):
            return 0;
        
        if (errcode == 207):
            f = http.getfile();
            data = f.read();
            f.close();
            data = self._removeXMLHeader(data);
            if data == None:
                print "got unexpected data";
                return None;
            lines = string.split(data, "\n")
            for line in lines:
                if line[:14] != "<D:NSFileType>":
                    continue
                line = line[14:]
                tfin = string.find(line, "</")
                line = line[:tfin]
                if line == "NSFileTypeDirectory":
                    return 1
                else:
                    return 0
        return 0;
    
    def dataSourceAtPath(self, path):
        return SkyProjectFolderDataSource(self, path)

# SkyProjectFileManager
