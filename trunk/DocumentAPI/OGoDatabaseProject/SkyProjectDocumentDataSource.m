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

#include "SkyProjectDocumentDataSource.h"
#include "SkyProjectFileManager.h"
#include <OGoProject/SkyProjectDataSource.h>
#include "FMContext.h"
#include "common.h"

static inline BOOL _showUnknownFiles(id self) {
  static BOOL showUnknownFiles_value = NO;
  static BOOL showUnknownFiles_flag  = NO;
  
 if (!showUnknownFiles_flag) {
   NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    showUnknownFiles_flag  = YES;
    showUnknownFiles_value = 
      [ud boolForKey:@"SkyProjectFileManager_show_unknown_files"];
  }
  return showUnknownFiles_value;
}

@interface EOQualifier(SqlExpression) /* implemented in EOAdaptorDataSource */
- (NSString *)sqlExpressionWithAdaptor:(EOAdaptor *)_adaptor
  attributes:(NSArray *)_attrs;
@end

@interface SkyProjectDocumentDataSource(Internals)
- (NSArray *)projects;
@end /*SkyProjectDocumentDataSource(Internals)*/

@implementation SkyProjectDocumentDataSource

- (id)initWithContext:(id)_ctx {
  if ((self = [super init])) {
    self->context = [_ctx retain];
  }
  return self;
}

- (void)dealloc {
  [self->context            release];
  [self->fetchSpecification release];
  [self->projects           release];
  [super dealloc];
}

/*
  SELECT c1.description 
  FROM project p1, project_company_assignment a1, company c1
  WHERE p1.fname = '007' AND p1.project_id = a1.project_id AND
        a1.company_id = c1.company_id;

*** all allowed processes ***

j = 100407
SELECT DISTINCT p1.kind FROM project p1;

  SELECT DISTINCT p1.fname
  FROM project p1, project_company_assignment a1, company c1 
  WHERE p1.kind <> '00_invoiceProject' OR
        p1.kind <> '05_historyProject' OR
        p1.kind <> '10_edcProject' OR
        p1.kind <> '15_accountLog' OR
        p1.kind IS NULL AND
    (p1.owner_id = 100407 OR 
      (p1.project_id = a1.project_id AND (a1.company_id = c1.company_id) AND 
       (c1.company_id = 100407 OR c1.company_id IN
          (SELECT cc1.company_id FROM company cc1, company_assignment aa1
           WHERE cc1.company_id = aa1.company_id
                 AND aa1.sub_company_id = 100407)) 
       AND (a1.access_right LIKE '%r%' OR a1.access_right LIKE '%m%')));

*** all allowed processes ***

  SELECT * 
  FROM project p1, project_company_assignment a1, company c1
  WHERE p1.kind NOT IN ('invoiceProject', 'historyProject', 'edcProject', \
  'accountLog') AND \
    (p1.owner_id = 'owner' OR \
      (p1.project_id = a1.project_id AND a1.company_id = c1.company_id AND \
       (c1.company_id = 'owner` or c1.company_id in (team_ids)) \
       AND (c1.access_right LIKE '%r%' OR c1.access_right LIKE '%m%')))
*/

/* 
   Hints:
     ProjectKind: archived, private

   without
             invoiceProject
             historyProject
             edcProject
             accountLog
   
   Qualifier:
     NSFileType, NSFileSubject, NSFileName
*/

- (void)setFetchSpecification:(EOFetchSpecification *)_fs {
  ASSIGN(self->fetchSpecification, _fs);
}
- (EOFetchSpecification *)fetchSpecification {
  return self->fetchSpecification;
}

- (EOFetchSpecification *)fetchSpecificationForProjectDS {
  NSMutableArray       *quals;
  NSEnumerator         *kinds;
  id                   obj;
  EOFetchSpecification *fs;

  fs    = nil;
  kinds = [[[self->fetchSpecification hints] objectForKey:@"kinds"]
                                      objectEnumerator];
  
  quals = [NSMutableArray arrayWithCapacity:3];
  while ((obj = [kinds nextObject]) != nil) {
    EOQualifier *qual;

    qual = [EOQualifier qualifierWithQualifierFormat:@"type=%@", obj];
    [quals addObject:qual];
  }
  if ([quals count] > 0) {
    EOQualifier *q;
    
    q  = [[[EOOrQualifier alloc] initWithQualifierArray:quals] autorelease];
    fs = [[[EOFetchSpecification alloc] init] autorelease];
    [fs setQualifier:q];
  }
  return fs;
}

- (NSArray *)fetchDocsWithChannel:(EOAdaptorChannel *)_channel {
  static NSArray *docAttrs = nil;
  NSArray        *projectIds;
  EOQualifier    *qual;
  int            maxInQual = 250, cnt, pcnt;
  EOEntity       *entity;
  NSMutableArray *result;

  qual = [self->fetchSpecification qualifier];

  if (![SkyProjectFileManager supportQualifier:qual]) {
    NSLog(@"ERROR(%s) qualifier %@ is not supported", __PRETTY_FUNCTION__,
          qual);
    return nil;
  }
  entity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                             entityNamed:@"Doc"];
  if (docAttrs == nil)
    docAttrs = [[entity attributes] retain];
  
  result     = [[NSMutableArray alloc] initWithCapacity:32];
  projectIds = [[self projects] mappedArrayUsingSelector:@selector(projectId)];
  qual       = [SkyProjectFileManager convertQualifier:qual projectId:nil
                                      evalInMemory:NULL];
  cnt        = 0;
  pcnt       = [projectIds count];
  
  while (cnt <= pcnt) {
    NSArray        *subProjectIds;
    EOSQLQualifier *sqlQual;
    NSString       *expr, *s;
    NSDictionary   *row;
    NSRange        r;

    r = NSMakeRange(cnt, (maxInQual+cnt)<pcnt?
		    maxInQual:(pcnt-cnt));
    subProjectIds = [projectIds subarrayWithRange:r];
    
    cnt     +=maxInQual;
    expr     = [qual sqlExpressionWithAdaptor:
                         [[_channel adaptorContext] adaptor]
		     attributes:docAttrs];
    s = [NSString stringWithFormat:@" AND (projectId IN (%@))",
		   [subProjectIds componentsJoinedByString:@","]];
    expr = [expr stringByAppendingString:s];
#if LIB_FOUNDATION_LIBRARY
    expr = [expr stringByReplacingString:@"%" withString:@"%%"];
#else
#  warning FIXME: incorrect implementation for this Foundation library!
#endif
    sqlQual  = [[EOSQLQualifier alloc] initWithEntity:entity
                                       qualifierFormat:expr];
    if (![_channel selectAttributes:docAttrs
                  describedByQualifier:sqlQual fetchOrder:nil lock:NO]) {
      NSLog(@"ERROR[%s]: select failed for qualifier %@ attrs %@ ",
            __PRETTY_FUNCTION__, sqlQual, docAttrs);
      [sqlQual release]; sqlQual = nil;
      return nil;
    }
    [sqlQual release]; sqlQual = nil;
    
    while ((row = [_channel fetchAttributes:docAttrs withZone:NULL]) != nil)
      [result addObject:row];
  }
  return result;
}

- (NSDictionary *)fetchDocEditingsForDocs:(NSArray *)_docs
  channel:(EOAdaptorChannel *)_channel
{
  static NSArray *editingAttrs = nil;
  NSMutableDictionary *result;
  EOEntity            *entity;
  int                 maxInQual = 250, cnt, pcnt;

  entity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                             entityNamed:@"DocumentEditing"];

  if (editingAttrs == nil)
    editingAttrs = [[entity attributes] retain];
  
  cnt    = 0;
  pcnt   = [_docs count];
  result = [NSMutableDictionary dictionaryWithCapacity:pcnt];
  
  while (cnt <= [_docs count]) {
    EOSQLQualifier *qualifier;
    NSArray        *subDocs;
    NSDictionary   *row;
    NSString       *docIdList;

    subDocs   = [_docs subarrayWithRange:
			 NSMakeRange(cnt, (maxInQual+cnt)<pcnt?
				     maxInQual:(pcnt-cnt))];
    cnt      += maxInQual;
    // TODO: should use "safe" pkey join for IN (like in LSDBBaseCommand)
    
    docIdList = [[subDocs map:@selector(objectForKey:)
			  with:@"documentId"] componentsJoinedByString:@","];
    qualifier = [[EOSQLQualifier alloc]
                                 initWithEntity:entity
                                 qualifierFormat:@"(%A = %@)"
                                 @" AND (%A = '%@') AND (%A IN (%@))",
                                 @"toDoc.isFolder",
                                 [NSNumber numberWithBool:NO],
                                 @"toDoc.status", @"edited",
                                 @"toDoc.documentId",
                                 docIdList];
    if (![_channel selectAttributes:editingAttrs
                  describedByQualifier:qualifier fetchOrder:nil lock:NO]) {
      NSLog(@"ERROR[%s]: select failed for qualifier %@ attrs %@ ",
            __PRETTY_FUNCTION__, qualifier, editingAttrs);
      [qualifier release]; qualifier = nil;
      return nil;
    }
      
    while ((row = [_channel fetchAttributes:editingAttrs withZone:NULL])!=nil)
      [result setObject:row forKey:[row objectForKey:@"documentId"]];
    
    [qualifier release]; qualifier = nil;
  }
  return result;
}

- (NSArray *)projects {
  SkyProjectDataSource *ds;
  
  if (self->projects != nil)
    return self->projects;
  
  ds = [[[SkyProjectDataSource alloc] initWithContext:self->context]
                               autorelease];
  [ds setFetchSpecification:[self fetchSpecificationForProjectDS]];
  self->projects = [[ds fetchObjects] retain];
  return self->projects;
}

- (NSArray *)fetchObjects {
  // TODO: split up this method!
  NSMutableArray      *docs;
  NSEnumerator        *enumerator;
  EOAdaptorChannel    *channel;
  BOOL                commitTransaction;
  NSDictionary        *docEditings;
  id                  doc;
  NSMutableDictionary *projectForId;
  NGMutableHashMap    *result;
  FMContext           *fmContext;
  
  fmContext = [[[FMContext alloc] initWithContext:self->context] autorelease];
  
  if (![self->context isTransactionInProgress]) {
    commitTransaction = YES;
    [self->context begin];
  }
  else
    commitTransaction = NO;
  
  channel = [[self->context valueForKey:LSDatabaseChannelKey] adaptorChannel];
  
  if ([[self projects] count] == 0)
    return [NSArray array];
  
  if ((docs = (id)[self fetchDocsWithChannel:channel]) == nil) {
    if (commitTransaction)
      [self->context rollback];
    NSLog(@"ERROR[%s]: Missing docs", __PRETTY_FUNCTION__);
    return nil;
  }
  
  if ([docs count] == 0)
    return [NSArray array];
  
  {
    id obj;
    
    enumerator   = [[self projects] objectEnumerator];
    projectForId = [NSMutableDictionary dictionaryWithCapacity:
                                        [[self projects] count]];
    
    while ((obj = [enumerator nextObject]) != nil)
      [projectForId setObject:obj forKey:[obj valueForKey:@"projectId"]];
  }
  
  docEditings = [self fetchDocEditingsForDocs:docs channel:channel];
  enumerator  = [docs objectEnumerator];
  result      = [[NGMutableHashMap alloc] initWithCapacity:[docs count]];
  while ((doc = [enumerator nextObject]) != nil) {
    NSDictionary *dic;
    NSDictionary *p;
    EOGlobalID   *rootGid;
    id editing;
    
    editing = [docEditings objectForKey:[doc valueForKey:@"documentId"]];
    p   = [projectForId objectForKey:[doc valueForKey:@"projectId"]];
    dic = [SkyProjectFileManager buildFileAttrsForDoc:doc editing:editing
                                 atPath:nil isVersion:NO projectId:nil
                                 projectName:[p valueForKey:@"name"]
                                 projectNumber:[p valueForKey:@"number"]
                                 fileAttrContext:fmContext];

    if ((rootGid = [dic objectForKey:@"SkyParentGID"]) != nil) {
      if (_showUnknownFiles(self))
	[result addObject:dic forKey:rootGid];
      else if (![[dic objectForKey:NSFileType] isEqual:NSFileTypeUnknown])
	[result addObject:dic forKey:rootGid];
    }
  }
  docs = nil;
  {
    NSEnumerator *enumerator;
    id           pid;
    NSArray *pgids;
    
    pgids = [[self->context accessManager] objects:[result allKeys]
					   forOperation:@"r"];
    
    enumerator = [pgids objectEnumerator];
    docs       = [NSMutableArray arrayWithCapacity:[result count] * 5];
      
    while ((pid = [enumerator nextObject]) != nil) {
      NSEnumerator *docEnum;
      id           obj;
      
      docEnum = [result objectEnumeratorForKey:pid];
      while ((obj = [docEnum nextObject])) {
	NSEnumerator *pEnum;
	id           p;

	obj = [[obj mutableCopy] autorelease];
	[docs addObject:obj];
	  
	pEnum = [[self projects] objectEnumerator];
	while ((p = [pEnum nextObject]) != nil) {
	  if ([[p valueForKey:@"projectId"]
		isEqual:[obj objectForKey:@"projectId"]]) {
	    [obj setObject:p forKey:@"project"];
	  }
	}
      }
    }
  }
  [result release]; result = nil;
  if (commitTransaction)
    [self->context commit];

  return docs;
}

@end /* SkyProjectDocumentDataSource */
