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

#import <NGObjWeb/WOComponent.h>

/*
  TODO: check whether this class can be removed, seems so:
    Skyrix41e/WebUI> find . -type f -exec grep -l SkyEmbedForm \{\} \;
    ./Project/SkyProject4/ChangeLog
    ./SkyForms/CVS/Entries
    ./SkyForms/SkyEmbedForm.m
    ./SkyForms/README
*/

@class NSString, NSURL, NSData;
@class WOElement, WOComponent;

@interface SkyEmbedForm : WOComponent
{
  NSURL       *formURL;                  /* in binding  */
  NSString    *formName;                 /* in binding  */
  NSString    *formClassName;            /* in binding  */
  NSString    *componentDefinitionClass; /* in binding  */
  NSData      *formData;                 /* in binding  */

  /* form cache */
  WOComponent *formComponent;         /* out binding */
  WOElement   *template;
}

@end

#import <NGObjWeb/NGObjWeb.h>
#include <OGoForms/SkyComponentDefinition.h>
#include "common.h"
#include "used_privates.h"
#include "WOComponent+Forms.h"

@implementation SkyEmbedForm

+ (int)version {
  return [super version] + 0 /* v2 */;
}
+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (void)dealloc {
  [self->template      release];
  [self->formData      release];
  [self->formComponent release];
  [self->componentDefinitionClass release];
  [self->formClassName release];
  [self->formName      release];
  [self->formURL       release];;
  [super dealloc];
}

/* accessors */

- (void)_clearFormInfo:(SEL)_callsite {
  if (self->formComponent) {
    [self debugWithFormat:@"release form in %@.",
            NSStringFromSelector(_callsite)];
    [self->formComponent release]; self->formComponent = nil;
  }
  if (self->template) {
    [self debugWithFormat:@"release form template in %@.",
            NSStringFromSelector(_callsite)];
    [self->template release]; self->template = nil;
  }
}

- (void)setFormURL:(id)_url {
  NSURL *nsurl;
  
  nsurl = ([_url isKindOfClass:[NSURL class]])
    ? _url
    : [NSURL URLWithString:[_url stringValue]];
  
  if (![self->formURL isEqual:nsurl]) {
    //NSLog(@"%@ != %@", formURL, nsurl);
    [self _clearFormInfo:_cmd];
    ASSIGNCOPY(self->formURL, nsurl);
  }
}
- (NSURL *)formURL {
  return self->formURL;
}

- (void)setFormData:(NSData *)_data {
  if (![_data isEqual:self->formData]) {
    [self _clearFormInfo:_cmd];
    ASSIGNCOPY(self->formData, _data);
  }
}
- (NSData *)formData {
  return self->formData;
}

- (void)setFormName:(NSString *)_formName {
  if (![self->formName isEqualToString:_formName]) {
    ASSIGNCOPY(self->formName, _formName);
    [self _clearFormInfo:_cmd];
  }
}
- (NSString *)formName {
  return self->formName;
}

- (void)setFormClassName:(NSString *)_formClassName {
  if (![self->formClassName isEqualToString:_formClassName]) {
    ASSIGNCOPY(self->formClassName, _formClassName);
    [self _clearFormInfo:_cmd];
  }
}
- (NSString *)formClassName {
  return self->formClassName;
}

- (void)setComponentDefinitionClass:(NSString *)_componentDefinitionClass {
  if (![self->componentDefinitionClass isEqualToString:
            _componentDefinitionClass]) {
    ASSIGNCOPY(self->componentDefinitionClass, _componentDefinitionClass);
    [self _clearFormInfo:_cmd];
  }
}
- (NSString *)componentDefinitionClass {
  return self->componentDefinitionClass;
}

/* get the form */

- (NSStringEncoding)formContentEncoding {
  return NSISOLatin1StringEncoding;
}

- (WOComponent *)formComponent {
  NSData   *data;
  NSString *contentString;
  NSString *fname;
  Class    formClazz;

  fname = (self->formName)
    ? self->formName
    : [self->formURL absoluteString];
  
  formClazz = self->formClassName
    ? NSClassFromString(self->formClassName)
    : NSClassFromString(fname);
  
  if ((data = [self formData]) == nil) {
    NSString    *ctype;
    NSURLHandle *handle;
    
    if ((handle = [self->formURL URLHandleUsingCache:YES]) == nil) {
      [self logWithFormat:@"couldn't get handle for URL %@", self->formURL];
      return nil;
    }
    
    //[self debugWithFormat:@"use URL handle: %@", handle];
  
    ctype = [[[handle propertyForKey:@"content-type"] copy] autorelease];
    data  = [[[handle resourceData] copy] autorelease];

    [handle flushCachedData];
    
    if (data == nil) {
      [self debugWithFormat:@"got no data for url: %@", self->formURL];
      return nil;
    }
  }

  contentString =
    [[NSString alloc] initWithData:data encoding:[self formContentEncoding]];
  contentString = [contentString autorelease];
  
  self->formComponent = 
    [self formWithName:fname
          componentClass:formClazz
          content:contentString];

  return self->formComponent;
}

/* provide the template for this form (a component-reference) .. */

- (void)setTemplate:(WOElement *)_template {
  ASSIGN(self->template, _template);
}

- (WOElement *)templateWithName:(NSString *)_name {
  WODynamicElement    *cref;
  NSMutableDictionary *assocs;
  
  if (self->template)
    return self->template;
  
  /* setup associations */
  
  assocs = [NSMutableDictionary dictionaryWithCapacity:4];
  
  [assocs addEntriesFromDictionary:[self _bindings]];
  
  [assocs setObject:[WOAssociation associationWithKeyPath:@"formComponent"]
          forKey:@"component"];
  
  //[self debugWithFormat:@"apply bindings: %@", assocs];
  
  /* instantiate element */
  
  cref = [NSClassFromString(@"WOComponentReference") alloc];
  cref = [cref initWithName:_name associations:assocs template:nil];

  /* set element as template & return */
  
  [self setTemplate:cref];
  
  return self->template;
}

@end /* SkyEmbedForm */
