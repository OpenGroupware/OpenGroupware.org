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

#include "SxEvoContactQueryInfo.h"
#include <ZSFrontend/EOQualifier+Additions.h>
#include <EOControl/EOControl.h>
#include "common.h"

@interface SxEvoContactQueryInfo(Privates)
- (void)_loadFetchSpecification:(EOFetchSpecification *)_fs;
- (BOOL)_processQualifier:(EOQualifier *)_q;
@end

@implementation SxEvoContactQueryInfo

static EOQualifier *qIsPersOrContact = nil;

+ (void)initialize {
  if (qIsPersOrContact == nil) {
    qIsPersOrContact = [[EOQualifier qualifierWithQualifierFormat:
       @"davContentClass = 'urn:content-classes:person' OR "
       @"davContentClass = 'urn:content-classes:contact'"] 
       retain];
  }
}

- (id)initWithFetchSpecification:(EOFetchSpecification *)_fs {
  if (_fs == nil) {
    [self release];
    return nil;
  }
  if ((self = [super init])) {
    [self _loadFetchSpecification:_fs];
  }
  return self;
}

- (void)dealloc {
  [self->fullSearch  release];
  [self->emailPrefix release];
  [self->prefix      release];
  [super dealloc];
}

/* results */

- (BOOL)isFullSearchQuery {
  return self->fullSearch != nil ? YES : NO;
}
- (BOOL)isEmailPrefixQuery {
  return self->emailPrefix != nil ? YES : NO;
}
- (BOOL)isPrefixQuery {
  return self->prefix != nil ? YES : NO;
}
- (BOOL)isContactWithEmailQuery {
  return self->hasEmail;
}

- (NSString *)prefix {
  return self->prefix;
}
- (NSString *)fullSearch {
  return self->fullSearch;
}
- (NSString *)emailPrefix {
  return self->emailPrefix;
}

/* disassemble fetch-spec */

- (BOOL)doExplainQueries {
  return YES;
}

- (void)_processRemainingAndQualifiers:(NSMutableArray *)_qs {
  int i, count;
  
  if ((count = [_qs count]) == 0)
    return;

  for (i = 0; i < count; ) {
    EOQualifier *q;
    
    q = [_qs objectAtIndex:i];
    if ([self _processQualifier:q]) {
      [_qs removeObjectAtIndex:i];
      count--;
    }
    else
      /* skip */
      i++;
  }
  if (count == 0)
    return;
  
  // see NOTES
  [self logWithFormat:@"WARNING: remaining[%i]: %@ !", [_qs count], _qs];
}

- (void)_processEmail1Like:(NSString *)email1Like {
  if (email1Like == nil) 
    return;
  
  if ([email1Like isEqualToString:@"*"]) /* match all */
    email1Like = nil;
  else if ([email1Like hasSuffix:@"*"] && ![email1Like hasPrefix:@"*"])
    self->emailPrefix = 
      [[email1Like substringToIndex:([email1Like length] - 1)] copy];
  else
    [self logWithFormat:@"cannot process email1-like: '%@'", email1Like];
}

- (BOOL)_processNotQualifier:(EONotQualifier *)_q {
  id q;
  
  if ((q = [_q qualifier]) == nil)
    return YES;

  // check: "NOT (email1 = '')"
  if (![q isKindOfClass:[EOKeyValueQualifier class]])
    return NO;
  
  if (![[q key] isEqualToString:@"email1"])
    return NO;
  
  /* email-not-something qualifier */
  if ([[q value] isEqual:@""]) { // TODO: check operator ...
    self->hasEmail = YES;
    return YES;
  }
  else {
    [self logWithFormat:@"not implemented: query emails which do not have: %@",
            [q value]];
  }
  return NO;
}

- (BOOL)_processOrQualifier:(EOOrQualifier *)_q {
  NSDictionary *sa;
  NSArray *qs;
  NSArray *rest;
  BOOL    result = NO;
  
  qs = [_q qualifiers];
  if ([qs count] == 0)
    /* empty OR ... */
    return YES;
  
  sa = [qs generalizeKeyValueLikeQualifiers:&rest];
      
  if ([sa count] == 0) {
    /* generalized nothing ... */
  }
  else if ([sa count] == 1) {
    NSString *value;
	
    value = [[sa allKeys] lastObject];
	
    // check for common prefixes
    if ([value isEqualToString:@"*"]) {
      /* fetch everything, nothing restricted */
    }
    else if ([value hasSuffix:@"*"] && ![value hasPrefix:@"*"]) {
      NSMutableArray *keys;

      keys  = [[sa objectForKey:value] mutableCopy];
      if ([keys count] > 0) {
        [keys removeObject:@"sn"];
        [keys removeObject:@"cn"];
        [keys removeObject:@"fileas"];
	    
        if ([keys count] == 0)
          self->prefix = [[value substringToIndex:([value length] - 1)] copy];
        else
          [self logWithFormat:@"WARNING: could not process keys: %@", keys];
      }
      [keys release];
    }
    else if ([value hasSuffix:@"*"] && [value hasPrefix:@"*"]) {
      if ([(NSArray *)[sa objectForKey:value] count] > 20) {
        NSString *s;
        
        s = [value substringFromIndex:1];
        self->fullSearch = [[s substringToIndex:([s length] - 1)] copy];
        if ([self doExplainQueries])
          [self logWithFormat:
                  @"EXPLAIN:   more than 20 keys => full search: '%@'", 
                  self->fullSearch];
      }
    }
    
    result = YES;
  }
  else {
    [self logWithFormat:@"generalized: %@", sa];
  }
  
  if (([rest count] > 0 && [sa count] != 0) || ([sa count] > 1))
    [self logWithFormat:@"WARNING: could not generalize qualifier %@", _q];
  
  return result;
}

- (BOOL)_processAndQualifier:(EOAndQualifier *)_q {
  /* disassemble qualifier */
  NSMutableArray *qs;
  BOOL     isPersonOrContact;
  unsigned i;
  NSString *fileAsLike, *email1Like, *cnLike, *snLike;
  
  qs = [[[_q qualifiers] mutableCopy] autorelease];
  if ([qs count] == 0)
    return YES;
  
  isPersonOrContact = [qs removeQualifier:qIsPersOrContact];
  
  fileAsLike = [qs removeKeyValueQualifierForKey:@"fileas"
                   operation:EOQualifierOperatorLike];
  email1Like = [qs removeKeyValueQualifierForKey:@"email1"
                   operation:EOQualifierOperatorLike];
  cnLike     = [qs removeKeyValueQualifierForKey:@"cn"
                   operation:EOQualifierOperatorLike];
  snLike     = [qs removeKeyValueQualifierForKey:@"sn"
                   operation:EOQualifierOperatorLike];
  
  if (fileAsLike) {
    if ([fileAsLike isEqualToString:@"*"]) /* match all */
      fileAsLike = nil;
    else if ([fileAsLike hasSuffix:@"*"] && ![fileAsLike hasPrefix:@"*"]) {
      self->prefix = 
        [[fileAsLike substringToIndex:([fileAsLike length] - 1)] copy];
    }
  }
  else if (cnLike != nil && [cnLike isEqualToString:snLike]) {
    if ([cnLike isEqualToString:@"*"]) /* match all */ {
      cnLike = nil;
      snLike = nil;
    }
    else if ([cnLike hasSuffix:@"*"] && ![cnLike hasPrefix:@"*"])
      self->prefix = [[cnLike substringToIndex:([cnLike length] - 1)] copy];
  }
  
  if ((i = [qs indexOfQualifierOfClass:[EOOrQualifier class]]) != NSNotFound) {
    if ([self _processOrQualifier:[qs objectAtIndex:i]])
      [qs removeObjectAtIndex:i];
  }
  
  [self _processEmail1Like:email1Like];
  [self _processRemainingAndQualifiers:qs];
  return YES;
}

- (BOOL)_processKeyValueQualifier:(EOKeyValueQualifier *)_q {
  NSString *key;
  
  key = [_q key];
  if ([key isEqualToString:@"davIsCollection"]) {
    if ([[_q value] boolValue]) {
      [self logWithFormat:
              @"WARNING: cannot process query (dav-collection request): %@",
              _q];
      return NO;
    }
    /* just an ensurance request for not getting folders: davIsCollection=0 */
    return YES;
  }
  
  return NO;
}

- (BOOL)_processUnknownQualifier:(EOQualifier *)_q {
  [self logWithFormat:@"WARNING: cannot classify Evo qualifier(%@): %@ !", 
          NSStringFromClass([_q class]), _q];
  return NO;
}

- (BOOL)_processQualifier:(EOQualifier *)_q {
  BOOL ok;
  
  if ([_q isEqual:qIsPersOrContact] || (_q == nil))
    /* nothing to do :-) */
    ok = YES;
  else if ([_q isKindOfClass:[EOAndQualifier class]])
    ok = [self _processAndQualifier:(EOAndQualifier *)_q];
  else if ([_q isKindOfClass:[EOOrQualifier class]])
    ok = [self _processOrQualifier:(EOOrQualifier *)_q];
  else if ([_q isKindOfClass:[EONotQualifier class]])
    ok = [self _processNotQualifier:(EONotQualifier *)_q];
  else if ([_q isKindOfClass:[EOKeyValueQualifier class]])
    ok = [self _processKeyValueQualifier:(EOKeyValueQualifier *)_q]; 
  else
    ok = [self _processUnknownQualifier:_q];
  return ok;
}

- (void)_loadFetchSpecification:(EOFetchSpecification *)_fs {
  [self _processQualifier:[_fs qualifier]];
}

@end /* SxEvoContactQueryInfo */
