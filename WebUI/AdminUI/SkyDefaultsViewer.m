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

#include "SkyDefaultsViewer.h"
#include "common.h"
#include "SkyDefaultsDomain.h"
#include "SkyDefaultsElement.h"
#include "SkyDefaultsEditor.h"

@interface NSObject(Priv)
- (NSDictionary *)loadPersistentDomainNamed:(id)_n;
@end /* NSObject(Priv) */
@implementation SkyDefaultsViewer

- (void)_initDefaults {
  NSArray         *fileNames;
  NSEnumerator    *fileEnum;
  NSString        *fileName;
  NSBundle        *bundle;
  NSMutableArray  *foundDefaults;
  NSString        *envLanguage;
  
  ASSIGN(self->defaults, nil);
  
  envLanguage = [[[[self session] commandContext] userDefaults]
                         valueForKey:@"language"];

  if (envLanguage == nil)
    envLanguage = @"English";
  else
    envLanguage = [[envLanguage componentsSeparatedByString:@"_"]
                                objectAtIndex:0];
  
  bundle    = [NGBundle bundleForClass:[self class]];

  if (self->domains == nil) {
    fileNames = [NSArray arrayWithObjects:@"Skyrix.plist",
                         @"NSGlobalDomain.plist", @"skyxmlrpcd.plist",
                         @"snsd.plist", @"skyaptnotify.plist" ,nil];
  }
  else {
    NSEnumerator *enumerator;
    NSString     *str;

    enumerator = [self->domains objectEnumerator];
    fileNames  = [NSMutableArray arrayWithCapacity:[self->domains count]];
    while ((str = [enumerator nextObject])) {
      [(NSMutableArray *)fileNames addObject:
                         [str stringByAppendingPathExtension:@"plist"]];
    }
  }

  foundDefaults = [NSMutableArray arrayWithCapacity:[fileNames count]];
  fileEnum      = [fileNames objectEnumerator];
  
  while ((fileName = [fileEnum nextObject])) {
    NSString *path;
    NSString *domainName;

    domainName = [fileName stringByDeletingPathExtension];
    path       = [bundle pathForResource:domainName
                         ofType:[fileName pathExtension]];

    if (path != nil) {
      NSDictionary *fileContents;

      fileContents = [NSDictionary dictionaryWithContentsOfFile:path];
      if (fileContents != nil) {
        SkyDefaultsDomain *dd;

        dd = [SkyDefaultsDomain domainWithDictionary:fileContents
                                forLanguage:envLanguage
                                domain:domainName
                                localization:[self labels]];
        if (dd != nil)
          [foundDefaults addObject:dd];
      }
      else
        [self logWithFormat:@"Error: File '%@' seems to be broken", path];
    }
    else
      [self logWithFormat:@"Error: Didn't find path for file '%@'", fileName];
  }

  self->defaults = [foundDefaults copy];
}

- (void)dealloc {
  [self->defaults             release];
  [self->domains              release];
  [self->currentDomain        release];
  [self->currentDomainElement release];
  [super dealloc];
}

- (void)awake {
  NSUserDefaults *ud;
  NSEnumerator   *enumerator;
  id             obj;

  ud = [NSUserDefaults standardUserDefaults];

  enumerator = [self->domains objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    if ([obj isEqualToString:@"NSGlobalDomain"])
      continue;
    
    if (([ud persistentDomainForName:obj])) {
      [ud removePersistentDomainForName:obj];
      [ud setPersistentDomain:[(id)ud loadPersistentDomainNamed:obj] forName:obj];
    }
  }
  [ud synchronize];
  
  ASSIGN(self->defaults, nil);
  [super awake];
}


/* accessors */

- (NSArray *)defaults {
  if (self->defaults == nil)
    [self _initDefaults];
  return self->defaults;
}

- (void)setCurrentDomain:(SkyDefaultsDomain *)_dm {
  ASSIGN(self->currentDomain, _dm);
}
- (SkyDefaultsDomain *)currentDomain {
  return self->currentDomain;
}

- (void)setCurrentDomainElement:(SkyDefaultsElement *)_de {
  ASSIGN(self->currentDomainElement, _de);
}
- (SkyDefaultsElement *)currentDomainElement {
  return self->currentDomainElement;
}


/* actions */

- (id)edit {
  SkyDefaultsEditor *editor;

  editor = [self pageWithName:@"SkyDefaultsEditor"];
  [editor setDomain:currentDomain];
  
  return editor;
}

- (void)setDomains:(NSArray *)_domains {
  if ([_domains isKindOfClass:[NSArray class]]) {
    ASSIGN(self->domains, _domains);
  }
  else {
    ASSIGN(self->domains,nil);
    if (_domains) {
      self->domains = [[NSArray alloc] initWithObjects:&_domains count:1];
    }
  }
}

- (NSArray *)domains {
  return self->domains;
}

- (BOOL)isVisible {
  return [[[[self session] commandContext] userDefaults]
                  boolForKey:
                  [@"domain_is_visible_" stringByAppendingString:
                    [self->currentDomain name]]];
}
- (void)setIsVisible:(BOOL)_b {
  [[[[self session] commandContext] userDefaults]
           takeValue:[NSNumber numberWithBool:_b]
           forKey:[@"domain_is_visible_" stringByAppendingString:
                    [self->currentDomain name]]];
}

@end /* SkyDefaultsViewer */
