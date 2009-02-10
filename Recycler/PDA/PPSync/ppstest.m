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

#include <stdio.h>
#import <Foundation/Foundation.h>
#import <EOControl/EOControl.h>
#import <NGExtensions/NGExtensions.h>
#import <NGPython/NGPython.h>
#include <PPSync/PPSyncPort.h>
#include <PPSync/PPSyncContext.h>
#include <PPSync/PPDatabase.h>
#include <PPSync/PPRecordDatabase.h>
#include <PPSync/PPToDoDatabase.h>
#include <PPSync/PPAddressDatabase.h>
#include <PPSync/PPDatebookDatabase.h>

#define SINGLE_TX 1

@interface Acceptor : NSObject
@end

@implementation Acceptor

- (void)syncWithTransaction:(PPSyncContext *)sc {
  PPTransaction        *tx;
  EOFetchSpecification *fs;
  EOQualifier          *q;
  NSArray              *objects;
  id job, address, appointment;
  
  tx = [[PPTransaction alloc] initWithParentObjectStore:sc];
  
  q  = [EOQualifier qualifierWithQualifierFormat:@"lastName hasPrefix: 'E'"];
  fs = [EOFetchSpecification fetchSpecificationWithEntityName:@"AddressDB"
                             qualifier:q
                             sortOrderings:nil];
  
  objects = [tx objectsWithFetchSpecification:fs];
  NSLog(@"objects: %@", objects);
  NSLog(@"oids:  %@", [objects valueForKey:@"globalID"]);
  NSLog(@"names: %@", [objects valueForKey:@"lastName"]);
  NSLog(@"notes: %@", [objects valueForKey:@"note"]);
  
  q  = [EOQualifier qualifierWithQualifierFormat:@"title hasPrefix: 'Kaffe'"];
  fs = [EOFetchSpecification fetchSpecificationWithEntityName:@"DatebookDB"
                             qualifier:q
                             sortOrderings:nil];
  objects = [tx objectsWithFetchSpecification:fs];
  NSLog(@"objects: %@", objects);
  
  q  = nil;
  fs = [EOFetchSpecification fetchSpecificationWithEntityName:@"ToDoDB"
                             qualifier:nil
                             sortOrderings:nil];
  objects = [tx objectsWithFetchSpecification:fs];
  NSLog(@"objects: %@", objects);
  
  /* create new job */
  
  job = [[PPToDoRecord alloc] init];
  [job takeValue:@"SyncTest"      forKey:@"title"];
  [job takeValue:[NSString stringWithFormat:@"%@\n%@",
                             [NSCalendarDate date], ec]
       forKey:@"note"];
  [job takeValue:[NSNumber numberWithInt:15] forKey:@"priority"];
  AUTORELEASE(job);

  [tx insertObject:job];
  NSLog(@"ec: has changes: %s", [tx hasChanges] ? "yes" : "no");
  [tx deleteObject:job];
  NSLog(@"ec: has changes: %s", [tx hasChanges] ? "yes" : "no");
  
  [tx insertObject:job];
  NSLog(@"ec: has changes: %s", [tx hasChanges] ? "yes" : "no");
  
  NSLog(@"saving changes ..");
  [tx saveChanges];
  NSLog(@"saved changes.");
  NSLog(@"ec: has changes: %s", [tx hasChanges] ? "yes" : "no");

  /* update new job */

  [job takeValue:
         [[job valueForKey:@"note"] stringByAppendingString:@"\nupdated !"]
       forKey:@"note"];
  NSLog(@"ec: has changes: %s", [tx hasChanges] ? "yes" : "no");
  
  NSLog(@"saving changes ..");
  [tx saveChanges];
  NSLog(@"saved changes.");
  NSLog(@"ec: has changes: %s", [tx hasChanges] ? "yes" : "no");

  /* update new job */

  [job takeValue:@"Firma" forKey:@"category"];
  NSLog(@"ec: has changes: %s", [tx hasChanges] ? "yes" : "no");
  
  NSLog(@"saving changes ..");
  [tx saveChanges];
  NSLog(@"saved changes.");
  NSLog(@"ec: has changes: %s", [tx hasChanges] ? "yes" : "no");

  /* update new job, create address, create appointment */

  address = [[[PPAddressRecord alloc] init] autorelease];
  [address takeValue:@"Duck"                    forKey:@"lastName"];
  [address takeValue:@"Donald"                  forKey:@"firstName"];
  [address takeValue:@"Entenhausen"             forKey:@"city"];
  [address takeValue:@"donald@geldspeicher.com" forKey:@"E-Mail"];
  [address takeValue:@"+88-21838-271"           forKey:@"Privat"];
  //[address takeValue:@"E-Mail"                  forKey:@"phoneLabel5"];
  //[address takeValue:@"Privat"                  forKey:@"phoneLabel1"];
  [address takeValue:@"QuickList"               forKey:@"category"];
  [address takeValue:[[NSCalendarDate date] description] forKey:@"note"];
  [tx insertObject:address];

  appointment = [[[PPDatebookRecord alloc] init] autorelease];
  [appointment takeValue:[NSCalendarDate date] forKey:@"startDate"];
  [appointment takeValue:
                 [[NSCalendarDate date] addYear:0 month:0 day:0
                                        hour:1 minute:0 second:0]
               forKey:@"endDate"];
  [appointment takeValue:@"SyncTest"      forKey:@"title"];
  [appointment takeValue:[tx description] forKey:@"note"];
  [tx insertObject:appointment];
  
  [job takeValue:[NSCalendarDate date] forKey:@"due"];
  [job takeValue:[[job valueForKey:@"note"]
                       stringByAppendingString:
                         [[job valueForKey:@"due"] description]]
       forKey:@"note"];
  NSLog(@"ec: has changes: %s", [tx hasChanges] ? "yes" : "no");
  
  NSLog(@"saving changes ..");
  [tx saveChanges];
  NSLog(@"saved changes.");
  NSLog(@"ec: has changes: %s", [tx hasChanges] ? "yes" : "no");
  
  [tx release];
}

- (void)sync:(NSNotification *)_notification {
  return [self syncWithTransaction:[_notification object]];
}

@end

int main(int argc, char **argv, char **env) {
  NSUserDefaults *ud;
  NSAutoreleasePool *pool;

  pool = [NSAutoreleasePool new];
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
  [NSAutoreleasePool enableDoubleReleaseCheck:YES];
#endif

  ud = [NSUserDefaults standardUserDefaults];

  {
    NS_DURING {
      PPSyncPort *port;
      Acceptor *a;
    
      port = [PPSyncPort defaultPilotSyncPort];
      a    = [[Acceptor new] autorelease];

#if SINGLE_TX
      [[NSNotificationCenter defaultCenter]
                             addObserver:a
                             selector:@selector(sync:)
                             name:PPSynchronizePDANotificationName
                             object:nil];
      
      [port accept];
#else

      [[NSNotificationCenter defaultCenter]
                             addObserver:a
                             selector:@selector(sync:)
                             name:PPSynchronizePDANotificationName
                             object:nil];
      
      while (YES) {
        NSDate *limitDate;

        /* this runs the timers */
        limitDate = [[NSRunLoop currentRunLoop]
                                limitDateForMode:NSDefaultRunLoopMode];

        /* and this waits for connections/IO */
        NSLog(@"waiting for hotsync ..");
        [[NSRunLoop currentRunLoop]
                    runMode:NSDefaultRunLoopMode
                    beforeDate:limitDate];
      }
#endif
    }
    NS_HANDLER {
      fprintf(stderr, "%s\n", [[localException description] cString]);
      fflush(stderr);
      abort();
    }
    NS_ENDHANDLER;
  }
  RELEASE(pool);

  exit(0);
  return 0;
}
