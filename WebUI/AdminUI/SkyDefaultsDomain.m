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

#include "SkyDefaultsDomain.h"
#include "common.h"
#include "SkyDefaultsElement.h"

@implementation SkyDefaultsDomain

- (id)initWithDictionary:(NSDictionary *)_dict forLanguage:(NSString *)_l
  domain:(NSString *)_domain localization:(id)_loc
{
  if ((self = [super init])) {
    NSString       *domainDesc;
    NSEnumerator   *elemEnum;
    NSDictionary   *defaultElem;
    NSArray        *dictElements;
    NSMutableArray *dElements;
    
    domainDesc      = [[_dict allKeys] objectAtIndex:0];
    self->name      = [domainDesc retain];
    self->domain    = [_domain retain];
    self->oldDomain = [[[NSUserDefaults standardUserDefaults]
                                        persistentDomainForName:_domain]
                                        retain];

    self->localization = [_loc retain];

    dictElements = [_dict valueForKey:domainDesc];
    dElements    = [NSMutableArray arrayWithCapacity:[dictElements count]];
    elemEnum     = [dictElements objectEnumerator];
    
    while ((defaultElem = [elemEnum nextObject])) {
      SkyDefaultsElement *elem;
      NSString           *defaultName;

      defaultName = [defaultElem valueForKey:@"name"];
      elem        = [SkyDefaultsElement elementWithDictionary:defaultElem
                                        forLanguage:_l
                                        withValue:
                                        [self->oldDomain valueForKey:
                                                              defaultName]];
      if (elem != nil)
        [dElements addObject:elem];
    }
    self->domainElements = [dElements copy];
    self->isVisible      = NO;
  }
  return self;
}

- (id)init {
  return [self initWithDictionary:nil forLanguage:nil domain:nil
               localization:nil];
}

+ (SkyDefaultsDomain *)domainWithDictionary:(NSDictionary *)_dict
  forLanguage:(NSString *)_lang domain:(NSString *)_domain
  localization:(id)_loc
{
  return [[[self alloc] initWithDictionary:_dict
                        forLanguage:_lang domain:_domain localization:_loc]
                 autorelease];
}

- (void)dealloc {
  [self->name           release];
  [self->domainElements release];
  [self->domain         release];
  [self->localization   release];
  [super dealloc];
}

/* accessors */

- (NSString *)name {
  return self->name;
}

- (NSArray *)domainElements {
  return self->domainElements;
}

- (void)setIsVisible:(BOOL)_visible {
  self->isVisible = _visible;
}
- (BOOL)isVisible {
  return self->isVisible;
}

- (NSString *)domain {
  return self->domain;
}

- (void)setErrorString:(NSString *)_errorString {
  ASSIGNCOPY(self->errorString, _errorString);
}
- (NSString *)errorString {
  return self->errorString;
}

/* actions */

- (BOOL)saveAllElements {
  // TODO: split up this big method
  NSMutableDictionary *newDomain;
  NSEnumerator        *elemEnum;
  SkyDefaultsElement  *element;
  BOOL                hasChanged;
  NSDictionary        *curDomain;
  

  hasChanged = NO;
  curDomain  = [[NSUserDefaults standardUserDefaults]
                                persistentDomainForName:[self domain]];

  newDomain  = (curDomain != nil)
    ? [curDomain mutableCopy]
    : [[NSMutableDictionary alloc] initWithCapacity:4];
  
  elemEnum = [[self domainElements] objectEnumerator];
  while ((element = [elemEnum nextObject])) {
    NSString *elemName;
    id       vOld, vNew, vCur;

    elemName = [element name];

    if ([elemName hasSuffix:@"_version"])
      continue;
    
    
    vOld     = [self->oldDomain valueForKey:elemName];
    vNew     = [newDomain valueForKey:elemName];

    if ((vNew != nil) && (vOld != nil)) {
      if (![[vOld stringValue] isEqualToString:[vNew stringValue]]) {
        [self setErrorString:
              [NSString stringWithFormat:
                        [self->localization valueForKey:
                              @"ValuesDontMatchError"], vOld, vNew]];
        return NO;
      }
    }

    if ((vCur = [element value]) != nil) {
      BOOL addValue;

      addValue = YES;
      
      if (vNew != nil) {
        if ([[vCur stringValue] isEqualToString:[vNew stringValue]])
          addValue = NO;
      }

      if (addValue) {
        int version;
        NSString *vElem;

        vElem   = [elemName stringByAppendingString:@"_version"];
        version = [[curDomain objectForKey:vElem] intValue];
        version++;

        [newDomain takeValue:[NSNumber numberWithInt:version] forKey:vElem];
        [newDomain takeValue:vCur forKey:elemName];
        hasChanged = YES;
      }
    }
  }

  if (hasChanged) {
    NSUserDefaults *ud;
    NSString       *domainName;

    ud         = [NSUserDefaults standardUserDefaults];
    domainName = [self domain];

    [ud removePersistentDomainForName:domainName];
    [ud setPersistentDomain:newDomain forName:domainName];

    if (![ud synchronize]) {
      [self setErrorString:@"SyncFailedError"];
      return NO;
    }
  }
  ASSIGN(self->oldDomain, newDomain);
  [newDomain release]; newDomain = nil;
  [[NSUserDefaults standardUserDefaults] makeStandardDomainSearchList];
  return YES;
}

@end /* SkyDefaultsDomain */
