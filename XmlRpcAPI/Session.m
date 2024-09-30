/*
  Copyright (C) 2000-2007 SKYRIX Software AG
  Copyright (C) 2007      Helge Hess

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

#include "Session.h"
#include "common.h"
#include <OGoProject/OGoFileManagerFactory.h>

@implementation Session

- (id)init {
  if ((self = [super init]) != nil) {
    [self setStoresIDsInCookies:NO];
  }
  return self;
}

- (void)dealloc {
  [self->commandContext   release];
  [self->accountDS        release];
  [self->personDS         release];
  [self->appointmentDS    release];
  [self->enterpriseDS     release];
  [self->teamDS           release];
  [self->projectDS        release];
  [self->fileManagerCache release];
  [super dealloc];
}

/* accessors */

- (void)setCommandContext:(id)_ctx {
  ASSIGN(self->commandContext, _ctx);
}
- (id)commandContext {
  return self->commandContext;
}

/* notifications */

- (void)sleep {
  if ([self->commandContext isTransactionInProgress]) {
    if (![self->commandContext commit]) {
      [self logWithFormat:@"ERROR: could not commit transaction."];
      [self->commandContext rollback];
    }
  }
  [super sleep];
}

/* datasource factories */

- (EODataSource *)_dataSourceWithClassName:(NSString *)_dsName {
  EODataSource *ds;
  Class clazz;
  
  if ((clazz = NGClassFromString(_dsName)) == nil) {
    [self logWithFormat:@"no datasource named '%@' ...", _dsName];
    return nil;
  }
  
  // TODO: fix prototype
  ds = [(SkyAccessManager *)[clazz alloc]
			    initWithContext:[self commandContext]];
  [self debugWithFormat:@"instantiated new datasource '%@' ...", _dsName];
  return [ds autorelease];
}

- (EODataSource *)personDataSource {
  if (self->personDS == nil) {
    self->personDS =
      [[self _dataSourceWithClassName:@"SkyPersonDataSource"] retain];
  }
  return self->personDS;
}

- (EODataSource *)enterpriseDataSource {
  if (self->enterpriseDS == nil) {
    self->enterpriseDS =
      [[self _dataSourceWithClassName:@"SkyEnterpriseDataSource"] retain];
  }
  return self->enterpriseDS;
}

- (EODataSource *)appointmentDataSource {
  if (self->appointmentDS == nil) {
    self->appointmentDS =
      [[self _dataSourceWithClassName:@"SkyAppointmentDataSource"] retain];
  }
  return self->appointmentDS;
}

- (EODataSource *)accountDataSource {
  if (self->accountDS == nil) {
    self->accountDS =
      [[self _dataSourceWithClassName:@"SkyAccountDataSource"] retain];
  }
  return self->accountDS;
}

- (EODataSource *)teamDataSource {
  if (self->teamDS == nil) {
    self->teamDS =
      [[self _dataSourceWithClassName:@"SkyTeamDataSource"] retain];
  }
  return self->teamDS;
}

- (EODataSource *)projectDataSource {
  if (self->projectDS == nil) {
    self->projectDS =
      [[self _dataSourceWithClassName:@"SkyProjectDataSource"] retain];
  }
  return self->projectDS;
}

/* filemanager factories */

- (Class)fileManagerClass {
  return NGClassFromString(@"SkyProjectFileManager");
}

- (id)fileManagerForCode:(NSString *)_code {
  // TODO: cleanup method
  NGFileManager *fm;
  EOGlobalID  *gid = nil;
  NSRange     r;

  if (self->fileManagerCache == nil)
    self->fileManagerCache = [[NSMutableDictionary alloc] initWithCapacity:64];
  
  if ((fm = [self->fileManagerCache objectForKey:_code]))
    return fm;
  
  r = [_code rangeOfString:@"://"];
  
  if (r.length != 0) {
    gid = [[self->commandContext documentManager] globalIDForURL:_code];
  }
  else {
    EOFetchSpecification *fspec;
    EOQualifier          *qualifier;
    EODataSource         *pds;
    id                   project    = nil;
    NSArray              *projects  = nil;
    NSString             *pid;
    NSDictionary         *hints;
    
    if (self->commandContext == nil) {
      [self errorWithFormat:@"%@: missing commandContext.", self];
      return nil;
    }
    
    pid = _code;
    
    if (![pid isNotEmpty]) {
      [self errorWithFormat:@"missing project number"];
      return nil;
    }
    qualifier = [EOQualifier qualifierWithQualifierFormat:@"number=%@",
                             pid];

    hints = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                          forKey:@"SearchAllProjects"];
    fspec = [[EOFetchSpecification alloc] initWithEntityName:nil
                                          qualifier:qualifier
                                          sortOrderings:nil
                                          usesDistinct:YES isDeep:NO
                                          hints:hints];
    pds = [self projectDataSource];
    
    [pds setFetchSpecification:fspec];
    projects = [pds fetchObjects];
  
    project = [projects count] == 1
      ? [projects objectAtIndex:0]
      : nil;
    
    [fspec release]; fspec = nil;
    
    if (project == nil) {
      [self errorWithFormat:@"%s: missing project", __PRETTY_FUNCTION__];
      return nil;
    }
    gid = [project valueForKey:@"globalID"];
  }   

  if (gid == nil) {
    [self errorWithFormat:
            @"%s: found no global-id for project code: '%@'", 
            __PRETTY_FUNCTION__, _code];
    return nil;
  }

  return [[OGoFileManagerFactory sharedFileManagerFactory]
	   fileManagerInContext:self->commandContext
	   forProjectGID:gid];
}

@end /* Session */
