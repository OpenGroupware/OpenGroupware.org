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

#include <OGoFoundation/LSWComponent.h>

@class NSString, NSDictionary, NSArray, NSUserDefaults;
@class NSMutableDictionary;

@interface SkyCompanyAttributesViewer : LSWComponent
{
  NSString       *viewerPattern;
  BOOL           isInConfigMode;
  id             company;
  NSString       *allPatternsItem;
  NSDictionary   *currentAttr;

  /* user defaults */
  NSArray        *patternsList;
  NSArray        *patternValues; 

  NSUserDefaults *defaults;
  NSString       *addressType;
}

- (void)_fetchPatternValues;

@end

#include <OGoContacts/SkyPersonDocument.h>
#include <OGoContacts/SkyEnterpriseDocument.h>
#include <OGoJobs/SkyJobDocument.h>
#import "common.h"

@implementation SkyCompanyAttributesViewer

static NSArray *PersonAttributes     = nil;
static NSArray *EnterpriseAttributes = nil;
static NSArray *JobAttributes        = nil;

- (id)init {
  if ((self = [super init])) {
    self->defaults = nil;
    
    if (PersonAttributes == nil || EnterpriseAttributes == nil ||
        JobAttributes == nil) {
      NSDictionary *dict;
      NSBundle     *bundle;
      NSString     *file;
      
       bundle = [NGBundle bundleForClass:[self class]];
       file   = [bundle pathForResource:@"SkyCompanyAttributesViewer"
                        ofType:@"plist"];
       
       dict = [NSDictionary dictionaryWithContentsOfFile:file];
       
       PersonAttributes     =
         [[dict objectForKey:@"PersonAttributes"] copy];
       EnterpriseAttributes =
         [[dict objectForKey:@"EnterpriseAttributes"] copy];
       JobAttributes        =
         [[dict objectForKey:@"JobAttributes"] copy];

    }
    self->isInConfigMode = NO;
  }
  return self;
}

- (void)dealloc {
  [self->company         release];
  [self->viewerPattern   release];
  [self->currentAttr     release];
  [self->patternsList    release];
  [self->patternValues   release];
  [self->allPatternsItem release];
  [self->defaults        release];
  [self->addressType     release];
  [super dealloc];
}

- (NSUserDefaults *)defaults {
  if (self->defaults == nil)
    self->defaults = [[[self session] userDefaults] retain];
  return self->defaults;
}

- (void)sleep {
  [[self defaults] synchronize];
  [super sleep];
}

- (NSString *)_entityName {
  if ([self->company isKindOfClass:[SkyPersonDocument class]])
    return @"Person";
  else if ([self->company isKindOfClass:[SkyPersonDocument class]])
    return @"Enterprise";
  else if ([self->company isKindOfClass:[SkyJobDocument class]])
    return @"Job";
  else if ([self->company respondsToSelector:@selector(entityName)])
    return [self->company entityName];
  else
    return nil;
}

- (void)_fetchPatternValues {
  NSDictionary *allCfg;
  NSString     *key;

  key = [[self _entityName] lowercaseString];
  key = [key stringByAppendingString:@"s_view_attributes"];
  allCfg = [[self defaults] dictionaryForKey:key];

  if ((allCfg != nil) && (self->viewerPattern != nil)) {
    NSMutableArray *pats;
    NSEnumerator   *patEnum;
    NSString       *pat;
    
    [self->patternValues release]; self->patternValues = nil;
    patEnum = [[allCfg objectForKey:self->viewerPattern] objectEnumerator];
    pats    = [NSMutableArray arrayWithCapacity:32];
    while ((pat = [patEnum nextObject])) {
      if ([pat isEqualToString:@"description"]) {
        if ([[self _entityName] isEqualToString:@"Person"])
          pat = @"nickname";
        else // it's an Enterprise
          pat = @"name";
      }
      [pats addObject:pat];
    }
    self->patternValues = [pats copy];
  }
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  if (self->viewerPattern != nil) {
    [self _fetchPatternValues];
  }
  [super appendToResponse:_response inContext:_ctx];
}

/* accessors */

- (void)setCurrentAttr:(NSDictionary *)_obj {
  ASSIGN(self->currentAttr, _obj);
}
- (NSDictionary *)currentAttr {
  return self->currentAttr;
}

- (void)setAddressType:(NSString *)_atype {
  ASSIGN(self->addressType, _atype);
}
- (NSString *)addressType {
  return self->addressType;
}

- (NSString *)_currentAttrKey {
  return [self->currentAttr valueForKey:@"key"];
}
- (NSString *)_currentAttrLabel {
  return [self->currentAttr valueForKey:@"label"];
}

- (NSString *)currentAttrLabel {
  NSString *ret;
  NSArray  *ak;
  id       labels;

  labels = [self labels];

  ak = [self->currentAttr allKeys];
  if ([ak containsObject:@"label"]) 
    ret = [labels valueForKey:[self _currentAttrLabel]];
  else
    ret = [labels valueForKey:[self _currentAttrKey]];

  if ([[self->currentAttr valueForKey:@"isPrivate"] boolValue]) {
    NSString *p;

    p = [labels valueForKey:@"private"];
    if (p == nil) p = @"private";
    ret = [ret stringByAppendingString:
               [NSString stringWithFormat:@" (%@)", p]];
  }
  return (ret == nil) ? [self _currentAttrKey] : ret;
}

- (void)setAllPatternsItem:(NSString *)_s {
  ASSIGN(self->allPatternsItem, _s);
}
- (NSString *)allPatternsItem {
  return self->allPatternsItem;
}

- (void)setIsInConfigMode:(BOOL)_b {
  self->isInConfigMode = _b;
}
- (BOOL)isInConfigMode {
  return self->isInConfigMode;
}

- (void)setViewerPattern:(NSString *)_s {
  ASSIGN(self->viewerPattern, _s);
}
- (NSString *)viewerPattern {
  return self->viewerPattern;
}

- (void)setCompany:(id)_company {
  ASSIGN(self->company, _company);
}
- (id)company {
  return self->company;
}

- (void)setPatternsList:(NSArray *)_a {}
- (NSArray *)patternsList {
  return self->patternsList;
}

- (void)setPatternValues:(NSArray *)_a {}
- (NSArray *)patternValues {
  return self->patternValues;
}

- (BOOL)allPatternsIsSelected {
  return ([self->viewerPattern isEqualToString:self->allPatternsItem]);
}

- (NSArray *)allPatternsList {
  return self->patternsList;
}

- (BOOL)isInDefaults {
  if (self->patternValues != nil) {
    return ([self->patternValues containsObject:[self _currentAttrKey]]);
  }
  /* default: all elements are visible */
  return YES;
}

- (BOOL)doHideEmpty {
  if (self->patternValues != nil) {
    return ([self->patternValues containsObject:@"nonEmptyOnly"]);
  }
  /* default: don't hide empty values */
  return NO;
}

- (BOOL)_isNullOrNil:(id)_obj {
  NSString *tmp;
  
  if (![_obj isNotNull])
    return YES;
  
  tmp = [_obj stringValue];

  if ([tmp isEqualToString:@""] || [tmp isEqualToString:@" "])
    return YES;
  
  return NO;
}

- (BOOL)isNotEmpty {
  BOOL     locVal;
  id       tobj;
  NSString *keyValue = nil;
  NSString *relKeyValue = nil;

  keyValue      = [self->currentAttr valueForKey:@"key"];
  relKeyValue   = [self->currentAttr valueForKey:@"relKey"];
  locVal = [[self->currentAttr valueForKey:@"localizeValue"] boolValue];

  tobj = self->company;

  if (keyValue != nil && relKeyValue != nil) {
    tobj = [[tobj valueForKey:keyValue] valueForKey:relKeyValue];
  }
  else if (keyValue != nil) {
    tobj = [tobj valueForKey:keyValue];
  }
  
  if ([self _isNullOrNil:tobj])
    return NO;
  
  if (locVal &&
      [self _isNullOrNil:[[self labels] valueForKey:[tobj stringValue]]]) {
    return NO;
  }
  return YES;
}

- (BOOL)isCurrentAttributeVisible {
  if (![self doHideEmpty])
    return YES;
  
  if ([self isNotEmpty])
    return YES;
  return NO;
}

- (NSArray *)attributes {
  if ([[self _entityName] isEqualToString:@"Job"])
    return JobAttributes;
  else
    return ([[self _entityName] isEqualToString:@"Person"])
      ? PersonAttributes
      : EnterpriseAttributes;
}

- (NSArray *)publicAttributes {
  NSString *key;

  key = [NSString stringWithFormat:@"SkyPublicExtended%@Attributes",
                  [self _entityName]];
  return [[self defaults] arrayForKey:key];
}

- (NSArray *)privateAttributes {
  NSString *key;

  key = [NSString stringWithFormat:@"SkyPrivateExtended%@Attributes",
                  [self _entityName]];
  return [[self defaults] arrayForKey:key];
}


- (NSString *)attributeSuffix {
  NSString *suffixLabel;

  if ([self isNotEmpty]) {
    if ((suffixLabel = [self->currentAttr valueForKey:@"suffixLabel"]) != nil){
      return [[self labels] valueForKey:suffixLabel];
    }
  }
  return nil;
}

/* address types */

- (NSArray *)addressTypes {
  return [[[self defaults] dictionaryForKey:@"LSAddressType"]
                 objectForKey:[self _entityName]];
}

- (BOOL)showAddressType {
  return [self->patternValues
              containsObject:[self valueForKey:@"addressType"]];
}

- (BOOL)isJobViewer {
  return ([[self _entityName] isEqualToString:@"Job"]);
}

- (NSString *)addressTypeLabel {
  NSString* typeL = nil;

  typeL = [NSString stringWithFormat: @"addresstype_%@",
                    [self valueForKey:@"addressType"]];
  return [[self labels] valueForKey:typeL];
}

- (id)address {
  return [self->company addressForType:[self valueForKey:@"addressType"]];
}

@end /* SkyCompanyAttributesViewer */
