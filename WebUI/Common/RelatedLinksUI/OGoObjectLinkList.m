/*
  Copyright (C) 2003-2004 SKYRIX Software AG

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

/*
  OGoObjectLinkList

  This component is intended for the object "link" tab which contains 
  information about links attached to an object and links going to the
  object in question.

  Bindings:
    object - the "base" object for the link queries
*/

@class NSArray, NSString;
@class EOKeyGlobalID;

@interface OGoObjectLinkList : OGoComponent
{
  EOKeyGlobalID *gid;
  id         object;
  NSArray    *attachedLinks;
  NSArray    *linksPointingToObject;
  NSArray    *selectedLinks;
  NSString   *linkType;
  
  id currentLink;
}

@end

#include "common.h"
#include <NGObjWeb/WORequest.h>

@interface NSObject(Links)
- (EOGlobalID *)globalID;
@end

@implementation OGoObjectLinkList

static NSDictionary *OGoObjectLinkTypeMap = nil;
static NSArray      *OGoObjectLinkTypes   = nil;

+ (int)version {
  return [super version] + 0 /* v2 */;
}
+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
  
  OGoObjectLinkTypeMap = [[ud dictionaryForKey:@"OGoObjectLinkTypeMap"] copy];
  OGoObjectLinkTypes   = [[OGoObjectLinkTypeMap allKeys] copy];
}

- (NSNotificationCenter *)notificationCenter {
  return [NSNotificationCenter defaultCenter];
}

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter *nc;
    
    nc = [self notificationCenter];
    [nc addObserver:self selector:@selector(linkSetChanged:)
        name:@"OGoLinkWasCreated" object:nil];
    [nc addObserver:self selector:@selector(linkSetChanged:)
        name:@"OGoLinkWasDeleted" object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->linkType              release];
  [self->gid                   release];
  [self->object                release];
  [self->attachedLinks         release];
  [self->linksPointingToObject release];
  [self->selectedLinks         release];
  [self->currentLink           release];
  [super dealloc];
}

/* reset for refetch on demand */

- (void)resetCaches {
  /* reset data (and refetch on next click */
  /* Note: we loose the selection, but this should be OK */
  [self->selectedLinks         release]; self->selectedLinks         = nil;
  [self->attachedLinks         release]; self->attachedLinks         = nil;
  [self->linksPointingToObject release]; self->linksPointingToObject = nil;
}

/* notifications */

- (void)linkSetChanged:(NSNotification *)_notification {
  [self resetCaches];
}

- (void)sleep {
  /* release temporary vars */
  [self->currentLink release]; self->currentLink = nil;
  [self->linkType    release]; self->linkType    = nil;
  [super sleep];
}

/* accessors */

- (void)setObject:(id)_object {
  if (self->object == _object)
    return;
  
  [self->gid release]; self->gid = nil;
  ASSIGN(self->object, _object);
  
  if ([self->object isKindOfClass:[EOKeyGlobalID class]])
    self->gid = [self->object retain];
  else if ([self->object respondsToSelector:@selector(globalID)])
    self->gid = [[self->object globalID] retain];
  else if (self->object) {
    self->gid = [[self->object valueForKey:@"globalID"] retain];
    if (self->gid == nil)
      [self logWithFormat:@"ERROR: cannot extract GID from: %@", self->object];
  }
}
- (id)object {
  return self->object;
}
- (EOKeyGlobalID *)gid {
  return self->gid;
}

- (NSNumber *)sourcePrimaryKey {
  if (self->gid == nil || ![self->gid isKindOfClass:[EOKeyGlobalID class]])
    return nil;
  
  return [(EOKeyGlobalID *)self->gid keyValues][0];
}
- (NSString *)sourceEntity {
  if (self->gid == nil || ![self->gid isKindOfClass:[EOKeyGlobalID class]])
    return nil;
  
  return [(EOKeyGlobalID *)self->gid entityName];
}

- (BOOL)hasGID {
  return self->gid ? YES : NO;
}

- (void)setCurrentLink:(OGoObjectLink *)_value {
  ASSIGN(self->currentLink, _value);
}
- (OGoObjectLink *)currentLink {
  return self->currentLink;
}

- (void)setLinkType:(NSString *)_value {
  ASSIGN(self->linkType, _value);
}
- (NSString *)linkType {
  return self->linkType;
}

- (void)setSelectedLinks:(NSArray *)_links {
  ASSIGN(self->selectedLinks, _links);
}
- (NSArray *)selectedLinks {
  return self->selectedLinks;
}

/* localized */

- (NSString *)linkTypeLabel {
  NSString *type, *label, *labelKey;
  
  type = [[self currentLink] valueForKey:@"linkType"];
  if (![type isNotNull])
    type = @"unset";
  
  labelKey = [@"linkType_" stringByAppendingString:type];
  label    = [[self labels] valueForKey:labelKey];
  return [label isEqualToString:labelKey] ? type : label;
}

/* link manager */

- (OGoObjectLinkManager *)linkManager {
  return [[(OGoSession *)[self existingSession] commandContext] linkManager];
}

/* query accessors ... */

- (NSString *)sourceObjectLabel {
  return [[self session] labelForObject:[[self currentLink] sourceGID]];
}

- (NSArray *)linksPointingToObject {
  if (self->linksPointingToObject)
    return self->linksPointingToObject;

  self->linksPointingToObject =
    [[[self linkManager] allLinksTo:[self gid]] shallowCopy];
  
  return self->linksPointingToObject;
}

- (NSArray *)attachedLinks {
  if (self->attachedLinks)
    return self->attachedLinks;

  self->attachedLinks =
    [[[self linkManager] allLinksFrom:[self gid] type:[self linkType]] 
                         shallowCopy];
  
  return self->attachedLinks;
}

- (NSArray *)linkTypeNames {
  return OGoObjectLinkTypes;
}
- (BOOL)hasConfiguredLinkTypes {
  return [OGoObjectLinkTypes count] > 0 ? YES : NO;
}

/* entity labels */

- (NSString *)entityLabelForGlobalID:(EOGlobalID *)tgid typeSelector:(SEL)_ts {
  id labels;
  
  labels = [self labels];
  
  if ([tgid respondsToSelector:@selector(entityName)]) {
    NSString *ename;
    
    ename = [tgid entityName];
    return [labels valueForKey:[@"linkentity_" stringByAppendingString:ename]];
  }
  
  // TODO: this requires currentLink!
  /* OK, not a key global ID */
  if (_ts != NULL && [[self currentLink] respondsToSelector:_ts])
    return [labels valueForKey:[[self currentLink] performSelector:_ts]];
  
  return [labels valueForKey:@"linkentity_external"];
}

- (NSString *)currentLinkEntityLabel {
  return [self entityLabelForGlobalID:(id)[[self currentLink] targetGID]
               typeSelector:@selector(targetType)];
}
- (NSString *)currentLinkSourceEntityLabel {
  return [self entityLabelForGlobalID:(id)[[self currentLink] sourceGID]
               typeSelector:@selector(sourceType)];
}

/* actions */

- (id)deleteLink {
  OGoObjectLinkManager *linkManager;
  LSCommandContext *cmdctx;
  OGoObjectLink    *link;
  NSException      *error;
  
  cmdctx      = [[self session] commandContext];
  linkManager = [cmdctx linkManager];
  link        = [self currentLink];
  
  if (link == nil)
    return nil;
  
  if ((error = [linkManager deleteLink:link])) {
    [self logWithFormat:@"ERROR: could not delete link %@: %@", link, error];
    [[[self context] page] setErrorString:
            [@"Delete failed: " stringByAppendingString:[error reason]]];
    [cmdctx rollback];
    return nil;
  }
  
  [self resetCaches];
  [[self notificationCenter] postNotificationName:@"OGoLinkWasDeleted"
                             object:[self currentLink]];
  return nil;
}

- (id)createLinkAction {
  LSCommandContext *cmdctx;
  OGoContentPage *page;
  WORequest  *rq;
  NSString   *newLinkType;
  NSNumber   *newSourceId;
  EOGlobalID *newSourceGID;
  NSString   *editorPageName;
  id tmp;
  
  if ((cmdctx = [[self session] commandContext]) == nil) {
    [self logWithFormat:@"ERROR: missing command context!"];
    return nil;
  }
  if ((page = [[[self existingSession] navigation] activePage]) == nil) {
    [self logWithFormat:@"ERROR: missing active page!"];
    return nil;
  }
  
  rq          = [[self context] request];
  newLinkType = [rq formValueForKey:@"linktype"];
  newSourceId = ((tmp = [rq formValueForKey:@"sourceId"]))
    ? [NSNumber numberWithUnsignedInt:[tmp unsignedIntValue]]
    : nil;
  
  if ([newLinkType isEqualToString:WONoSelectionString]) {
    [page setErrorString:@"please specify a linktype in the popup!"];
    return page;
  }
  
  if ([newLinkType length] == 0)
    newLinkType = @"generic";

  editorPageName = [OGoObjectLinkTypeMap objectForKey:newLinkType];
  if ([editorPageName length] == 0) {
    [page setErrorString:
            [@"found no component to create links of specified type: "
              stringByAppendingString:newLinkType]];
    return page;
  }
  
  if ([newSourceId intValue] < 9000) {
    [page setErrorString:@"missing source id for link!"];
    return page;
  }
  
  newSourceGID = [[cmdctx typeManager] globalIDForPrimaryKey:newSourceId];
  if (newSourceGID == nil) {
    [page setErrorString:@"did not find object specified as source for link!"];
    return page;
  }
  
  if ((tmp = [self pageWithName:editorPageName]) == nil) {
    [page setErrorString:
            [@"could not find configured link creator page: " 
              stringByAppendingString:editorPageName]];
    return page;
  }
  
  /* setup link editor */
  
  page = tmp;
  [page takeValue:newLinkType  forKey:@"linkType"];
  [page takeValue:newSourceGID forKey:@"sourceGlobalID"];
  // TODO: we might want to pass in some info on where we are coming from
  
#if 0
  [self debugWithFormat:@"create link of type %@ source %@(%@) ...",
          [rq formValueForKey:@"linktype"], 
          [rq formValueForKey:@"sourceId"],
          [rq formValueForKey:@"entityName"]];
#endif
  
  return page;
}

@end /* OGoObjectLinkList */
