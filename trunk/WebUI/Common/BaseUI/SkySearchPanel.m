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

#include <OGoFoundation/LSWContentPage.h>

@class NSString;

@interface SkySearchPanel : LSWContentPage
{
  NSDictionary *availablePanels;
  NSString     *tabKey;
  id           item;
}
@end

#import "common.h"

@implementation SkySearchPanel

- (id)init {
  if ((self = [super init])) {
    NGBundleManager *bm;
    WOSession       *sn;
    NSArray         *tmp;
    
    bm = [NGBundleManager defaultBundleManager];
    sn = [self session];

    /* query bundle manager for all available dockables */

    if ([(tmp = [bm providedResourcesOfType:@"SkySearchPanels"]) count] > 0) {
      NSMutableDictionary *dict;
      NSMutableSet   *uniquer;
      int count, i;

      count   = [tmp count];
      dict    = [NSMutableDictionary dictionaryWithCapacity:count];
      uniquer = [NSMutableSet   setWithCapacity:count];
      
      for (i = 0; i < count; i++) {
        NSDictionary   *cfgEntry;
        LSWContentPage *component;
        NSString       *componentName;
        NSString       *labelKey;
        NSString       *icon;
        NSString       *sortName;

        cfgEntry      = [tmp objectAtIndex:i];
        
        sortName      = [cfgEntry objectForKey:@"name"];
        componentName = [cfgEntry objectForKey:@"component"];
        labelKey      = [cfgEntry objectForKey:@"labelKey"];
        icon          = [cfgEntry objectForKey:@"icon"];

        if (componentName == nil) {
          [self logWithFormat:
                @"SkySearchPanel: missing name in bundle config %@", cfgEntry];
          continue;
        }

        sortName = (sortName) ? sortName : componentName;

        if ([uniquer containsObject:componentName])
          /* already found a bundle providing that resource */
          continue;

        [uniquer addObject:componentName];

        component = (LSWContentPage *)[self pageWithName:componentName];
        
        if (component) { /* ok, add panels */
          NSDictionary *entry;
          NSString     *label;

          label = [[component labels] valueForKey:labelKey];
          if (label == nil) label = labelKey;
          
          entry = [NSDictionary dictionaryWithObjectsAndKeys:
                                  sortName,      @"name",
                                  label,         @"label",
                                  component,     @"component",
                                  icon,          @"icon",
                                  nil];
          [dict setObject:entry forKey:sortName];
        }
      }
      self->availablePanels = [dict copyWithZone:[self zone]];
    }
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->availablePanels);
  RELEASE(self->item);
  RELEASE(self->tabKey);
  [super dealloc];
}
#endif

- (NSArray *)panels {
  return [self->availablePanels allValues];
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (NSString *)tabKey {
  return self->tabKey;
}
- (void)setTabKey:(NSString *)_tabKey {
  ASSIGN(self->tabKey, _tabKey);
}

@end

