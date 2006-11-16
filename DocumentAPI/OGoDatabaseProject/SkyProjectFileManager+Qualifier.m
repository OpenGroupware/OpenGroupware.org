/*
  Copyright (C) 2000-2006 SKYRIX Software AG
  Copyright (C) 2006      Helge Hess

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
 
#include "SkyProjectFileManager.h"
#include <NGExtensions/NSString+Ext.h>
#include "common.h"

@implementation SkyProjectFileManager(Qualifier)

static NSNumber *yesNum = nil, *noNum = nil;
static inline NSNumber *boolNum(BOOL value) {
  if (value) {
    if (yesNum == nil)
      yesNum = [[NSNumber numberWithBool:YES] retain];
    return yesNum;
  }
  else {
    if (noNum == nil)
      noNum = [[NSNumber numberWithBool:NO] retain];
    return noNum;
  }
}

+ (BOOL)supportQualifier:(EOQualifier *)_qual {
  // TODO: weird method naming, probably "-supportsQualifier:" or
  //       "-canHandleQualifier:"
  NSSet        *allKeys;
  NSEnumerator *enumerator;
  NSString     *key;

  if (!_qual)
    return YES;
  
  allKeys = [_qual allQualifierKeys];
  if ([allKeys count] > 3)
    return NO;

  enumerator = [allKeys objectEnumerator];

  while ((key = [enumerator nextObject])) {
    if (![key isEqualToString:@"NSFileSubject"] &&
        ![key isEqualToString:@"NSFileName"] &&
        ![key isEqualToString:@"NSFileType"])
      break;
  }
  if (key) { /* unknown keys */
    return NO;
  }
  if ([_qual isKindOfClass:[EOAndQualifier class]] ||
      [_qual isKindOfClass:[EOOrQualifier class]]) {
    EOQualifier *q;

    enumerator = [[(EOAndQualifier *)_qual qualifiers] objectEnumerator];
    while ((q = [enumerator nextObject])) {
      if (![q isKindOfClass:[EOKeyValueQualifier class]]) {
        return NO;
      }
    }
  }
  else if (![_qual isKindOfClass:[EOKeyValueQualifier class]]) {
    return NO;
  }
  return YES;
}

+ (EOQualifier *)convertQualifier:(EOQualifier *)_qualifier
  projectId:(NSNumber *)_pid
  evalInMemory:(BOOL *)evalQual_
{
  EOQualifier *qual, *pQual;

  if (evalQual_)
    *evalQual_ = NO;
  
  qual       = nil;
    
  if (_qualifier) {
    if (evalQual_)
      *evalQual_ = YES; /* evaluate _qualifier after */

    if ([SkyProjectFileManager supportQualifier:_qualifier]) {
      int kind;
        
      if (evalQual_)
        *evalQual_ = NO;
      
      kind     = -1;
        
      if ([_qualifier isKindOfClass:[EOOrQualifier class]])
        kind = 1;
      else if ([_qualifier isKindOfClass:[EOAndQualifier class]])
        kind = 2;
      else if ([_qualifier isKindOfClass:[EOKeyValueQualifier class]])
        kind = 3;
        
      if (kind == 1 || kind == 2) {
        NSEnumerator   *enumerator;
        NSMutableArray *newQuals;
        EOQualifier    *q;

        enumerator = [[(EOAndQualifier *)_qualifier qualifiers]
                                       objectEnumerator];
        newQuals   = [NSMutableArray array];
        while ((q = [enumerator nextObject])) {
          EOQualifier *tmp;

          if ((tmp = [SkyProjectFileManager replaceAttributes:q]))
            [newQuals addObject:tmp];
          else
            break;
        }
        if (q == nil) {
          if (kind == 1)
            qual = [[EOOrQualifier alloc] initWithQualifierArray:newQuals];
          else
            qual = [[EOAndQualifier alloc] initWithQualifierArray:newQuals];

          AUTORELEASE(qual);
          if (evalQual_)
            *evalQual_ = NO;
        }
      }
      else if (kind == 3) {
        qual       = [SkyProjectFileManager replaceAttributes:_qualifier];
        if (evalQual_)
          *evalQual_ = NO;
      }
    }
  }
  if (_pid) 
    pQual = [EOQualifier qualifierWithQualifierFormat:@"projectId = %@",
                         _pid];
  else
    pQual = nil;
  
  if (!qual) {
    if (_qualifier) {
#if DEBUG
      [self logWithFormat:@"Note: evaluating qualifier in RAM: %@",
	      _qualifier];
#endif
    }
    qual = pQual;
  }
  else {
    NSArray *array;

    array = [NSArray arrayWithObjects:qual, pQual, nil];
    qual  = [[EOAndQualifier alloc] initWithQualifierArray:array];
    AUTORELEASE(qual);
  }
  return qual;
}

/*
  converts EOKeyValueQualifier like: NSFileName = ' *.txt' to attribute qualifiers
*/

+ (EOQualifier *)replaceAttributes:(EOQualifier *)_qual {
  // TODO: split up this huge method!
  EOQualifier *qualifier;
  
  qualifier = nil;
  if ([_qual isKindOfClass:[EOKeyValueQualifier class]]) {
    NSString *key, *val;
    EOKeyValueQualifier *kvq;

    kvq = (id)_qual;

    key = [kvq key];
    val = [kvq value];

    if ([val isKindOfClass:[NSString class]])
      val = [val stringByReplacingString:@"*" withString:@"%"];
    
    if ([key isEqualToString:@"NSFileSubject"]) {
      SEL selector;

      selector = [kvq selector];

      if ([val rangeOfString:@"%"].length > 0) {
        if (SEL_EQ(selector, [EOQualifier operatorSelectorForString:@"="]))
          selector = [EOQualifier operatorSelectorForString:@"like"];
      }
      qualifier = [[EOKeyValueQualifier alloc]
                                        initWithKey:@"abstract"
                                        operatorSelector:selector
                                        value:val];
      [qualifier autorelease];
    }
    else if ([key isEqualToString:NSFileType]) {
      SEL  sel, eqalSel;
      BOOL isFolder;

      sel        = [kvq selector];
      eqalSel    = [EOQualifier operatorSelectorForString:@"="];
      isFolder   = NO;
      
      if ([val isEqualToString:NSFileTypeDirectory]) {
        if (SEL_EQ(sel, eqalSel)) {
          isFolder = YES;
        }
      }
      else if (!SEL_EQ(sel, eqalSel)) {
        isFolder = YES;
      }
      if (isFolder) {
        qualifier = [[EOKeyValueQualifier alloc]
                                          initWithKey:@"isFolder"
                                          operatorSelector:eqalSel
                                          value:boolNum(YES)];
      }
      else {
        qualifier = [[EOKeyValueQualifier alloc]
                                          initWithKey:@"isFolder"
                                          operatorSelector:eqalSel
                                          value:boolNum(NO)];
      }
      [qualifier autorelease];
    }
    else if ([key isEqualToString:NSFileName]) {
      EOKeyValueQualifier *k;
      NSString            *type, *title;
      int                 vLen;
      NSMutableArray      *marry;

      vLen = [val length];
      type = [[val componentsSeparatedByString:@"."] lastObject];
      
      if ([type length] == vLen) { /* no type was specified */
        type  = @"*";
        title = val;
      }
      else {
        title = [val substringToIndex:vLen - [type length] - 1];
      }
      marry = [[NSMutableArray alloc] init];
      k   = [[EOKeyValueQualifier alloc] initWithKey:@"title"
                                         operatorSelector:[kvq selector]
                                         value:title];
      [marry addObject:k];
      RELEASE(k);

      k = [[EOKeyValueQualifier alloc] initWithKey:@"fileType"
                                       operatorSelector:[kvq selector]
                                       value:type];
      
      if ([type isEqualToString:@"*"]) {
        NSMutableArray *a;

        a = [NSMutableArray array];
        [a addObject:k];
        [k release];
        k = [[EOKeyValueQualifier alloc] initWithKey:@"fileType"
                                         operatorSelector:EOQualifierOperatorEqual
                                         value:[NSNull null]];
        [a addObject:k];
        [k release];
        k = [[EOOrQualifier alloc] initWithQualifierArray:a];
      }
      [marry addObject:k];
      [k release];
      qualifier = 
	[[[EOAndQualifier alloc] initWithQualifierArray:marry] autorelease];
      
      [marry release]; marry = nil;
    }
  }
  else {
    NSLog(@"ERROR[%s]: cannot evaluate qualifier [%@]"
          @", expected key-value qualifier", __PRETTY_FUNCTION__, _qual);
  }
  return qualifier;
}

@end /* SkyProjectFileManager(Qualifier) */
