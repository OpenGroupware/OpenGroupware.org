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

#include "RegistryEntry.h"
#include "common.h"
#include "SkyRegistryApplication.h"
#include "SkyIDLTag+XmlRpcType.h"

#include <NGXmlRpc/NGXmlRpcClient.h>
#include <OGoIDL/SkyIDL.h>

@implementation RegistryEntry

- (id)init {
  return [self initWithName: nil dictionary:nil];
}

- (void)initIDLInterfaceFromFile:(NSString *)_file {
  if ([[NSFileManager defaultManager] fileExistsAtPath:_file])
    self->interface = [[SkyIDLSaxBuilder parseInterfaceFromContentsOfFile:
                                         _file] retain];
  else
    [self logWithFormat:@"IDL location specified : %@ - file not found",
          _file];
}

- (id)initWithName:(NSString *)_name dictionary:(NSDictionary *)_dict {
  if ((self = [super init])) {
    NSString *idlPath;
    NSString *tmp;
    
    self->entryName = [_name copy];
    self->namespace = [[_dict objectForKey:@"namespace"] copy];

    if ((tmp = [_dict objectForKey:@"check"]) != nil)
      self->check = [tmp boolValue];
    else
      self->check = YES;

    self->url       = [[NSURL alloc]
                              initWithString:[_dict objectForKey:@"url"]];
    self->registrationDate = [[NSCalendarDate calendarDate] retain];
    
    if ((idlPath = [_dict objectForKey:@"idl"]) != nil)
      [self initIDLInterfaceFromFile:idlPath];

    self->client = [[NGXmlRpcClient alloc] initWithHost:[self->url host]
                                           uri:[self->url path]
                                           port:[[self->url port] intValue]
                                           userName:nil
                                           password:nil];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->entryName);
  RELEASE(self->namespace);
  RELEASE(self->url);
  RELEASE(self->registrationDate);
  RELEASE(self->interface);
  RELEASE(self->client);
  [super dealloc];
}

/* accessors */

- (NSString *)entryName {
  return self->entryName;
}

- (NSString *)namespace {
  return self->namespace;
}

- (NSURL *)url {
  return self->url;
}

- (SkyIDLInterface *)interface {
  return self->interface;
}

- (NSString *)fqMethodNameForMethod:(NSString *)_methodName {
  if (self->namespace == nil)
    return _methodName;

  return [[self->namespace stringByAppendingString:@"."]
                           stringByAppendingString:_methodName];
}

/* introspection methods */

- (NSArray *)methodsForComponent {
  if(self->interface != nil)
    return [self->interface methodNames];

  return nil;
}

- (NSArray *)listMethods {
  NSArray     *result;
  if ((result = [self methodsForComponent]) != nil)
    return result;

  if (self->client != nil)
    return [self->client call:@"system.listMethods",nil];
  return nil;
}

- (NSArray *)signaturesForMethodNamed:(NSString *)_method {
  if(self->interface != nil) {
    id method;

    if ((method = [self->interface methodWithName:_method]) != nil) {
      NSArray *signatures;

      signatures =  [[self->interface methodWithName:method] signatures];

      if (signatures != nil) {
        NSMutableArray *result;
        NSEnumerator   *sigEnum;
        id              sigElem;

        sigEnum = [signatures objectEnumerator];
        
        result = [NSMutableArray arrayWithCapacity:[signatures count]];
        while((sigElem = [sigEnum nextObject])) {
          NSArray *signature;

          signature = [NSArray arrayWithObjects:
                               [(id)[sigElem outputs] xmlrpcTypeForSOAPType],
                               [(id)[sigElem inputs] xmlrpcTypeForSOAPType],
                               nil];
          [result addObject:signature];
        }
        return result;
      }
    }
  }    
  return nil;
}

- (NSArray *)methodSignature:(NSString *)_method {
  NSArray  *result;

#warning check if this method already needs the fqMethodName
  if((result = [self signaturesForMethodNamed:_method]) != nil)
    return result;

  NSLog(@"%s: entryname: %@", __PRETTY_FUNCTION__, self->entryName);
  NSLog(@"%s: namespace: %@", __PRETTY_FUNCTION__, self->namespace);

  _method = [self fqMethodNameForMethod:_method];

  if (self->client != nil)
    return [self->client call:@"system.methodSignature", _method, nil];

  return nil;
}

- (NSString *)helpForMethodNamed:(NSString *)_methodName {
  if(self->interface != nil) {
    id method;

    method = [self->interface methodWithName:_methodName];
    if (method != nil)
      return  [[method example] characters];
  }
  return nil;
}

- (NSString *)methodHelp:(NSString *)_method {
  NSString *result;

#warning check if this method already needs the fqMethodName (see above)
  if ((result = [self helpForMethodNamed:_method]) != nil)
    return result;

  _method = [self fqMethodNameForMethod:_method];
  
  if (self->client) {
    return [self->client call:@"system.methodHelp", _method, nil];
  }
  return nil;
}

/* timeout */

- (BOOL)entryTimedOut {
  SkyRegistryApplication *app;
  int timeout;

  if (!self->check)
    return NO;
  
  app = (SkyRegistryApplication *)[WOApplication application];

  timeout = [app checkInterval];
  timeout += ((timeout / 10) < 5)
    ? 5
    : (timeout/10);

  if (-[self->registrationDate timeIntervalSinceNow] > timeout)
    return YES;
  return NO;
}

/* description */

- (NSString *)description {
  return [NSString stringWithFormat:@"<0x%08X[%@]: %@>",
                     self, NSStringFromClass([self class]),
                     self->entryName];
}

@end /* RegistryEntry */
