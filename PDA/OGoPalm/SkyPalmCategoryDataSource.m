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

#include <OGoPalm/SkyPalmCategoryDataSource.h>
#include <OGoPalm/SkyPalmCategoryDocument.h>
#include <Foundation/Foundation.h>
#include <LSFoundation/LSFoundation.h>
#include <EOControl/EOControl.h>

@interface SkyPalmCategoryDataSource(PrivatMethods)
- (void)setPalmTable:(NSString *)_table;
- (void)postDataSourceChangedNotification;
@end

@implementation SkyPalmCategoryDataSource

- (id)init {
  if ((self = [super init])) {
    self->ds              = nil;
    self->context         = nil;
    self->palmTable       = nil;
    self->defaultDeviceId = nil;
  }
  return self;
}

- (id)initWithContext:(LSCommandContext *)_ctx {
  if ((self = [self init])) {
    self->ds = [[SkyAdaptorDataSource alloc] initWithContext:_ctx];
    ASSIGN(self->context,_ctx);
  }
  return self;
}
+ (SkyPalmCategoryDataSource *)dataSourceWithContext:(LSCommandContext *)_ctx
                                        forPalmTable:(NSString *)_palmDb
{
  SkyPalmCategoryDataSource *das;

  das = [[SkyPalmCategoryDataSource alloc] initWithContext:_ctx];
  [das setPalmTable:_palmDb];

  return AUTORELEASE(das);
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->ds);
  RELEASE(self->context);
  RELEASE(self->palmTable);
  RELEASE(self->defaultDeviceId);
  [super dealloc];
}
#endif

// accessors

- (void)setPalmTable:(NSString *)_table {
  ASSIGN(self->palmTable,_table);
}
- (NSString *)palmTable {
  return self->palmTable;
}

- (void)setDefaultDevice:(NSString *)_devId {
  ASSIGN(self->defaultDeviceId,_devId);
}
- (NSArray *)devices {
  if (self->defaultDeviceId == nil) {
    NSLog(@"%s !!!! NO defaultDeviceId set !!! %@",
          __PRETTY_FUNCTION__, self);
    return nil;
  }
  return [NSArray arrayWithObject:self->defaultDeviceId];
}

- (void)setFetchSpecification:(EOFetchSpecification *)_spec {
  if (![_spec isEqual:[self->ds fetchSpecification]]) {
    [self->ds setFetchSpecification:_spec];
  }
}
- (EOFetchSpecification *)fetchSpecification {
  return [self->ds fetchSpecification];
}

- (id)currentAccount {
  return [self->context valueForKey:LSAccountKey];
}
- (NSNumber *)companyId {
  return [[self currentAccount] valueForKey:@"companyId"];
}


// checking
- (EOFetchSpecification *)_defaultFetchSpec {
  EOQualifier *qual =
    [EOQualifier qualifierWithQualifierFormat:
                 @"company_id=%@", [self companyId]];
  return
    [EOFetchSpecification fetchSpecificationWithEntityName:@"palm_category"
                          qualifier:qual sortOrderings:nil];
}
- (void)_checkFetchSpecification {
  if ([self fetchSpecification] == nil)
    [self setFetchSpecification:[self _defaultFetchSpec]];
}

// datasource
- (NSArray *)_fetchDicts {
  return [self->ds fetchObjects];
}
- (NSArray *)fetchObjects {
  NSMutableArray *docs = [NSMutableArray array];
  NSEnumerator   *e    = nil;
  id             one   = nil;

  e = [[self _fetchDicts] objectEnumerator];

  while ((one = [e nextObject])) {
    [docs addObject:[self documentForObject:one]];
  }
  
  return docs;
}

- (void)_insertDict:(id)_obj {
  [_obj setObject:[self companyId] forKey:@"company_id"];
  [self->ds insertObject:_obj];
  [self postDataSourceChangedNotification];
}
- (void)insertObject:(SkyPalmCategoryDocument *)_doc {
  if ([[_doc categoryName] length] != 0) {
    id dict = [_doc asDictionary];
    [self _checkFetchSpecification];
    [self _insertDict:dict];
    [_doc updateSource:dict fromDataSource:self];
  }
}

- (void)_updateDict:(id)_obj {
  [_obj setObject:[self companyId] forKey:@"company_id"];
  [self->ds updateObject:_obj];
  [self postDataSourceChangedNotification];
}
- (void)updateObject:(SkyPalmCategoryDocument *)_doc {
  id dict = [_doc asDictionary];
  [self _checkFetchSpecification];
  [self _updateDict:dict];
  [_doc updateSource:dict fromDataSource:self];
}

- (void)_deleteDict:(id)_obj {
  [self->ds deleteObject:_obj];
  [self postDataSourceChangedNotification];
}
- (void)deleteObject:(SkyPalmCategoryDocument *)_doc {
  [self _checkFetchSpecification];
  [self _deleteDict:[_doc asDictionary]];
}

// refetch
- (NSDictionary *)fetchDictionaryForDocument:(SkyPalmCategoryDocument *)_doc
{
  SkyPalmCategoryDataSource *das  = nil;
  EOQualifier               *qual = nil;

  das = [SkyPalmCategoryDataSource dataSourceWithContext:self->context
                                   forPalmTable:self->palmTable];
  qual = [EOQualifier qualifierWithQualifierFormat:
                      @"company_id=%@ AND "
                      @"palm_category_id=%@",
                      [self companyId],
                      [[_doc asDictionary] valueForKey:@"palm_category_id"]];

  [das setFetchSpecification:
       [EOFetchSpecification fetchSpecificationWithEntityName:@"palm_category"
                             qualifier:qual
                             sortOrderings:nil]];

  return [[das _fetchDicts] lastObject];
}

// category docs
- (SkyPalmCategoryDocument *)documentForObject:(id)_obj {
  SkyPalmCategoryDocument *doc = 
    [[SkyPalmCategoryDocument alloc] initWithDictionary:_obj
                                     fromDataSource:self];
  return AUTORELEASE(doc);
}

- (SkyPalmCategoryDocument *)newDocument {
  SkyPalmCategoryDocument *doc =
    [[SkyPalmCategoryDocument alloc] initAsNewFromDataSource:self];

  return AUTORELEASE(doc);
}

- (SkyPalmCategoryDocument *)unfiledCategory {
  return [self newDocument];
}

// assigning records
- (EOFetchSpecification *)_fetchSpecForPalmDocs:(NSArray *)_palmRecs
  table:(NSString *)_table
{
  NSEnumerator   *e    = [_palmRecs objectEnumerator];
  id             rec   = nil;
  NSMutableArray *cIds = [NSMutableArray array];
  id             cId   = nil;

  NSString *query;
  NSString *device    = nil;
  NSNumber *companyId = [self companyId];

  NSString *entity    = nil;
  EOQualifier *qual   = nil;

  while ((rec = [e nextObject])) {
    rec = [rec asDictionary];
    
    if (device == nil)
      device = [rec valueForKey:@"device_id"];
      
    cId = [rec valueForKey:@"category_index"];
    if (![cIds containsObject:cId]) {
      [cIds addObject:cId];
    }
  }
  if ([cIds count] < 1)
    return nil;

  query = @" OR category_index=";
  query = [NSString stringWithFormat:
                    @"device_id=%%@ AND company_id=%%@ AND "
                    @"(category_index=%@)",
                    [cIds componentsJoinedByString:query]];

  entity = @"palm_category";
  qual   = [EOQualifier qualifierWithQualifierFormat:
                        query, device, companyId];

  return [EOFetchSpecification fetchSpecificationWithEntityName:entity
                               qualifier:qual sortOrderings:nil];
}

- (void)assignCategoriesToDocuments:(NSArray *)_palmRecs
  ofTable:(NSString *)_table
{
  NSEnumerator         *e           = nil;
  NSMutableDictionary  *orderedCats = nil;
  id                   obj          = nil;
  EOFetchSpecification *fspec;

  if ((_palmRecs == nil) || ([_palmRecs count] == 0))
    return;
  
  fspec = [self _fetchSpecForPalmDocs:_palmRecs table:_table];
  NSAssert2(fspec, @"got no fetch specification for %d records of table %@",
            [_palmRecs count], _table);
  
  [self setFetchSpecification:fspec];
  
  e    = [[self fetchObjects] objectEnumerator];
  orderedCats = [NSMutableDictionary dictionaryWithCapacity:16];
  
  while ((obj = [e nextObject])) {
    [orderedCats setObject:obj
                 forKey:[obj valueForKey:@"categoryIndex"]];
  }

  e = [_palmRecs objectEnumerator];
  while ((obj = [e nextObject])) {
    id idx  = [obj valueForKey:@"categoryId"];
    id cat  = [orderedCats objectForKey:idx];
    if (cat != nil)
      [obj takeValue:cat forKey:@"category"];
  }
}

@end /* SkyPalmCategoryDataSource */
