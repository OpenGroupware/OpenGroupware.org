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
//$Id$

#include "SkyImapMailDataSource.h"
#include <NGStreams/NGSocketExceptions.h>
#include "common.h"

// TODO: whats different between this datasource and the NGImap4DataSource?

@interface SkyImapMailDataSource(PrivateMethodes)
- (NSArray *)fetchMessages;
@end

@interface EOQualifier(PrivateMethodes)
- (NSString *)qualifierDescription;
@end


@implementation SkyImapMailDataSource

static BOOL    profileDS    = NO;
static int     SSSortingForStringAttributes = -1;
static int     ServerSideSortingDisabled    = -1;

static NSArray      *StringAttrs = nil;
static NSNull       *Null        = nil;
static NSDictionary *SoMapping   = nil;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  SSSortingForStringAttributes =
    [ud boolForKey:@"EnableSSSortingForStringAttributes"]?1:0;
  ServerSideSortingDisabled = [ud boolForKey:@"ServerSideSortingDisabled"]?1:0;
  
  if (Null == nil) 
    Null = [[NSNull null] retain];
  if (StringAttrs == nil) {
    StringAttrs = [[NSArray alloc] initWithObjects:
                                     @"subject", @"sender", @"to", @"from",
				   nil];
  }
  if (SoMapping == nil) { // TODO: find out what it does
    /* possible so-keys: subject, sender, sendDate, contentLen,seen, to */
    SoMapping = [[NSDictionary alloc] initWithObjectsAndKeys:
					@"date",    @"sendDate",
				        @"from",    @"sender",
				        @"size",    @"contentLen",
				        @"subject", @"subject",
				        @"unseen",  @"seen",
				        @"to",      @"to", nil];
  }
  
  if ((profileDS = [ud boolForKey:@"ProfileImap4DataSource"]))
    NSLog(@"SkyImapMailDataSource: Profiling enabled!");
}

- (NSNotificationCenter *)notificationCenter {
  static NSNotificationCenter *nc = nil;
  if (nc == nil) nc = [[NSNotificationCenter defaultCenter] retain];
  return nc;
}

- (id)init {
  if ((self = [super init])) {
    NSNotificationCenter *nc = [self notificationCenter];
    
    [nc addObserver:self selector:@selector(mailsWereDeleted:)
	name:@"LSWImapMailWasDeleted" object:nil];
    
    [nc addObserver:self selector:@selector(folderWasMoved:)
	name:@"LSWImapMailFolderWasDeleted" object:nil];
    
    [nc addObserver:self selector:@selector(flagsWereChanged:)
	name:@"LSWImapMailFlagsChanged" object:nil];
    self->maxCount     = -1;
    self->doSubFolders = NO;
    
  }
  return self;
}

- (void)dealloc {
  [[self notificationCenter] removeObserver:self];
  [self->folder            release];
  [self->qualifier         release];
  [self->messages          release];
  [self->sortOrderings     release];
  [self->oldUnseenMessages release];
  [super dealloc];
}

/* notifications */

- (void)folderWasMoved:(id)_obj {
  [self->folder            release]; self->folder   = nil;
  [self->messages          release]; self->messages = nil;
  [self->oldUnseenMessages release]; self->oldUnseenMessages = nil;
}

- (void)mailsWereDeleted:(id)_obj {
  [self->messages          release]; self->messages = nil;
  [self->oldUnseenMessages release]; self->oldUnseenMessages = nil;
}

- (void)flagsWereChanged:(id)_obj {
  [[self notificationCenter]
                         postNotificationName:
                           EODataSourceDidChangeNotification
                         object:self];
}

/* fetching */

- (NSArray *)fetchObjects {
  NSAutoreleasePool *pool;
  NSArray *tmp;
  
  if (self->messages) {
    if (profileDS) [self logWithFormat:@"fetchObjects: already fetched."];
    return self->messages;
  }
  
  pool = [[NSAutoreleasePool alloc] init];
  {  
    if (profileDS) [self logWithFormat:@"fetchObjects: fetch ..."];
    
    tmp = (self->folder) ? [self fetchMessages] : [NSArray array];

    if (profileDS) [self logWithFormat:@"fetchObjects:   done ..."];
    ASSIGN(self->messages, tmp);
  }
  [pool release];
  if (profileDS) [self logWithFormat:@"fetchObjects:   pool released."];
  
  return self->messages;
}

- (void)setFolder:(NGImap4Folder *)_folder {
  NSNotificationCenter *nc;

  nc = [self notificationCenter];
  
  ASSIGN(self->folder,            _folder);
  [self->messages          release]; self->messages          = nil;
  [self->oldUnseenMessages release]; self->oldUnseenMessages = nil;
  
  [nc postNotificationName:EODataSourceDidChangeNotification object:self];
}
- (NGImap4Folder *)folder {
  return self->folder;
}

- (void)setQualifier:(EOQualifier *)_qualifier {
  NSString             *qualString;
  NSNotificationCenter *nc;
  
  if (self->qualifier == _qualifier)
    return;
  
  nc = [self notificationCenter];
  qualString = [self->qualifier qualifierDescription];
  ASSIGN(self->qualifier, _qualifier);
  [self->messages release]; self->messages = nil;
  
  // TODO: perf - also see NGImap4 EOQualifier!
  if (([qualString rangeOfString:@"unseen"].length == 0) ||
      (self->qualifier == nil)) {
    [self->oldUnseenMessages release]; self->oldUnseenMessages = nil;
  }
  [nc postNotificationName:EODataSourceDidChangeNotification object:self];
}

- (void)setFetchSpecification:(EOFetchSpecification *)_fetchSpec {
  NSArray     *so;
  EOQualifier *q;

  q = [_fetchSpec qualifier];
  
  if (self->qualifier || q) {
    if (![self->qualifier isEqual:q]) {
      [self setQualifier:q];
      [self->messages release]; self->messages = nil;
    }
  }
  so = [_fetchSpec sortOrderings];
  if (![self->sortOrderings isEqual:so]) {
    ASSIGN(self->sortOrderings, so);
    [self->messages release]; self->messages = nil;
  }
}

- (EOFetchSpecification *)fetchSpecification {
  EOFetchSpecification *fetchSpec;

  fetchSpec = [[[EOFetchSpecification alloc] init] autorelease];
  [fetchSpec setSortOrderings:self->sortOrderings];
  [fetchSpec setQualifier:self->qualifier];
  return fetchSpec;
}

- (int)oldExists {
  return self->oldExists;
}
- (int)oldUnseen {
  return self->oldUnseen;
}

/* private methodes */

- (BOOL)useSSSortingForSOArray:(NSArray *)_array {
  if (![self useServerSideSorting])
    return NO;
  
  if ([_array count] == 0)
    return YES;
  
  if (SSSortingForStringAttributes == 0) {
    NSString *sKey;
    
    sKey = [[_array objectAtIndex:0] key];
    return ![StringAttrs containsObject:[sKey lowercaseString]];
  }
  return YES;
}

- (BOOL)useServerSideSorting {
  static int CanSortAllowed             = -1;
  static int ServerSideSortingDisabled2 = -1;

  if (ServerSideSortingDisabled2 == -1) {
    ServerSideSortingDisabled2 = ServerSideSortingDisabled;
    if (!ServerSideSortingDisabled2) {
      if (![self->folder respondsToSelector:@selector(fetchSortedMessages:)]) {
        NSLog(@"WARNING[%s]: server side sorting was enabled, "
              @"but the linked version of NGImap4 does not support it",
              __PRETTY_FUNCTION__);
        ServerSideSortingDisabled2 = YES;
      }
    }
  }
  if (ServerSideSortingDisabled2)
    return NO;
  
  if (CanSortAllowed == -1) {
    CanSortAllowed = 
      [[self->folder context] respondsToSelector:@selector(canSort)]?1:0;
  }
  if (CanSortAllowed)
    return [[self->folder context] canSort];

  return YES;
}


- (void)setDoSubFolders:(BOOL)_flag {
  self->doSubFolders = _flag;
}
- (BOOL)doSubFolders {
  return self->doSubFolders;
}

- (void)setMaxCount:(unsigned)_maxCount {
  self->maxCount = _maxCount;
}
- (unsigned)maxCount {
  return self->maxCount;
}

- (NSArray *)searchFolder:(NGImap4Folder *)_folder maxCount:(int)_maxCount{
  NSMutableArray *m;
  
  if (profileDS) 
    [self logWithFormat:@"searchFolder: begin (max %i) ...", _maxCount];

  if (_maxCount == -1) {
    m = (NSMutableArray *)[_folder messagesForQualifier:self->qualifier];
  }
  else {
    m = (NSMutableArray *)[_folder messagesForQualifier:self->qualifier
                                   maxCount:_maxCount];
  }
  if (self->doSubFolders) {
    NSEnumerator  *enumerator;
    NGImap4Folder *f;

    if (_maxCount == -1)
      _maxCount = 400;
    
    m = (m != nil) ? [m mutableCopy]
                   : [[NSMutableArray alloc]
                                      initWithCapacity:256];
    
    enumerator = [[_folder subFolders] objectEnumerator];

    while ((f = [enumerator nextObject])) {
      _maxCount = _maxCount - [m count];
      if (_maxCount <= 0) break;
      [m addObjectsFromArray:[self searchFolder:f maxCount:_maxCount]];
    }
    [m autorelease];
  }

  if (profileDS) [self logWithFormat:@"searchFolder: done."];
  return m;
}

static NSString *formatEmail(NSString *_s) {
  int  strLen = [_s cStringLength];
  int  cnt;
  char str[strLen + 1];

  if (!strLen)
    return _s;

  [_s getCString:str];
  cnt = 0;

  while ((cnt < strLen)) { /* remove leading ' ', '(', '[' */
    if (str[cnt] == ' ' || str[cnt] == '"' ||
        str[cnt] == '\'' || str[cnt] == '<') 
      cnt++;
    else
      break;
  }
  if (cnt == strLen || cnt == 0) /* if no more chars, return */
    return _s;

  return [_s substringWithRange:NSMakeRange(cnt, strLen - cnt)];
}

static NSString *formatSubject(NSString *_s) {
  int  strLen = [_s cStringLength];
  int  cnt;
  char str[strLen + 1];
  BOOL found;

  if (!strLen)
    return _s;

  [_s getCString:str];
  cnt = 0;

  while ((cnt < strLen)) { /* remove leading ' ', '(', '[' */
    if (str[cnt] == ' ' || str[cnt] == '(' || str[cnt] == '[')
      cnt++;
    else
      break;
  }
  if (cnt == strLen) /* if no more chars, return */
    return _s;

  found = NO;
  if (strLen - cnt > 1) {
    if ((str[cnt] == 'r' && str[cnt + 1] == 'e') ||
        (str[cnt] == 'a' && str[cnt + 1] == 'w') ||
        (str[cnt] == 'w' && str[cnt + 1] == 'g')) {
      found =  YES;
      cnt  += 2;
    }
  }
  if (strLen - cnt > 2) {
    if ((str[cnt] == 'f' && str[cnt + 1] == 'w' && str[cnt + 2] == 'd') ||
        (str[cnt] == 'f' && str[cnt + 1] == 'y' && str[cnt + 2] == 'i')) {
      found =  YES;
      cnt  += 3;
    }
  }
  if (!found)
    return _s;

  while ((cnt < strLen)) { /* remove leading ' ', '(', '[' */
    if (str[cnt] == ' ' || str[cnt] == ':' || str[cnt] == ']'
        || str[cnt] == ')')
      cnt++;
    else
      break;
  }
  _s = [_s substringWithRange:NSMakeRange(cnt, strLen - cnt)];
  return formatSubject(_s);
}

static int sortEmailHeader(id o1, id o2, void *_so) {
  // TODO: performance!
  NSEnumerator *enumerator;
  id           obj;
  NSArray      *a;

  a          = (NSArray *)_so;
  enumerator = [a objectEnumerator];

  while ((obj = [enumerator nextObject])) {
    NSString *key;
    SEL      sel;
    id       v1, v2;
    int      (*ccmp)(id, SEL, id);
    int      result;

    key = [obj key];
    sel = [obj selector];
    v1  = [o1 valueForKey:key];
    v2  = [o2 valueForKey:key];
    
    key = [key lowercaseString];

    if ([@"subject" isEqualToString:key]) {
      v1 = formatSubject([v1 lowercaseString]);
      v2 = formatSubject([v2 lowercaseString]);
    }
    if ([@"sender" isEqualToString:key] ||
        [@"from" isEqualToString:key] ||
        [@"to" isEqualToString:key]) {
      v1 = formatEmail([v1 lowercaseString]);
      v2 = formatEmail([v2 lowercaseString]);
    }
    if (v1 == v2)
      result = NSOrderedSame;
    else if ((v1 == nil) || (v1 == Null))
      result = (sel == EOCompareAscending)
        ? NSOrderedAscending : NSOrderedDescending;
    else if ((v2 == nil) || (v2 == Null))
      result = (sel == EOCompareAscending)
        ? NSOrderedDescending : NSOrderedAscending;
    else if ((ccmp = (void *)[v1 methodForSelector:sel]))
      result = ccmp(v1, sel, v2);
    else
      result = (int)[v1 performSelector:sel withObject:v2];

    if (result != NSOrderedSame)
      return result;
  }
  return NSOrderedSame;
}


- (NSArray *)_fetchMessagesUsingSearch {
  NSArray *result;
  
  if (profileDS) [self logWithFormat:@"_fetchMessagesUsingSearch: begin ..."];
  
  result = [self searchFolder:self->folder maxCount:self->maxCount];
  
  if (profileDS) {
    [self logWithFormat:@"_fetchMessagesUsingSearch:   got: %i, sort ...", 
	    [result count]];
  }
  result = [result sortedArrayUsingKeyOrderArray:self->sortOrderings];
  
  if (profileDS) [self logWithFormat:@"_fetchMessagesUsingSearch: done."];
  return result;
}
- (NSArray *)_fetchMessagesUsingSSS {
  /* possible so-keys: subject, sender, sendDate, contentLen,seen, to */
  NSArray        *result;
  NSArray        *sos;
  NSString       *soKey;
  EOSortOrdering *so;
	
  so = nil;
  if ([self->sortOrderings count] > 0) {
    so = [self->sortOrderings objectAtIndex:0];
            
    if ((soKey = [so key]) == nil)
      soKey = @"sendDate";
  }
  else
    soKey = @"sendDate";
  soKey = [SoMapping objectForKey:soKey];
	
  sos = [NSArray arrayWithObject:
		   [EOSortOrdering sortOrderingWithKey:soKey
				   selector:[so selector]]];
  
  /* fetch */
  
  if (profileDS) 
    [self logWithFormat:@"_fetchMessagesUsingSSS:   fetch sorted ..."];
  result = [self->folder fetchSortedMessages:sos];
  if (profileDS) 
    [self logWithFormat:@"_fetchMessagesUsingSSS: done: %i.", [result count]];
  return result;
}

- (NSException *)_processFetchException:(NSException *)localException {
  static NSString  *rawResp = @"RawResponse";
  static NSString  *respRes = @"ResponseResult";
  static NSString  *descr   = @"description";
  
  if (localException == nil)
    return nil;

  if ([localException isKindOfClass:[NGImap4ResponseException class]]) {
    NSString *str;

    str = [(NSDictionary *)[(NSDictionary *)[[localException userInfo]
                                       objectForKey:rawResp]
                                       objectForKey:respRes]
                                       objectForKey:descr];
    printf("%s\n", [str cString]);
  }    
  else if ([localException isKindOfClass:[NGIOException class]]) {
    printf("%s\n", [[localException reason] cString]);
  }
  else if ([localException isKindOfClass:[NGImap4Exception class]]) {
    printf("%s\n", [[localException description] cString]);
  }
  else {
    return localException;
  }
  return nil;
}

- (NSArray *)fetchMessages {
  // TODO: split up
  NSArray   *result;
  NSString  *qualStr;
  BOOL      useSSS;
  
  if (profileDS) [self logWithFormat:@"fetchMessages: begin ..."];
  
  result = nil;
  useSSS = [self useSSSortingForSOArray:self->sortOrderings];
  {
    id localException;

    [self->folder resetLastException];
    self->oldExists = [self->folder exists];
    self->oldUnseen = [self->folder unseen];

    if (!useSSS) {
      result = (self->qualifier == nil)
        ? [self->folder messages]
        : [self searchFolder:self->folder maxCount:self->maxCount];
    }
    else {
      if (self->qualifier)
	result = [self _fetchMessagesUsingSearch];
      else
	result = [self _fetchMessagesUsingSSS];
    }
    if ((localException = [self->folder lastException])) {
      [[self _processFetchException:localException] raise];
      result = [NSArray array];
    }
  }
  qualStr = [self->qualifier qualifierDescription];
  
  if (profileDS) [self logWithFormat:@"fetchMessages:   process unseen ..."];
  // TODO: perf, see EOQualifier+IMAP in NGImap4
  if ([qualStr rangeOfString:@"unseen"].length > 0 && self->qualifier) {
    NSMutableSet *set = nil;

    if (self->oldUnseenMessages) { // this implies, the folder hasn't changed
      set = [NSMutableSet setWithArray:result];
      [set addObjectsFromArray:self->oldUnseenMessages];
      result = [set allObjects];
    }
    [self->oldUnseenMessages release]; self->oldUnseenMessages = nil;
    ASSIGN(self->oldUnseenMessages, result);
  }

  if (useSSS) {
    if (profileDS) [self logWithFormat:@"fetchMessages: SSS done."];
    return result;
  }
  
  if (profileDS) 
    [self logWithFormat:@"fetchMessages:   sorting on client ..."];
  result = [result sortedArrayUsingFunction:sortEmailHeader
		   context:self->sortOrderings];
  if (profileDS) [self logWithFormat:@"fetchMessages: done."];
  return result;
}

- (void)preFetchMessagesInRange:(NSRange)_range {
  if ((self->folder != nil) && [self useServerSideSorting]) {
    static int CheckNGMimeVersion = -1;

    if (CheckNGMimeVersion == -1)
      CheckNGMimeVersion =
        [self->folder respondsToSelector:
             @selector(bulkFetchHeadersFor:inRange:withAllUnread:)] ? 1 : 0;

    if (!CheckNGMimeVersion) {
      [self logWithFormat:@"%s: NGMime Version 4.1.125 or higher are needed",
            __PRETTY_FUNCTION__];
      [self->folder bulkFetchHeadersFor:[self fetchObjects] inRange:_range];
    }
    else {
      [self->folder bulkFetchHeadersFor:[self fetchObjects] inRange:_range
           withAllUnread:YES];
    }
  }
  else {
    [self logWithFormat:@"WARNING[%s]: try to prefetch messages although "
            @"ServerSideSortingDisabled=YES", __PRETTY_FUNCTION__];
  }
}

@end /* SkyImapMailDataSource */
