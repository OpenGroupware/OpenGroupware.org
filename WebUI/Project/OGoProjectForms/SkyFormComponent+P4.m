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
// $Id$

#include <OGoForms/SkyFormComponent.h>
#include <NGObjWeb/WOResourceManager.h>

/*
  JavaScript: SkyFormComponent

    Methods

      AccountInfo     getAccountInfo()
      DataSource      DBConnection([,adaptor,login,pwd,db,host][,cache])
      Process         Process(path[,args])
      DataSource      getDataSource(name,[cache=yes])
      DocumentManager getDocumentManager()
      PersonDocument  getAccount()
*/

#include "SkyJSProcess.h"
#include <OGoDocuments/LSCommandContext+Doc.h>
#include "common.h"

@interface NSObject(GID)
- (EOGlobalID *)globalID;
@end

@interface NSObject(PrivateJSFuncs)
- (id)_jsfunc_alert:(NSArray *)_array;
@end

@implementation SkyFormComponent(Additions)

- (id)_jsfunc_showError:(NSArray *)_array {
  // DEPRECATED: use alert() !
  return [self _jsfunc_alert:_array];
}

- (NSString *)_lastFormEditorLogin {
  id       formDoc;
  NSString *currentOwner;
  
  formDoc = [self valueForKey:@"formDocument"];
  [self debugWithFormat:@"formdoc: %@", formDoc];
  
  currentOwner = [formDoc valueForKey:NSFileOwnerAccountName];
  [self debugWithFormat:@"owner: %@", currentOwner];
  
  return currentOwner;
}

- (BOOL)_isForkAllowed {
  NSString *currentOwner;
  NSArray  *allowedLogins;
  
  currentOwner = [self _lastFormEditorLogin];
  
  allowedLogins =
    [[NSUserDefaults standardUserDefaults]
                     arrayForKey:@"SkyJavaScriptForkLogins"];
  
  return [allowedLogins containsObject:currentOwner];
}

- (id)_jsfunc_Process:(NSArray *)_array {
  unsigned       count;
  SkyJSProcess   *task;
  NSMutableArray *args;
  
  /* check permission */
  
  if (![self _isForkAllowed]) {
    NSString *s;
    
    s = [self _lastFormEditorLogin];
    s = [NSString stringWithFormat:
                    @"forms created by '%@' have no permission to "
                    @"fork shell processes !", s];
    
    [[[self context] page] takeValue:s forKey:@"errorString"];
    return nil;
  }
  
  /* setup process object */
  
  count = [_array count];
  
  task = [[[SkyJSProcess alloc] init] autorelease];
  
  if (count > 0)
    [task setPath:[[_array objectAtIndex:0] stringValue]];
  
  args = nil;
  if (count > 1) {
    unsigned i;
    
    args = [NSMutableArray arrayWithCapacity:count];
    for (i = 1; i < count; i++)
      [args addObject:[[_array objectAtIndex:i] stringValue]];
  }
  [task setArguments:args];
  
  return task;
}

- (id)_jsfunc_DBConnection:(NSArray *)_array {
  unsigned count;
  id   ds, cmdctx;
  BOOL doCache;
  
  cmdctx = [(LSWSession *)[self session] commandContext];

  doCache = YES;
  
  ds = nil;
  if ((count = [_array count]) == 0) {
    ds = [[SkyDBDataSource alloc] initWithContext:cmdctx];
  }
  else {
    NSString     *adaptor;
    NSString     *login, *pwd, *dbname, *hostname;
    NSDictionary *conDict;
    
    adaptor  = [_array objectAtIndex:0];
    login    = count > 1 ? [_array objectAtIndex:1] : @"nobody";
    pwd      = count > 2 ? [_array objectAtIndex:2] : @"";
    dbname   = count > 3 ? [_array objectAtIndex:3] : @"skyformdb";
    hostname = count > 4 ? [_array objectAtIndex:4] : @"localhost";
    
    if (count > 5) doCache = [[_array objectAtIndex:5] boolValue];
    
    conDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [login    stringValue], @"userName",
                              [pwd      stringValue], @"password",
                              [hostname stringValue], @"hostName",
                              [dbname   stringValue], @"databaseName",
                              nil];
    
    ds = [[SkyDBDataSource alloc] initWithContext:cmdctx
                                  adaptorName:adaptor
                                  connectionDictionary:conDict
                                  primaryKeyGenerationDictionary:nil];
  }
  
  if (ds == nil) {
    [self logWithFormat:@"couldn't create SKYRiX database datasource .."];
  }
  else if (doCache) {
    EOCacheDataSource *cds;
    
    if ((cds = [[EOCacheDataSource alloc] initWithDataSource:ds])) {
      [ds release];;
      ds = cds;
    }
  }
  
  return [ds autorelease];
}

- (id)_jsfunc_getDocumentManager:(NSArray *)_array {
  return [[(id)[self session] commandContext] documentManager];
}

- (NSException *)handleDataSourceCreationError:(NSException *)_exception {
  [self logWithFormat:
          @"WARNING: exception during JavaScript datasource instantiation: %@",
          _exception];
  return nil;
}

- (id)_jsfunc_getDataSource:(NSArray *)_array {
  unsigned     count;
  NSString     *dsName;
  Class        dsClass;
  EODataSource *dataSource;
  BOOL         doCache = YES;
  
  if ((count = [_array count]) == 0)
    return nil;

  if (count > 1)
    doCache = [[_array objectAtIndex:1] boolValue];
  
  dsName  = [[_array objectAtIndex:0] stringValue];
  dsClass = NSClassFromString(dsName);
  if (dsClass == Nil) {
    [self debugWithFormat:@"missing datasource class %@", dsName];
    return nil;
  }
  
  if ([dsClass instancesRespondToSelector:@selector(initWithContext:)]) {
    NS_DURING {
      dataSource =
        [[dsClass alloc] initWithContext:
                           (id)[(id)[self session] commandContext]];
    }
    NS_HANDLER
      [[self handleDataSourceCreationError:localException] raise];
    NS_ENDHANDLER;
  }
  else {
    NS_DURING
      dataSource = [[dsClass alloc] init];
    NS_HANDLER
      [[self handleDataSourceCreationError:localException] raise];
    NS_ENDHANDLER;
  }
  
  if (dataSource == nil) {
    [self debugWithFormat:@"couldn't allocate datasource object of class %@ ..",
            dsName];
    return nil;
  }

  if (doCache) {
    EOCacheDataSource *cds;
    
    cds = [[EOCacheDataSource alloc] initWithDataSource:dataSource];
    [dataSource release];
    dataSource = cds;
  }
  
  return [dataSource autorelease];
}

- (id)_jsfunc_getAccountInfo:(NSArray *)_array {
  NSMutableDictionary *md;
  LSWSession *sn;
  id      tmp;
  NSArray *teams;
  id      account;
  
  md = [NSMutableDictionary dictionaryWithCapacity:16];
  
  sn = (LSWSession *)[self session];
  
  if ((tmp = [sn primaryLanguage]))
    [md setObject:tmp forKey:@"language"];
  if ((tmp = [[sn timeZone] timeZoneName]))
    [md setObject:tmp forKey:@"timeZoneAbbreviation"];
  if ((tmp = [sn activeLogin]))
    [md setObject:tmp forKey:@"login"];
  
  if ((account = [sn activeAccount])) {
    if ((tmp = [account valueForKey:@"description"]))
      [md setObject:tmp forKey:@"nickname"];
    if ((tmp = [account valueForKey:@"firstname"]))
      [md setObject:tmp forKey:@"firstname"];
    if ((tmp = [account valueForKey:@"name"]))
      [md setObject:tmp forKey:@"lastname"];
    if ((tmp = [account valueForKey:@"middlename"]))
      [md setObject:tmp forKey:@"middlename"];
    if ((tmp = [account valueForKey:@"url"]))
      [md setObject:tmp forKey:@"url"];

    if ((tmp = [account valueForKey:@"email1"]))
      [md setObject:tmp forKey:@"mail"];
    
    teams = [[sn commandContext] runCommand:@"account::teams",
                                   @"object", account, nil];
    teams = [teams valueForKey:@"description"];
    
    if (teams)
      [md setObject:teams forKey:@"teams"];
  }
  
  return [[md copy] autorelease];
}

- (id)_jsfunc_getAccount:(NSArray *)_array {
  id         eo;
  LSWSession *sn;
  
  sn = (LSWSession *)[self session];
  
  if ((eo = [sn activeAccount]) == nil)
    /* no active account ??? */
    return nil;
  
  return [[[sn commandContext]
               documentManager]
               documentForGlobalID:[eo globalID]];
}

@end /* SkyFormComponent(Additions) */
