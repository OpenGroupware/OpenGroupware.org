/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#include "LSNewCompanyCommand.h"

@class NSArray;

@interface LSNewEnterpriseCommand : LSNewCompanyCommand
{
@private
  NSArray *persons;
}

@end

#include "common.h"

@implementation LSNewEnterpriseCommand

- (void)dealloc {
  [self->persons release];
  [super dealloc];
}

- (id)_newProjectInContext:(id)_context {
  id             ep, proj;
  NSCalendarDate *start, *end;
  
  ep = [self object];
  
  start = [NSCalendarDate date];
  end   = [NSCalendarDate dateWithString:@"2032-12-31 23:59:59"
                          calendarFormat:@"%Y-%m-%d %H:%M:%S"];
  
  proj = LSRunCommandV(_context, @"project", @"new",
                          @"name",      [ep valueForKey:@"description"],
                          @"startDate", start,
                          @"endDate",   end,
                          @"ownerId",   [ep valueForKey:@"ownerId"],
                          @"isFake",    [NSNumber numberWithBool:YES],
                          nil);      

  if (proj) {
    id rootDoc = nil;

    LSRunCommandV(_context, @"project",     @"get-root-document",
                            @"object",      proj,
                            @"relationKey", @"rootDocument", nil);

    rootDoc = [proj valueForKey:@"rootDocument"];
    
    LSRunCommandV(_context, @"doc", @"new",
                  @"title",       @"index",
                  @"abstract",    [ep valueForKey:@"description"],
                  @"fileContent", @"",
                  @"fileType",    @"txt",
                  @"fileSize",    [NSNumber numberWithInt:0],
                  @"isFolder",    [NSNumber numberWithBool:NO],
                  @"isNote",      [NSNumber numberWithBool:NO],
                  @"isIndexDoc",  [NSNumber numberWithBool:YES],
                  @"autoRelease", [NSNumber numberWithBool:YES],
                  @"project",     proj,
                  @"folder",      rootDoc,
                  nil);
    return proj;
  }
  return nil;
}

- (void)_prepareForExecutionInContext:(id)_context {
  [super _prepareForExecutionInContext:_context];
  [[self object] takeValue:[NSNumber numberWithBool:YES]
                 forKey:@"isEnterprise"];
  
  
}

- (void)_executeInContext:(id)_context {
  id proj = nil;

  [super _executeInContext:_context];

  proj = [self _newProjectInContext:_context];

  if (proj) {
    LSRunCommandV(_context, @"enterprise", @"assign-projects",
                  @"object",   [self object],
                  @"projects", [NSArray arrayWithObject:proj], nil);
  }
  
  
  if (self->persons != nil) { 
    LSRunCommandV(_context, @"enterprise", @"set-persons",
                  @"group",   [self object],
                  @"members", self->persons, nil);
  }
}

// initialize records

- (NSString *)entityName {
  return @"Enterprise";
}

// accessors

- (void)setPersons:(NSArray *)_persons {
  ASSIGN(persons, _persons);
}

- (NSArray *)persons {
  return self->persons;
}

// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"persons"]) {
    [self setPersons:_value];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"persons"])
    return [self persons];

  return [super valueForKey:_key];
}

@end /* LSNewEnterpriseCommand */
