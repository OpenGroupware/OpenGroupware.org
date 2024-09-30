/*
  Copyright (C) 2002-2005 SKYRIX Software AG

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

#include "SxMsgRootFolder.h"
#include "common.h"
#include "NGResourceLocator+ZSF.h"
#include <NGExtensions/NGPropertyListParser.h>

@interface NSObject(PubFolder)
- (id)publicFolder:(NSString *)_name container:(id)_c;
- (NSString *)ownerID;
@end

@implementation SxMsgRootFolder

static NSDictionary *personalFolderMap = nil;

+ (void)initialize {
  NGResourceLocator *locator;
  NSDictionary *info;
  NSString     *path;
  
  locator = [NGResourceLocator zsfResourceLocator];
  path = [locator lookupFileWithName:@"PersonalFolderInfo.plist"];
  if ([path length] < 10) {
    info = nil;
    NSLog(@"ERROR(%s): did not find PersonalFolderInfo.plist!",
	  __PRETTY_FUNCTION__);
  }
  else if ((info = [NSDictionary skyDictionaryWithContentsOfFile:path]) == nil)
    [self logWithFormat:@"ERROR: could not load folder info: '%@'", path];
  personalFolderMap = [[info objectForKey:@"keymap"] copy];
}

/* homepage */

- (BOOL)showHomePageURL {
  return YES;
}
- (NSString *)homePageURL {
  NSMutableArray *paras;
  WOContext *ctx;
  WORequest *rq;
  NSString *url;
  NSString *t;
  
  ctx = [(WOApplication *)[WOApplication application] context];
  rq  = [ctx request];
  url = [[self container] baseURLInContext:ctx];
  url = [url stringByAppendingString:@"settings"];
  
  /* collect parameters */
  
  paras = [NSMutableArray arrayWithCapacity:8];
  if ((t = [rq headerForKey:@"x-zidestore-name"])) {
    t = [t stringByEscapingURL];
    t = [@"zidelook=" stringByAppendingString:t];
    [paras addObject:t];
  }
  if ((t = [[self container] ownerID])) {
    t = [t stringByEscapingURL];
    t = [@"owner=" stringByAppendingString:t];
    [paras addObject:t];
  }
  
  // TODO: could add basic-auth as a query parameter, but this would be
  //       visible in the Apache log (no good) - maybe use a ticket
  //       till then, maybe allow to configure that using a default
  //  'authorization' header
  
  if ([paras count] > 0) {
    url = [url stringByAppendingString:@"?"];
    url = [url stringByAppendingString:[paras componentsJoinedByString:@"&"]];
  }
  
  return url;
}

/* subfolders */

- (NSArray *)toManyRelationshipKeys {
  static NSArray *keys = nil;
  if (keys == nil) {
    keys = [[NSArray alloc] initWithObjects:
			      @"Calendar",
                              @"Overview",
			      @"Tasks",
			      @"Contacts",
			      @"Enterprises",
			      @"Groups",
			      @"public",
                              @"Trash",
                              @"Sent",
                              @"Drafts",
                              @"Outgoing",
                            nil];
  }
  return keys;
}

- (id)iCalendarForName:(id)_key inContext:(id)_ctx {
  id defCalendar;
  
  defCalendar = [self lookupName:@"Calendar" inContext:_ctx acquire:NO];
  if (defCalendar == nil) {
    [self logWithFormat:@"WARNING: did not find default-calendar !"];
    return nil;
  }
  return [defCalendar lookupName:_key inContext:_ctx acquire:NO];
}

/* lookup */

- (id)personalFolder:(NSString *)_name inContext:(id)_ctx
  info:(NSDictionary *)_info
{
  Class clazz;
  id tmp, folder;
  
  // [self logWithFormat:@"creating personal folder: %@: %@", _name, _info];
  
  tmp = [_info objectForKey:@"class"];
  clazz = tmp ? NGClassFromString(tmp) : Nil;
  if (clazz == Nil) {
    [self logWithFormat:@"ERROR: got no class for personal folder '%@': %@",
            _name, _info];
    return nil;
  }
  if ((folder = [[clazz alloc] initWithName:_name inContainer:self]) == nil) {
    [self logWithFormat:@"ERROR: could not create personal folder '%@': %@",
            _name, _info];
    return nil;
  }
  folder = [folder autorelease];
  
  if ((tmp = [_info objectForKey:@"config"])) {
    // TODO: does not seem to process BOOL values properly !!!
    [folder takeValuesFromDictionary:tmp];
  }
  
  return folder;
}

- (id)lookupName:(NSString *)_key inContext:(id)_ctx acquire:(BOOL)_flag {
  NSString *ua;
  id tmp;
  
  if ((tmp = [personalFolderMap objectForKey:_key]))
    return [self personalFolder:_key inContext:_ctx info:tmp];
  
  ua = [[[(WOContext *)_ctx request] clientCapabilities] userAgentType];
  if ([ua isEqualToString:@"AppleDAVAccess"]) {
    [self logWithFormat:@"UA: %@ - probably iCal.app / iCal-over-HTTP", ua];
    if ([_key isEqualToString:@".ics"])
      return [self iCalendarForName:@"calendar.ics" inContext:_ctx];
  }
  
  if ([_key isEqualToString:@"Public"] || [_key isEqualToString:@"public"]) {
    if (![ua hasPrefix:@"Evolution"]) {
      /* with Evolution we use a separate root-url for public folders */
      return [[WOApplication application] publicFolder:_key container:self];
    }
    
    return nil;
  }
  
  if ([_key isEqualToString:@"calendar.ics"] || [_key isEqualToString:@"ics"])
    return [self iCalendarForName:_key inContext:_ctx];
  
  return [super lookupName:_key inContext:_ctx acquire:_flag];
}

- (NSString *)baseURL {
  return [self baseURLInContext:
		 [(WOApplication *)[WOApplication application] context]];
}

/* DAV things */

- (BOOL)davHasSubFolders {
  /* user folders are there to have child folders */
  return YES;
}

- (NSArray *)defaultWebDAVPropertyNamesInContext:(id)_ctx {
  static NSMutableArray *defNames = nil;
  if (defNames == nil) {
    defNames =
      [[[self propertySetNamed:@"DefaultMailFolderProperties"]allObjects]copy];
  }
  return defNames;
}

- (NSException *)davCreateCollection:(NSString *)_name inContext:(id)_ctx {
  WOResponse *r;
  
  [self logWithFormat:@"shall create collection: '%@'", _name];
  
  // TODO: we should just return 'nil'?!
  r = [(WOContext *)_ctx response];
  [r setStatus:201 /* Created */];
  [r appendContentString:@"collection already exists, faked creation !"];
  return (id)r;
}

/* messages */

- (int)zlGenerationCount {
  /* root folders have no messages and therefore never change */
  return 1;
}

- (id)getIDsAndVersionsAction:(id)_ctx {
  WOResponse *response = [(WOContext *)_ctx response];
  [response setStatus:200]; /* OK */
  [response setHeader:@"text/plain" forKey:@"content-type"];
  return response;
}
- (int)cdoContentCount {
  return 0;
}

/* actions */

- (id)GETAction:(id)_ctx {
  BOOL isLicensed = NO;
  
#if 0
  isLicensed = [[self commandContextInContext:_ctx] 
                      isModuleLicensed:@"ZideStore"];
#else
  isLicensed = YES;
#endif
  
  
  /* Evolution issues a GET on the folder to check credentials */
  if ([[[(WOContext *)_ctx request] 
	 headerForKey:@"user-agent"] hasPrefix:@"Evolution/"]) {
    [[(WOContext *)_ctx response] 
      setStatus:isLicensed ? 200 : 402 /* Payment Required */];
    return [(WOContext *)_ctx response];
  }
  
  if (!isLicensed)
    return [[WOApplication application] pageWithName:@"SxMissingLicensePage"];
  
  return [[WOApplication application] pageWithName:@"SxUserHomePage"];
}

@end /* SxMsgRootFolder */
