/*
  Copyright (C) 2008 Whitemice Consulting (Adam Tauno Williams)

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


#include <LSFoundation/LSGetAsRSSFeedCommand.h>

@class NSCalendarDate, NSTimeZone;
@class NSMutableString;
@class LSCommandContext;

@interface LSGetDelegatedActionsAsRSSCommand : LSGetAsRSSFeedCommand
{
  NSString  *accountId;
}

@end

#include "common.h"

@implementation LSGetDelegatedActionsAsRSSCommand

+ (void)initialize {
}

- (id)initForOperation:(NSString *)_operation inDomain:(NSString *)_domain {
  if ((self = [super initForOperation:_operation inDomain:_domain])) {
  }
  return self;
}

- (void)dealloc {
  [self->accountId release];
  [super dealloc];
}

- (void)setAccountId:(NSString *)_accountId {
  ASSIGNCOPY(self->accountId, _accountId);
}
- (NSString *)accountId {
  return self->accountId;
}

/* Data expression */

- (void)buildQueryExpression {
  [[self query] appendString:@"SELECT jh.job_history_id, "
                      @"       j.job_id, "
                      @"       j.name AS jobname, "
                      @"       p.name AS projectname, "
                      @"       jh.action_date AS actionDate, "
                      @"       jh.action AS action, "
                      @"       s.login AS login, "
                      @"       jhi.comment AS comment, "
                      @"        cv.value_string AS email1 "
                      @"FROM "];
  [self addTable:@"Job" as:@"j"];
  [self addInnerJoin:@"JobHistory" as:@"jh" on:@"jh.job_id = j.job_id"];
  [self addInnerJoin:@"JobHistoryInfo" as:@"jhi" on:@"jhi.job_history_id = jh.Job_history_id"];
  [self addOuterJoin:@"Project" as:@"p" on:@"p.project_id = j.project_id"];
  [self addOuterJoin:@"Person" as:@"s" on:@"s.company_id = jh.actor_id"];
  [self addOuterJoin:@"CompanyValue" as:@"cv" 
                  on:@"cv.company_id = s.company_id AND cv.attribute = 'email1'"];
  [[self query] appendFormat:@" WHERE j.creator_id = %@", [self accountId]];
  [[self query] appendString:@" ORDER BY jh.action_date DESC"];
  [[self query] appendFormat:@" LIMIT %@", [self limit]];
}

/* RSS data methods, override in descendents */

- (NSString *)rssChannelTitle {
  return @"Actions on delegated tasks";
}

- (NSString *)rssChannelDescription {
  return @"Actions on delegated tasks";
}

/* TODO: needs to generate a meaningful link attribute */
- (void)appendRSSItem:(NSDictionary *)_record {
  NSMutableString *title, *description, *author;
  NSString        *tmp, *guid;

  /* Create a title */
  title = [NSMutableString stringWithCapacity:128];
  tmp = [_record valueForKey:@"jobname"];
  [title appendString:[tmp stringByEscapingHTMLString]];
  tmp = [_record valueForKey:@"action"];
  tmp = [tmp substringWithRange:NSMakeRange(3,[tmp length]-3)];
  [title appendFormat:@" (%@ by %@)", tmp, [_record valueForKey:@"login"]];

  /* Create a description */
  description = [NSMutableString stringWithCapacity:512];
  tmp = [_record valueForKey:@"comment"];
  [description appendString:[tmp stringByEscapingHTMLString]];
  [description appendString:@"\n-----\n"];
  tmp = [_record valueForKey:@"projectname"];
  if ([tmp isNotNull]) {
    [description appendFormat:@"<STRONG>Project:</STRONG> %@\n", tmp];
  }

  /* Create an Author */
  author = [NSMutableString stringWithCapacity:128];
  [author appendString:[_record valueForKey:@"email1"]];
  [author appendFormat:@" (%@)", [_record valueForKey:@"login"]];

  /* Create a GUID */
  tmp = [_record valueForKey:@"jobHistoryId"];
  guid = [NSString stringWithFormat:@"OGo-TaskAction-%@-delegated", tmp];
 
  [self appendRSSItem:description
            withTitle:title
              andDate:[_record valueForKey:@"actiondate"]
            andAuthor:author
              andLink:nil
              andGUID:guid
             forObject:[_record valueForKey:@"jobId"]];
} // end appendRSSItem

/* key-value coding */

- (void)takeValue:(id)_value forKey:(NSString *)_key {
  if ([_key isEqualTo:@"accountId"]) {
    [self setAccountId:_value];
  } else {
      [super takeValue:_value forKey:_key];
    }
}

- (id)valueForKey:(NSString *)_key {
  if ([_key isEqualTo:@"accountId"])
    return [self accountId];
  return [super valueForKey:_key];
}


@end /* LSGetDelegatedActionsAsRSSCommand */
