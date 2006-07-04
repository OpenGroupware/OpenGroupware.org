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

#include "SkyP4ProjectResourceManager.h"
#include "SkyP4ViewerFormComponent.h"
#include "common.h"

@interface WOResourceManager(Privates)
- (NSString *)pathToComponentNamed:(NSString *)_name
  inFramework:(NSString *)_framework;
- (id)definitionForComponent:(NSString *)_name
  languages:(NSArray *)_languages;
- (id)_dataForKey:(NSString *)_key sessionID:(NSString *)_sid;
- (NSString *)labelForKey:(NSString *)_key component:(NSString *)_component;
@end

@implementation SkyP4ProjectResourceManager

- (id)initWithFormComponent:(SkyP4ViewerFormComponent *)_form {
  if ((self->formComponent = _form) == nil) {
    RELEASE(self);
    return nil;
  }
  self->parentRM = [[[self->formComponent parent] resourceManager] retain];
  return self;
}
- (void)dealloc {
  RELEASE(self->cache);
  RELEASE(self->parentRM);
  [super dealloc];
}

/* fallback rm */

- (WOResourceManager *)parentResourceManager {
  if (self->parentRM)
    return self->parentRM;
  return [[self->formComponent parent] resourceManager];
}

/* methods */

- (NSString *)pathForResourceNamed:(NSString *)_name
  inFramework:(NSString *)_frameworkName
  languages:(NSArray *)_languages
{
  NSString *path;
  
  path = [[self parentResourceManager]
                pathForResourceNamed:_name
                inFramework:_frameworkName
                languages:_languages];

  return path;
}

- (NSString *)urlForResourceNamed:(NSString *)_name
  inFramework:(NSString *)_frameworkName
  languages:(NSArray *)_languages
  request:(WORequest *)_request
{
  NSString *url;
  id fm;

  /* check whether URL is cached */
  
  if ((url = [self->cache objectForKey:_name])) {
    if (![url isNotNull])
      return nil;
    
    return url;
  }

  if (self->cache == nil)
    self->cache = [[NSMutableDictionary alloc] initWithCapacity:16];

  /* check system tree */

  url = [[self parentResourceManager]
               urlForResourceNamed:_name
               inFramework:_frameworkName
               languages:_languages
               request:_request];
  
  if (url) {
    /* store URL in cache */
    [self->cache setObject:url forKey:_name];
    return url;
  }
  
  /* check filemanager tree */
  
  if ((fm = [self->formComponent fileManager])) {
    NSString *path;
    NSString *pname;
    
    if ([_name isAbsolutePath])
      path = _name;
    else { /* could support languages and Resources here ... */
      path = [self->formComponent name];
      path = [path stringByDeletingLastPathComponent];
      path = [path stringByAppendingPathComponent:_name];
    }
    
    pname = [[fm fileSystemAttributesAtPath:path]
                 objectForKey:@"NSFileSystemName"];
    
    if ([fm fileExistsAtPath:path]) {
      url = [[self->formComponent context]
                                  p4documentURLForProjectNamed:pname
                                  path:path
                                  versionTag:nil];
      if (url) {
        /* store URL in cache .. */
        [self->cache setObject:url forKey:_name];
        return url;
      }
    }
  }
  
  [self->cache setObject:[NSNull null] forKey:_name];
  return nil;
}

- (NSString *)stringForKey:(NSString *)_key
  inTableNamed:(NSString *)_tableName
  withDefaultValue:(NSString *)_default
  languages:(NSArray *)_languages
{
  return [[self parentResourceManager]
                stringForKey:_key
                inTableNamed:_tableName
                withDefaultValue:_default
                languages:_languages];
}

- (NSString *)labelForKey:(NSString *)_key component:(NSString *)_component {
  return [[self parentResourceManager] labelForKey:_key component:_component];
}

/* component definitions */

- (NSString *)pathToComponentNamed:(NSString *)_name
  inFramework:(NSString *)_framework
{
  return [[self parentResourceManager]
                pathToComponentNamed:_name
                inFramework:_framework];
}

- (SkyComponentDefinition *)definitionForFormComponent:(NSString *)_name
  languages:(NSArray *)_languages
{
  SkyComponentDefinition     *cdef;
  id<SkyDocumentFileManager> fm;
  NSString *contentString;
  id       formDoc;

#if DEBUG
  NSAssert(self->formComponent, @"missing form component ...");
#endif
  
  if (![[_name pathExtension] isEqualToString:@"sfm"])
    return nil;
  
  /* make absolute path */
  
  if (![_name isAbsolutePath]) {
#if DEBUG
    [self->formComponent
         debugWithFormat:@"component name '%@' is not an absolute path !",
           _name];
#endif
  }
  
  /* check filemanager */
  
  if ((fm = [self->formComponent fileManager]) == nil) {
#if DEBUG
    [self->formComponent debugWithFormat:@"missing filemanager ..."];
#endif
    return nil;
  }
  
  if ((formDoc = [fm documentAtPath:_name]) == nil) {
#if DEBUG
    [self->formComponent debugWithFormat:
         @"no document exist at path '%@' ...", _name];
#endif
    return nil;
  }
  
  contentString = [formDoc contentAsString];
  
  if ((cdef = [[[SkyComponentDefinition alloc] init] autorelease]) == nil) {
    [self->formComponent logWithFormat:@"couldn't allocate comp-def !"];
    return nil;
  }
  
  [cdef setComponentName:_name];
  [cdef setComponentClass:[SkyP4ViewerFormComponent class]];
  
  if (![cdef loadFromSource:contentString]) {
    [self->formComponent logWithFormat:
           @"%s: couldn't load template of form '%@'.",
          __PRETTY_FUNCTION__,_name];
    return nil;
  }
  
  return cdef;
}

- (id)definitionForComponent:(NSString *)_name
  languages:(NSArray *)_languages
{
  id cdef;
  
  if ((cdef = [self definitionForFormComponent:_name languages:_languages])) {
#if DEBUG && 0
    [self->formComponent
         debugWithFormat:@"%s: found cdef for %@: %@", __PRETTY_FUNCTION__,
         _name, cdef];
#endif
    return cdef;
  }

#if DEBUG
  [self->formComponent
       debugWithFormat:@"%s: not a form: name=%@", __PRETTY_FUNCTION__, _name];
#endif
  
  cdef = [[self parentResourceManager]
                definitionForComponent:_name
                languages:_languages];
  return cdef;
}

/* keyed storage */

- (void)setData:(NSData *)_data
  forKey:(NSString *)_key
  mimeType:(NSString *)_type
  session:(WOSession *)_session
{
  [[self parentResourceManager]
         setData:_data forKey:_key
         mimeType:_type session:_session];
}
- (id)_dataForKey:(NSString *)_key sessionID:(NSString *)_sid {
  return [[self parentResourceManager]
                _dataForKey:_key sessionID:_sid];
}
- (void)removeDataForKey:(NSString *)_key session:(WOSession *)_session {
  [[self parentResourceManager] removeDataForKey:_key session:_session];
}
- (void)flushDataCache {
  [[self parentResourceManager] flushDataCache];
}

/* description */

- (NSString *)description {
  NSMutableString *ms;

  ms = [NSMutableString stringWithCapacity:64];

  [ms appendFormat:@"<%@[0x%p]:", [self class], self];
  [ms appendFormat:@" form=%@", self->formComponent];
  [ms appendFormat:@" rm=%@", self->parentRM];
  [ms appendString:@">"];
  return ms;
}

@end /* SkyP4ProjectResourceManager */
