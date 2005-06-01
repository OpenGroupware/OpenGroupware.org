/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxAddressFolder.h"
#include <ZSFrontend/SxMapEnumerator.h>
#include "common.h"

@interface SxAddressFolder(Evo)

- (NSEnumerator *)runEvoQueryWithContactManager:(SxContactManager *)_cm 
  prefix:(NSString *)_prefix;

@end

@interface NSObject(Renderer)
+ (id)rendererWithFolder:(SxFolder *)_folder inContext:(id)_ctx;
- (void)setGenerateNormalizedSubject:(BOOL)_flag;
@end

@implementation SxAddressFolder(ZL)

/* ZideLook support */

- (id)zideLookRendererInContext:(id)_ctx {
  static Class ZLCLass = NULL;
  static BOOL didInit = NO;

  if (!didInit) {
    NSString *rcName = @"SxZLPersonRenderer";
    didInit = YES;
    
    if ((ZLCLass = NSClassFromString(rcName)) == Nil) {
      [self logWithFormat:
	      @"ERROR: attempt to use '%@' which could not be found."];
    }
  }
  return [ZLCLass rendererWithFolder:self inContext:_ctx];
}

- (id)performZLAddressQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  SxContactManager *cm;
  NSEnumerator *e;
  
  if ([self doExplainQueries]) {
    [self logWithFormat:@"ZL Address Query [depth=%@]: %@",
	    [[(WOContext *)_ctx request] headerForKey:@"depth"],
            [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  }
  
  // TODO: add a special ZideLook query
  cm = [self contactManagerInContext:_ctx];
  e  = [self runEvoQueryWithContactManager:cm prefix:nil];
  
  return [SxMapEnumerator enumeratorWithSource:e
			  object:[self zideLookRendererInContext:_ctx]
			  selector:@selector(renderEntry:)];
}

- (id)performZLABQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  SxContactManager *cm;
  NSEnumerator *e;
  id renderer;
  
  if ([self doExplainQueries]) {
    [self logWithFormat:@"ZL Address Book Query [depth=%@]: %@",
	    [[(WOContext *)_ctx request] headerForKey:@"depth"],
            [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  }
  
  // TODO: add a special ZideLook query
  cm = [self contactManagerInContext:_ctx];
  e  = [self runEvoQueryWithContactManager:cm prefix:nil];
  
  renderer = [self zideLookRendererInContext:_ctx];
  [renderer setGenerateNormalizedSubject:YES];
  
  return [SxMapEnumerator enumeratorWithSource:e
			  object:renderer
			  selector:@selector(renderEntry:)];
}

- (id)renderMsgInfoEntry:(id)_entry {
  // gets: pkey,version
  /* 
     davDisplayName      - firstname, lastname ?
     davResourceType     - fix: ""
     zlGenerationCount   - objectVersion
     outlookMessageClass - fix: "IPM.Contact"
     cdoDisplayType      - 0
  */
  NSMutableDictionary *record;
  NSString *url, *pkey;
  id  keys[6], vals[6];
  int p;
  
  if (_entry == nil) return nil;
  if ((record = _entry) == nil)
    return nil;
  
  pkey = [[record objectForKey:@"pkey"] stringValue];
  url = [NSString stringWithFormat:@"%@%@.vcf", [self baseURL], pkey];
  
  p = 0;
  keys[p] = @"{DAV:}href";     vals[p] = url;  p++;
  keys[p] = @"davDisplayName"; vals[p] = pkey; p++; // TODO ?
  keys[p] = @"zlGenerationCount"; 
  vals[p] = [_entry valueForKey:@"version"]; 
  p++;
  keys[p] = @"outlookMessageClass"; vals[p] = @"IPM.Contact"; p++;
  
  return [NSDictionary dictionaryWithObjects:vals forKeys:keys count:p];
}

- (id)performMsgInfoQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  /* the second query by ZideLook, get basic message infos */
  // davDisplayName, davResourceType, zlGenerationCount, outlookMessageClass,
  // cdoDisplayType
  SxContactManager *cm;
  NSEnumerator *e;
  
  [self logWithFormat:@"ZL 1 Query - address message baseinfo: %@",
          [[_fs selectedWebDAVPropertyNames] componentsJoinedByString:@","]];
  
  cm = [self contactManagerInContext:_ctx];
  e  = [self runListQueryWithContactManager:cm];
  
  return [SxMapEnumerator enumeratorWithSource:e
			  object:self selector:@selector(renderMsgInfoEntry:)];
}

- (int)cdoDisplayType {
  return 0x04000000;
}

@end /* SxAddressFolder(ZL) */
