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

#include "JobHistory.h"
#include "common.h"

@implementation JobHistory

+ (JobHistory *)jobHistoryWithContext:(id)_ctx
  record:(EOGenericRecord *)_record
{
  return AUTORELEASE([[JobHistory alloc] initWithEOGenericRecord:_record
                                         context:_ctx]);
}

- (id)init {
  return [self initWithEOGenericRecord:nil context:nil];
}

- (id)initWithEOGenericRecord:(id)_record context:(id)_ctx {
  if ((self = [super init])) {
    if (_record != nil) {
      self->jobHistoryId = [[_record valueForKey:@"jobHistoryId"] copy];
      ASSIGN(self->record, _record);
    }
    self->context = _ctx;
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->record);
  RELEASE(self->jobHistoryId);
  [super dealloc];
}

/* accessors */

- (id)record {
  return self->record;
}

- (void)setRecord:(EOGenericRecord *)_record {
  ASSIGN(self->record, _record);
}

- (NSDictionary *)asDictionary {
  NSMutableDictionary *dict;
  NSArray *comment;
  EOGenericRecord *rec;

  rec = [self record];

  dict = [NSMutableDictionary dictionaryWithCapacity:8];
    
  [dict setObject:[rec valueForKey:@"actionDate"] forKey:@"actionDate"];
  [dict setObject:[rec valueForKey:@"action"] forKey:@"action"];
  [dict setObject:[rec valueForKey:@"jobStatus"] forKey:@"jobStatus"];
  [dict setObject:[rec valueForKey:@"actorId"] forKey:@"actor"];

  comment = [rec valueForKeyPath:@"toJobHistoryInfo.comment"];
  if (comment != nil) {
    [dict setObject:[comment lastObject] forKey:@"comment"];
  }
  return dict;
}

@end /* JobHistory */


