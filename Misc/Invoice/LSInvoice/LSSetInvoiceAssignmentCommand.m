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

#import "common.h"
#import "LSSetInvoiceAssignmentCommand.h"

@interface LSSetInvoiceAssignmentCommand(PrivatMethods)
- (void)setArticles:(NSArray*)_articles;
- (NSArray*)articles;

@end

@implementation LSSetInvoiceAssignmentCommand

#if !LIB_FOUNDATION_BOEHM_GC
- (void)dealloc {
  RELEASE(self->articlesList);
  [super dealloc];
}
#endif

- (BOOL)_article:(id)_article isInList:(NSArray *)_list {
  NSEnumerator *listEnum = [_list objectEnumerator];
  id           item      = nil;
  id           artKey;

  artKey = [_article valueForKey:@"invoiceArticleAssignmentId"];

  while ((item = [listEnum nextObject])) {
    if ([artKey isEqual:
                [item valueForKey:@"invoiceArticleAssignmentId"]]) {
      return YES;
    }
  }
  return NO;
}

- (void)_removeOldAssignmentsInContext:(id)_context {
  NSArray       *oldAssignments = nil;
  NSEnumerator  *listEnum       = nil;
  id            assignment      = nil;

  oldAssignments = [[self object]
                          valueForKey:@"toInvoiceArticleAssignment"];
  listEnum = [oldAssignments objectEnumerator];
  
  while ((assignment = [listEnum nextObject])) {
    if (![self _article:assignment isInList:self->articlesList]) {
      LSDBObjectDeleteCommand *dCmd = nil;

      dCmd = LSLookupCommandV(@"invoicearticleAssignment", @"delete",
                              @"object", assignment, nil);
      [dCmd setReallyDelete:YES];
      [dCmd runInContext:_context];
    }
  }
}

- (void)_saveAssignmentsInContext:(id)_context {
  NSArray      *oldAssignments = nil;
  NSEnumerator *listEnum       = nil;
  id             newArticle      = nil;

  oldAssignments = [[self object]
                          valueForKey:@"toInvoiceArticleAssignment"];
  listEnum       = [self->articlesList objectEnumerator];
  
  while ((newArticle = [listEnum nextObject])) {
    if (![self _article:newArticle isInList:oldAssignments]) {
      id aCount;
      id vat;
      id netAmount;

      //aCount=[NSNumber numberWithDouble:
      // [[newArticle valueForKey:@"articleCount"] doubleValue]];
      //vat   =[NSNumber numberWithDouble:
      //                 [[newArticle valueForKey:@"vat"] doubleValue]];
      aCount= MONEY2SAVEFORNUMBER([newArticle valueForKey:@"articleCount"]);
      vat   = MONEY2SAVEFORNUMBER([newArticle valueForKey:@"vat"]);
      netAmount = MONEY2SAVEFORNUMBER([newArticle valueForKey:@"netAmount"]);

      LSRunCommandV(_context,
                    @"InvoiceArticleAssignment", @"new",
                    @"invoiceId",    [[self object] valueForKey:@"invoiceId"],
                    @"articleId",    [newArticle valueForKey:@"articleId"],
                    @"articleCount", aCount,
                    @"netAmount",    netAmount,
                    @"vat",          vat,
                    @"comment",      [newArticle valueForKey:@"comment"],
                    nil);
    }
  }
}

- (void)_prepareForExecutionInContext:(id)_context{
  id account = [_context valueForKey:LSAccountKey];
  NSEnumerator *teamEnum =
    [LSRunCommandV(_context, @"account", @"teams",
                  @"account", account,
                  @"returnType", intObj(LSDBReturnType_ManyObjects),
                  nil) objectEnumerator];
  id team;
  BOOL access = NO;
  while ((team = [teamEnum nextObject])) {
    if ([[team valueForKey:@"login"] isEqualToString:@"invoices"]) {
      access = YES;
    }
  }
  [self assert:access
        reason:@"You have no permission for doing that!"];
}


- (void)_executeInContext:(id)_context {
  LSRunCommandV(_context, @"invoice", @"get",
                @"invoiceId",
                [[self object] valueForKey:@"invoiceId"],
                nil);
  [self _removeOldAssignmentsInContext:_context];
  [self _saveAssignmentsInContext:_context];
  LSRunCommandV(_context, @"invoice", @"get",
                @"invoiceId",
                [[self object] valueForKey:@"invoiceId"],
                nil);
}

- (NSString*)entityName {
  return @"InvoiceArticleAssignment";
}

// accessors

- (void)setArticles:(NSArray*)_articles {
  ASSIGN(self->articlesList, _articles);
}
- (NSArray*)articles {
  return self->articlesList;
}


// key/value coding

- (void)takeValue:(id)_value forKey:(id)_key {
  if ([_key isEqualToString:@"articles"]) {
    [self setArticles:_value];
    return;
  }
  if (([_key isEqualToString:@"invoice"]) ||
      ([_key isEqualToString:@"object"])) {
    [self setObject:_value];
    return;
  }
  
  [super takeValue:_value forKey:_key];
}

- (id)valueForKey:(id)_key {
  if ([_key isEqualToString:@"articles"]) {
    return [self articles];
  }
  if (([_key isEqualToString:@"invoice"]) ||
      ([_key isEqualToString:@"object"])) {
    return [self object];
  }
  return [super valueForKey:_key];
}

@end
