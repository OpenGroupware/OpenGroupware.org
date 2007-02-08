/*
  Copyright (C) 2002-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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
#include <SaxObjC/XMLNamespaces.h>
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
  // TODO: is this used somewhere?
  [self logWithFormat:@"WARNING(%s): this method is hardcoded to Person!",
        __PRETTY_FUNCTION__];
  return @"Person";
}

- (Class)recordClassForKey:(NSString *)_key {
  // TODO: mostly DUP from SxAppointmentFolder
  NSString *n;
  
  [self debugWithFormat:@"record class for key: '%@'", _key];
  
  if ([_key length] == 0)
    return [super recordClassForKey:_key];
  
  if (!isdigit([_key characterAtIndex:0])) {
    Class clazz;
    
    [self logWithFormat:@"no digit, ask super for key: '%@'", _key];
    if ((clazz = [super recordClassForKey:_key]))
      return clazz;
    
    // intended fall through
    [self logWithFormat:@"  no digit super returned no key: '%@'", _key];
  }
  
  if ((n = [[self soClass] lookupKey:@"recordClass" inContext:nil]) == nil) {
    [self logWithFormat:@"ERROR: found no 'recordClass' in SoClass!"];
    return [super recordClassForKey:_key];
  }
  
  [self debugWithFormat:@"use %@ for key: '%@'", n, _key];
  return NSClassFromString(n);
}

- (id)childForExistingKey:(NSString *)_key inContext:(id)_ctx {
  id v;
  
  if ((v = [super childForExistingKey:_key inContext:_ctx]) == nil)
    return nil;
  
  if (![[self type] isEqualToString:@"public"])
    [v markAsPrivate];
  return v;
}

- (id)childForNewKey:(NSString *)_key inContext:(id)_ctx {
  id child;
  
  if ([[self type] isEqualToString:@"account"]) {
    [self logWithFormat:@"tried to access new account key (forbidden)."];
    return nil;
  }
  
  child = [[self recordClassForKey:_key] alloc];
  child = [[child initNewWithName:_key inFolder:self] autorelease];
  
  if (![[self type] isEqualToString:@"public"])
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
  // TODO: who uses that? isn't that overridden by all subclasses?
  //       - used by SxGroupFolder
  // TODO: move to a renderer class
  // contentlength,lastmodified,displayname,executable,resourcetype
  // checked-in,checked-out
  /*
    <key name="{DAV:}href"    >$baseURL$/$pkey$.vcf?sn=$sn$</key>
    <key name="davContentType">text/vcard</key>
    <key name="davDisplayName">$sn$, $givenname$</key>
  */
  NSMutableDictionary *record;
  NSString *url, *pkey;
  id tmp;
  
  if ((record = [[_entry mutableCopy] autorelease]) == nil)
    return nil;
  
  pkey = [[record objectForKey:@"pkey"] stringValue];
  url  = [NSString stringWithFormat:@"%@%@.vcf", [self baseURL], pkey];
  [record setObject:url  forKey:@"{DAV:}href"];
  [record setObject:pkey forKey:@"davDisplayName"];
  
  /* render etag */
  
  if ([(tmp = [record objectForKey:@"version"]) isNotNull]) {
    tmp = [@":" stringByAppendingString:[tmp stringValue]];
    tmp = [pkey stringByAppendingString:tmp];
    [record setObject:tmp forKey:@"davEntityTag"];
  }
  
  return record;
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
  e  = [self runListQueryWithContactManager:cm];
  return [SxMapEnumerator enumeratorWithSource:e 
			  object:self selector:@selector(renderListEntry:)];
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
  if (handler != NULL) return handler;
  
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

- (NSString *)davResourceType {
  static id coltype = nil;
  if (coltype == nil) {
    id gdCol, cdCol;
    
    cdCol = [[NSArray alloc] initWithObjects:
		     @"adbk", XMLNS_CARDDAV, nil];
    gdCol = [[NSArray alloc] initWithObjects:
		     @"vcard-collection", XMLNS_GROUPDAV, nil];
    coltype = [[NSArray alloc] initWithObjects:
				 @"collection", cdCol, gdCol, nil];
    [gdCol release];
    [cdCol release];
  }
  return coltype;
}

/* description */

- (NSString *)description {
  NSMutableString *ms;
  
  ms = [NSMutableString stringWithCapacity:64];
  [ms appendFormat:@"<0x%p[%@]:", self, NSStringFromClass([self class])];
  if (self->type != nil) [ms appendFormat:@" type=%@", self->type];
  [ms appendFormat:@" name=%@", [self nameInContainer]];
  [ms appendString:@">"];
  return ms;
}

@end /* SxAddressFolder */
