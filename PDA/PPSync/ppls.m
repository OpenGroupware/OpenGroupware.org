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

#include "NHSNameServiceDaemon.h"
#import <Foundation/Foundation.h>
#import <EOControl/EOControl.h>
#import <PPSync/PPSyncContext.h>
#import <PPSync/PPDatabase.h>

#include "PPTransaction.h"

@interface PPListDaemon : NHSNameServiceDaemon
{
  NSString    *entityName;
  EOQualifier *q;
  NSString    *action;
}

@end

@implementation PPListDaemon

- (id)init {
  if ((self = [super init])) {
    self->action = @"list";
  }
  return self;
}

- (void)dealloc {
  [self->entityName release];
  [self->q release];
  [super dealloc];
}

- (void)setEntityName:(NSString *)_entityName {
  ASSIGN(self->entityName, _entityName);
}
- (void)setQualifierString:(NSString *)_qualString {
  EOQualifier *qq;

  qq = [EOQualifier qualifierWithQualifierFormat:_qualString arguments:nil];
  ASSIGN(self->q, qq);
}

- (void)setAction:(NSString *)_action {
  ASSIGN(self->action, _action);
}
- (NSString *)action {
  return self->action;
}

- (BOOL)forkTransactions {
  return NO;
}

- (NSArray *)listWithTransaction:(PPTransaction *)_ec {
  NSArray              *records;
  EOFetchSpecification *fs;
  
  fs = [EOFetchSpecification fetchSpecificationWithEntityName:self->entityName
                             qualifier:self->q
                             sortOrderings:nil];
  
  records = [_ec objectsWithFetchSpecification:fs];
  return records;
}

- (void)runTransaction:(PPTransaction *)ec {
  if (self->entityName) {
    NSArray      *objects;
    NSEnumerator *e;
    id eo;
    
    NSLog(@"query entity '%@'", self->entityName);

    if ([self->action isEqualToString:@"list"]) {
      objects = [self listWithTransaction:ec];
      e = [objects objectEnumerator];

      while ((eo = [e nextObject])) {
        printf("  %s\n", [[eo description] cString]);
      }
    }
    else if ([self->action isEqualToString:@"delete"]) {
      objects = [self listWithTransaction:ec];
      if (objects == nil) {
        NSLog(@"no records matching qualifier in database ..");
        return;
      }
        
      printf("ATTENTION: Really delete %i records from entity %s: [N/y]",
             [objects count], [self->entityName cString]);
      fflush(stdout);

      if (getc(stdin) == 'y') {
        e = [objects objectEnumerator];
        while ((eo = [e nextObject])) {
          [ec deleteObject:eo];
          [ec saveChanges];
        }
      }
    }
  }
  else {
    NSArray *dbs;
    NSEnumerator *e;
    id db;
    
    dbs = [(id)[ec rootObjectStore] databasesMatchingQualifier:(id)self];
    e = [dbs objectEnumerator];

    printf("Palm databases:\n");
    printf("  %-20s | %s | %s | %s\n", "name", "creator", "type", "card");
    while ((db = [e nextObject])) {
      printf("  %-20s | %-7s | %s | %i",
             [[db databaseName] cString],
             [[db creatorString] cString],
             [[db typeString] cString],
             [db cardNumber]);
      if ([db isReadOnly])
        printf(" read-only");
      printf("\n");
    }
  }
}

- (void)runTransaction {
  [super runTransaction];
  [self terminate];
}

- (BOOL)evaluateWithObject:(id)_o {
  /* I'm a fake EOQualifier .. ;-) */
  return YES;
}

@end

int main(int argc, char *argv[], char **env) {
  NSAutoreleasePool *pool;
  id d;
  
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  pool = [NSAutoreleasePool new];
  
  d = [[[PPListDaemon alloc] init] autorelease];

  if (argc > 1)
    [d setEntityName:[NSString stringWithCString:argv[1]]];
  if (argc > 2)
    [d setQualifierString:[NSString stringWithCString:argv[2]]];
  if (argc > 3)
    [d setAction:[NSString stringWithCString:argv[3]]];
  
  NSLog(@"waiting for connection ..");
  [d run];

  RELEASE(pool);
  exit(0);
  return 0;
}
