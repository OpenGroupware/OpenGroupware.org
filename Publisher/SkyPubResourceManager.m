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

#include "SkyPubResourceManager.h"
#include "SkyPubComponentDefinition.h"
#include "SkyPubComponent.h"
#include "SkyPubFileManager.h"
#include "SkyDocument+Pub.h"
#include "common.h"

@interface WOResourceManager(FM)
- (id<NSObject,NGFileManager>)fileManager;

- (id)definitionForComponent:(id)_name
  languages:(NSArray *)_languages;
@end

static int profile = -1;

@implementation SkyPubResourceManager

+ (int)version {
  return [super version] + 0 /* v4 */;
}
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL isInitialized = NO;
  if (isInitialized) return;
  isInitialized = YES;
  NSAssert2([super version] == 4,
	    @"invalid superclass (%@) version %i !",
	    NSStringFromClass([self superclass]), [super version]);
  
  profile = [ud boolForKey:@"ProfilePubResourceManager"] ? 1 : 0;
}

- (id)initWithFileManager:(id)_fm {
  if ((self = [self initWithPath:nil]) == nil) {
    NSLog(@"%s: superclass initialization failed !", __PRETTY_FUNCTION__);
    [self release];
    return nil;
  }
  
  self->fileManager = [_fm retain];
  return self;
}
- (id)init {
  return [self initWithFileManager:nil];
}
- (void)dealloc {
  [self->masterTemplateName release];
  [self->fileManager        release];
  [super dealloc];
}

/* accessors */

- (void)setMasterTemplateName:(NSString *)_name {
  ASSIGNCOPY(self->masterTemplateName, _name);
}
- (NSString *)masterTemplateName {
  return self->masterTemplateName ? self->masterTemplateName : @"Main";
}

- (id)fileManager {
  return self->fileManager;
}

/* pathes */

- (NSString *)pathToComponentNamed:(NSString *)_name
  inFramework:(NSString *)_fw
  languages:(NSArray *)_langs
{
  if ([_name isAbsolutePath])
    return _name;

#if 0
  NSLog(@"%s: lookup '%@' using WOResourceManager ...",
        __PRETTY_FUNCTION__, _name);
#endif
  
  return [super pathToComponentNamed:_name
                inFramework:_fw
                languages:_langs];
}

/* component definitions */

- (id)definitionForComponent:(NSString *)_name
  languages:(NSArray *)_languages
{
  SkyPubComponentDefinition *cdef;
#if CHECK_WO_ATTR
  id       templDoc = nil;
  NSString *woName  = nil;
#endif
  NSDate   *date;
  
  if (_name == nil)
    return nil;

  if (profile)
    date = [NSDate date];
  else
    date = nil;
  
  if (![_name isAbsolutePath]) {
    NSLog(@"%s: def for '%@' using WOResourceManager ...",
          __PRETTY_FUNCTION__, _name);
    return [super definitionForComponent:_name languages:_languages];
  }

#if CHECK_WO_ATTR
  templDoc = [(id)self->fileManager documentAtPath:_name];
  woName   = [templDoc valueForKey:@"wo"];
  
  if ([woName length] > 0) {
    NSLog(@"%s: def for '%@' (wo=%@) using WOResourceManager ...",
          __PRETTY_FUNCTION__, _name, woName);
    return [super definitionForComponent:woName languages:_languages];
  }
#endif
  
  cdef = [[SkyPubComponentDefinition alloc]
                                     initWithName:_name path:_name
                                     baseURL:nil frameworkName:nil];

  if (cdef) {
    if (profile) {
      NSLog(@"RM: cdef creation %@: %.3fs", _name,
            [[NSDate date] timeIntervalSinceDate:date]);
    }
    
    [cdef setFileManager:[self fileManager]];
  }

  return AUTORELEASE(cdef);
}

@end /* SkyPubResourceManager */

@implementation WOResourceManager(Additions)

static NSNumber *boolYes = nil;

- (NSString *)masterTemplateName {
  return @"Main";
}
- (NSString *)templateExtension {
  return @"xtmpl";
}

/* WARNING: -templateWithName:languages: is already defined in
   WOResourceManager */

- (id)templateWithName:(NSString *)_name atPath:(NSString *)_path {
  SkyPubFileManager *fileManager;
  WOComponent       *template;
  NSDate   *date;
  NSString *tpath;
  
  if (boolYes == nil)
    boolYes = [[NSNumber numberWithBool:YES] retain];
  if ((fileManager = (SkyPubFileManager *)[self fileManager]) == nil)
    return nil;

  if (profile)
    date = [NSDate date];
  else
    date = nil;
  
  if (_name == nil) {
    /* mastertemplate ... */
    _name = [[self masterTemplateName]
                   stringByAppendingPathExtension:[self templateExtension]];
  }
  
  if ([[_name pathExtension] length] == 0)
    _name = [_name stringByAppendingPathExtension:[self templateExtension]];
  
  if ([_name isAbsolutePath]) {
    tpath = _name;
  }
  else {
    NSString *p;
    BOOL    isDir;
    
    tpath = nil;
    
    if (![fileManager fileExistsAtPath:_path isDirectory:&isDir])
      p = nil;
    else if (isDir)
      p = _path;
    else
      p = [_path stringByDeletingLastPathComponent];
    
    while ([p length] > 0) {
      NSString *tp;
      
      tp = [p stringByAppendingPathComponent:_name];
      if ([fileManager fileExistsAtPath:tp]) {
        tpath = tp;
        break;
      }
      if ([p isEqualToString:@"/"]) break;
      
      p = [p stringByDeletingLastPathComponent];
    }
  }
  
  if (profile) {
    NSLog(@"RM: template %@ lookup '%@': %.3fs", _name, _path,
          [[NSDate date] timeIntervalSinceDate:date]);
  }
  
  if ([tpath length] == 0)
    return nil;
  
  template = [self pageWithName:tpath languages:nil];
  if ([template respondsToSelector:@selector(setResourceManager:)])
    [(id)template setResourceManager:self];
  [template takeValue:boolYes forKey:@"isTemplate"];
  
  if (profile) {
    NSLog(@"RM: template %@ lookup + instantiation '%@': %.3fs", _name, _path,
          [[NSDate date] timeIntervalSinceDate:date]);
  }
  
  return template;
}

@end /* WOResourceManager */
