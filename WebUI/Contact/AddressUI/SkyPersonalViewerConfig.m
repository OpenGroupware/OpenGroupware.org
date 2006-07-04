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

#include <OGoFoundation/OGoComponent.h>

@class NSUserDefaults, NSString, NSArray;

@interface SkyPersonalViewerConfig : OGoComponent
{
  // parameters
  NSString *viewerPattern;
  NSString *patternName;
  BOOL     isInConfigMode;
  
@private
  id             object;
  NSString       *errorString;
  NSString       *item;
  NSArray        *checkedItems;
  NSArray        *selections;
  NSUserDefaults *defaults;
  BOOL           hideEmptyFields;
  NSArray        *allAttributes;
 }
@end

#include <OGoFoundation/OGoContentPage.h>
#include <OGoContacts/SkyPersonDocument.h>
#include <OGoContacts/SkyEnterpriseDocument.h>
#include <OGoJobs/SkyJobDocument.h>
#include "common.h"

@implementation SkyPersonalViewerConfig

static NSArray *PersonKeys     = nil;
static NSArray *EnterpriseKeys = nil;
static NSArray *JobKeys        = nil;

static int compareAttributes(id attr1, id attr2, void *context) {
  NSString *name1 = nil;
  NSString *name2 = nil;

  if (attr1 == nil)
    return NSOrderedDescending;
  if (attr2 == nil)
    return NSOrderedAscending;
  
  name1 = [(id)context valueForKey:attr1];
  name2 = [(id)context valueForKey:attr2];
  
  name1 = (name1 == nil) ? (NSString *)attr1 : name1;
  name2 = (name2 == nil) ? (NSString *)attr2 : name2;
                                                        
  return [name1 caseInsensitiveCompare:name2];
}

+ (void)initialize {
  if (PersonKeys == nil) {
    PersonKeys = [[NSArray alloc] initWithObjects:@"name", @"firstname",
                                  @"middlename",@"nickname",
                                  @"degree", @"salutation",@"sex", @"url",
                                  @"birthday",@"keywords",@"owner", @"contact",
                                  @"objectVersion", @"comment", nil];
  }
  if (EnterpriseKeys == nil) {
    EnterpriseKeys = [[NSArray alloc] initWithObjects:@"owner", @"contact",
                                      @"url", @"keywords", @"comment",
                                      @"bank", @"bankCode", @"account",
                                      @"email", @"objectVersion",
                                      @"name", @"number", // ??????
                                      nil];
  }

  if (JobKeys == nil) {
    JobKeys = [[NSArray alloc] initWithObjects:@"owner", @"project",
                               @"executant",@"objectVersion",
                               @"notify",@"jobStatus",
                               @"category",@"priority",@"kind",@"keywords",
                               @"sensitivity",@"comment",
                               @"completionDate",@"percentComplete",
                               @"actualWork",@"totalWork",@"accountingInfo",
                               @"kilometers",@"associatedCompanies",
                               @"associatedContacts",nil];
  }
}

- (id)init {
  if ((self = [super init])) {
    self->defaults = nil;
  }
  return self;
}

- (void)dealloc {
  [self->object        release];
  [self->viewerPattern release];
  [self->item          release];
  [self->checkedItems  release];
  [self->selections    release];
  [self->defaults      release];
  [self->patternName   release];
  [self->allAttributes release];
  [self->errorString   release];
  [super dealloc];
}

/* defaults */

- (NSUserDefaults *)defaults {
  if (self->defaults == nil)
    self->defaults = [[[self session] userDefaults] retain];
  return self->defaults;
}

/* notifications */

- (void)syncAwake {
  [self->allAttributes release]; self->allAttributes = nil;
}

- (void)sleep {
  [self->selections  release]; self->selections = nil;
  [self->patternName release]; self->patternName = nil;
  self->hideEmptyFields = NO;
  [self->errorString release]; self->errorString = nil;

  [super sleep];
}

/* accessors */

- (NSString *)_entityName {
  id obj;
  
  obj = [self valueForKey:@"object"];
  
  if ([obj isKindOfClass:[SkyPersonDocument class]])
    return @"Person";
  if ([obj isKindOfClass:[SkyEnterpriseDocument class]])
    return @"Enterprise";
  if ([obj isKindOfClass:[SkyJobDocument class]])
    return @"Job";
  
  if ([obj respondsToSelector:@selector(entityName)])
    return [obj entityName];
  
  return nil;
}

- (NSArray *)_allKeyValuesInDefaultsArray:(NSArray *)_a {
  NSMutableArray *tmp;
  NSEnumerator   *en;
  NSString       *obj;

  tmp = [NSMutableArray arrayWithCapacity:100];
  if (_a == nil)
    return tmp;

  en = [_a objectEnumerator];
  while ((obj = [(NSDictionary*)[en nextObject] objectForKey:@"key"]) != nil) {
    if ([obj isEqualToString:@"description"]) {
      if ([[self _entityName] isEqualToString:@"Person"])
	obj = @"nickname";
      else //  it's a enterprise
	obj = @"name";
    }
    [tmp addObject:obj];
  }
  return tmp;
}

- (NSArray *)_allAttributes {
  NSMutableArray *tarray;
  NSString       *eName;
  NSString       *key;
  NSArray        *tmp;
  NSUserDefaults *ud;

  ud = [self defaults];
  eName = [self _entityName];

  if (eName == nil) return [NSArray array];

  tarray = [NSMutableArray arrayWithCapacity:200];
  
  // StandardAttributes
  if ([eName isEqualToString:@"Job"])
    tmp = JobKeys;
  else
    tmp = [eName isEqualToString:@"Person"] ? PersonKeys : EnterpriseKeys;
  [tarray addObjectsFromArray:tmp];

  // PublicAttributes
  key = [NSString stringWithFormat:@"SkyPublicExtended%@Attributes", eName];
  tmp = [self _allKeyValuesInDefaultsArray:[ud objectForKey:key]];
  [tarray addObjectsFromArray:tmp];

  // PrivateAttributes
  key = [NSString stringWithFormat:@"SkyPrivateExtended%@Attributes", eName];
  tmp = [self _allKeyValuesInDefaultsArray:[ud objectForKey:key]];
  [tarray addObjectsFromArray:tmp];

  if (![[self _entityName] isEqualToString:@"Job"]) {
    // TelephoneTypes
    tmp = [[ud objectForKey:@"LSTeleType"] valueForKey:eName];
    [tarray addObjectsFromArray:tmp];

    // AddressTypes
    tmp = [[ud objectForKey:@"LSAddressType"] valueForKey:eName];
    [tarray addObjectsFromArray:tmp];
  }

  return [tarray sortedArrayUsingFunction:compareAttributes
                                  context:[self labels]];
}

- (NSArray *)allAttributes {
  if (self->allAttributes == nil)
    self->allAttributes = [[self _allAttributes] retain];
  
  return self->allAttributes;
}

/* accessors */

- (void)setIsInConfigMode:(BOOL)_b {
  self->isInConfigMode = _b;
}
- (BOOL)isInConfigMode {
  return self->isInConfigMode;
}

- (void)setItem:(NSString *)_s {
  ASSIGN(self->item,_s);
}
- (NSString *)item {
  return self->item;
}

- (void)setObject:(id)_obj {
  ASSIGN(self->object, _obj);
}
- (NSString *)object {
  return self->object;
}

- (void)setViewerPattern:(NSString *)_s {
  ASSIGN(self->viewerPattern, _s);

  if (self->patternName == nil) {
    self->patternName = [_s copy];
  }
}
- (NSString *)viewerPattern {
  return self->viewerPattern;
}

- (void)setPatternName:(NSString *)_s {
  ASSIGN(self->patternName, _s);
}
- (NSString *)patternName {
  return self->patternName;
}

- (BOOL)isNonEmptyChecked {
  return self->hideEmptyFields;
}
- (void)setIsNonEmptyChecked:(BOOL)_b {
  self->hideEmptyFields = _b;
}

- (NSString *)displayNameForItem {
  NSString *result;
  NSString *it;

  it = self->item;

  if ([self->item isEqualToString:@"mailing"])  it = @"mailing_address";
  if ([self->item isEqualToString:@"private"])  it = @"private_address";
  if ([self->item isEqualToString:@"location"]) it = @"location_address";
    
  result = [[self labels] valueForKey:it];
  return (result == nil) ? it : result;
}

- (void)setErrorString:(NSString *)_errorString {
  ASSIGN(self->errorString, _errorString);
}
- (NSString *)errorString {
  return self->errorString;
}

- (BOOL)hasErrorString {
  return (self->errorString != nil);
}

- (BOOL)allowDelete {
  NSString *key;
  NSArray  *tmp;
  
  key = [[self _entityName] lowercaseString];
  key = [key stringByAppendingString:@"s_view_attributes"];
     
  tmp = [[[self defaults] dictionaryForKey:key] allKeys];
  
  return (([tmp count] > 1) && self->viewerPattern);
}

- (void)setCheckedItems:(NSArray *)_items {
  ASSIGN(self->checkedItems, _items);

  if (self->selections == nil) {
    ASSIGN(self->selections, self->checkedItems);
    self->hideEmptyFields = 
      [self->checkedItems containsObject:@"nonEmptyOnly"];
  }
}
- (NSArray *)checkedItems {
  return self->checkedItems;
}

- (void)setSelections:(NSArray *)_items {
  ASSIGN(self->selections, _items);
}
- (NSArray *)selections {
  return self->selections;
}

/* operations */

- (NSString *)viewerExpandKey:(NSString *)_pat {
  NSString *key;
  
  key = [[self _entityName] lowercaseString];
  key = [key stringByAppendingString:@"_viewer_expand_"];
  key = [key stringByAppendingString:_pat];
  return key;
}

- (NSString *)viewAttributesKeys {
  NSString *key;
  
  key = [[self _entityName] lowercaseString];
  key = [key stringByAppendingString:@"s_view_attributes"];
  return key;
}

/* actions */

// TODO: actions contain quite some duplicate code?

- (BOOL)shouldPerformDefaultsEditAction {
  if ((self->patternName != nil) && (self->selections != nil) &&
      (![self->patternName isEqualToString:@""]))
    return YES;

  return NO;
}

- (id)newViewerDefaults {
  // TODO: split up method
  NSDictionary        *vd;
  NSMutableDictionary *vdmutable;
  NSMutableArray      *tmp;
  NSString            *key;
  NSUserDefaults      *ud;
  
  if (![self shouldPerformDefaultsEditAction])
    return nil;
  
  ud  = [self defaults];
  key = [self viewAttributesKeys];
    
    vd = [ud dictionaryForKey:key];
    vdmutable = [NSMutableDictionary dictionaryWithCapacity:[vd count]+1];
    [vdmutable addEntriesFromDictionary:vd];
    
    if ([vdmutable objectForKey:self->patternName] != nil) {
      NSString *tmp;

      tmp = [[self labels] valueForKey:@"patternAlreadyExists"];
      tmp = (tmp != nil) ? tmp : (NSString *)@"Pattern already exists";
      tmp = [tmp stringByAppendingString:@" ("];
      tmp = [tmp stringByAppendingString:self->patternName];
      tmp = [tmp stringByAppendingString:@")!"];
      
      [self setErrorString:tmp];

      return nil;
    }

    tmp = [self->selections mutableCopy];
    
    [tmp removeObject:@"nonEmptyOnly"];
    
    if (self->hideEmptyFields) 
      [tmp addObject:@"nonEmptyOnly"];

    [vdmutable setObject:tmp forKey:self->patternName];

    [ud setObject:vdmutable forKey:key];

    // set expand info to expanded if new
    key = [self viewerExpandKey:self->patternName];
    if ([ud objectForKey:key] == nil)
      [ud setBool:YES forKey:key];
    
    [ud synchronize];
    self->isInConfigMode = NO;
    [tmp release];
    
  return nil;
}

- (id)setViewerDefaults {
  // TODO: split up method
  NSDictionary        *vd;
  NSMutableDictionary *vdmutable;
  NSMutableArray      *tmp;
  NSString            *key;
  NSUserDefaults      *ud;
  
  if (![self shouldPerformDefaultsEditAction])
    return nil;
    
  ud  = [self defaults];
  key = [self viewAttributesKeys];
    
  vd = [ud dictionaryForKey:key];
  vdmutable = [NSMutableDictionary dictionaryWithCapacity:[vd count]+1];
  [vdmutable addEntriesFromDictionary:vd];

  if (![self->patternName isEqualToString:self->viewerPattern] &&
        [vdmutable objectForKey:self->patternName] != nil) {
      NSString *tmp;

      tmp = [[self labels] valueForKey:@"patternAlreadyExists"];
      tmp = (tmp != nil) ? tmp : (NSString *)@"Pattern already exists";
      tmp = [tmp stringByAppendingString:@" ("];
      tmp = [tmp stringByAppendingString:self->patternName];
      tmp = [tmp stringByAppendingString:@")!"];
      
      [self setErrorString:tmp];
      return nil;
  }
    
  if (self->viewerPattern)
    [vdmutable removeObjectForKey:self->viewerPattern];
    
  [vdmutable removeObjectForKey:self->patternName];

  tmp = [self->selections mutableCopy];
    
  [tmp removeObject:@"nonEmptyOnly"];
    
  if (self->hideEmptyFields) 
    [tmp addObject:@"nonEmptyOnly"];

  [vdmutable setObject:tmp forKey:self->patternName];

  [ud setObject:vdmutable forKey:key];

  // set expand info to expanded if new
  key = [self viewerExpandKey:self->patternName];
    
  if ([ud objectForKey:key] == nil)
    [ud setBool:YES forKey:key];
    
  [ud synchronize];
  self->isInConfigMode = NO;
  [tmp release];
  return nil;
}

- (id)deleteViewerDefaults {
  // TODO: split up method
  NSDictionary        *vd;
  NSMutableDictionary *vdmutable;
  NSString            *key;
  NSUserDefaults      *ud;
  
  if (self->viewerPattern == nil)
    return nil;

  ud  = [self defaults];
  key = [self viewAttributesKeys];
    
  vd        = [ud dictionaryForKey:key];
  vdmutable = [NSMutableDictionary dictionaryWithCapacity:[vd count]];
  [vdmutable addEntriesFromDictionary:vd];
  [vdmutable removeObjectForKey:self->viewerPattern];

  [ud setObject:vdmutable forKey:key];
  [ud removeObjectForKey:[self viewerExpandKey:self->viewerPattern]];

  [ud synchronize];
  self->isInConfigMode = NO;
  return nil;
}

- (id)cancelViewerConfig {
  self->isInConfigMode = NO;
  return nil;
}

@end /* SkyPersonalViewerConfig */
