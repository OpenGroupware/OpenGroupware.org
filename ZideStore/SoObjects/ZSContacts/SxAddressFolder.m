/*
  Copyright (C) 2002-2004 SKYRIX Software AG

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
#include "SxAddress.h"
#include <Main/SxAuthenticator.h>
#include <ZSFrontend/SxMapEnumerator.h>
#include <NGObjWeb/SoWebDAVValue.h>
#include <NGObjWeb/WEClientCapabilities.h>
#include <ZSFrontend/EOQualifier+Additions.h>
#include <EOControl/EOControl.h>
#include "common.h"

#include <ZSBackend/SxContactManager.h>

@interface NSObject(Renderer)
+ (id)rendererWithFolder:(SxFolder *)_folder inContext:(id)_ctx;
- (id)initWithFolder:(SxFolder *)_folder inContext:(id)_ctx;
- (void)setGenerateNormalizedSubject:(BOOL)_flag;
- (BOOL)doesGenerateNormalizedSubject;
@end

@interface SxAddressFolder(Evo)

- (NSEnumerator *)runEvoQueryWithContactManager:(SxContactManager *)_cm 
  prefix:(NSString *)_prefix;

@end

@implementation SxAddressFolder

- (void)dealloc {
  [self->type release];
  [super dealloc];
}

/* accessors */

- (void)setType:(NSString *)_type {
  ASSIGNCOPY(self->type, _type);
}
- (NSString *)type {
  return self->type;
}

- (NSString *)entity {
  return @"Person";
}

- (id)childForNewKey:(NSString *)_key inContext:(id)_ctx {
  id child;
  
  if ([[self type] isEqualToString:@"account"]) {
    [self logWithFormat:@"tried to access new account key (forbidden)."];
    return nil;
  }
  
  child = [[self recordClassForKey:_key] alloc];
  child = [[child initNewWithName:_key inFolder:self] autorelease];
  
  if ([[self type] isEqualToString:@"public"])
    ;
  else
    [child markAsPrivate];
  
  return child;
}

/* actions */

- (NSString *)defaultMethodNameInContext:(id)_ctx {
  return @"view";
}

/* query */

- (SxContactManager *)contactManagerInContext:(id)_ctx {
  LSCommandContext *cmdctx;
  SxContactManager *sm;

  if ((cmdctx = [self commandContextInContext:_ctx]) == nil) {
    [self logWithFormat:@"got no SKYRiX context for context: %@", _ctx];
    return nil;
  }
  if ((sm = [SxContactManager managerWithContext:cmdctx]) == nil) {
    [self logWithFormat:@"got no contact manager for SKYRiX context: %@", 
            cmdctx];
    return nil;
  }
  return sm;
}

- (SxContactSetIdentifier *)contactSetID {
  if ([self doExplainQueries])
    [self debugWithFormat:@"folder should override contact-set identifier !"];
  return nil;
}

- (int)zlGenerationCount {
  SxContactSetIdentifier *sid;
  
  if ((sid = [self contactSetID]) == nil)
    return [super zlGenerationCount];
  
  return [[self contactManagerInContext:nil] generationOfContactSet:sid];
}

/* FileSystem */

- (id)renderListEntry:(id)_entry {
  // contentlength,lastmodified,displayname,executable,resourcetype
  // checked-in,checked-out
  /*
    <key name="{DAV:}href"    >$baseURL$/$pkey$.vcf?sn=$sn$</key>
    <key name="davContentType">text/vcard</key>
    <key name="davDisplayName">$sn$, $givenname$</key>
  */
  NSMutableDictionary *record;
  NSString *url, *pkey;
  
  if ((record = [_entry mutableCopy]) == nil)
    return nil;
  
  pkey = [[record objectForKey:@"pkey"] stringValue];
  url = [NSString stringWithFormat:@"%@%@.vcf", [self baseURL], pkey];
  [record setObject:url  forKey:@"{DAV:}href"];
  [record setObject:pkey forKey:@"davDisplayName"];
  return [record autorelease];
}

- (NSEnumerator *)runListQueryWithContactManager:(SxContactManager *)_cm {
  SxContactSetIdentifier *sid = [self contactSetID];
  if (sid == nil) {
    [self logWithFormat:@"subclass needs to override list-query method !"];
    return nil;
  }
  return [_cm listContactSet:[self contactSetID]];
}

- (NSString *)getIDsAndVersionsInContext:(id)_ctx {
  SxContactSetIdentifier *sid;
  SxContactManager *cm;
  
  cm = [self contactManagerInContext:_ctx];
  if ((sid = [self contactSetID])) {
    NSString *csv;
    
    if ((csv = [cm idsAndVersionsCSVForContactSet:sid]) == nil) {
      [self logWithFormat:@"ERROR: could not fetch contact set !"];
      return nil;
    }
    return csv;
  }
  else { /* this is still required for group[s] folders ! */
    NSMutableString  *ms;
    NSEnumerator *e;
    NSDictionary *address;
    id       version;
    unsigned i = 0;
    
    ms = [NSMutableString stringWithCapacity:4096];
    e  = [self runListQueryWithContactManager:cm];
    while ((address = [e nextObject])) {
      i++;
      version = [address objectForKey:@"version"];
      if (![version isNotNull]) version = @"1";
      
      [ms appendFormat:@"%i:%@\n", 
            [[address objectForKey:@"pkey"] intValue],
            version];
    }
    if ([self doExplainQueries])
      [self debugWithFormat:@"[ids and versions] processed %i contacts", i];
    return ms;
  }
}
- (int)cdoContentCount {
  SxContactSetIdentifier *sid;
  SxContactManager *cm;
  int count;
  
  cm = [self contactManagerInContext:[[WOApplication application] context]];
  if ((sid = [self contactSetID])) 
    count = [cm countOfContactSet:sid];
  else {
    NSEnumerator *e;
    
    if ((e = [self runListQueryWithContactManager:cm]) == nil)
      count = -1;
    else {
      for (count = 0; [e nextObject]; count++) ;
    }
  }
  if (count == -1) {
    [self logWithFormat:@"failed to fetch number of contacts .."];
    return 0;
  }
  return count;
}

- (id)performListQuery:(EOFetchSpecification *)_fs inContext:(id)_ctx {
  SxContactManager *cm;
  NSEnumerator *e = nil;
  
  cm = [self contactManagerInContext:_ctx];
  e = [self runListQueryWithContactManager:cm];
  return [SxMapEnumerator enumeratorWithSource:e 
			  object:self selector:@selector(renderListEntry:)];
}

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

/* general */

- (SEL)fetchSelectorForQuery:(EOFetchSpecification *)_fs
  onAttributeSet:(NSSet *)propNames
  inContext:(id)_ctx
{
  static NSSet *cadaverSet   = nil;
  static NSSet *zlABSet      = nil;
  static NSSet *zlAddrQuery  = nil;
  static NSSet *evoSubFolder = nil;
  static NSSet *evoQuery     = nil;
  SEL handler = NULL;
  
  /* cache sets */
  if (cadaverSet == nil)
    cadaverSet = [[self propertySetNamed:@"CadaverListSet"] copy];
  if (zlABSet == nil)
    zlABSet = [[self propertySetNamed:@"ZideLookABQuery"] copy];
  if (zlAddrQuery == nil)
    zlAddrQuery = [[self propertySetNamed:@"ZideLookAddrQuery"] copy];
  if (evoSubFolder == nil)
    evoSubFolder = [[self propertySetNamed:@"EvolutionSubFolderSet"] copy];
  if (evoQuery == nil)
    evoQuery = [[self propertySetNamed:@"EvolutionQuerySet"] copy];
  
  /* check sets */
  
  if ([propNames isSubsetOfSet:cadaverSet])
    return @selector(performListQuery:inContext:);
  if ([propNames isSubsetOfSet:evoQuery]) 
    return @selector(performEvoQuery:inContext:);
  
  if ([propNames isSubsetOfSet:evoSubFolder])
    return @selector(performEvoSubFolderQuery:inContext:);
  
  handler = [super fetchSelectorForQuery:_fs onAttributeSet:propNames
                   inContext:_ctx];
  if (handler) return handler;
  
  /* ZideLook Address Query */
  if ([propNames isSubsetOfSet:zlAddrQuery])
    return @selector(performZLAddressQuery:inContext:);
  
  /* ZideLook Outlook AB Query */
  if ([propNames isSubsetOfSet:zlABSet])
    return @selector(performZLABQuery:inContext:);
  
#if 0 && DEBUG
  {
    NSMutableSet *s;
    s = [propNames mutableCopy];
    
    [s minusSet:zlABSet];
    
    [self logWithFormat:@"SUBSET with AB-set:\n|%@|\nWITH:\n|%@|", 
            [[[zlABSet allObjects] 
               sortedArrayUsingSelector:@selector(compare:)] 
               componentsJoinedByString:@","],
            [[[s allObjects]
               sortedArrayUsingSelector:@selector(compare:)]
               componentsJoinedByString:@","]];
  }
#endif
  
  return handler;
}

- (SEL)defaultFetchSelectorForZLQuery {
  return @selector(performZLAddressQuery:inContext:);
}

/* Exchange properties */

- (NSString *)outlookFolderClass {
  return @"IPF.Contact";
}

- (id)davResourceType {
  static id coltype = nil;
  if (coltype == nil) {
    id tmp;
    tmp = [NSArray arrayWithObjects:@"vcard-collection", @"GROUPWARE:", nil];
    coltype = [[NSArray alloc] initWithObjects:@"collection", tmp, nil];
  }
  return coltype;
}

- (int)cdoDisplayType {
  return 0x04000000;
}

- (NSString *)folderAllPropSetName {
  return @"DefaultContactFolderProperties";
}
- (NSString *)entryAllPropSetName {
  return @"DefaultContactProperties";
}

- (NSArray *)defaultWebDAVPropertyNamesInContext:(id)_ctx {
  /* overridden for efficiency (caches array in static var) */
  static NSArray *defFolderNames = nil;
  static NSArray *defEntryNames  = nil;
  
  if (defFolderNames == nil) {
    defFolderNames =
      [[[self propertySetNamed:[self folderAllPropSetName]] allObjects] copy];
  }
  if (defEntryNames == nil) {
    defEntryNames =
      [[[self propertySetNamed:[self entryAllPropSetName]] allObjects] copy];
  }
  return [self isBulkQueryContext:_ctx] ? defEntryNames : defFolderNames;
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:64];
  [ms appendFormat:@"<0x%08X[%@]:", self, NSStringFromClass([self class])];
  if (self->type) [ms appendFormat:@" type=%@", self->type];
  [ms appendFormat:@" name=%@", [self nameInContainer]];
  [ms appendString:@">"];
  return ms;
}

@end /* SxAddressFolder */
