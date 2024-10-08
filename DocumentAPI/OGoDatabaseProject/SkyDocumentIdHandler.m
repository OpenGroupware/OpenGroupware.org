/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2006-2007 Helge Hess

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

#include "SkyDocumentIdHandler.h"
#include <OGoDatabaseProject/SkyProjectFileManager.h>
#include "common.h"

static int ChunkSize = 10000;

@interface SkyDocumentIdHandler(Private)
- (void)_fetchDataInContext:(id)_ctx;
@end /* SkyDocumentIdHandler(Private) */

@implementation SkyDocumentIdHandler

static EOSQLQualifier *trueQualifier = nil;

+ (id)handlerWithContext:(id)_ctx {
  SkyDocumentIdHandler *handler;
  
  if ((handler = [_ctx valueForKey:@"SkyDocumentIdHandler"]) == nil) {
    handler = [[[SkyDocumentIdHandler alloc] init] autorelease];
    [_ctx takeValue:handler forKey:@"SkyDocumentIdHandler"];
  }
  return handler;
}

- (id)init {
  if ((self == [super init])) {
    self->itemCnt = -1;
  }
  return self;
}

- (void)dealloc {
  [self resetData];
  [super dealloc];
}

/* operations */

- (int)projectIdForDocumentId:(int)_i context:(id)_ctx {
  /* private method, only used inside this class */
  int i;
  
  if (self->itemCnt == -1)
    [self _fetchDataInContext:_ctx];
  
  for (i = 0; i < self->itemCnt; i++) {
    if (self->documents[i] == _i)
      return self->projects[i];
  }
  return -1;
}
- (EOGlobalID *)projectGIDForDocumentGID:(EOGlobalID *)_gid 
  refreshOnFail:(BOOL)_refresh
  context:(id)_ctx
{
  /* 
     Note: Must use a signed int for the pid here because the method below
           returns -1 for missing projects.
  */
  int      pid;
  NSNumber *nr;
  
  if (_gid == nil)
    return nil;
  
  /* Note: remember that this returns -1 if the lookup failed */
  pid = [self projectIdForDocumentId:
		[[(EOKeyGlobalID *)_gid keyValues][0] unsignedLongValue]
              context:_ctx];
  nr = pid > 0 ? [NSNumber numberWithUnsignedLong:pid] : (NSNumber *)nil;
  
  if (![nr isNotNull]) {
    if (_refresh) {
      // TODO: this is suboptimal, can't we check for the ID?
      [self resetData];
      return [self projectGIDForDocumentGID:_gid
		   refreshOnFail:NO /* avoid recursion */
		   context:_ctx];
    }
    
    [self warnWithFormat:@"%s: got no project GID for document: %@",
	  __PRETTY_FUNCTION__, _gid];
    return nil;
  }
  
  return [EOKeyGlobalID globalIDWithEntityName:@"Project"
			keys:&nr keyCount:1 zone:NULL];
}
- (EOGlobalID *)projectGIDForDocumentGID:(EOGlobalID *)_gid context:(id)_ctx {
  return [self projectGIDForDocumentGID:_gid refreshOnFail:YES context:_ctx];
}

- (void)resetData {
  self->maxId    = -1;
  self->minId    = -1;
  self->itemCnt  = -1;
  self->itemSize = -1;
  
  if (self->documents != NULL) free(self->documents); self->documents = NULL;
  if (self->projects  != NULL) free(self->projects);  self->projects = NULL;
}

- (void)resizeBuffers {
  self->itemSize += ChunkSize;
  self->documents = realloc(self->documents, self->itemSize * sizeof(int));
  self->projects  = realloc(self->projects,  self->itemSize * sizeof(int));
}

- (void)_fetchDataInContext:(id)_ctx {
  // TODO: split method
  EOEntity         *doc;
  EOAttribute      *pAttr, *dAttr;
  BOOL             closeTrans;
  EOAdaptorChannel *channel;
  NSArray          *attrs;
  NSDictionary     *row;

  [self resetData];

  doc = [[[[_ctx valueForKey:LSDatabaseKey] adaptor] model]
                 entityNamed:@"Doc"];
  pAttr = [doc attributeNamed:@"projectId"];
  dAttr = [doc attributeNamed:@"documentId"];
  
  attrs = [NSArray arrayWithObjects:pAttr, dAttr, nil];
  
  if (![_ctx isTransactionInProgress]) {
    closeTrans = YES;
    [_ctx begin];
  }
  else
    closeTrans = NO;

  channel = [[_ctx valueForKey:LSDatabaseChannelKey] adaptorChannel];
  
  if (trueQualifier == nil) {
    trueQualifier = [[EOSQLQualifier alloc] initWithEntity:doc
					    qualifierFormat:@"1 = 1"
					    argumentsArray:nil];
  }
  if (![channel selectAttributes:attrs
                describedByQualifier:trueQualifier
                fetchOrder:nil lock:NO]) {
    [self errorWithFormat:@"could not select attributes: %@", attrs];
    if (closeTrans)
      [_ctx rollback];
    return;
  }
  
  self->itemCnt  = 0;
  self->itemSize = ChunkSize;
    
  self->documents = calloc(self->itemSize + 2, sizeof(int));
  self->projects  = calloc(self->itemSize + 2, sizeof(int));
     
  while (YES) {
    int               docId;
    NSAutoreleasePool *pool;

    pool = [[NSAutoreleasePool alloc] init];
    {  
      if ((row = [channel fetchAttributes:attrs withZone:NULL]) == nil) {
        [pool release];
        break;
      }
      
      self->itemCnt++;

      if (self->itemCnt > self->itemSize)
        [self resizeBuffers];
      
      self->projects[self->itemCnt - 1] = 
	[[row objectForKey:@"projectId"] intValue];
      
      docId = [[row objectForKey:@"documentId"] intValue];

      self->documents[self->itemCnt-1] = docId;

      if (docId < self->minId || self->minId == -1)
        self->minId = docId;

      if (docId > self->maxId || self->maxId == -1)
        self->maxId = docId;
    }
    [pool release];
  }
  
  [self logWithFormat:
	  @"Note: build cache itemSize=%d, itemCnt=%d for doc-id handler.",
          self->itemSize, self->itemCnt];
  if (closeTrans)
    [_ctx commit];
}

/* description */

- (void)appendAttributesToDescription:(NSMutableString *)ms {
  [ms appendFormat:@" item=#%i/%i min=%i,max=%i",
        self->itemCnt, self->itemSize, self->minId, self->maxId];
  
  if (self->documents != NULL) [ms appendFormat:@" d=%p", self->documents];
  if (self->projects  != NULL) [ms appendFormat:@" p=%p", self->projects];
}

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:128];
  [ms appendFormat:@"<%p[%@]:", self, NSStringFromClass([self class])];
  [self appendAttributesToDescription:ms];
  [ms appendString:@">"];
  return ms;
}

@end /* SkyDocumentIdHandler */
