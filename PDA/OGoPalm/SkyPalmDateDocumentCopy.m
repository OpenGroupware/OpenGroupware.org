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

#include <OGoPalm/SkyPalmDateDocumentCopy.h>
#import <Foundation/Foundation.h>
#include <EOControl/EOKeyGlobalID.h>

@implementation SkyPalmDateDocumentCopy

- (id)initAsCopyWithDictionary:(NSDictionary *)_src
  index:(unsigned)_repetitionIndex
  origin:(SkyPalmDateDocument *)_doc
  fromDataSource:(SkyPalmDocumentDataSource *)_ds
{
  if ((self = [super initWithDictionary:_src fromDataSource:_ds])) {
    self->origin = _doc;
    RETAIN(self->origin);
    self->idx    = _repetitionIndex;

    [[NSNotificationCenter defaultCenter]
                           addObserver:self
                           selector:@selector(_originChanged)
                           name:@"LSWUpdatedPalmDate"
                           object:self->origin];
    [[NSNotificationCenter defaultCenter]
                           addObserver:self
                           selector:@selector(_originChanged)
                           name:@"LSWDeletedPalmDate"
                           object:self->origin];
    {
      id pKeys[2];
      id parGid;
      parGid = [self->origin globalID];
      pKeys[0] = [parGid keyValues][0];
      pKeys[1] = [NSNumber numberWithInt:_repetitionIndex];
      self->gid = [EOKeyGlobalID globalIDWithEntityName:[parGid entityName]
                                 keys:pKeys keyCount:2 zone:nil];
      [self->gid retain];
    }
  }
  return self;
}

+ (SkyPalmDateDocument *)documentWithDocument:(SkyPalmDateDocument *)_src
                                   dataSource:(SkyPalmDocumentDataSource *)_ds
                                    startdate:(NSCalendarDate *)_start
                                      enddate:(NSCalendarDate *)_end
                                        index:(unsigned)_repetitionIndex
{
  SkyPalmDateDocument *cp   = nil;
  NSMutableDictionary *dict = [_src asDictionary];

  [dict setObject:_start forKey:@"startdate"];
  [dict setObject:_end   forKey:@"enddate"];

  cp = [[SkyPalmDateDocumentCopy alloc] initAsCopyWithDictionary:dict
                                        index:_repetitionIndex
                                        origin:_src
                                        fromDataSource:_ds];
  
  return AUTORELEASE(cp);
}

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self->origin release];
  [self->gid    release];
  [super dealloc];
}
#endif

- (void)_originChanged {
  // origin changed --> detach
  RELEASE(self->origin);  self->origin = nil;
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:@"LSWDeletedPalmDate"
                         object:self];
}

// accessors

- (id)globalID {
  return self->gid;
}

- (SkyPalmDateDocument *)origin {
  return self->origin;
}

- (unsigned)repetitionIndex {
  return self->idx;
}

- (int)repeatType {
  return 0; // no repeating 'cause it's a single copy
}

// overwriting

- (id)save {
  return nil;
}
- (id)delete {
  return @"SkyPalmDateDocumentCopy is not deleteable!!";
}
- (id)undelete {
  return @"SkyPalmDateDocumentCopy is not undeleteable!!";
}
- (id)reload {
  return @"SkyPalmDateDocumentCopy is not reloadable!!";
}
- (id)revert {
  return @"SkyPalmDateDocumentCopy is not revertable!!";
}

- (NSArray *)repeatsBetween:(NSCalendarDate *)_start
                        and:(NSCalendarDate *)_end
{
  // document is already a copy
  return nil;
}

// actions

// detaches date from origin and returns a new 
- (id)detachFromOrigin {
  NSMutableDictionary *dict   = nil;
  SkyPalmDateDocument *newDoc = nil;

  if ([[self origin] detachDate:self] == nil) {
    // failed
    return nil;
  }

  dict = [self asDictionary];
  [dict removeObjectForKey:@"globalID"];
  [dict removeObjectForKey:@"palm_date_id"];
  [dict removeObjectForKey:@"exceptions"];
  [dict removeObjectForKey:@"repeat_enddate"];
  //  [dict setObject:[NSNumber numberWithInt:0] forKey:@"repeat_type"];
  [dict setObject:[NSNumber numberWithInt:0] forKey:@"repeat_frequency"];
  [dict setObject:[NSNumber numberWithInt:0] forKey:@"repeat_on"];
  [dict setObject:[NSNumber numberWithInt:0] forKey:@"repeat_start_week"];
  [dict setObject:[NSNumber numberWithInt:0] forKey:@"palm_id"];

  newDoc = [[SkyPalmDateDocument alloc] initAsNewFromDictionary:dict
                                        fromDataSource:self->dataSource];

  return AUTORELEASE(newDoc);
}

- (BOOL)isEqual:(id)_other {
  SkyPalmDateDocumentCopy *other;
  if (![super isEqual:_other]) return NO;
  other = (SkyPalmDateDocumentCopy *)_other;
  if (![[self startdate] isEqual:[other startdate]]) return NO;
  if (![[self enddate]   isEqual:[other enddate]])   return NO;
  if ([self repetitionIndex] != [other repetitionIndex]) return NO;
  return YES;
}

@end /* SkyPalmDateDocumentCopy */
