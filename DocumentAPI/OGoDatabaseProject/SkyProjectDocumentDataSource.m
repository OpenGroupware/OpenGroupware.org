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

#include "SkyProjectDocumentDataSource.h"
#include "SkyProjectFileManager.h"
#include <OGoProject/SkyProjectDataSource.h>
#include "FMContext.h"
#include "common.h"

static inline BOOL _showUnknownFiles(id self) {

static BOOL showUnknownFiles_value = NO;
static BOOL showUnknownFiles_flag  = NO;

 if (!showUnknownFiles_flag) {
    showUnknownFiles_flag  = YES;
    showUnknownFiles_value = [[NSUserDefaults standardUserDefaults]
                                   boolForKey:@"SkyProjectFileManager_show_"
                                              @"unknown_files"];
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
    ASSIGN(self->context, _ctx);
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->context);
  RELEASE(self->fetchSpecification);
  RELEASE(self->projects);
  [super dealloc];
}

/*

select c1.description from project p1, project_company_assignment a1, company c1 where p1.fname = '007' and p1.project_id = a1.project_id and a1.company_id = c1.company_id;

*** alle erlaubten Prozesse ***

j = 100407
select distinct p1.kind FROM project p1 ;

  select distinct p1.fname
  FROM project p1, project_company_assignment a1, company c1 
  where p1.kind <> '00_invoiceProject' OR
        p1.kind <> '05_historyProject' OR
        p1.kind <> '10_edcProject' OR
        p1.kind <> '15_accountLog' OR
        p1.kind is NULL AND
    (p1.owner_id = 100407 OR 
      (p1.project_id = a1.project_id AND a1.company_id = c1.company_id AND 
       (c1.company_id = 100407 or c1.company_id in
          (SELECT cc1.company_id FROM company cc1, company_assignment aa1
             WHERE cc1.company_id = aa1.company_id
                   AND aa1.sub_company_id = 100407)) 
       AND (a1.access_right like '%r%' OR a1.access_right like '%m%')));

*** alle erlaubten Prozesse ***

  select * from project p1, project_company_assignment a1, company c1 \
  where p1.kind not in ('invoiceProject', 'historyProject', 'edcProject', \
  'accountLog') AND \
    (p1.owner_id = 'owner' OR \
      (p1.project_id = a1.project_id AND a1.company_id = c1.company_id AND \
       (c1.company_id = 'owner` or c1.company_id in (team_ids)) \
       AND (c1.access_right like '%r%' OR c1.access_right like '%m%')))

       
 */

/* Hints:
     ProjectKind: archived, private

   without
             invoiceProject
             historyProject
             edcProject
             accountLog
   
   Qualifier:
     NSFileType, NSFileSubject, NSFileName
*/

- (EOFetchSpecification *)fetchSpecification {
  return self->fetchSpecification;
}
- (void)setFetchSpecification:(EOFetchSpecification *)_fs {
  ASSIGN(self->fetchSpecification, _fs);
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
  while ((obj = [kinds nextObject])) {
    EOQualifier *qual;

    qual = [EOQualifier qualifierWithQualifierFormat:@"type=%@", obj];
    [quals addObject:qual];
  }
  if ([quals count]) {
    fs = [[EOFetchSpecification alloc] init];
    AUTORELEASE(fs);
    [fs setQualifier:[[[EOOrQualifier alloc] initWithQualifierArray:quals]
                                      autorelease]];
  }
  return fs;
}

- (NSArray *)fetchDocsWithChannel:(EOAdaptorChannel *)_channel
{
  NSArray          *projectIds;
  EOQualifier      *qual;
  int              maxInQual = 250, cnt, pcnt;
  EOEntity         *entity;
  NSMutableArray   *result;

  static NSArray *docAttrs = nil;

  qual = [self->fetchSpecification qualifier];

  if (![SkyProjectFileManager supportQualifier:qual]) {
    NSLog(@"ERROR(%s) qualifier %@ is not supported", __PRETTY_FUNCTION__,
          qual);
    return nil;
  }
  entity = [[[[self->context valueForKey:LSDatabaseKey] adaptor] model]
                             entityNamed:@"Doc"];
  if (!docAttrs) {
    docAttrs = [[entity attributes] retain];
  }
  result     = [[NSMutableArray alloc] initWithCapacity:32];
  projectIds = [[self projects] mappedArrayUsingSelector:@selector(projectId)];
  qual       = [SkyProjectFileManager convertQualifier:qual projectId:nil
                                      evalInMemory:NULL];
  cnt        = 0;
  pcnt       = [projectIds count];
  
  while (cnt <= pcnt) {
    NSArray        *subProjectIds;
    EOSQLQualifier *sqlQual;
    NSString       *expr;
    NSDictionary   *row;

    subProjectIds = [projectIds subarrayWithRange:
                                NSMakeRange(cnt, (maxInQual+cnt)<pcnt?
                                            maxInQual:(pcnt-cnt))];
    cnt     +=maxInQual;
    expr     = [qual sqlExpressionWithAdaptor:
                         [[_channel adaptorContext] adaptor]
                         attributes:docAttrs];
    expr     = [expr stringByAppendingString:
                     [NSString stringWithFormat:@" AND (projectId IN (%@))",
                         [subProjectIds componentsJoinedByString:@","]]];
#if LIB_FOUNDATION_LIBRARY
    expr     = [expr stringByReplacingString:@"%" withString:@"%%"];
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

    while ((row = [_channel fetchAttributes:docAttrs withZone:NULL]))
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

    subDocs   = [_docs subarrayWithRange:
			 NSMakeRange(cnt, (maxInQual+cnt)<pcnt?
				     maxInQual:(pcnt-cnt))];
    cnt      += maxInQual;
    // TODO: should use "safe" pkey join for IN (like in LSDBBaseCommand)
    qualifier = [[EOSQLQualifier alloc]
                                 initWithEntity:entity
                                 qualifierFormat:@"(%A = %@)"
                                 @" AND (%A = '%@') AND (%A IN (%@))",
                                 @"toDoc.isFolder",
                                 [NSNumber numberWithBool:NO],
                                 @"toDoc.status", @"edited",
                                 @"toDoc.documentId",
                                 [[subDocs map:@selector(objectForKey:)
                                           with:@"documentId"]
                                           componentsJoinedByString:@","]];
    if (![_channel selectAttributes:editingAttrs
                  describedByQualifier:qualifier fetchOrder:nil lock:NO]) {
      NSLog(@"ERROR[%s]: select failed for qualifier %@ attrs %@ ",
            __PRETTY_FUNCTION__, qualifier, editingAttrs);
      [qualifier release]; qualifier = nil;
      return nil;
    }
      
    while ((row = [_channel fetchAttributes:editingAttrs withZone:NULL])) 
      [result setObject:row forKey:[row objectForKey:@"documentId"]];
    
    [qualifier release]; qualifier = nil;
  }
  return result;
}

- (NSArray *)projects {
  if (self->projects == nil) {
    SkyProjectDataSource *ds;
  
    ds = [[[SkyProjectDataSource alloc] initWithContext:self->context]
                                 autorelease];
    [ds setFetchSpecification:[self fetchSpecificationForProjectDS]];
  
    self->projects = [[ds fetchObjects] retain];
  }
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
  else {
    commitTransaction = NO;
  }
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
    
    enumerator = [[self projects] objectEnumerator];
    projectForId = [NSMutableDictionary dictionaryWithCapacity:
                                        [[self projects] count]];

    while ((obj = [enumerator nextObject])) {
      [projectForId setObject:obj forKey:[obj valueForKey:@"projectId"]];
    }
  }
  
  docEditings = [self fetchDocEditingsForDocs:docs channel:channel];
  enumerator  = [docs objectEnumerator];
  result      = [[NGMutableHashMap alloc] initWithCapacity:[docs count]];
  while ((doc = [enumerator nextObject])) {
    NSDictionary *dic;
    NSDictionary *p;

    p   = [projectForId objectForKey:[doc valueForKey:@"projectId"]];
    dic = [SkyProjectFileManager buildFileAttrsForDoc:doc
                                 editing:
                                 [docEditings objectForKey:
                                              [doc valueForKey:@"documentId"]]
                                 atPath:nil
                                 isVersion:NO
                                 projectId:nil
                                 projectName:[p valueForKey:@"name"]
                                 projectNumber:[p valueForKey:@"number"]
                                 fileAttrContext:fmContext];

    {
      id rootGid;

      if ((rootGid = [dic objectForKey:@"SkyParentGID"])) {
        if (_showUnknownFiles(self)) {
          [result addObject:dic forKey:rootGid];
        }
        else if (![[dic objectForKey:NSFileType] isEqual:NSFileTypeUnknown]) {
          [result addObject:dic forKey:rootGid];
        }
      }
    }
  }
  docs = nil;
  {
    NSArray *pgids;
    
    
    pgids = [[self->context accessManager] objects:[result allKeys]
                                          forOperation:@"r"];

    {
      NSEnumerator *enumerator;
      id           pid;

      enumerator = [pgids objectEnumerator];
      docs       = [NSMutableArray arrayWithCapacity:[result count] * 5];
      
      while ((pid = [enumerator nextObject])) {
        NSEnumerator *docEnum;
        id           obj;

        docEnum = [result objectEnumeratorForKey:pid];

        while ((obj = [docEnum nextObject])) {
          NSEnumerator *pEnum;
          id           p;

          obj = [obj mutableCopy];
          AUTORELEASE(obj);
          [docs addObject:obj];

          pEnum = [[self projects] objectEnumerator];

          while ((p = [pEnum nextObject])) {
            if ([[p valueForKey:@"projectId"]
                    isEqual:[obj objectForKey:@"projectId"]]) {
              [obj setObject:p forKey:@"project"];
            }
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
