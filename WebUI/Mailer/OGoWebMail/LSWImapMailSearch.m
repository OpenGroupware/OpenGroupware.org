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

#include "LSWImapMailSearch.h"
#include "LSWImapMails.h"
#include "SkyImapMailDataSource.h"
#include "SkyImapMailListState.h"
#include "common.h"

@interface LSWImapMailSearch(Private)
- (id)search;
@end

@implementation LSWImapMailSearch

- (id)init {
  if ((self = [super init])) {
    self->flags  = [[NSMutableDictionary alloc] initWithCapacity:4];
    self->infos  = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    self->opList = [[NSArray alloc] initWithObjects:@"AND", @"OR", nil];
    
    self->sortOperation = @"OR";
    self->dataSource = [[SkyImapMailDataSource alloc] init];
    self->state
      = [[SkyImapMailListState alloc] initWithDefaults:
                                      (id)[[self session] userDefaults]];
    [self->state setName:@"SearchMailList"];
    
    [self->dataSource setDoSubFolders:YES];
  }
  return self;
}

- (void)dealloc {
  [self->rootFolder    release];
  [self->infos         release];
  [self->opList        release];
  [self->sortOperation release];
  [self->item          release];
  [self->folderName    release];
  [self->folders       release];
  [self->dataSource    release];
  [super dealloc];
}

/* accessors */

- (SkyImapMailDataSource *)dataSource {
  return self->dataSource;
}

/* notifications */

- (void)syncAwake {
  [super syncAwake];
  
  [self->folders release]; self->folders = nil;
  
  self->folders  = [[NSMutableDictionary alloc] initWithCapacity:32];
  
  [LSWImapBuildFolderDict buildFolderDictionary:self->folders
                          folder:[NSArray arrayWithObject:self->rootFolder]
                          prefix:@""];
}

/* accessors */

- (void)setFlags:(NSMutableDictionary *)_flags {
  ASSIGN(self->flags, _flags);
}
- (NSMutableDictionary *)flags {
  return self->flags;
}

- (void)setInfos:(NSMutableDictionary *)_infos {
  ASSIGN(self->infos, _infos);
}
- (NSMutableDictionary *)infos {
  return self->infos;
}

- (void)setOpList:(NSArray *)_opList {
  ASSIGN(self->opList, _opList);
}
- (NSArray *)opList {
  return self->opList;
}

- (NSArray *)folderList {
  NSArray *list =  [self->folders allKeys];
  return [list sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (NSString *)radioSuffix {
  NSString *suff = [NSString stringWithFormat:@"sortOpSuffix%@", self->item];

  return [[self labels] valueForKey:suff];
}

- (NSString *)folder {
  NSString *newFolderName = @"";
  NSArray  *items         = [self->item componentsSeparatedByString:@"@ @"];
  int      i              = 0;

  while (i < [items count]-1) {
    newFolderName = [newFolderName stringByAppendingString:@"-- "];
    i++;
  }
  return [newFolderName stringByAppendingString:[items lastObject]];
}

- (NSString *)folderName {
  return self->folderName;
}
- (void)setFolderName:(NSString *)_name {
  ASSIGN(self->folderName, _name);
}

- (void)setItem:(id)_id {
  ASSIGN(self->item, _id);
}
- (id)item {
  return self->item;
}

- (void)setSortOperation:(NSString *)_sortOperation {
  ASSIGN(self->sortOperation, _sortOperation);
}
- (NSString *)sortOperation {
  return self->sortOperation;
}

- (NGImap4Folder *)rootFolder {
  return self->rootFolder;
}
- (void)setRootFolder:(NGImap4Folder *)_folder {
  ASSIGN(self->rootFolder, _folder);
}

- (BOOL)doSubFolders {
  return [self->dataSource doSubFolders];
}
- (void)setDoSubFolders:(BOOL)_flag {
  [self->dataSource setDoSubFolders:_flag];
}

- (void)setState:(SkyImapMailListState *)_state {
  ASSIGN(self->state, _state);
}
- (SkyImapMailListState *)state {
  return self->state;
}
  
// --- actions -------------------

- (id)search {
  EOFetchSpecification *fetchSpec  = nil;
  NSMutableString      *string     = nil;
  NSString             *field      = nil;
  NSString             *obj        = nil;
  NSEnumerator         *enumerator = nil;
  EOQualifier          *q          = nil;

  enumerator = [[self->infos allKeys] objectEnumerator];
  string     = [[NSMutableString alloc] initWithCapacity:128];
  
  fetchSpec  = [self->dataSource fetchSpecification];

  while ((obj = [enumerator nextObject])) {
    field = [self->infos objectForKey:obj];
    if ([field isNotNull] && ([field length] > 0)) {
      if ([string length] > 0) {
        [string appendString:@" "];
        [string appendString:self->sortOperation];
        [string appendString:@" "];
      }
      [string appendFormat:@"%@ = '%@'", obj, field];
    }
  }

  if ([[self->flags objectForKey:@"searchRead"] boolValue]) {
    if ([string length] > 0) {    
      [string appendString:@" "];
      [string appendString:self->sortOperation];
      [string appendString:@" "];
    }
    [string appendString:@"Flags = 'seen'"];
  }
  if ([[self->flags objectForKey:@"searchUnread"] boolValue]) {
    if ([string length] > 0) {    
      [string appendString:@" "];
      [string appendString:self->sortOperation];
      [string appendString:@" "];
    }
    [string appendString:@"Flags = 'unseen'"];
  }
  if ([[self->flags objectForKey:@"searchFlagged"] boolValue]) {
    if ([string length] > 0) {
      [string appendString:@" "];
      [string appendString:self->sortOperation];
      [string appendString:@" "];
    }
    [string appendString:@"Flags = 'flagged'"];
  }

  if ([string length] == 0) {
    [string release]; string = nil;
    
    [fetchSpec setQualifier:nil];
    [self->dataSource setFetchSpecification:fetchSpec];
    return nil;
  }
  
  q = [EOQualifier qualifierWithQualifierFormat:string, NULL];
  [string release]; string = nil;

  [fetchSpec setQualifier:q];
  
  [self->dataSource setFolder:[self->folders objectForKey:self->folderName]];
  [self->dataSource setFetchSpecification:fetchSpec];
  [self->dataSource setMaxCount:400];
  
  [self->state setFolder:[self->folders objectForKey:self->folderName]];
  [self->state setCurrentBatch:1];
  
  [[NSNotificationCenter defaultCenter]
       postNotificationName:@"LSWImapMailsShouldClearSelections"
       object:nil];
  
  return nil;
}

- (id)clearForm {
  [self->folderName release]; folderName = nil;
  
  [self->infos removeAllObjects];
  [self->flags removeAllObjects];
  
  [self->dataSource setDoSubFolders:YES];
  [self->dataSource setQualifier:nil];

  self->sortOperation = @"OR";
  
  return nil;
}

@end /* LSWImapMailSearch */
