/*
  Copyright (C) 2000-2005 SKYRIX Software AG

  This file is part of OpenGroupware.org.

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

#ifndef __DirectAction_Mails_H__
#define __DirectAction_Mails_H__

#include "DirectAction.h"
#include <EOControl/EOControl.h>
#include <NGMime/NGMimeType.h>
#include <NGMime/NGMimeFileData.h>
#include <NGMail/NGMail.h>
#include "EOControl+XmlRpcDirectAction.h"
#include "NSObject+EKVC.h"
#include "common.h"
#include <unistd.h>

static inline NSDistributedLock   *lock(id self);
static inline BOOL                tryLock(id self);
static inline void                breakLock(id self);
static inline NSDate              *lockDate(id self);
static inline NSString            *headerPath(id self, NSString *_path);
static inline NSString            *textPath(id self, NSString *_path,
                                            BOOL _isHtml);
static inline NSMutableDictionary *loadHeaders(id self, NSString *_path);
static inline BOOL                saveHeaders(id self, NSString *_path,
                                              NSDictionary *_headers);
static inline NSString            *loadText(id self, NSString *_path,
                                            BOOL _isHtml);
static inline id                  saveText(id self, NSString *_path,
                                           NSString *_text, BOOL _isHtml);
static inline NSNumber            *toBool(BOOL _b);
static inline NSFileManager       *fm();
static inline NSString            *pathForTransId(id self, NSString *_tid);
static inline NSString            *login(id self);
static inline NSString            *workingPath(id self);
static inline id                  saveHeaderField(id self, NSString *_mid,
                                                  id _val, NSString *_name,
                                                  BOOL _add);
static inline NSMutableArray      *loadAttachments(id self, NSString *_path);
static inline NGMutableHashMap    *convertDictToMap(id self,
                                                    NSDictionary *_dict);


static inline id saveHeaderFields(id self, NSString *_mid,
                                  NSDictionary *_headers,
                                                   BOOL _add);
static inline id buildBlobPart(id self, NSMutableDictionary *_headers);
static inline id buildPart(id self, NSString *_content, BOOL _isText);
static inline id buildAlternativePart(id self, NSString *_txt,NSString *_html);
static inline id buildTextPart(id self, NSString *_contentType,
                               NSString *_txt, NSString *_html);


static inline NSDistributedLock *lock(id self) {
  return
    [NSDistributedLock lockWithPath:
                       [workingPath(self) stringByAppendingPathComponent:
                                   @"write.lock"]];
}

static inline BOOL tryLock(id self) {
  NSDistributedLock *l;
  
  l = lock(self);

  if (![l tryLock]) {
    static int MaxLockTime = -1; /* max lock time in seconds */
    NSDate     *ld;

    if (MaxLockTime == -1) {
      MaxLockTime = [[NSUserDefaults standardUserDefaults]
                                     integerForKey:@"MailLockTimeout"];
      if (!MaxLockTime)
        MaxLockTime = 15;
    }
    if ((ld = lockDate(self))) {
      if (abs([ld timeIntervalSinceNow]) > MaxLockTime) {
        NSLog(@"WARNING[%s]: unlock locked FS-Project %@, locked "
              @"since %@ now %@", __PRETTY_FUNCTION__,
              self, ld, [NSDate date]);
        [l breakLock];
      
        if ([l tryLock]) {
          return YES;
        }
      }
    } 
    NSLog(@"WARNING[%s] try to lock already locked Mail Path %@."
          @"Locked since:%@ now:%@.", __PRETTY_FUNCTION__, self, ld,
          [NSDate date]);
    [[self faultWithFaultCode:XMLRPC_FAULT_LOCK_ERROR
           format:@"Could not lock mail tmp directory. locked since %@",
           ld] raise];
  }
  return YES;
}

static inline void breakLock(id self) {
  [lock(self) breakLock];
}

static inline NSDate *lockDate(id self) {
  return [lock(self) lockDate];
}
static inline NSString *headerPath(id self, NSString *_path)
{
  return [_path stringByAppendingPathComponent:@"headers.plist"];
}

static inline NSString *textPath(id self, NSString *_path, BOOL _isHtml) {
  return [_path stringByAppendingPathComponent:
                _isHtml ? @"blob.html" : @"blob.text"];
}

static inline NSMutableDictionary *loadHeaders(id self, NSString *_path)
{
  NSString *path;

  path = headerPath(self, _path);
  
  if ([fm() fileExistsAtPath:path isDirectory:NO]) {
    return [NSMutableDictionary dictionaryWithContentsOfFile:path];
  }
  return [NSMutableDictionary dictionaryWithCapacity:32];
}

static inline BOOL saveHeaders(id self, NSString *_path, NSDictionary *_headers)
{
  BOOL res;

  if (!_headers)
    _headers = [NSDictionary dictionary];
  
  tryLock(self);
  res = [_headers writeToFile:headerPath(self, _path) atomically:YES];
  breakLock(self);
  return res;
}

static inline NSString *loadText(id self, NSString *_path, BOOL _isHtml) {
  if ([fm() fileExistsAtPath:_path isDirectory:NULL])
    return [NSString stringWithContentsOfFile:textPath(self, _path, _isHtml)];

  return nil;
}

static inline id saveText(id self, NSString *_path, NSString *_text,
                          BOOL _isHtml) {
  BOOL res;
  
  if (!_text) {
    _text = @"";
  }

  _text = [_text stringByAppendingString:@"\n"];

  tryLock(self);
  res = [_text writeToFile:textPath(self, _path, _isHtml) atomically:YES];
  breakLock(self);
  return toBool(res);
}

static inline NSNumber *toBool(BOOL _b) 
{
  static NSNumber *YesNum = nil;
  static NSNumber *NoNum  = nil;

  if (YesNum == nil) {
    YesNum = [[NSNumber numberWithBool:YES] retain];
  }
  if (NoNum == nil) {
    NoNum = [[NSNumber numberWithBool:NO] retain];
  }
  return _b ? YesNum : NoNum;
}

static inline NSFileManager *fm() 
{
  static NSFileManager *Fm = nil;

  if (Fm == nil) {
    Fm = [[NSFileManager defaultManager] retain];
  }
  return Fm;
}

static inline NSString *pathForTransId(id self, NSString *_tid)
{
  BOOL     isDir;
  NSString *path;

  if (![_tid length])
    [[self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
           reason:@"missing mail transaction id"] raise];

  path = [workingPath(self) stringByAppendingPathComponent:_tid];
  NSLog(@"path %@", path);
  
  if (![fm() fileExistsAtPath:path isDirectory:&isDir]) {
    [[self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
           format:@"Couldn`t find mail transaction for id %@",
           _tid] raise];
  }
  if (!isDir) {
    [[self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
           format:@"mail transaction path is no directory %@",
           path] raise];
  }
  return path;
}

static inline NSString *login(id self) 
{
  return [[[self commandContext] valueForKey:LSAccountKey]
                 valueForKey:@"login"];
}

static inline NSString *workingPath(id self) 
{
  NSFileManager  *f;
  NSUserDefaults *ud;
  NSString       *path;
  BOOL           isDir;
  id             ctx;
  
  static NSString *RootPathForUser = nil;

  ud  = [NSUserDefaults standardUserDefaults];
  ctx = [self commandContext];

  if ((path = [ctx valueForKey:@"TempMailBuildPath"])) {
    return path;
  }
  
  if (!RootPathForUser) {
    RootPathForUser = [[ud stringForKey:@"TempMailBuildPath"] retain];

    if (!RootPathForUser) {
      NSProcessInfo *pi;
      pi = [NSProcessInfo processInfo];

      RootPathForUser = [[pi environment] objectForKey:@"GNUSTEP_USER_ROOT"];

      if (![RootPathForUser length])
        RootPathForUser = @"/tmp";

      RootPathForUser = [[RootPathForUser stringByAppendingPathComponent:
                                          @"XmlRpc_MailDir"] retain];
    }
    NSLog(@"DirectAction+Mails: build root path %@",
          RootPathForUser);
  }

  path = [RootPathForUser stringByAppendingPathComponent:login(self)];
  f   = fm();
  if (![f fileExistsAtPath:path isDirectory:&isDir]) {
    if (![f createDirectoryAtPath:path attributes:nil]) {
      [[self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
             format:@"couldn`t create user mail directory at path: %@",
             path] raise];
    }
  }
  else if (!isDir) {
    [[self faultWithFaultCode:XMLRPC_FAULT_INTERNAL_ERROR
           format:@"user mail directory path is no directory : %@",
           path] raise];
  }
  [ctx takeValue:path forKey:@"TempMailBuildPath"];
  return path;
}

static inline void checkField(id self, id _field, NSString *_name) {

  if ([_field isKindOfClass:[NSArray class]]) {
    if (![_field count])
      [[self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
             format:@"missing value for header %@", _name] raise];
  }
  else if (![_field length]) {
    [[self faultWithFaultCode:XMLRPC_FAULT_INVALID_PARAMETER
           format:@"missing value for header %@", _name] raise];
  }
}

static inline id saveHeaderField(id self, NSString *_mid,
                                 id _val, NSString *_name, BOOL _add)
{
  NSMutableDictionary *dict;
  NSString            *path;
  id                  obj;

  checkField(self, _val, _name);
  
  path = pathForTransId(self, _mid);
  dict = loadHeaders(self, path);

  if (![_val isKindOfClass:[NSArray class]])
    _val = [NSArray arrayWithObject:_val];
  
  if (_add) {
    obj = [dict objectForKey:_name];

    if (!obj) {
      obj = _val;
    } else {
      obj = [obj mutableCopy];

      [obj addObjectsFromArray:_val];
    }
  }
  else {
    obj = _val;
  }
  [dict setObject:obj forKey:_name];
  
  return toBool(saveHeaders(self, path, dict));
}

static inline NGMutableHashMap *convertDictToMap(id self,
                                                 NSDictionary *_dict)
{
  NGMutableHashMap *map;
  NSEnumerator     *enumerator;
  id               key;

  map = [[NGMutableHashMap alloc] initWithCapacity:[_dict count]];

  enumerator = [_dict keyEnumerator];

  while ((key = [enumerator nextObject])) {
    id val;

    val = [_dict objectForKey:key];
    
    if ([val isKindOfClass:[NSArray class]]) {
      [map setObjects:val forKey:key];
    }
    else {
      [map setObject:val forKey:key];
    }
  }
  return [map autorelease];
}

static inline id saveHeaderFields(id self, NSString *_mid,
                                  NSDictionary *_headers, BOOL _add)
{
  NSEnumerator *enumerator;
  id           key;

  enumerator = [_headers keyEnumerator];

  while ((key = [enumerator nextObject])) {

    if (![saveHeaderField(self, _mid, [_headers objectForKey:key],
                          key, _add) boolValue])
      return toBool(NO);
  }
  return toBool(YES);
}

static inline id buildBlobPart(id self, NSMutableDictionary *_headers) {
  NGMimeBodyPart *part;
  NGMimeFileData *data;

  data = [[[NGMimeFileData alloc] initWithPath:
                                  [_headers objectForKey:@"AttachmentBlobPath"]
                                  removeFile:NO] autorelease];
  [_headers removeObjectForKey:@"AttachmentBlobPath"];
  part = [[NGMimeBodyPart alloc] initWithHeader:
                                 convertDictToMap(self, _headers)];
  [part setBody:data];
  return [part autorelease];
}

static inline id buildPart(id self, NSString *_content, BOOL _isText) {
  NGMimeBodyPart      *part;
  NSMutableDictionary *header;

  header = [NSMutableDictionary dictionaryWithCapacity:4];

  [header setObject:_isText ? @"text/plain" : @"text/html"
          forKey:@"content-type"];

  part = [[NGMimeBodyPart alloc] initWithHeader:
                                 convertDictToMap(self ,header)];
  [part setBody:_content];
  return [part autorelease];
}

static inline id buildAlternativePart(id self, NSString *_txt,
                                      NSString *_html) {
  NGMimeBodyPart      *part;
  NGMimeMultipartBody *body;
  NSMutableDictionary *header;

  header = [NSMutableDictionary dictionaryWithCapacity:4];

  [header setObject:@"multipart/alternative" forKey:@"content-type"];

  part = [[NGMimeBodyPart alloc]
                          initWithHeader:convertDictToMap(self, header)];
  
  body = [[NGMimeMultipartBody alloc] initWithPart:part];
  [body addBodyPart:buildPart(self, _txt, YES)];
  [body addBodyPart:buildPart(self, _html, NO)];
  [part setBody:body];
  [body release]; body = nil;
  return [part autorelease];
}


static inline id buildTextPart(id self,
                               NSString *_contentType,
                               NSString *_txt,
                               NSString *_html)
{
  if ([_contentType hasPrefix:@"multipart"]) {
    if (_html != _txt) {
      return buildAlternativePart(self, _txt, _html);
    }
    else if (_html) {
      return buildPart(self, _html, NO);
    }
    else 
      return buildPart(self, _txt, YES);
  }
  else {
    return _txt;
  }
}


static inline NSMutableArray *loadAttachments(id self, NSString *_path) {
  NSString       *attPath;
  NSMutableArray *attachments;
  
  attPath = [_path stringByAppendingPathComponent:@"attachments.plist"];

  if (![fm() fileExistsAtPath:attPath isDirectory:NO]) {
    attachments = [NSMutableArray array];
  }
  else {
    attachments = [NSMutableArray arrayWithContentsOfFile:attPath];
  }
  return attachments;
}

#endif /* __DirectAction_Mails_H__ */
