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

#include <OGoFoundation/OGoContentPage.h>

@class NSMutableArray, EODataSource;

@interface SkyContactImportPage : OGoContentPage
{
  NSString *contactType;
  int      importCnt;
  int      ignoreCnt;
  int      duplicateCnt;
  int      errorCnt;
  BOOL     isError;
  BOOL     importPrivate;

  NSMutableArray *entries;
  NSArray        *duplicates;
  NSString       *fileName;
  EODataSource   *contactDataSource;

  id item;
}

- (id)nextEntry;

@end /* SkyContactImportPage */

#include "common.h"
#include <OGoFoundation/OGoFoundation.h>
#include <NGExtensions/EODataSource+NGExtensions.h>
#include <EOControl/EOQualifier.h>
#include <EOControl/EOFetchSpecification.h>
#include <OGoContacts/SkyPersonDataSource.h>
#include <OGoContacts/SkyEnterpriseDataSource.h>
#include <OGoContacts/SkyCompanyDocument.h>

/* TODO: clean up this messy file */

@interface SkyContactImportPage(PrivateMethods)
- (void)_loadImportRule;
- (void)_searchForDuplicates;
- (BOOL)_removeImportRuleFile;
- (BOOL)_saveImportRuleFile;
- (id)_createNewContactWithValues:(id)_values;
@end /* SkyContactImportPage(PrivateMethods) */

@implementation SkyContactImportPage

static EOQualifier *falseQual = nil;
static NSArray  *persAttrs  = nil;
static NSArray  *entAttrs   = nil;
static NSArray  *emptyArray = nil;
static NSString *blobPath   = nil;
static NSString *birthdayDateFormat;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  emptyArray = [[NSArray alloc] init];
  falseQual  = [[EOQualifier qualifierWithQualifierFormat:@"1=0"] retain];
  
  persAttrs = [[ud arrayForKey:@"contactimport_personattrnames"]     copy];
  entAttrs  = [[ud arrayForKey:@"contactimport_enterpriseattrnames"] copy];
  
  blobPath           = [[ud stringForKey:@"LSAttachmentPath"] copy];
  birthdayDateFormat =
    [[ud stringForKey:@"contactimport_birthdaydateformat"] copy];
}

- (id)init {
  if ((self = [super init])) {
    self->contactType   = @"Person";
    self->importCnt     = -1;
    self->ignoreCnt     = -1;
    self->duplicateCnt  = -1;
    self->errorCnt      = -1;
    self->importPrivate = YES;
  }
  return self;
}

- (void)dealloc {
  [self->contactType       release];
  [self->entries           release];
  [self->duplicates        release];
  [self->fileName          release];
  [self->contactDataSource release];
  [self->item              release];
  [super dealloc];
}

/* notifications */

- (void)syncSleep {
  [super syncSleep];
  [self->duplicates release]; self->duplicates = nil;
}

/* accessors */

- (void)setContactType:(NSString *)_type {
  ASSIGNCOPY(self->contactType, _type);
}
- (NSString *)contactType {
  return self->contactType;
}
- (BOOL)isPerson {
  return [self->contactType isEqualToString:@"Person"] ? YES : NO;
}
- (BOOL)isEnterprise {
  return [self->contactType isEqualToString:@"Enterprise"] ? YES : NO;
}

- (unsigned)importCount {
  if (self->importCnt == -1) [self _loadImportRule];
  return self->importCnt;
}
- (unsigned)ignoreCount {
  if (self->ignoreCnt == -1) [self _loadImportRule];
  return self->ignoreCnt;
}
- (unsigned)duplicateCount {
  if (self->duplicateCnt == -1) [self _loadImportRule];
  return self->duplicateCnt;
}
- (unsigned)errorCount {
  if (self->errorCnt == -1) [self _loadImportRule];
  return self->errorCnt;
}

- (NSArray *)entries {
  if (self->entries == nil) [self _loadImportRule];
  return self->entries;
}
- (id)nextEntry {
  NSArray *es = [self entries];
  if ([es count]) return [es objectAtIndex:0];
  return nil;
}
- (BOOL)hasNextEntry {
  return [[self entries] count];
}
- (BOOL)maySkip {
  return ([[self entries] count] > 1);
}
- (NSArray *)duplicates {
  if (self->duplicates == nil) {
    [self _searchForDuplicates];
  }
  return self->duplicates;
}
- (BOOL)hasDuplicates {
  return [[self duplicates] count];
}

- (void)setItem:(id)_item {
  ASSIGN(self->item,_item);
}
- (id)item {
  return self->item;
}

- (NSArray *)contactAttributes {
  if ([self->contactType isEqualToString:@"Person"])     return persAttrs;
  if ([self->contactType isEqualToString:@"Enterprise"]) return entAttrs;
  return emptyArray;
}

- (NSString *)isPrivateLabelKey {
  return [self->item isPrivate] ? @"YES" : @"NO";
}

- (NSString *)windowTitle {
  NSString *s;
  
  s = [@"import_label_import" stringByAppendingString:self->contactType];
  return [[self labels] valueForKey:s];
}

/* actions */

- (id)cancel {
  return [[[self session] navigation] leavePage];
}
- (id)gotoNext {
  if (![self->entries count]) {
    [self _removeImportRuleFile];
    return [self cancel];
  }
  [self->entries removeObjectAtIndex:0];
  self->isError = NO;
  [self->duplicates release]; self->duplicates = nil;
  if ([self->entries count] == 0) {
    [self _removeImportRuleFile];
    return [self cancel];
  }

  [self _saveImportRuleFile];
  return nil;
}
- (SkyCompanyDocument *)createContactRecord {
  id next = [self nextEntry];
  SkyCompanyDocument *doc;
  if (next == nil) {
    [self setErrorString:
          [[self labels] valueForKey:@"import_error_noMoreEntries"]];
    return nil;
  }

  doc = [self _createNewContactWithValues:next];
  if (doc == nil) {
    if (!self->isError) {
      self->isError = YES;
      self->errorCnt++;
    }
    [self setErrorString:
          [[self labels] valueForKey:@"import_error_failedToCreateContact"]];
    return nil;
  }

  return doc;
}

- (id)importNext {
  SkyCompanyDocument *doc;
  
  if ((doc = [self createContactRecord]) == nil) 
    return nil;
  [doc setIsPrivate:self->importPrivate];
  
  if (![doc save]) {
    if (!self->isError) {
      self->isError = YES;
      self->errorCnt++;
    }
    if (![self hasErrorString]) {
      [self setErrorString:
            [[self labels] valueForKey:@"import_error_failedToSaveContact"]];
    }
    return nil;
  }

  // all successfull
  self->importCnt++;
  return [self gotoNext];
}

- (id)ignoreNext {
  self->ignoreCnt++;
  return [self gotoNext];
}
- (id)markDuplicate {
  self->duplicateCnt++;
  return [self gotoNext];
}

- (id)skip {
  id next = [self nextEntry];
  [self->entries addObject:next];
  return [self gotoNext];
}

- (id)openInEditor {
  SkyCompanyDocument *doc = [self createContactRecord];
  if (doc == nil) return nil;
  return [[[self session] navigation] activateObject:doc withVerb:@"edit"];
}
- (id)openInBussinessCardGathering {
  SkyCompanyDocument  *doc;
  id                  page;
  NSMutableDictionary *vals;

  doc  = [self createContactRecord];
  vals = (id)[doc asDict];
  if (vals == nil) return nil;
  [vals setObject:[vals objectForKey:@"description"] forKey:@"nickname"];
  page = [self pageWithName:@"SkyBusinessCardGathering"];
  [page takeValue:vals forKey:@"presetGatheringPerson"];
  [self enterPage:page];
  return nil;
}
- (id)viewDuplicate {
  return [[[self session] navigation] activateObject:self->item
                                      withVerb:@"view"];
}

/* KVC */

- (void)takeValue:(id)_val forKey:(NSString *)_key {
  if (![_key isEqualToString:@"contactType"]) {
    ASSIGN(self->contactType,_val);
    return;
  }

  [super takeValue:_val forKey:_key];
}

/* PrivateMethods */

- (NSString *)fileName {
  NSString *tmp;
  
  if (self->fileName)
    return self->fileName;
  
  tmp = [NSString stringWithFormat:@"%@_import.%@.plist",
		    self->contactType,
                    [[[self session] activeAccount] valueForKey:@"companyId"]];

  self->fileName = [[blobPath stringByAppendingPathComponent:tmp] copy];
  return self->fileName;
}

- (void)_loadImportRule {
  NSDictionary *dict;

  [self->entries release]; self->entries = nil;
  
  dict = [NSDictionary dictionaryWithContentsOfFile:[self fileName]];
  if (dict == nil) {
    [self setErrorString:@"failed to load import file"];
    [self logWithFormat:@"WARNING[%s] failed to load file: '%@'",
            __PRETTY_FUNCTION__, [self fileName]];
    self->importCnt     = 0;
    self->ignoreCnt     = 0;
    self->duplicateCnt  = 0;
    self->errorCnt      = 0;
    self->entries       = [[NSMutableArray alloc] init];
    self->importPrivate = YES;
  }
  else {
    self->importCnt     = [[dict objectForKey:@"importCnt"]    intValue];
    self->ignoreCnt     = [[dict objectForKey:@"ignoreCnt"]    intValue];
    self->duplicateCnt  = [[dict objectForKey:@"duplicateCnt"] intValue];
    self->errorCnt      = [[dict objectForKey:@"errorCnt"]     intValue];
    self->entries       = [[dict objectForKey:@"entries"]      mutableCopy];
    self->importPrivate = [[dict objectForKey:@"private"]      boolValue];
  }
}

- (EODataSource *)contactDataSource {
  EODataSource     *ds;
  LSCommandContext *ctx;
  
  if (self->contactDataSource)
    return self->contactDataSource;
  
  ctx = [[self session] commandContext];
  if ([self->contactType isEqualToString:@"Person"]) {
    ds = [(SkyPersonDataSource *)[SkyPersonDataSource alloc] 
				 initWithContext:(id)ctx];
  }
  else if ([self->contactType isEqualToString:@"Enterprise"]) {
    ds = [(SkyEnterpriseDataSource *)[SkyEnterpriseDataSource alloc] 
				     initWithContext:(id)ctx];
  }
  else {
    [self logWithFormat:@"WARNING[%s] invalid contactType: %@",
	  __PRETTY_FUNCTION__, self->contactType];
    ds = nil;
  }
  self->contactDataSource = ds;
  return self->contactDataSource;
}

- (EOQualifier *)_qualifierForPersonSearch {
  id       entry;
  NSString *name;

  entry = [self nextEntry];
  name  = [(NSDictionary *)entry objectForKey:@"name"];
  if ([name length] == 0)
    return falseQual;
  
  entry = [NSString stringWithFormat:
		      @"name like '*%@*' or firstname like '*%@*' or "
		      @"nickname like '*%@*' or login like '*%@*'",
		      name, name, name, name];
  return [EOQualifier qualifierWithQualifierFormat:entry];
}
- (EOQualifier *)_qualifierForCompanySearch {
  id       entry;
  NSString *desc;
  
  // TODO: is this correct? (the two lines below where previously in the decl)
  entry  = [self nextEntry];
  desc   = [(NSDictionary *)entry objectForKey:@"name"];
  
  entry = [self nextEntry];
  desc  = [(NSDictionary *)entry objectForKey:@"name"];
  if ([desc length] == 0)
    return falseQual;
  
  entry = [NSString stringWithFormat:
		      @"name like '*%@*' or number like '*%@*' or "
		      @"keywords like '*%@*'",
		      desc, desc, desc];
  return [EOQualifier qualifierWithQualifierFormat:entry];
}

- (EOFetchSpecification *)fetchSpecForSearch {
  EOFetchSpecification *fspec;
  EOQualifier          *qual;

  if ([self->contactType isEqualToString:@"Person"])
    qual = [self _qualifierForPersonSearch];
  else if ([self->contactType isEqualToString:@"Enterprise"])
    qual = [self _qualifierForCompanySearch];
  else
    qual = falseQual;
  
  fspec =
    [EOFetchSpecification fetchSpecificationWithEntityName:self->contactType
                          qualifier:qual sortOrderings:nil];
  [fspec setFetchLimit:200];
  return fspec;
}

- (void)_searchForDuplicates {
  EODataSource *ds;
  
  [self->duplicates release]; self->duplicates = nil;
  ds = [self contactDataSource];
  [ds setFetchSpecification:[self fetchSpecForSearch]];
  self->duplicates = [[ds fetchObjects] retain];
}

- (BOOL)_removeImportRuleFile {
  NSFileManager *fm = [NSFileManager defaultManager];
  
  if ([fm fileExistsAtPath:[self fileName]])
    return [fm removeFileAtPath:[self fileName] handler:nil];
  return YES;
}

- (BOOL)_saveImportRuleFile {
  NSDictionary *dict;
  if (self->importCnt == -1) [self _loadImportRule];
  dict =
    [NSDictionary dictionaryWithObjectsAndKeys:
                  [NSNumber numberWithInt:self->importCnt],    @"importCnt",
                  [NSNumber numberWithInt:self->ignoreCnt],    @"ignoreCnt",
                  [NSNumber numberWithInt:self->duplicateCnt], @"duplicateCnt",
                  [NSNumber numberWithInt:self->errorCnt],     @"errorCnt",
                  self->entries,     @"entries",
                  self->contactType, @"type",
                  nil];
  return [dict writeToFile:[self fileName] atomically:YES];
}

- (id)_createNewContactWithValues:(id)_values {
  SkyCompanyDocument *newRecord;
  NSEnumerator       *e;
  NSString           *one;
  id                 val;
  
  newRecord = [[self contactDataSource] createObject];
  if (newRecord == nil) {
    [self logWithFormat:
	    @"WARNING[%s] failed to create an empty new record from "
            @"dataSource %@",
            __PRETTY_FUNCTION__, [self contactDataSource]];
    return nil;
  }
  
  e = [_values keyEnumerator];
  while ((one = [e nextObject])) {
    // TODO: move body to separate method
    val = [(NSDictionary *)_values objectForKey:one];
    
    if ([one hasPrefix:@"phone."]) {
      [newRecord setPhoneNumber:val forType:[one substringFromIndex:6]];
      continue;
    }
    
    if ([one hasPrefix:@"address."]) {
      NSString *str;
      NSRange  r;
      NSString *addr;
      
      str  = [one substringFromIndex:8];
      r    = [str rangeOfString:@"."];
      addr = (r.length > 0) ? [str substringToIndex:r.location] : nil;
      if (addr != nil) {
        id aD = [newRecord addressForType:addr];
        str   = [str substringFromIndex:(r.location + r.length)];
        if (aD) {
          [aD takeValue:val forKey:str];
        }
        else {
          [self logWithFormat:@"WARNING[%s]: cannot get address type %@",
                __PRETTY_FUNCTION__, addr];
        }
      }
      else {
	[self logWithFormat:@"WARNING[%s]: invalid address key %@",
              __PRETTY_FUNCTION__, str];
      }
      continue;
    }
    
    if ([one isEqualToString:@"birthday"]) {
      val = [NSCalendarDate dateWithString:val 
			    calendarFormat:birthdayDateFormat];
      [newRecord takeValue:val forKey:one];
      continue;
    }
    
    /* take raw value */
    [newRecord takeValue:val forKey:one];
  }
  return newRecord;
}

@end /* SkyContactImportPage(PrivateMethods) */
