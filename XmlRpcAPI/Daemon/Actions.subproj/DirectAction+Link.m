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

#include "DirectAction.h"
#include <LSFoundation/OGoObjectLinkManager.h>
#include <LSFoundation/OGoObjectLink.h>
#include "common.h"

@implementation DirectAction(Links)

- (OGoObjectLinkManager *)linkManager {
  return [[self commandContext] linkManager];
}

- (id)link_setLinkAction:(id)_source:(id)_target:(NSString *)_type
  :(NSString *)_label
{
  OGoObjectLink *link;
  EOGlobalID *source, *target;
  id ctx;

  ctx = [self commandContext];

  source = [[ctx documentManager] globalIDForURL:_source];  
  target = [[ctx documentManager] globalIDForURL:_target];  
  
  link = [[OGoObjectLink alloc] initWithSource:(id)source target:target
                                type:_type label:_label];
  [[self linkManager] createLink:link];
  ASSIGN(link, nil);
  return [NSNumber numberWithBool:YES];
}

- (id)_builObjLinkDicts:(NSArray *)_objLinks {
  NSEnumerator *enumerator;
  id           obj, ctx;
  NSMutableArray *array;
  NSMutableDictionary *dict;

  dict       = [NSMutableDictionary dictionaryWithCapacity:5];
  array      = [NSMutableArray arrayWithCapacity:[_objLinks count]];
  enumerator = [_objLinks objectEnumerator];
  ctx        = [self commandContext];

  while ((obj = [enumerator nextObject])) {
    id             tmp;

    [dict setObject:[[ctx documentManager] urlForGlobalID:[obj sourceGID]]
          forKey:@"source"];

    [dict setObject:[[ctx documentManager] urlForGlobalID:[obj globalID]]
          forKey:@"id"];

    if ((tmp = [obj targetGID]))
      [dict setObject:[[ctx documentManager] urlForGlobalID:tmp]
            forKey:@"target"];
    else
      [dict setObject:[[ctx documentManager] urlForGlobalID:[obj target]]
            forKey:@"target"];

    if ((tmp = [obj label])) {
      [dict setObject:tmp forKey:@"label"];
    }
    if ((tmp = [obj linkType])) {
      [dict setObject:tmp forKey:@"type"];
    }
    [array addObject:[[dict copy] autorelease]];
    [dict removeAllObjects];
  }
  return array;
}

- (id)link_getLinksToAction:(id)_target:(NSString *)_type {
  _target = [[[self commandContext] documentManager] globalIDForURL:_target];
  
  return [self _builObjLinkDicts:[[self linkManager]
                                        allLinksTo:_target type:_type]];
}

- (id)link_getLinksFromAction:(id)_source:(NSString *)_type {
  _source = [[[self commandContext] documentManager] globalIDForURL:_source];
  
  return [self _builObjLinkDicts:[[self linkManager]
                                        allLinksFrom:_source type:_type]];
}

- (id)link_deleteLinksFromAction:(id)_source:(NSString *)_type {
  id exc;
  
  _source = [[[self commandContext] documentManager] globalIDForURL:_source];
  
  exc = [[self linkManager] deleteLinksFrom:_source type:_type];

  if (exc)
    [exc raise];

  return nil;
}

- (id)link_deleteLinksToAction:(id)_target:(NSString *)_type {
  id exc;
  
  _target = [[[self commandContext] documentManager] globalIDForURL:_target];
  
  exc = [[self linkManager] deleteLinksTo:_target type:_type];

  if (exc)
    [exc raise];

  return nil;
}

- (id)link_deleteLinkAction:(id)_link {
  id      exc;

  _link = [[[self commandContext] documentManager] globalIDForURL:_link];
  
  exc = [[self linkManager] deleteLinkGID:_link];

  if (exc)
    [exc raise];

  return nil;
}

@end /* DirectAction(Defaults) */
