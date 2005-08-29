/*
  Copyright (C) 2005 SKYRIX Software AG

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

#import <Foundation/NSObject.h>

@class NSArray;
@class OGoContextManager, LSCommandContext;

@interface OGoChkAptConflictsTool : NSObject
{
  OGoContextManager *lso;
  LSCommandContext  *ctx;
  NSString          *sxid;
  NSString          *login;
  NSString          *password;
}

+ (int)run:(NSArray *)_args;

@end

#include "common.h"
#include <NGExtensions/NSCalendarDate+misc.h>
#include <LSFoundation/OGoContextManager.h>
#include <LSFoundation/OGoContextSession.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommandKeys.h>

@implementation OGoChkAptConflictsTool

- (id)init {
  if ((self = [super init])) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    self->lso      = [[OGoContextManager defaultManager] retain];
    self->login    = [[ud stringForKey:@"login"]     copy];
    self->password = [[ud stringForKey:@"password"]  copy];
    self->sxid     = [[ud stringForKey:@"skyrix_id"] copy];
  }
  return self;
}
- (void)dealloc {
  [self->sxid     release];
  [self->login    release];
  [self->password release];
  [self->lso      release];
  [super dealloc];
}

/* usage */

- (void)usage:(NSString *)_toolname {
  static const char *toolname = "ogo-chkaptconflicts";
  fprintf(stderr,
	  "Usage:\n"
          "  %s -login <login> -password <pwd> <from> <to> [<login>]\n\n"
          "  examples:\n"
	  "    %s -login donald -password x 20050810 20050921 donald\n"
	  "\n", toolname, toolname);
}

/* run with context */

- (void)printAppointment:(id)_apt conflictInfo:(NSArray *)conflictInfo {
  unsigned i, count;
  
  printf("  %s (%s)\n", 
         [[_apt valueForKey:@"title"] cString],
         [[[_apt valueForKey:@"dateId"] description] cString]);
  printf("    time: %s - %s\n",
         [[[_apt valueForKey:@"startDate"] description] cString],
         [[[_apt valueForKey:@"endDate"] description] cString]);

  if ((count = [conflictInfo count]) == 0) {
    printf("    no info on conflict?!\n");
    return;
  }
  
  for (i = 0; i < count; i++) {
    NSDictionary *info;
    NSString *stat;
    
    info = [conflictInfo objectAtIndex:i];
    if ([(stat = [info valueForKey:@"resourceName"]) isNotNull]) {
      printf("    resource:  %s\n", [stat cString]);
    }
    else {
      stat = [info valueForKey:@"partStatus"];
      printf("    conflicts: %-8d (status=%s, role=%s)\n",
             [[info valueForKey:@"companyId"] unsignedIntValue],
             [stat isNotNull] ? [stat cString] : "<null>",
             [[info valueForKey:@"role"] cString]);
    }
  }
}

- (int)checkFrom:(NSCalendarDate *)_from to:(NSCalendarDate *)_to
  forParticipants:(NSArray *)_parts
  inContext:(LSCommandContext *)_ctx
{
  NSDictionary *conflictInfo;
  NSArray  *apts;
  unsigned i;
  
  conflictInfo = [_ctx runCommand:@"appointment::conflicts",
                       @"begin", _from, @"end", _to,
                       @"staffList",         _parts,
                       @"fetchGlobalIDs",    @"YES",
                       @"fetchConflictInfo", @"YES",
#if 0 // to test resource conflicts
                       @"resourceList", [NSArray arrayWithObject:@"Tisch"],
#endif
                       nil];
  
  if ([conflictInfo count] == 0) {
    printf("No conflicting appointments found.\n");
    return 0;
  }
  
  apts = [_ctx runCommand:@"appointment::get-by-globalid",
               @"gids", [conflictInfo allKeys], nil];
  
  printf("Found %d conflicting appointments (%s - %s):\n", 
         [conflictInfo count],
         [[_from description] cString],
         [[_to   description] cString]);
  
  for (i = 0; i < [apts count]; i++) {
    [self printAppointment:[apts objectAtIndex:i] 
          conflictInfo:[conflictInfo objectForKey:
                                       [[apts objectAtIndex:i] globalID]]];
  }
  
  return 0;
}

- (id)staffObjectFromName:(NSString *)_name inContext:(LSCommandContext *)_ctx{
  id obj;
  
  if (![_name isNotEmpty]) return nil;

  if (isdigit([_name characterAtIndex:0])) {
    EOGlobalID *gid;
    
    gid = [[_ctx typeManager] globalIDForPrimaryKey:_name];
    obj = [_ctx runCommand:@"object::get-by-globalid", @"gid", gid, nil];
    return [obj isKindOfClass:[NSArray class]]
      ? ([obj isNotEmpty] ? [obj objectAtIndex:0] : nil)
      : obj;
  }
  
  obj = [_ctx runCommand:@"account::get-by-login", @"login", _name, nil];
  if ([obj isNotNull])
    return obj;
  
  obj = [_ctx runCommand:@"team::get-by-login", @"login", _name, nil];
  if ([obj isNotNull])
    return obj;
  
  return nil;
}

- (NSArray *)staffListFromNames:(NSArray *)_names
  inContext:(LSCommandContext *)_ctx
{
  NSMutableArray *ma;
  unsigned i, count;
  
  if ((count = [_names count]) == 0)
    return nil;
  
  ma = [NSMutableArray arrayWithCapacity:count];
  for (i = 0; i < count; i++) {
    NSString *key;
    id obj;
    
    key = [_names objectAtIndex:i];
    if (![key isNotEmpty]) continue;
    
    if ((obj = [self staffObjectFromName:key inContext:_ctx]) == nil) {
      [self errorWithFormat:@"Did not find participant object for key: %@",
              key];
      continue;
    }
    
    [ma addObject:obj];
  }
  return ma;
}

- (NSCalendarDate *)dateForString:(NSString *)_s {
  static NSCalendarDate *now = nil;
  static NSCalendarDate *mon = nil;

  if (now == nil) now = [[NSCalendarDate date] retain];
  if (mon == nil) mon = [[now mondayOfWeek] retain];
  _s = [_s lowercaseString];
  
  if ([_s isEqualToString:@"now"])       return now;
  if ([_s isEqualToString:@"tomorrow"])  return [now tomorrow];
  if ([_s isEqualToString:@"yesterday"]) return [now yesterday];
  
  if ([_s hasPrefix:@"mon"]) return mon;
  if ([_s hasPrefix:@"tue"]) return [mon dateByAddingYears:0 months:0 days:1];
  if ([_s hasPrefix:@"wed"]) return [mon dateByAddingYears:0 months:0 days:2];
  if ([_s hasPrefix:@"thu"]) return [mon dateByAddingYears:0 months:0 days:3];
  if ([_s hasPrefix:@"fri"]) return [mon dateByAddingYears:0 months:0 days:4];
  if ([_s hasPrefix:@"sat"]) return [mon dateByAddingYears:0 months:0 days:5];
  if ([_s hasPrefix:@"sun"]) return [mon dateByAddingYears:0 months:0 days:6];
  
  switch ([_s length]) {
  case 6:
    return [NSCalendarDate dateWithString:_s calendarFormat:@"%Y%m"];
  case 8:
    return [NSCalendarDate dateWithString:_s calendarFormat:@"%Y%m%d"];
  case 10:
    return [NSCalendarDate dateWithString:_s calendarFormat:@"%Y%-m-%d"];
  case 13:
    return [NSCalendarDate dateWithString:_s calendarFormat:@"%Y%m%d %H%M"];
  case 14:
    return [NSCalendarDate dateWithString:_s calendarFormat:@"%Y%m%d %H:%M"];
  case 16:
    return [NSCalendarDate dateWithString:_s calendarFormat:@"%Y-%m-%d %H:%M"];
  default:
    return nil;
  }
}

- (int)run:(NSArray *)_args onContext:(LSCommandContext *)_ctx {
  NSArray        *partNames;
  NSCalendarDate *from, *to;
  
  if ([_args count] < 3) {
    [self usage:[_args objectAtIndex:0]];
    return 1;
  }

  from = [self dateForString:[_args objectAtIndex:1]];
  to   = [self dateForString:[_args objectAtIndex:2]];
  if (from == nil || to == nil) {
    [self usage:[_args objectAtIndex:0]];
    NSLog(@"Could not decode from or to argument!");
    return 1;
  }
  
  partNames = ([_args count] > 3)
    ? [_args subarrayWithRange:NSMakeRange(3, [_args count] - 3)]
    : [NSArray arrayWithObject:self->login];
  
  return [self checkFrom:from to:to 
               forParticipants:
                 [self staffListFromNames:partNames inContext:_ctx]
               inContext:_ctx];
}

/* parameter run */

- (int)run:(NSArray *)_args {
  id sn;
  
  sn = [self->lso login:self->login password:self->password
                  isSessionLogEnabled:NO];
  if (sn == nil) {
    [self logWithFormat:@"could not login user '%@'", self->login];
    return 1;
  }
  ASSIGN(self->ctx, [sn commandContext]);
  
  return [self run:_args onContext:self->ctx];
}

+ (int)run:(NSArray *)_args {
  return [[[[self alloc] init] autorelease] run:_args];
}

@end /* OGoChkAptConflictsTool */


int main(int argc, char **argv, char **env) {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int rc;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  rc = [OGoChkAptConflictsTool run:[[NSProcessInfo processInfo] 
                                     argumentsWithoutDefaults]];
  [pool release];
  return rc;
}
