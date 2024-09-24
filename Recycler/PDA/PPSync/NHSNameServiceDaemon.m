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

#include "NHSNameServiceDaemon.h"
#include "common.h"
#include <Foundation/UnixSignalHandler.h>
#include <NGStreams/NGNet.h>
#include <PPSync/PPSyncContext.h>
#include <PPSync/PPSyncPort.h>
#include <PPSync/PPPostSync.h>

#include "PPTransaction.h"

#include <signal.h>
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/wait.h>

#include <pi-socket.h>
#include <pi-source.h>

#include <unistd.h>

BOOL   dontFork;
BOOL   dumpCore;
BOOL   quiet;
char   pilotport[255];

@interface NSObject(Conduits)
- (void)sync;
- (void)syncWithTransaction:(PPTransaction *)_ctx;
@end

@implementation NHSNameServiceDaemon

+ (void)initialize {
  quiet = YES;

  /* argument processing */
  {
    NSUserDefaults *ud;
    NSString       *tmp;
    NSString       *port;
    
    ud  = [NSUserDefaults standardUserDefaults];

    quiet = ((tmp = [ud objectForKey:@"verbose"]))
      ? ([tmp boolValue] ? 0 : 1)
      : 1;

    if ((tmp = [ud objectForKey:@"fork"]))
      dontFork = [tmp boolValue] ? 0 : 1;
    else
      dontFork = 0;
    
    if ((tmp = [ud objectForKey:@"dumpCore"]))
      dumpCore = [tmp boolValue] ? 1 : 0;
    else
      dumpCore = 0;
    
    if (dontFork)
      NSLog(@"forking disabled.");

    port = [ud objectForKey:@"PILOTPORT"];
    if (![port length]) {
      BOOL ok = NO;
      if (getenv("PILOTPORT")) {
        if (strlen(getenv("PILOTPORT")) > 0) {
          strncpy(pilotport, getenv("PILOTPORT"), sizeof(pilotport));
          ok = YES;
        }
      }
      if (!ok) {
        NSLog(@"using default port: net:any:14238 (may be configured by "
              @"changing PILOTPORT)");
        strcpy(pilotport,"net:any:14238");
      }
    }
    else {
      strncpy(pilotport, [port cString], sizeof(pilotport)); 
    }
  }
}

- (id)init {  
  struct pi_sockaddr addr;

#ifndef PI_AF_PILOT
  // TODO: is this correct?
  self->pisockd = pi_socket(PI_AF_SLP, PI_SOCK_STREAM, PI_AF_INETSLP);
#else
  self->pisockd = pi_socket(PI_AF_PILOT, PI_SOCK_STREAM, PI_PF_NET);
#endif
  
  if (self->pisockd <= 0) {
    [self release]; self = nil;
    [NSException raise:@"PPSocketException"
                 format:@"Could not setup pi_socket: %s", strerror(errno)];
  }
  self->pisockfd = ((struct pi_socket *)find_pi_socket(self->pisockd))->sd;

  /* address for local IP port for Network HotSync */
  /* setup enviroment for nhsd settings:           */
  /* export PILOTPORT="net:any:<port>"             */
  /* default port is 14238                         */
#ifndef PI_AF_PILOT
  addr.pi_family = PI_AF_SLP;
#else
  addr.pi_family = PI_AF_PILOT;
#endif
  strncpy(addr.pi_device, pilotport, sizeof(addr.pi_device));

  // binding socket with values from enviroment var PILOTPORT
  if (pi_bind(self->pisockd, (struct sockaddr*)&addr,
              sizeof(struct pi_sockaddr)) < 0) {
    RELEASE(self); self = nil;
    [NSException raise:@"PPSocketException"
                 format:@"Couldn't bind socket to '%s': %s\n"
                 @"Ensure that PILOTPORT env var is set properly "
                 @"(PILOTPORT=\"net:any:<port>\" def. port: 14238)",
                 pilotport, strerror(errno)];
  }
  NSLog(@"bound to %s", pilotport);

  [[UnixSignalHandler sharedHandler]
                      addObserver:self
                      selector:@selector(_taskDidTerminate:)
#if defined(SIGCHLD)
                      forSignal:SIGCHLD
#elif defined(SIGCLD)
                      forSignal:SIGCLD
#endif
                      immediatelyNotifyOnSignal:YES];
  
  self->domain = RETAIN([NGInternetSocketDomain domain]);

  return self;
}

- (void)dealloc {
  [[UnixSignalHandler sharedHandler] removeObserver:self];
  
  if (self->pisockd != -1)
    pi_close(self->pisockd);
  
  RELEASE(self->domain);
  [self->postSyncs release];
  [super dealloc];
}

/* tasks */

- (void)_taskDidTerminate:(int)_signum {
  int   status;
  pid_t pid;

  /* consume signal */
  pid = wait(&status);
  
  if (pid != -1) {
    if (WIFSIGNALED(status)) {
      NSLog(@"child process %i terminated because of signal %i",
            pid, WTERMSIG(status));
    }
    else if (WIFSTOPPED(status)) {
      NSLog(@"child process %i terminated because of stop signal %i",
            pid, WSTOPSIG(status));
    }
    else if (WIFEXITED(status)) {
      status = WEXITSTATUS(status);
      if (status != 0)
        NSLog(@"child process %i terminated with exit code %i", pid, status);
    }
  }
}

- (void)logException:(NSException *)_exception
  inConduit:(id)_conduit
  withContext:(PPTransaction *)_ec
{
  PPSyncContext *ctx;

  ctx = (id)[_ec rootObjectStore];
  
  [ctx syncLogWithFormat:
         @"%@ failed:\n  %@\n  %@",
         _conduit, [_exception name], [_exception reason]];
}

- (void)runConduit:(id)_conduit inContext:(PPTransaction *)_ec {

  NS_DURING {
    [(id)[_ec rootObjectStore] syncLogWithFormat:@"sync %@ ..\n", _conduit];
    
    if ([_conduit respondsToSelector:@selector(syncWithTransaction:)])
      [_conduit syncWithTransaction:_ec];
    else if ([_conduit respondsToSelector:@selector(sync)])
      [_conduit sync];
    else if ([_conduit respondsToSelector:@selector(run)])
      // TODO: fix me (is this used at all?)
      [(NHSNameServiceDaemon *)_conduit run];
    else {
      NSLog(@"  invalid conduit: missing a sync method !");
    }
  }
  NS_HANDLER {
    [self logException:localException inConduit:_conduit withContext:_ec ];
    
    fprintf(stderr, "ERROR: conduit failed: %s\n",
            [[localException description] cString]);
    if (dumpCore) {
      abort();
    }
  }
  NS_ENDHANDLER;

}

- (void)runTransaction:(PPTransaction *)ec {
  PPSyncContext    *ctx;
  NGBundleManager  *bm;
  NSEnumerator     *conduits;
  NSMutableSet     *processedConduits;
  id     conduit;
  
  bm = [NGBundleManager defaultBundleManager];
  
  ctx = (PPSyncContext *)[ec rootObjectStore];

  processedConduits = [NSMutableSet setWithCapacity:16];
  
  // TODO: requires NGBundlePath default
  conduits = [[bm providedResourcesOfType:@"PPConduits"] objectEnumerator];
  while ((conduit = [conduits nextObject])) {
    NSString *conduitName;
    NSBundle *conduitBundle;
    NSString *conduitClassName;
    Class    conduitClass;
    id       conduitObject;
    
    conduitName      = [conduit objectForKey:@"name"];
    conduitClassName = [conduit objectForKey:@"class"];

    if ([processedConduits containsObject:conduitName])
      continue;

    if (conduitClassName == nil) conduitClassName = conduitName;
    
    conduitBundle =
      [bm bundleProvidingResource:conduitName ofType:@"PPConduits"];

    if (conduitBundle == nil) {
      NSLog(@"  did not find bundle of conduit %@", conduitName);
      continue;
    }

    if (![conduitBundle load]) {
      NSLog(@"  couldn't load bundle of conduit %@:\n  %@",
            conduitName, conduitBundle);
      continue;
    }
    
    if ((conduitClass = NGClassFromString(conduitClassName)) == Nil) {
      NSLog(@"  did not find conduit class %@ in bundle %@",
            conduitClassName, conduitBundle);
    }

    [processedConduits addObject:conduitName];
    
    NSLog(@"sync with conduit %@ ..", conduitName);
    
    conduitObject = [[conduitClass alloc] init];
    AUTORELEASE(conduitObject);
    
    if (conduitObject == nil) {
      NSLog(@"  couldn't create conduit object of class %@ in bundle %@",
            conduitClassName, conduitBundle);
      continue;
    }
    
    [self runConduit:conduitObject inContext:ec];

    if ([ec hasChanges]) {
      NSLog(@"Conduit %@ left changes, saving ..", conduitObject);
      NSLog(@"  inserted: %@", [ec insertedObjects]);
      NSLog(@"  deleted:  %@", [ec deletedObjects]);
      NSLog(@"  updated:  %@", [ec updatedObjects]);
      [ec saveChanges];
    }
  }
  
  [[NSNotificationCenter defaultCenter]
                         postNotificationName:PPSynchronizePDANotificationName
                         object:ctx];
}

- (void)runTransactionOnDescriptor:(int)_csd {
  PPSyncContext    *ctx;
  PPTransaction *ec;
  NSDate *start, *end;
  
  ctx = [[PPSyncContext alloc] initWithDescriptor:_csd];
  AUTORELEASE(ctx);

  NSLog(@"starting sync process ..");
  start = [NSDate date];
  [ctx prepare];
  
  ec = [[[PPTransaction alloc] 
	  initWithParentObjectStore:ctx] autorelease];

  [self runTransaction:ec];

  [self addPostSyncs:[ec registeredPostSyncs]];

  [ctx finish];
  end = [NSDate date];
  NSLog(@"synchronization finished (%.4fs).",
        [end timeIntervalSinceDate:start]);
}

- (BOOL)forkTransactions {
  return dontFork ? NO : YES;
}

- (void)runTransaction {
  struct sockaddr_in caddr;
  struct pi_socket   *pisock;
  socklen_t          caddrLen;
  int                csd;
  pid_t              pid;
  id                 clientAddress;
  BOOL               isChild = NO;

  if ((csd = pi_accept(self->pisockd, 0, 0)) < 0) {
    NSLog(@"couldn't accept connection .. %s", strerror(errno));
    return;
  }

  pisock = find_pi_socket(csd);

  /* find out address */

  caddrLen = sizeof(caddr);
  if (getpeername(pisock->sd, (void *)&caddr, &caddrLen) < 0) {
    NSLog(@"%@: Couldn't get peer name ..", self);
    return;
  }
  clientAddress = [self->domain addressWithRepresentation:(void *)&caddr
                                size:caddrLen];
  
  NSLog(@"accepted NHS connection from %@ ..", [clientAddress stringValue]);
  
  if (![self forkTransactions]) {
    NS_DURING
      [self runTransactionOnDescriptor:csd];
    NS_HANDLER {
      fprintf(stderr, "catched exceptions ..\n");
    }
    NS_ENDHANDLER;
  }
  else {
    /* fork child */
    if ((pid = fork()) == 0) {
      /* child */
      isChild = YES;
      NS_DURING {
        [self runTransactionOnDescriptor:csd];
      }
      NS_HANDLER {
        fprintf(stderr, "exiting due to exceptions ..\n");
        
        exit(20);
      }
      NS_ENDHANDLER;

      //fprintf(stderr, "will exit with code 0\n");
      //fflush(stderr);
      //NSLog(@"%s exiting with code 0", __PRETTY_FUNCTION__);
      //exit(0);
    }
    
    /* close client socket for parent process (owned by child process) */
    //NSLog(@"%s closing connection to palm", __PRETTY_FUNCTION__);
    {
      struct pi_socket *ps;
      ps = find_pi_socket(csd);
#ifdef PI_AF_PILOT
      if (ps != NULL)
        ps->state = PI_SOCK_CLOSE;
#endif
    }
    pi_close(csd); csd = -1;
  }
  [self handlePostSyncs];
  [self resetPostSyncs];
  if (isChild) {
    exit(0);
  }
}

/* event loop */

- (void)terminate {
  self->isTerminating = YES;
}

- (void)run {
  if (pi_listen(self->pisockd, 1) < 0) {
    RELEASE(self); self = nil;
    [NSException raise:@"PPSocketException"
                 format:@"Couldn't listen on socket '.': %s", strerror(errno)];
  }

  while (!self->isTerminating) {
    NSAutoreleasePool *pool;
    fd_set            rset;
    int               count;

    /* wait for NHS connection */
    FD_ZERO(&rset);
    FD_SET(self->pisockfd, &rset);
        
    count = select(1 + self->pisockfd,
                   &rset, 0, 0, 0);
    if (count < 0) {
      if (errno == EINTR) {
        /* interrupted, eg Ctrl-C */
        continue;
      }
      NSLog(@"select failed: %s", strerror(errno));
      continue;
    }
    if (count == 0) {
      /* timeout */
      NSLog(@"select timeout ..");
      continue;
    }
    
    pool = [NSAutoreleasePool new];
    
    NS_DURING {
      if (FD_ISSET(self->pisockfd, &rset)) {
        [self runTransaction];
      }
    }
    NS_HANDLER {
      fprintf(stderr, "catched: %s\n", [[localException description] cString]);
    }
    NS_ENDHANDLER;
    
    RELEASE(pool);
  }
}

- (void)addPostSyncs:(NSArray *)_postSyncs {
  if (self->postSyncs == nil)
    self->postSyncs = [[NSMutableArray alloc] initWithCapacity:16];
  [self->postSyncs addObjectsFromArray:_postSyncs];
}

- (void)handlePostSyncs {
  unsigned int i, cnt; 
  NSDate *start;

  cnt   = [self->postSyncs count];
  start = [NSDate date];
  if (cnt) {
    NSLog(@"handling %d postsync requests", cnt);
  }
  for (i = 0; i < cnt; i++) {
    if (![(PPPostSync *)[self->postSyncs objectAtIndex:i] run]) {
      NSLog(@"postsync %d failed", i);
    }
  }
  if (cnt) {
    NSDate *end = [NSDate date];
    NSLog(@"post sync finished (%.4fs).",
          [end timeIntervalSinceDate:start]);
  }
}

- (void)resetPostSyncs {
  [self->postSyncs removeAllObjects];
}

@end /* NHSNameServiceDaemon */
