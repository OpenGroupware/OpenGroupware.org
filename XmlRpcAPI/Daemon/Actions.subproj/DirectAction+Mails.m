/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

  OGo is free software; you can redistribute it and/or modify it under
  the terms of the GNU Lesser General Public License as published by the
  Free Software Foundation; either version 2, or (at your option) any
  later version.

  OGo is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
  License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with OGo; see the file COPYING.  If not, write to the
  Free Software Foundation, 59 Temple Place - Suite 330, Boston, MA
  02111-1307, USA.
*/
// $Id$

#include "DirectAction.h"
#include "DirectAction+Mails.h"

@implementation DirectAction(MailMethods)


- (id)mail_createMailAction {
  id            ctx;
  NSString      *ctxPath, *ctxId;
  NSFileManager *f;
  NSDate        *now;
  
  static int FailedCnt = 0;

  ctx = [self commandContext];
  f  = fm();

  ctxId = nil;
  now   = [NSDate date];
  while (!ctxId) {
    ctxId = [NSString stringWithFormat:@"%d_%f_%d",
                        (int)getpid(),
                        [now timeIntervalSince1970],
                        FailedCnt];

    ctxPath = [workingPath(self) stringByAppendingPathComponent:ctxId];
    
    if ([f fileExistsAtPath:ctxPath]) {
      NSLog(@"%s: file %d already exist, try again",
            __PRETTY_FUNCTION__, FailedCnt);
      sleep(1);
      FailedCnt++;
      ctxId = nil;
    }
  }
  if (![f createDirectoryAtPath:ctxPath attributes:nil]) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
                 format:@"Couldn`t create mail transaction directory at "
                 @"path %@", ctxPath];
  }
  return ctxId;
}

- (id)mail_setFromAction:(NSString *)_mid:(NSString *)_from {
  return saveHeaderField(self, _mid, _from, @"from", NO);
}

- (id)mail_addToAction:(NSString *)_mid:(NSString *)_to {
  return saveHeaderField(self, _mid, _to, @"to", YES);
}

- (id)mail_setToAction:(NSString *)_mid:(NSArray *)_to {
  return saveHeaderField(self, _mid, _to, @"to", NO);
}

- (id)mail_addCCAction:(NSString *)_mid:(NSString *)_cc {
  return saveHeaderField(self, _mid, _cc, @"cc", YES);
}

- (id)mail_setCCAction:(NSString *)_mid:(NSArray *)_cc {
  return saveHeaderField(self, _mid, _cc, @"cc", NO);
}

- (id)mail_addBCCAction:(NSString *)_mid:(NSString *)_bcc {
  return saveHeaderField(self, _mid, _bcc, @"bcc", YES);
}

- (id)mail_setBCCAction:(NSString *)_mid:(NSArray *)_bcc {
  return saveHeaderField(self, _mid, _bcc, @"bcc", NO);
}

- (id)mail_setSubjectAction:(NSString *)_mid:(NSString *)_sub {
  return saveHeaderField(self, _mid, _sub, @"subject", NO);
}

- (id)mail_addHeaderValueAction:(NSString *)_mid:(NSString *)_key
                               :(NSString *)_val
{
  return saveHeaderField(self, _mid, _val, _key, YES);
}

- (id)mail_setHeaderValueAction:(NSString *)_mid:(NSString *)_key
                               :(NSString *)_val
{
  return saveHeaderField(self, _mid, _val, _key, NO);
}

- (id)mail_addHeadersAction:(NSString *)_mid:(NSDictionary *)_headers {
  return saveHeaderFields(self, _mid, _headers, YES);
}

- (id)mail_setHeadersAction:(NSString *)_mid:(NSDictionary *)_headers {
  return saveHeaderFields(self, _mid, _headers, NO);
}

- (id)mail_setTextBodyAction:(NSString *)_mid:(NSString *)_body {
  return saveText(self, pathForTransId(self, _mid), _body, NO);
}

- (id)mail_setHtmlBodyAction:(NSString *)_mid:(NSString *)_body {
  return saveText(self, pathForTransId(self, _mid), _body, YES);
}

- (id)mail_addAttachmentAction:(NSString *)_mid
                              :(NSString *)_fileName
                              :(NSString *)_contentType
                              :(id)_blob
{
  NSString            *blobDir, *path;
  NSFileManager       *f;
  BOOL                isDir;
  NSMutableArray      *attachments;
  NSMutableDictionary *dict;
  
  f       = fm();
  if (_blob == nil) {
    if (![_fileName isAbsolutePath]) {
      return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                   reason:@"missing attachment blob or absolute filename"];
    }
    else {
      static int AllowAbsolutePath = -1;

      if (AllowAbsolutePath == -1) {
        AllowAbsolutePath =
          [[NSUserDefaults standardUserDefaults]
                           boolForKey:@"DeniedAbsolutePathBlobs"]?0:1;
      }
      if (!AllowAbsolutePath) {
        return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                     reason:@"asolute path are not allowed here"];
      }
      if (![f fileExistsAtPath:_fileName isDirectory:&isDir]) {
        return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                     reason:@"missing file for absolute path parameter"];
      }
      if (isDir) {
        return [self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
                     reason:@"absolute path is a directory"];
      }
    }
  }
  else {
    _fileName = [_fileName lastPathComponent];
  }
  path    = pathForTransId(self, _mid);
  blobDir = [path stringByAppendingPathComponent:@"attachments"];

  if (![f fileExistsAtPath:blobDir isDirectory:&isDir]) {
    if (![f createDirectoryAtPath:blobDir attributes:nil])
      return [self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
                   format:@"Couldn`t create path for attachments %@",
                   blobDir];
  }
  if (!isDir) {
    return [self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
                 format:@"Attachment path is no directory %@",
                 blobDir];
  }
  attachments = loadAttachments(self, path);
  dict        = [NSMutableDictionary dictionaryWithCapacity:8];

  if (_blob == nil) {
    [dict setObject:_fileName forKey:@"AttachmentBlobPath"];
  }
  else {
    NSString *p;
    BOOL     res;

    p = [blobDir stringByAppendingPathComponent:
                 [NSString stringWithFormat:@"%d.base64", [attachments count]]];

    tryLock(self);
    res = [_blob writeToFile:p atomically:YES];
    breakLock(self);
    if (!res) {
      return [self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
                   format:@"Couldn`t write blob to path %@", p];
    }
    [dict setObject:p forKey:@"AttachmentBlobPath"];
  }
  {
    NSArray      *a;
    NSString     *type, *subType;
    NSDictionary *paras;
    NGMimeType   *mt;

    a = [_contentType componentsSeparatedByString:@"/"];

    if ([a count] != 2) {
      type    = @"application";
      subType =  @"octet-stream";
    }
    else {
      type    = [a objectAtIndex:0];
      subType = [a objectAtIndex:1];
    }
    paras = nil;

    if (!_blob) {
      paras = [NSDictionary dictionaryWithObject:[_fileName lastPathComponent]
                            forKey:@"name"];
    }
    else if (_fileName) {
      paras = [NSDictionary dictionaryWithObject:_fileName
                            forKey:@"name"];
    }
    mt = [NGMimeType mimeType:type subType:subType parameters:paras];
    [dict setObject:[mt stringValue] forKey:@"content-type"];
    [dict setObject:@"base64" forKey:@"content-transfer-encoding"];
  }
  [attachments addObject:dict];
  {
    BOOL     res;
    NSString *attPath;
    
    attPath = [path stringByAppendingPathComponent:@"attachments.plist"];

    tryLock(self);
    res = [attachments writeToFile:attPath atomically:YES];
    breakLock(self);

    if (!res) {
      return [self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
                   format:@"Couldn`t attachment config file %@", attPath];
    }
  }
  return toBool(YES);
}

- (id)mail_closeTransactionAction:(NSString *)_mid {
  BOOL res;
  
  tryLock(self);
  res = [fm() removeFileAtPath:pathForTransId(self, _mid) handler:nil];
  breakLock(self);
  
  return toBool(res);
}

- (id)mail_sendAction:(NSString *)_mid:(NSNumber *)_keepOpen {
  NSMutableDictionary *header;
  NSMutableArray      *rec;
  NSArray             *objs;
  
  NSString            *txt, *html, *path, *contentTyp, *messageFile;
  NSArray             *attachments;
  NGMimeMessage       *message;
  NSEnumerator        *enumerator;
  id                  obj;

  path = pathForTransId(self, _mid);
  txt  = loadText(self, path, NO);
  html = loadText(self, path, YES);

  if (txt && html) { /* build alternative */
    contentTyp = @"multipart/alternative";
  }
  else {
    if (!txt && !html) {
      contentTyp = @"text/plain";
      txt        = @"";
    }
    else if (html) {
      txt = html;
      contentTyp = @"text/html";
    }
    else {
      contentTyp = @"text/plain";
    }
  }
  header = loadHeaders(self, path);
  rec    = [NSMutableArray arrayWithCapacity:16];
  
  objs = [header objectForKey:@"bcc"];
  if ([objs count]) {
    [rec addObjectsFromArray:objs];
  }
  [header removeObjectForKey:@"bcc"];

  objs = [header objectForKey:@"to"];
  if ([objs count]) {
    [rec addObjectsFromArray:objs];
  }
  objs = [header objectForKey:@"cc"];
  if ([objs count]) {
    [rec addObjectsFromArray:objs];
  }
  objs = [[rec copy] autorelease];
  [rec removeAllObjects];

  enumerator = [objs objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    NGMailAddressParser *parser;
    
    if (![obj length])
      continue;
    
    parser = [NGMailAddressParser mailAddressParserWithString:obj];
    [rec addObjectsFromArray:[parser parseAddressList]];
  }

  objs       = [[rec copy] autorelease];
  enumerator = [objs objectEnumerator];
  [rec removeAllObjects];

  while ((obj = [enumerator nextObject])) {
    NSString *mail;

    if ((mail = [obj address])) {
      [rec addObject:mail];
    }
  }
  
  attachments = loadAttachments(self, path);
  
  if ([attachments count]) {
    NGMimeMultipartBody *body;
    
    [header setObject:@"multipart/mixed" forKey:@"content-type"];
    
    message = [NGMimeMessage messageWithHeader:convertDictToMap(self, header)];
    body    = [[NGMimeMultipartBody alloc] initWithPart:message];
    
    [body addBodyPart:buildTextPart(self, @"multipart/mixed", txt, html)];
    {
      NSEnumerator *enumerator;
      id           dict;

      enumerator = [attachments objectEnumerator];

      while ((dict = [enumerator nextObject]))
        [body addBodyPart:buildBlobPart(self, dict)];
    }
    [message setBody:body];
  }
  else {
    [header setObject:contentTyp forKey:@"content-type"];

    message = [NGMimeMessage messageWithHeader:convertDictToMap(self, header)];

    if ([contentTyp hasPrefix:@"multipart"]) {
      NGMimeMultipartBody *body;
  
      body = [[NGMimeMultipartBody alloc] initWithPart:message];
      [body addBodyPart:buildPart(self, txt, YES)];
      [body addBodyPart:buildPart(self, html, NO)];
      [message setBody:body];
      [body release]; body = nil;
    }
    else {
      [message setBody:txt];
    }
  }
  {
    NGMimeMessageGenerator *gen;

    gen         = [NGMimeMessageGenerator mimePartGenerator];
    messageFile = [gen generateMimeFromPartToFile:message];
  }
  [[self commandContext] runCommand:@"email::deliver",
                         @"copyToSentFolder", [NSNumber numberWithBool:NO],
                         @"addresses", rec,
                         @"messageTmpFile", messageFile, nil];
  
  [fm() removeFileAtPath:messageFile handler:nil];
  if (![_keepOpen boolValue])
    [self mail_closeTransactionAction:_mid];
    
  return toBool(YES);
}

- (id)mail_getTransactionsAction {
  id array;

  array = [fm() directoryContentsAtPath:workingPath(self)];

  if ([array containsObject:@"write.lock"]) {
    array = [[array mutableCopy] autorelease];
    [array removeObject:@"write.lock"];
  }
  return array;
}

- (id)mail_deleteAllTransactionsAction {
  NSEnumerator *enumerator;
  id           obj;

  enumerator = [[self mail_getTransactionsAction] objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    if (![self mail_closeTransactionAction:obj])
      return toBool(NO);
  }
  return toBool(YES);
}


@end /* DirectAction(MailMethods) */
