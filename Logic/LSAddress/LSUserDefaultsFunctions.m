/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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
// $Id$

#include "LSUserDefaultsFunctions.h"
#include "common.h"

// TODO: replace this function junk with a proper method!
// TODO: fix for Apple Foundation which has no searchList

NSString *__getUserDefaultsPath_LSLogic_LSAddress(id self, id _context,
                                                  NSNumber *_uid)
{
  static NSString *LSAttachmentPath = nil;
  NSString *fileName;
  
  if (LSAttachmentPath == nil) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    LSAttachmentPath = [ud stringForKey:@"LSAttachmentPath"];
    if ([LSAttachmentPath length] == 0)
      NSLog(@"ERROR: LSAttachmentPath default is not set!");
  }
  
  fileName = [[_uid stringValue] stringByAppendingPathExtension:@"defaults"];
  return [LSAttachmentPath stringByAppendingPathComponent:fileName];
}

NSMutableDictionary *__getUserDefaults_LSLogic_LSAddress(id self, id _context,
                                                         NSNumber *_uid)
{
  NSMutableDictionary *def;
  NSString            *fileName;
  NSFileManager       *manager;

  def      = nil;
  manager  = [NSFileManager defaultManager];
  fileName = __getUserDefaultsPath_LSLogic_LSAddress(self, _context, _uid);
  
  if ([manager fileExistsAtPath:fileName]) {
    def = [[[NSMutableDictionary alloc] initWithContentsOfFile:fileName]
                                 autorelease];
  }
  else {
    def = [NSMutableDictionary dictionaryWithCapacity:64];
  }
  return def;
}

void __writeUserDefaults_LSLogic_LSAddress(id self,id _context,
                                           NSMutableDictionary *_defaults,
                                           NSNumber *_uid)
{
  NSString *path;
  
  path = __getUserDefaultsPath_LSLogic_LSAddress(self, _context, _uid);
  [self assert:[_defaults writeToFile:path atomically:YES]
        reason:@"Couldn`t write User-Defaults"];
}

void __registerVolatileLoginDomain_LSLogic_LSAddress(id self, id _context,
                                                     NSUserDefaults *_defaults,
                                                     NSDictionary *_domain,
                                                     NSNumber *_uid)
{
  NSString       *domainName, *argDomainName;
  NSMutableArray *searchList;
  NSDictionary   *argDomain;

  argDomainName = @"NSArgumentDomain";
  domainName    = [_uid stringValue];

  _domain       = [_domain retain];
  
  if ([_defaults volatileDomainForName:domainName] != nil)
    [_defaults removeVolatileDomainForName:domainName];

  [_defaults setVolatileDomain:_domain forName:domainName];

  [_domain release];
  
  searchList = [[_defaults searchList] mutableCopyWithZone:NULL];
  NSCAssert(searchList, @"missing search list !");
  {
    int idx;
    
    if ((idx = [searchList indexOfObject:domainName]) == NSNotFound) {
      [searchList insertObject:domainName atIndex:0];
    }
    else if (idx != 0) {
      [searchList removeObjectAtIndex:idx];
      [searchList insertObject:domainName atIndex:0];
    }
  }
  {
    int idx;

    argDomain = [_defaults volatileDomainForName:argDomainName];
    
    if ((idx = [searchList indexOfObject:argDomainName]) != NSNotFound) {
      [searchList removeObjectAtIndex:idx];
      [searchList insertObject:argDomain atIndex:0];
    }
  }
  [_defaults setSearchList:searchList];
  [searchList release]; searchList = nil;
}
