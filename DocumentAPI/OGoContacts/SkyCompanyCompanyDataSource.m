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

#include "SkyCompanyCompanyDataSource.h"
#include "common.h"
#include "SkyCompanyDocument.h"

@implementation SkyCompanyCompanyDataSource

+ (int)version {
  return [super version] + 0; /* v1 */
}
+ (void)initialize {
  NSAssert2([super version] == 1,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)initWithContext:(id)_ctx companyId:(EOGlobalID *)_gid {
  NSAssert(_ctx, @"missing context for datasource !");
  NSAssert(_gid, @"missing person gid for datasource !");
  
  if ((self = [super init])) {
    self->context  = RETAIN(_ctx);
    self->companyId = RETAIN(_gid);
  }
  return self;
}
- (id)initWithContext:(id)_ctx {
  return [self initWithContext:_ctx companyId:nil];
}
- (id)init {
  return [self initWithContext:nil companyId:nil];
}

- (void)dealloc {
  RELEASE(self->fetchSpecification);
  RELEASE(self->companyId);
  RELEASE(self->context);
  [super dealloc];
}

/* accessors */

- (void)setFetchSpecification:(EOFetchSpecification *)_fSpec {
  if (![self->fetchSpecification isEqual:_fSpec]) {
    ASSIGNCOPY(self->fetchSpecification, _fSpec);
    [self postDataSourceChangedNotification];
  }
}
- (EOFetchSpecification *)fetchSpecification {
  return AUTORELEASE([self->fetchSpecification copy]);
}

- (id)context {
  return self->context;
}

/* commands */

- (NSString *)destinyEntityName {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (EODataSource *)companyDataSource {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (NSString *)nameOfGetByGIDCommand {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return nil;
}

- (NSString *)_mapKeyFromDocToEO:(NSString *)_key {
  return _key;
}

/* fetching */

- (Class)documentClass {
  [self logWithFormat:@"ERROR(%s): subclasses must override this method!",
	  __PRETTY_FUNCTION__];
  return Nil;
}

- (NSArray *)_morphEOsToDocuments:(NSArray *)_eos {
  BOOL           addAsObserver = YES;
  unsigned       i, count;
  NSDictionary   *hints;
  NSMutableArray *result;

  if (_eos == nil)                 return nil;
  if ((count = [_eos count]) == 0) return [NSArray array];

  result = [NSMutableArray arrayWithCapacity:(count + 1)];

  hints  = [self->fetchSpecification hints];
  if ([hints objectForKey:@"addDocumentsAsObserver"])
    addAsObserver = [[hints objectForKey:@"addDocumentsAsObserver"] boolValue];
  
  for (i = 0; i < count; i++) {
    id doc;
    id company;
    
    company = [_eos objectAtIndex:i];

    /*
      the dataSource's fetchSpecification is responsible for the supported
      attributes in the document!!!
    */
    doc = [[[self documentClass] alloc]
                  initWithCompany:company
                  globalID:[company valueForKey:@"globalID"]
                  dataSource:self
                  addAsObserver:addAsObserver];

    
    [result addObject:doc];
    RELEASE(doc);
  }
  return result;
}

- (NSArray *)fetchObjects {
  NSArray *result;
  NSArray *attributes;
  
  /* could introduce hint to set this dynamically .. */
  if (self->companyId == nil)
    return nil;

  attributes = [[self->fetchSpecification hints] valueForKey:@"attributes"];

  if (attributes != nil) {
    NSEnumerator *attrEnum;
    NSArray      *attrs;
    NSString     *attr;

    attrs      = attributes;
    attrEnum   = [attrs objectEnumerator];
    attributes = [[NSMutableArray alloc] initWithCapacity:[attrs count]+1];
    while ((attr = [attrEnum nextObject])) {
      [(NSMutableArray *)attributes addObject:[self _mapKeyFromDocToEO:attr]];
    }
    AUTORELEASE(attributes);
  }

  if (attributes && ![attributes containsObject:@"companyId"]) {
    attributes = [attributes arrayByAddingObject:@"companyId"];
  }
  if (attributes && ![attributes containsObject:@"globalID"]) {
    attributes = [attributes arrayByAddingObject:@"globalID"];
  }
  
  NS_DURING {
    NSMutableDictionary *dict    = nil;
    NSNumber            *compId  = nil;
    BOOL                isPerson = NO;

    compId  = [[(EOKeyGlobalID *)self->companyId keyValuesArray] lastObject];
    NSAssert1(compId, @"couldn't get primaryKey from gid %@", self->companyId);
    
    dict = [[NSMutableDictionary alloc] initWithCapacity:4];
    isPerson = [[self destinyEntityName] isEqualToString:@"Person"];

    [dict setObject:intObj(LSDBReturnType_ManyObjects) forKey:@"returnType"];
    
    [dict setObject:compId forKey:(isPerson) ? @"companyId" : @"subCompanyId"];
   
    result = [self->context runCommand:@"companyassignment::get"
                            arguments:dict];

    result = [result valueForKey:(isPerson) ? @"subCompanyId" : @"companyId"];

    {
      NSMutableArray *gids;
      int            i, cnt;
  
      cnt  = [result count];
      gids = [NSMutableArray arrayWithCapacity:cnt];
  
      for (i = 0; i < cnt; i++) {
        id pk;
        EOGlobalID *gid;

        pk = [result objectAtIndex:i];
        gid = [[[self context] typeManager] globalIDForPrimaryKey:pk];

        if (gid == nil) {
          NSLog(@"%s: couldn't get gid for pkey %@", __PRETTY_FUNCTION__, pk);
          continue;
        }
        if ([[gid entityName] isEqualToString:[self destinyEntityName]])
          [gids addObject:gid];
      }
      result = gids;
    }
    result = (attributes == nil)
      ? [self->context runCommand:[self nameOfGetByGIDCommand],
             @"gids", result, nil]
      : [self->context runCommand:[self nameOfGetByGIDCommand],
             @"gids",       result,
             @"attributes", attributes,
             nil];
  }
  NS_HANDLER {
    *(&result) = nil;
    ASSIGN(self->lastException, localException);
  }
  NS_ENDHANDLER;
  
  result = [self _morphEOsToDocuments:result];
  
  {
    NSArray     *sortOrderings = nil;
    EOQualifier *qualifier     = nil;

    if ((qualifier = [self->fetchSpecification qualifier]) != nil)
      result = [result filteredArrayUsingQualifier:qualifier];
    if ((sortOrderings = [self->fetchSpecification sortOrderings]) != nil)
      result = [result sortedArrayUsingKeyOrderArray:sortOrderings];
  }
 
  return result;
}

/* operations */

- (NSArray *)_getAssignmentWithCompany:(id)_object {
  NSMutableDictionary *dict;
  NSNumber            *compId;
  NSNumber            *subId;

  dict   = [NSMutableDictionary dictionaryWithCapacity:4];
  compId = [[(EOKeyGlobalID *)self->companyId keyValuesArray] lastObject];
  subId  = [[(EOKeyGlobalID *)[_object globalID] keyValuesArray] lastObject];

  if (subId == nil || compId == nil) return [NSArray array];

  if (![[self destinyEntityName] isEqualToString:@"Person"]) {
    NSNumber *tmp = compId;

    compId = subId;
    subId  = tmp;
  }

  [dict setObject:compId                             forKey:@"companyId"];
  [dict setObject:subId                              forKey:@"subCompanyId"];
  [dict setObject:intObj(LSDBReturnType_ManyObjects) forKey:@"returnType"];
  [dict setObject:@"AND"                             forKey:@"operator"];
  
  return [self->context runCommand:@"companyassignment::get" arguments:dict];
}

- (id)createObject {
  /* should use Sky*Company*DataSource to create a company and associate
     the companyId with the company */
  return nil;
}

- (void)insertObject:(id)_object {
  NSArray *eos = nil;

  if (self->companyId == nil) return;

  eos = [self _getAssignmentWithCompany:_object];

  /*
    If the _object is a new document, this should use Sky*Company*DataSource
    to create the _object.
    
    -- done:
    -- If the _object is an existing document, this should add the company as
    -- a one associated to the company
  */
    
  if ([eos count] == 0) { // companies are not assigned
    NSMutableDictionary *args;
    NSNumber            *compId;
    NSNumber            *subId;

    args = [NSMutableDictionary dictionaryWithCapacity:2];

    if ([[self destinyEntityName] isEqualToString:@"Person"]) {
      compId = [[(EOKeyGlobalID *)self->companyId keyValuesArray] lastObject];
      subId  = [_object companyId];
    }
    else {
      compId = [_object companyId];
      subId  = [[(EOKeyGlobalID *)self->companyId keyValuesArray] lastObject];
    }
    [args setObject:compId forKey:@"companyId"];
    [args setObject:subId  forKey:@"subCompanyId"];
    
    [self->context runCommand:@"companyassignment::new" arguments:args];
    [self postDataSourceChangedNotification];
  }
}

- (void)deleteObject:(id)_object {
  NSArray *eos;
  /*
    toDo:
    If the _object is the last associated one with the company, the _object
    should be deleted/archived using Sky*Company*DataSource?????????
    
    -- done:
    -- If the _object has more associated companies, this should remove the
    -- _object from the associated ones.
  */

  if (self->companyId == nil) return;

  eos = [self _getAssignmentWithCompany:_object];
  
  if ([eos count] > 0) { // if companies are assigned
    NSEnumerator *eoEnum = [eos objectEnumerator];
    id           eo;

    while ((eo = [eoEnum nextObject])) {
      [self->context runCommand:@"companyassignment::delete",
           @"object", eo, nil];
    }
    [self postDataSourceChangedNotification];
  }
}

- (void)updateObject:(id)_object {
  EODataSource *companyDS;

  companyDS = [self companyDataSource];
  [companyDS updateObject:_object];
}

@end /* SkyCompanyCompanyDataSource */
