/*
  Copyright (C) 2009 Whitemice Consulting (Adam Tauno Williams)

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


#include <LSFoundation/LSDBObjectBaseCommand.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSBase/LSGetCTagForEntityCommand.h>
#include "common.h"

@class NSMutableString;

@implementation LSGetCTagForEntityCommand

//static BOOL       debugOn      = NO; 

+ (void)initialize {
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  self = [super initForOperation:_operation inDomain:_domain];
  return self;
}

- (void)dealloc {
  [entity release];
  [super dealloc];
}

/* accessors */

- (NSString *)entity {
  return self->entity;
}

- (void)setEntity:(NSString *)_entity{
  ASSIGNCOPY(self->entity, _entity);
}

- (void)_executeInContext:(id)_context {
  NSArray             *attrs;
  NSDictionary        *rec;
  EOAdaptorChannel    *eoChannel;
  NSString            *sql;
  NSString            *ctag;

  eoChannel = [[self databaseChannel] adaptorChannel];

  sql = [[NSString alloc] initWithFormat:@"SELECT ctag"
                                         @" FROM ctags" 
                                         @" WHERE entity = '%@';", 
                                           [self entity]];

  if ([eoChannel evaluateExpression:sql]) {
    if ((attrs = [eoChannel describeResults]) != nil) {
      while ((rec = [eoChannel fetchAttributes:attrs withZone:NULL]) != nil) {
        ctag = [rec valueForKey:@"ctag"]; 
      }
    }
  }
  [sql release];
  [self setReturnValue:ctag];
  [_context rollback]; 
}

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualToString:@"entity"]) {
    [self setEntity:_value];
  } else {
      [super takeValue:_value forKey:_key];
    }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualToString:@"entity"])
    return [self entity];
  return [super valueForKey:_key];
}

@end /* LSGetCTagForEntityCommand */
