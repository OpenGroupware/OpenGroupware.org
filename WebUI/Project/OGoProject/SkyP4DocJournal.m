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

#include <OGoFoundation/OGoComponent.h>

@class EODataSource;

@interface SkyP4DocJournal : OGoComponent
{
  id           fileManager;
  EODataSource *journalDS;
  id           currentFile;
}

@end

#include "common.h"

@implementation SkyP4DocJournal

- (void)dealloc {
  RELEASE(self->currentFile);
  RELEASE(self->journalDS);
  RELEASE(self->fileManager);
  [super dealloc];
}

/* attributes */

- (void)setFileManager:(id)_fm {
  if (self->fileManager != _fm) {
    ASSIGN(self->fileManager, _fm);
    ASSIGN(self->journalDS,   (id)nil);
  }
}
- (id)fileManager {
  return self->fileManager;
}

- (NSCalendarDate *)fromDate {
  return [[NSCalendarDate date] mondayOfWeek];
}
- (NSCalendarDate *)toDate {
  return [[self fromDate] dateByAddingYears:0 months:0 days:7];
}

- (EOQualifier *)qualifier {
  EOQualifier *q;
  NSCalendarDate *f, *t;

  f = [self fromDate];
  t = [self toDate];
  
  q = [EOQualifier qualifierWithQualifierFormat:
                     @"(NSFileModificationDate >= %@ AND "
                     @" NSFileModificationDate < %@) OR "
                     @"(SkyCreationDate >= %@ AND "
                     @" SkyCreationDate < %@)",
                     f, t, f, t];
  return q;
}
- (NSArray *)sortOrderings {
  return nil;
}
- (EOFetchSpecification *)fetchSpec {
  EOFetchSpecification *fspec;
  NSDictionary *hints;
  
  fspec = [EOFetchSpecification fetchSpecificationWithEntityName:@"/"
                                qualifier:[self qualifier]
                                sortOrderings:[self sortOrderings]];
  
  hints = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                        forKey:@"fetchDeep"];
  
  [fspec setHints:hints];
  
  return fspec;
}

- (EODataSource *)journalDS {
  if (self->journalDS == nil) {
    EODataSource *ds;
    
    ds = [self->fileManager dataSourceAtPath:@"/"];
    [ds setFetchSpecification:[self fetchSpec]];
    
    self->journalDS = [[EOCacheDataSource alloc] initWithDataSource:ds];
  }
  return self->journalDS;
}

- (void)setCurrentFile:(id)_file {
  ASSIGN(self->currentFile, _file);
}
- (id)currentFile {
  return self->currentFile;
}

/* matrix */

- (BOOL)isDocInCell {
  [self logWithFormat:@"in cell: row=%@, column=%@",
          [self valueForKey:@"row"], [self valueForKey:@"column"]];
  return YES;
}
- (BOOL)isDocInRow {
  [self logWithFormat:@"in row: row=%@", [self valueForKey:@"row"]];
  return YES;
  return [self valueForKey:@"row"] == [self currentFile];
}

- (int)columnsPerDay {
  return 1;
}

- (NSArray *)columns {
  int cnt;
  int pos;
  NSMutableArray *ma;
  
  cnt = [self columnsPerDay] * 7;
  pos = 0;
  ma  = [NSMutableArray array];
  
  while (pos < cnt)
    [ma addObject:[NSNumber numberWithInt:pos++]];
  return ma;
}

@end /* SkyP4DocJournal */
