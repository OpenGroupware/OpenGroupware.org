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

#include "ProjectChannel.h"
#include "common.h"
#include "Application.h"
#include "SkyProjectFileManager+MD5.h"
#include "Change.h"

@implementation ProjectChannel

- (id)init {
  if ((self = [super init])) {
    self->changeInfo = [[NSDictionary alloc] init];
    self->projectID  = [[NSString alloc] init];
  }
  return self;
}

- (void)dealloc {
  RELEASE(self->changeInfo);
  RELEASE(self->globalID);
  RELEASE(self->projectID);
  
  [super dealloc];
}

/* accessors */

- (NSDictionary *)changeInfo {
  return self->changeInfo;
} 
- (void)setChangeInfo:(NSDictionary *)_info {
  ASSIGN(self->changeInfo, _info);
}

- (NSString *)projectID {
  return self->projectID;
}
- (void)setProjectID:(NSString *)_projectID {
  ASSIGNCOPY(self->projectID, _projectID);
}

- (void)setGlobalID:(EOGlobalID *)_global {
  ASSIGN(self->globalID, _global);
}

- (void)resetChanges:(NSString *)_element {
  if (_element == nil) {
    [self setChangeInfo:[NSDictionary dictionary]];
  }
  else {
    NSMutableDictionary *dict = nil;

    dict = [NSMutableDictionary dictionaryWithCapacity:
				  [self->changeInfo count]];
    [dict addEntriesFromDictionary:self->changeInfo];
    [dict removeObjectForKey:_element];
    [self setChangeInfo:dict];
  }
}

- (SkyProjectFileManager *)fileManagerInContext:(LSCommandContext *)_ctx {
  id fm  = nil;

  if (self->globalID == nil) {
    NSRange r;
    
    self->globalID = [[EOGlobalID alloc] init];

    r = [[self projectID] rangeOfString:@"://"];

    if (r.length != 0) {
      [self setGlobalID:[[_ctx documentManager]
                               globalIDForURL:[self projectID]]];
    }
    else {
      EOFetchSpecification *fspec     = nil;
      EOQualifier          *qualifier = nil;
      id                   pds        = nil;
      id                   project    = nil;
      NSArray              *projects  = nil;
      NSString             *pid       = nil;
      NSDictionary         *hints     = nil;
    
      if (_ctx == nil) {
        NSLog(@"ERROR[%@] missing commandContext, return nil", self);
        return nil;
      } 

      pid = [self projectID];

      if (pid == nil || [pid length] == 0) {
        NSLog(@"missing project number");
        return nil;
      }
      qualifier = [EOQualifier qualifierWithQualifierFormat:@"number=%@",
                               pid];

      hints = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                            forKey:@"SearchAllProjects"];
      fspec = [[EOFetchSpecification alloc] initWithEntityName:nil
					    qualifier:qualifier
					    sortOrderings:nil
					    usesDistinct:YES];
      [fspec setHints:hints];
      pds = [[SkyProjectDataSource alloc] initWithContext:(id)_ctx];
        
      [pds setFetchSpecification:fspec];
      projects = [pds fetchObjects];
  
      if ([projects count] == 1) {
        project = [projects objectAtIndex:0];
      }
      else {
        project = nil;
      }
    
      AUTORELEASE(fspec); fspec = nil;
      RELEASE(pds); pds = nil;
    
      if (project == nil) {
        NSLog(@"ERROR[%s] missing project", __PRETTY_FUNCTION__);
        return nil;
      }
      [self setGlobalID:[project valueForKey:@"globalID"]];
    }   
  }

  if (self->globalID == nil) {
    NSLog(@"ERROR[%s] missing gid", __PRETTY_FUNCTION__);
    return nil;
  }
  
  fm = [[SkyProjectFileManager alloc] initWithContext:_ctx
                                      projectGlobalID:self->globalID];
  AUTORELEASE(fm);
  return fm;  
}

- (NSDictionary *)getMD5ValuesAndWriteToFile:(NSString *)fileName {
  LSCommandContext      *context     = nil;
  SkyProjectFileManager *fileManager = nil;
  NSDictionary          *md5Values   = nil;
  Application           *app         = nil;

  app = (Application *)[WOApplication application];
  
  context = [app contextForCredentials:[self credentials]];
  
  fileManager = [self fileManagerInContext:context];

  if (fileManager == nil) {
    NSLog(@"%s: no valid file manager found", __PRETTY_FUNCTION__);
    return nil;
  }

  md5Values = [fileManager md5ValuesAtPath:@"/" deep:YES];

  [md5Values writeToFile:fileName atomically:YES];

  return md5Values;
}

- (void)saveToUserFile:(NSString *)_userName {
  NSUserDefaults      *ud           = nil;
  NSString            *filePath     = nil;
  NSMutableDictionary *dict         = nil;
  NSMutableArray      *userChannels = nil;
  
  ud = [NSUserDefaults standardUserDefaults];

  filePath = [ud stringForKey:@"SkyTrackDaemonUserHome"];
  filePath = [filePath stringByAppendingPathComponent:_userName];

  filePath = [filePath stringByAppendingPathComponent:@"Channels.plist"];

  userChannels = [NSMutableArray arrayWithContentsOfFile:filePath];

  if (userChannels == nil) {
    userChannels = [NSMutableArray arrayWithCapacity:1];
  }
  
  dict = [NSMutableDictionary dictionaryWithCapacity:4];
  [dict takeValue:[self channelID] forKey:@"name"];
  [dict takeValue:@"ProjectChannel" forKey:@"type"];
  [dict takeValue:[self projectID] forKey:@"project_id"];
  [dict takeValue:[self credentials] forKey:@"credentials"];

  [userChannels addObject:dict];

  [userChannels writeToFile:filePath atomically:YES];

  filePath = [ud stringForKey:@"SkyTrackDaemonUserHome"];
  filePath = [filePath stringByAppendingPathComponent:[self channelID]];
  filePath = [filePath stringByAppendingString:@".md5"];
  
  [self getMD5ValuesAndWriteToFile:filePath];
}

- (NSDictionary *)channelInfo {
  NSMutableDictionary *dict = nil;

  dict = [NSMutableDictionary dictionaryWithCapacity:3];

  [dict takeValue:self->projectID forKey:@"projectID"];
  [dict takeValue:self->channelID forKey:@"channelID"];
  [dict takeValue:self->lastModification forKey:@"lastModified"];
  return dict;
} 

- (id)initWithDictionary:(NSDictionary *)_dict name:(NSString *)_name {
  [super initWithDictionary:_dict name:_name];
  [self setProjectID:[_dict objectForKey:@"project_id"]];
  return self;
}

- (id)trackChannel {
  NSDictionary          *snapShot     = nil;
  NSString              *fileName     = nil;
  Application           *app          = nil;
  NSUserDefaults        *ud           = nil;
  NSDictionary          *filesAndMD5s = nil; 
  
  NSLog(@"now tracking project %@", [self projectID]);
  
  app = (Application *)[WOApplication application];
  ud  = [NSUserDefaults standardUserDefaults];
  
  fileName = [ud stringForKey:@"SkyTrackDaemonUserHome"];
  fileName = [fileName stringByAppendingPathComponent:[self channelID]];
  fileName = [fileName stringByAppendingString:@".md5"];
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:fileName] == YES) {
    snapShot = [NSDictionary dictionaryWithContentsOfFile:fileName];
  }
    
  filesAndMD5s = [self getMD5ValuesAndWriteToFile:fileName];

  if (snapShot != nil) {
    NSMutableDictionary *changes    = nil;
    NSMutableDictionary *changeDict = nil;
    NSDictionary        *newValues  = nil;
    NSEnumerator        *keyEnum    = nil;
    id                  key         = nil;
    NSString            *userDir    = nil;

    userDir = [[fileName stringByDeletingPathExtension]
                        stringByAppendingString:@".log"];
      
    changes = [NSMutableDictionary dictionaryWithCapacity:16];
    [changes addEntriesFromDictionary:self->changeInfo];

    newValues = [self compareOldMD5:snapShot
                      withNewMD5:filesAndMD5s];

    keyEnum = [newValues keyEnumerator];

    while ((key = [keyEnum nextObject])) {
      Change *change = nil;

      if ((change = [changes objectForKey:key]) != nil) {
        Change *newChange;

        newChange = [newValues objectForKey:key];
        NSLog(@"there's already a change for %@", key);

        [change updateValues:newChange];
        [change runActions];
      }
      else {
        [changes setObject:[newValues objectForKey:key] forKey:key];
      }
    }

    keyEnum = [changes keyEnumerator];
    changeDict = [NSMutableDictionary dictionaryWithCapacity:[changes count]];
    
    while ((key = [keyEnum nextObject])) {
      NSMutableDictionary *subdict = nil;
      NSArray             *actions = nil;
      
      subdict = [NSMutableDictionary dictionaryWithCapacity:2];
      [subdict takeValue:[[changes objectForKey:key] changeType]
               forKey:@"type"];
      [subdict takeValue:[[changes objectForKey:key] changeDate]
               forKey:@"lastModification"];      

      if ((actions = [[changes objectForKey:key] actions]) != nil) {
        [subdict takeValue:actions
                 forKey:@"actions"];

      }
      
      [changeDict takeValue:subdict forKey:key];

    }
    
    [changeDict writeToFile:userDir atomically:YES];
    
    if (changes != nil) {
      [self setChangeInfo:changes];
    }
    [self setLastModification:[NSDate date]];
  }

  NSLog(@"%s: changeInfo for channel %@: %@",
        __PRETTY_FUNCTION__, [self channelID], [self changeInfo]);
  
  return nil;
}

- (id)compareOldMD5:(id)_old withNewMD5:(id)_new {
  NSMutableDictionary *changes    = nil;
  NSArray             *oldKeys    = nil;
  NSArray             *newKeys    = nil;
  NSEnumerator        *keyEnum    = nil;
  NSEnumerator        *oldKeyEnum = nil;
  id                  oldKey      = nil;
  id                  key         = nil;

  oldKeys = [_old allKeys];
  keyEnum = [_new keyEnumerator];

  changes = [NSMutableDictionary dictionaryWithCapacity:16];
  
  while ((key = [keyEnum nextObject])) {
    Change *entry = nil;

    if ([oldKeys containsObject:key]) {
      NSString *oldHash = nil;
      NSString *newHash = nil;

      oldHash = [[_old objectForKey:key] objectForKey:@"md5"];
      newHash = [[_new objectForKey:key] objectForKey:@"md5"];
      
      if (![oldHash isEqualToString:newHash]) {
        entry = [Change changeWithChangeType:@"changed"];
        [changes setObject:entry forKey:key];
      }
    }
    else {
      entry = [Change changeWithChangeType:@"added"];
      [changes setObject:entry forKey:key];
    }
  }

  newKeys = [_new allKeys];
  oldKeyEnum = [_old keyEnumerator];

  while ((oldKey = [oldKeyEnum nextObject])) {
    Change *entry = nil;

    if (![newKeys containsObject:oldKey]) {
      entry = [Change changeWithChangeType:@"deleted"];
      [changes setObject:entry forKey:oldKey];
    }
  }
  
  return changes;
}

- (void)registerAction:(id)_action forElement:(NSString *)_element {
  Change *change = nil;

  if ((change = [[self changeInfo] objectForKey:_element]) == nil) {
    NSMutableDictionary *dict;
    
    dict = [NSMutableDictionary dictionaryWithCapacity:
                                [self->changeInfo count]+1];

    [dict addEntriesFromDictionary:[self changeInfo]];

    change = [Change changeWithChangeType:@"check"];
    [dict setObject:change forKey:_element];

    [self setChangeInfo:dict];
  }

  if (_action != nil) {
    [change addAction:_action];
  }
}

@end /* ProjectChannel */
