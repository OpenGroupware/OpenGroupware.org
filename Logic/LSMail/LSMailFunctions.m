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

#import "LSMailFunctions.h"
#import "common.h"

NSString *_getExprCheckContent(id self, id _context, NSArray *_content,
                               NSNumber *_dummy) {
  NSMutableString *expr       = nil;
  EOEntity        *mEntity    = nil;
  NSEnumerator    *enumerator = nil;
  id              content     = nil;
  BOOL            isFirst     = YES;

  NSString *emailName     = nil;
  NSString *contentId     = nil;

  mEntity   = [[[[_context valueForKey:LSDatabaseKey] adaptor] model]
                           entityNamed:@"Email"];
  emailName = [mEntity externalName];
  contentId = [[mEntity attributeNamed:@"emailContentId"] columnName];  
  expr      = [NSMutableString stringWithCapacity:1024];
 
  [expr appendString:[NSString stringWithFormat:@"select %@ from %@ "
                                                @"where %@ in (",
                               contentId, emailName, contentId]];
  enumerator = [_content objectEnumerator];

  while ((content = [enumerator nextObject])) {
    if (isFirst == YES)
      isFirst = NO;
    else
      [expr appendString:@", "];
    [expr appendString:[content stringValue]];
  }
  [expr appendString:@")"];
  return expr;
}

NSString *_getExprMoveEmails(id self, id _context, NSArray *_emailIds,
                             NSNumber *_folder) {
  NSMutableString *expr       = nil;
  EOEntity        *mEntity    = nil;
  NSEnumerator    *enumerator = nil;
  id              email       = nil;
  BOOL            isFirst     = YES;

  NSString *emailName     = nil;
  NSString *emailId       = nil;
  NSString *emailFolderId = nil;
  NSString *isNew         = nil;  

  mEntity        = [[[[_context valueForKey:LSDatabaseKey] adaptor] model]
                                entityNamed:@"Email"];
  emailName     = [mEntity externalName];
  emailId       = [[mEntity attributeNamed:@"emailId"] columnName];
  emailFolderId = [[mEntity attributeNamed:@"emailFolderId"] columnName];
  isNew         = [[mEntity attributeNamed:@"isNew"] columnName];  
  expr          = [NSMutableString stringWithCapacity:1024];

  [expr appendString:[NSString stringWithFormat:@"update %@ set %@ = %@, %@ = 0"
                               @" where %@ in (",
                               emailName, emailFolderId, _folder, isNew,
                               emailId]];
  enumerator = [_emailIds objectEnumerator];

  while ((email = [enumerator nextObject])) {
    if (isFirst == YES)
      isFirst = NO;
    else
      [expr appendString:@", "];
    [expr appendString:[email stringValue]];
  }
  [expr appendString:@")"];
  return expr;
}

NSString *_getExprDeleteEmails(id self, id _context, NSArray *_emailIds,
                               NSNumber *_dummy) {
  NSMutableString *expr       = nil;
  EOEntity        *mEntity    = nil;
  NSEnumerator    *enumerator = nil;
  id              email       = nil;
  BOOL            isFirst     = YES;

  NSString *emailName     = nil;
  NSString *emailId       = nil;

  mEntity        = [[[[_context valueForKey:LSDatabaseKey] adaptor] model]
                                entityNamed:@"Email"];
  emailName     = [mEntity externalName];
  emailId       = [[mEntity attributeNamed:@"emailId"] columnName];
  expr          = [NSMutableString stringWithCapacity:1024];

  [expr appendString:[NSString stringWithFormat:@"delete from %@ where %@ in (",
                               emailName, emailId]];
  enumerator = [_emailIds objectEnumerator];

  while ((email = [enumerator nextObject])) {
    if (isFirst == YES)
      isFirst = NO;
    else
      [expr appendString:@", "];
    [expr appendString:[email stringValue]];
  }
  [expr appendString:@")"];
  return expr;
}

NSString *_getExprDeleteContent(id self, id _context, NSArray *_content,
                                NSNumber *_dummy) {
  NSMutableString *expr       = nil;
  EOEntity        *mEntity    = nil;
  NSEnumerator    *enumerator = nil;
  id              content     = nil;
  BOOL            isFirst     = YES;

  NSString *contentName = nil;
  NSString *contentId   = nil;

  mEntity        = [[[[_context valueForKey:LSDatabaseKey] adaptor] model]
                                entityNamed:@"EmailContent"];
  contentName = [mEntity externalName];
  contentId   = [[mEntity attributeNamed:@"emailContentId"] columnName];
  expr          = [NSMutableString stringWithCapacity:1024];

  [expr appendString:[NSString stringWithFormat:@"delete from %@ where %@ in (",
                               contentName, contentId]];
  enumerator = [_content objectEnumerator];

  while ((content = [enumerator nextObject])) {
    if (isFirst == YES)
      isFirst = NO;
    else
      [expr appendString:@", "];
    [expr appendString:[content stringValue]];
  }
  [expr appendString:@")"];
  return expr;
}

NSString *_getExprDeleteFolder(id self, id _context, NSArray *_folder,
                               NSNumber *_dummy) {
  NSMutableString *expr       = nil;
  EOEntity        *mEntity    = nil;
  NSEnumerator    *enumerator = nil;
  id              folder      = nil;
  BOOL            isFirst     = YES;

  NSString *folderName = nil;
  NSString *folderId   = nil;

  mEntity        = [[[[_context valueForKey:LSDatabaseKey] adaptor] model]
                                entityNamed:@"EmailFolder"];
  folderName = [mEntity externalName];
  folderId  = [[mEntity attributeNamed:@"emailFolderId"] columnName];
  expr          = [NSMutableString stringWithCapacity:1024];

  [expr appendString:[NSString stringWithFormat:@"delete from %@ where %@ in (",
                               folderName, folderId]];
  enumerator = [_folder objectEnumerator];

  while ((folder = [enumerator nextObject])) {
    if (isFirst == YES)
      isFirst = NO;
    else
      [expr appendString:@", "];
    [expr appendString:[folder stringValue]];
  }
  [expr appendString:@")"];
  return expr;
}

NSString *_getExprEmailForFolders(id self, id _context,
                                  NSArray *_folderIds, NSNumber *_dummy) {
  NSMutableString *expr       = nil;
  EOEntity        *mEntity    = nil;
  NSEnumerator    *enumerator = nil;
  id              folder      = nil;
  BOOL            isFirst     = YES;

  NSString *emailName     = nil;
  NSString *emailId       = nil;
  NSString *emailFolderId = nil;
  NSString *contentId     = nil;
  

  mEntity        = [[[[_context valueForKey:LSDatabaseKey] adaptor] model]
                                entityNamed:@"Email"];
  emailName     = [mEntity externalName];
  emailFolderId = [[mEntity attributeNamed:@"emailFolderId"] columnName];
  emailId       = [[mEntity attributeNamed:@"emailId"] columnName];
  contentId     = [[mEntity attributeNamed:@"emailContentId"] columnName];  
  expr          = [NSMutableString stringWithCapacity:1024];

  [expr appendString:[NSString stringWithFormat:@"select %@,%@ from %@ "
                                                @"where %@ in (",
                               emailId, contentId, emailName, emailFolderId]];
  enumerator = [_folderIds objectEnumerator];

  
  while ((folder = [enumerator nextObject])) {
    if (isFirst == YES)
      isFirst = NO;
    else
      [expr appendString:@", "];
    [expr appendString:[folder stringValue]];
  }
  [expr appendString:@")"];
  return expr;
}


NSString *_getExprFolderForParentFolders(id self, id _context,
                                         NSArray *_parentIds, NSNumber *_dummy) {
  NSMutableString *expr       = nil;
  EOEntity        *fEntity    = nil;
  NSEnumerator    *enumerator = nil;
  id              folder      = nil;
  BOOL            isFirst     = YES;

  NSString *folderName     = nil;
  NSString *folderId       = nil;
  NSString *parentFolderId = nil;
  
  fEntity        = [[[[_context valueForKey:LSDatabaseKey] adaptor] model]
                                entityNamed:@"EmailFolder"];
  folderName     = [fEntity externalName];
  parentFolderId = [[fEntity attributeNamed:@"parentFolderId"] columnName];
  folderId       = [[fEntity attributeNamed:@"emailFolderId"] columnName];
  expr           = [NSMutableString stringWithCapacity:1024];

  [expr appendString:[NSString stringWithFormat:@"select %@ from %@ where %@ "
                                                @"in (",
                               folderId, folderName, parentFolderId]];
  enumerator = [_parentIds objectEnumerator];
  
  while ((folder = [enumerator nextObject])) {
    if (isFirst == YES)
      isFirst = NO;
    else
      [expr appendString:@", "];
    [expr appendString:[folder stringValue]];
  }
  [expr appendString:@")"];
  return expr;
}

NSArray *_executeIdQueryWith(id self, id _context, __LSMail_getIdExpr _idExpr,
                             NSArray *_ids, NSNumber *_folder) {
  unsigned         cnt        = [_ids count];
  unsigned         pos        = 0;
  EOAdaptorChannel *adChannel = nil;
  NSMutableArray   *result    = nil;  

  adChannel = [[_context valueForKey:LSDatabaseChannelKey] adaptorChannel];
  result    = [NSMutableArray arrayWithCapacity:256];
  
  while (pos < cnt) {
    unsigned       elements = 0;
    NSArray        *ids     = nil;
    NSString       *query   = nil;

    elements = cnt - pos;
    if (elements > 100) elements = 100;
    
    ids  = [_ids subarrayWithRange:NSMakeRange(pos, elements)];
    pos += elements;
    query = _idExpr(self, _context, ids, _folder);
    if ([adChannel evaluateExpression:query]) {
      NSDictionary *r = nil;

      if ([adChannel isFetchInProgress]) {
        while ((r = [adChannel fetchAttributes:[adChannel describeResults]
                               withZone:[self zone]])) {
          [result addObject:r];
        }
        [adChannel cancelFetch];
      }
    }
    else {
      NSLog(@"WARNING: evaluateExpression failed");
    }
  }
  return result;
}

NSArray *_getAllSubFolders(id self, id _context, NSNumber *_trashId) {
  NSMutableArray *newQueryIds = nil;
  NSMutableArray *result      = nil;
  NSArray        *queryRes    = nil;
  NSEnumerator   *enumerator  = nil;
  id             obj          = nil;

  [self assert:(_trashId != nil) reason:@"expect a Trash-Folder-Id"];
  
  result      = [NSMutableArray arrayWithCapacity:128];
  newQueryIds = [[NSMutableArray alloc] initWithCapacity:128];
  [newQueryIds addObject:_trashId];

  while ([newQueryIds count] > 0) {
    queryRes =
      _executeIdQueryWith(self, _context,
                          (__LSMail_getIdExpr)_getExprFolderForParentFolders,
                          newQueryIds, nil);
    queryRes = [queryRes map:@selector(objectForKey:) with:@"emailFolderId"];
                                         
    [newQueryIds removeAllObjects];

    enumerator = [queryRes objectEnumerator];
    while ((obj = [enumerator nextObject])) {
      if ([result containsObject:obj] == NO) {
        [result addObject:obj];
        [newQueryIds addObject:obj];
      }
    }
  }
  RELEASE(newQueryIds); newQueryIds = nil;
  return result;
}

