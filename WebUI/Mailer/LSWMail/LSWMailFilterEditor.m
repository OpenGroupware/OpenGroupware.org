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

#include "LSWMailFilterEditor.h"
#include <OGoFoundation/LSWNotifications.h>
#include "common.h"

@interface LSWMailFilterEditor(Private)
- (NSArray *)folderList;
- (NSString *)folderString;
- (void)_calcFolderDictFrom:(NSArray *)_folders andPrefix:(NSString *)_prefix;
- (void)buildFolders;
@end

@implementation LSWMailFilterEditor

- (id)init {
  if ((self = [super init])) {
    self->isInNewMode = NO;
    //    ASSIGN(self->headerLabels,
    //           [[self config] valueForKey:@"MailHeaderFieldLabels"]);
    //    ASSIGN(self->filterKindLabels,
    //           [[self config] valueForKey:@"FilterKindLabels"]);

    self->matchList = [[NSArray allocWithZone:[self zone]]
                                initWithObjects:@"and", @"or", nil];

    self->folders = [[NSMutableDictionary allocWithZone:[self zone]]
                                          initWithCapacity:32];
    [self buildFolders];
  }
  return self;
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->filter);  
  RELEASE(self->filters); 
  RELEASE(self->entry);
  RELEASE(self->item);
  RELEASE(self->filterPos);
  //  RELEASE(self->headerLabels);
  //  RELEASE(self->filterKindLabels);
  RELEASE(self->matchList);
  RELEASE(self->folders);
  [super dealloc];
}
#endif

static NSMutableArray *_getFilter(LSWMailFilterEditor *self) {
  return self->filters;
};

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  if (self->filter)  { RELEASE(self->filter);  self->filter  = nil; }
  if (self->filters) { RELEASE(self->filters); self->filters = nil; }  

  {
    self->filters = [[[self session] getTransferObject] objectForKey:@"filters"];
    RETAIN(self->filters);
  }
  
  if ([_command hasPrefix:@"new"]) {
    self->oldFilterPos = -1;
    self->isInNewMode  = YES;
    self->filter = [[NSMutableDictionary allocWithZone:[self zone]]
                                         initWithCapacity:16];
    [self->filter setObject:[NSNumber numberWithInt:0] forKey:@"filterPos"];
    [self->filter setObject:@"<no entry>" forKey:@"name"];
    [self->filter setObject:@"and" forKey:@"match"];
  }

  else if ([_command hasPrefix:@"edit"]) {
    self->isInNewMode = NO;
    self->filter = [[[[self session] getTransferObject] objectForKey:@"filter"]
                            mutableCopy];

    self->oldFilterPos = [[self->filter objectForKey:@"filterPos"] intValue];
    NSAssert((self->filter != nil), @"no selected filter was set");
  }
  {
    NSMutableArray *entries = nil;

    entries = [self->filter objectForKey:@"entries"];
    
    if (entries == nil) {
      entries = [NSMutableArray arrayWithCapacity:16];
      [entries addObject:[NSMutableDictionary dictionaryWithCapacity:8]];
      [self->filter setObject:entries forKey:@"entries"];
    }
    else {
      entries = AUTORELEASE([entries mutableCopy]);
      [self->filter setObject:entries forKey:@"entries"];
      if ([entries count] == 0) {
        [entries addObject:[NSMutableDictionary dictionaryWithCapacity:8]];
      }
    }
  }
  { // set filterPos
    int length = 0;
    int cnt    = 0;
    id  allF   = nil;

    allF = _getFilter(self);

    if (self->filterPos) { RELEASE(self->filterPos); self->filterPos = nil; }

    self->filterPos = [[NSMutableArray allocWithZone:[self zone]]
                                       initWithCapacity:64];
  
    for (length = [allF count], cnt = 0;
         cnt < length;
         [self->filterPos addObject:
              [[NSNumber numberWithInt:cnt++] stringValue]]);
    
    if (self->isInNewMode == YES) {
      [self->filterPos addObject:[[NSNumber numberWithInt:cnt] stringValue]];
    }
  }
  return YES;
}

- (BOOL)forbidfewer {
  if ([[self->filter objectForKey:@"entries"] count] < 2)
    return YES;
  return NO;
}


- (id)more {
  [[self->filter objectForKey:@"entries"]
                 addObject:[NSMutableDictionary dictionaryWithCapacity:8]];
  return nil;
}

- (id)fewer {
  if ([self forbidfewer] == NO) {
    [[self->filter objectForKey:@"entries"] removeLastObject];
  }
  return nil;
}

- (BOOL)isSaveDisabled {
  return NO;
}

- (BOOL)isDeleteDisabled {
  return self->isInNewMode;
}

- (id)save {
  int            i, cnt   = 0;
  int            pos      = 0;
  NSMutableArray *entries = nil;
  NSMutableArray *allF    = nil;

  allF = _getFilter(self);
  
  if (self->oldFilterPos != -1)
    [allF removeObjectAtIndex:self->oldFilterPos];

  if ([self->filter valueForKey:@"name"] == nil) {
    [self->filter setObject:@"<no entry>" forKey:@"name"];
  }
  entries = [self->filter objectForKey:@"entries"];
  for (i = 0, cnt = [entries count]; i < cnt; i++) {
    if ([[entries objectAtIndex:i] valueForKey:@"string"] == nil) {
      [entries removeObjectAtIndex:i];
      i--;
      cnt--;
    }
  }

  pos = [[self->filter valueForKey:@"filterPos"] intValue];

  if (pos > [allF count] - 1)
    [allF addObject:self->filter];
  else
    [allF insertObject:self->filter atIndex:pos];

  // setPos
  for (i = 0, cnt = [allF count]; i < cnt; i++) {
    [[allF objectAtIndex:i] setObject:[NSNumber numberWithInt:i]
                            forKey:@"filterPos"];
  }
  [self run:@"email::set-filter", @"filters", allF, nil];
  [self postChange:LSWMailFilterDidChangeNotificationName onObject:nil];
  [self leavePage];
  return nil;
}

- (id)delete {
  int            i, cnt;
  NSMutableArray *allF  = nil;

  allF = [_getFilter(self) mutableCopy];
  AUTORELEASE(allF);
   
  [allF removeObjectAtIndex:self->oldFilterPos];
  for (i = 0, cnt = [allF count]; i < cnt; i++) {
    [[allF objectAtIndex:i] setObject:[NSNumber numberWithInt:i]
                            forKey:@"filterPos"];
  }
  [self run:@"email::set-filter", @"filters", allF, nil];
  [self postChange:LSWMailFilterDidChangeNotificationName onObject:nil];
  [self leavePage];
  return nil;
}

- (id)cancel {
  [self leavePage];
  return nil;
}

- (BOOL)isEditorPage {
  return YES;
}

- (NSString *)matchSuffix {
  //  NSString *result = [[[self config] valueForKey:@"MatchSuffixLabels"]
  //                           objectForKey:self->item];
  NSString* result = [[self labels] valueForKey:self->item];
  return (result != nil) ? result : self->item;
}

- (NSString *)mailHeaderLabel {
  //  NSString *result = [self->headerLabels objectForKey:self->item];
  NSString* result = [[self labels] valueForKey:self->item];
  return (result != nil) ? result : self->item;
}

- (NSString *)filterKindLabel {
  //  NSString *result = [self->filterKindLabels objectForKey:self->item];
  NSString* result = [[self labels] valueForKey:self->item];
  return (result != nil) ? result : self->item;
}

- (NSString *)theLabel {
  NSString *match = nil;
  
  match = [self-> filter objectForKey:@"match"];
  if (self->index == 0) {
    return [[self labels] valueForKey:@"the"];
  }
  else {
    if ([match isEqual:@"or"]) {
      return [[self labels] valueForKey:@"orThe"];
    }
    else
      return [[self labels] valueForKey:@"andThe"];
  }
  return nil;
}

// Folder stolen from LSWMailMove

- (NSArray *)folderList {
  NSArray *list =  [self->folders allKeys];
  return [list sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (void)_calcFolderDictFrom:(NSArray *)_folders andPrefix:(NSString *)_prefix {
  NSEnumerator *folderEnum = [_folders objectEnumerator];
  id           f;

  while ((f = [folderEnum nextObject])) {
    NSString *prefix  = _prefix;
    NSArray  *fs = [self runCommand:@"emailfolder::get", @"parentFolder", f,nil];

    prefix = [prefix stringByAppendingString:[f valueForKey:@"name"]];
    [self->folders setObject:f forKey:prefix];

    if ([fs count] > 0) {
      [self _calcFolderDictFrom:fs
            andPrefix:[prefix stringByAppendingString:@"@ @"]];      
    }
  }
}

- (void)buildFolders {
  NSArray *rootFolders=[self runCommandInTransaction:@"emailfolder::get", nil];
  [self _calcFolderDictFrom:rootFolders andPrefix:@""];
}

- (NSString *)folderString {
  NSString *newFolderName = @"";
  NSArray  *items         = [self->item componentsSeparatedByString:@"@ @"];
  int      i              = 0;

  while (i < [items count]-1) {
    newFolderName = [newFolderName stringByAppendingString:@"-- "];
    i++;
  }
  return [newFolderName stringByAppendingString:[items lastObject]];
}

- (void)setFilterFolder:(NSString *)_name {
  [self->filter setObject:[[self->folders objectForKey:_name]
                                          valueForKey:@"emailFolderId"]
                forKey:@"folder"];
}

- (id)filterFolder {
  id           folderId    = nil;
  NSEnumerator *enumerator = nil;
  id           obj         = nil;
  
  if ((folderId = [[self->filter objectForKey:@"folder"] stringValue]) == nil) {
    return nil;
  }
  enumerator = [self->folders keyEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    if ([[[[self->folders objectForKey:obj] valueForKey:@"emailFolderId"]
                          stringValue] isEqualToString:folderId]) {
      return obj;
    }
  }
  return nil;
};

- (void)setFilter:(id)_id    { ASSIGN(self->filter,    _id); }
- (void)setEntry:(id)_id     { ASSIGN(self->entry,     _id); }
- (void)setFilterPos:(id)_id { ASSIGN(self->filterPos, _id); }
- (void)setItem:(id)_id      { ASSIGN(self->item,      _id); }
- (void)setMatchList:(id)_id { ASSIGN(self->matchList, _id); }
- (void)setFolders:(id)_id   { ASSIGN(self->folders,   _id); }
- (void)setFolder:(id)_id    { ASSIGN(self->folder,    _id); }
- (void)setIndex:(int)_index { self->index = _index; }
 
- (id)filter    { return self->filter;    }
- (id)entry     { return self->entry;     }
- (id)filterPos { return self->filterPos; }
- (id)item      { return self->item;      }
- (id)matchList { return self->matchList; }
- (id)folders   { return self->folders;   }
- (id)folder    { return self->folder;    }
- (int)index    { return self->index;     }

@end
