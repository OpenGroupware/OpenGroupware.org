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

#include <NGObjWeb/WODynamicElement.h>

/*
  LSWSchedulerDateCell

  This dynamic element renders most appointment info "snippets" in OGo
  views.
*/

@class WOAssociation;

@interface LSWSchedulerDateCell : WODynamicElement
{
@protected
  WOAssociation *appointment;  // appointment record (EO)
  WOAssociation *weekday;      // NSCalendarDate of current weekday
  WOAssociation *linkColor;    // color of appointment link (start-time)
  WOAssociation *color;        // color of appointment content
  WOAssociation *participants; // array of participants (company EO's)
  WOAssociation *ownerColor;   // color of 'owner' name
  WOAssociation *titleColor;   // color of appointment title
  WOAssociation *locationColor;// color of appointment location
  WOAssociation *isClickable;
  WOAssociation *isPrivate;
  WOAssociation *isForSeveralDays;
  WOAssociation *privateLabel;  // private appointment title
  WOAssociation *action;
}

@end

#include "common.h"
#include <EOControl/EOControl.h>
#include <NGObjWeb/WOAssociation.h>
#include <NGExtensions/NSString+misc.h>
#include <time.h>

extern unsigned getpid();

@implementation LSWSchedulerDateCell

static NSArray *isAccountThenLoginOrderings = nil;

+ (int)version {
  return [super version] + 0;
}

+ (void)initialize {
  if (isAccountThenLoginOrderings == nil) {
    EOSortOrdering *lso, *aso;
    
    aso = [EOSortOrdering sortOrderingWithKey:@"isAccount"
			  selector:EOCompareAscending];
    lso = [EOSortOrdering sortOrderingWithKey:@"login"
			  selector:EOCompareAscending];
    isAccountThenLoginOrderings = [[NSArray alloc] initWithObjects:
						     aso, lso, nil];
  }
}

- (void)_setupDefaultBindings {
  if (self->linkColor == nil) {
    self->linkColor =
      [WOAssociation associationWithKeyPath:@"config.colors_appointmentLink"];
    RETAIN(self->linkColor);
  }
  if (self->ownerColor == nil) {
    self->ownerColor =
      [WOAssociation associationWithKeyPath:@"config.colors_ownerColor"];
    RETAIN(self->ownerColor);
  }
  if (self->titleColor == nil) {
    self->titleColor =
      [WOAssociation associationWithKeyPath:@"config.colors_titleColor"];
    RETAIN(self->titleColor);
  }
  if (self->locationColor == nil) {
    self->locationColor =
      [WOAssociation associationWithKeyPath:@"config.colors_locationColor"];
    RETAIN(self->locationColor);
  }
  if (self->color == nil) {
    self->color =
      [WOAssociation associationWithKeyPath:@"config.colors_contentText"];
    RETAIN(self->color);
  }
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->appointment      = OWGetProperty(_config, @"appointment");
    self->weekday          = OWGetProperty(_config, @"weekday");
    self->linkColor        = OWGetProperty(_config, @"linkColor");
    self->color            = OWGetProperty(_config, @"color");
    self->participants     = OWGetProperty(_config, @"participants");
    self->ownerColor       = OWGetProperty(_config, @"ownerColor");
    self->titleColor       = OWGetProperty(_config, @"titleColor");
    self->locationColor    = OWGetProperty(_config, @"locationColor");
    self->isClickable      = OWGetProperty(_config, @"isClickable");
    self->isPrivate        = OWGetProperty(_config, @"isPrivate");
    self->isForSeveralDays = OWGetProperty(_config, @"isForSeveralDays");
    self->privateLabel     = OWGetProperty(_config, @"privateLabel");
    self->action           = OWGetProperty(_config, @"action");
    
    [self _setupDefaultBindings];
  }
  return self;
}

- (void)dealloc {
  [self->action           release];
  [self->isClickable      release];
  [self->isPrivate        release];
  [self->ownerColor       release];
  [self->titleColor       release];
  [self->locationColor    release];
  [self->participants     release];
  [self->color            release];
  [self->linkColor        release];
  [self->appointment      release];
  [self->weekday          release];
  [self->privateLabel     release];
  [self->isForSeveralDays release];
  [super dealloc];
}

/* processing requests */

- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx {
  if (self->action)
    return [self->action valueInComponent:[_ctx component]];

  [self logWithFormat:@"WARNING(%@): no action is set!", [_ctx elementID]];
  return nil;
}

/* generating response */

- (void)_appendParticipant:(id)_person login:(id)_loginPKey 
  owner:(id)_ownerPKey
  toResponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  NSNumber *pkey;
  NSString *label1        = nil;
  NSString *label2        = nil;
  BOOL     isLoginAccount = NO;
  BOOL     isAccount      = NO;
  BOOL     isOwner        = NO;
  NSString *oc;

  pkey = [_person valueForKey:@"companyId"];
  oc   = [self->ownerColor stringValueInComponent:[_ctx component]];
  
  if ([[_person valueForKey:@"isAccount"] boolValue]) {
    label1         = [_person valueForKey:@"login"];
    isLoginAccount = [_loginPKey isEqual:pkey];
    isOwner        = [_ownerPKey isEqual:pkey];
    isAccount      = YES;
  }
  else if ([[_person valueForKey:@"isTeam"] boolValue]) {
    label1 = [_person valueForKey:@"description"];
    isAccount = YES;
  }
  else {
    label1 = [_person valueForKey:@"name"];
          
    if (label1 == nil)
      label1 = [_person valueForKey:@"description"];
  }
  if (![label1 isNotNull]) label1 = nil;
  if (![label2 isNotNull]) label2 = nil;
  
  if ((label1 == nil) && (label2 != nil)) {
    label1 = label2;
    label2 = nil;
  }
  
  if (label1 == nil)
    label1 = @"*";
  
  // TODO: replace tags with CSS
  
  if (isLoginAccount)  [_response appendContentString:@"<b>"];
  else if (!isAccount) [_response appendContentString:@"<i>"];

  if (isOwner && (oc != nil)) {
    [_response appendContentString:@"<font color=\""];
    [_response appendContentHTMLAttributeValue:oc];
    [_response appendContentString:@"\">"];
  }
  
  [_response appendContentHTMLString:label1];
  if (label2) {
    [_response appendContentHTMLString:@", "];
    [_response appendContentHTMLString:label2];
  }
        
  if (isOwner && (oc != nil))
    [_response appendContentString:@"</font>"];

  if (isLoginAccount)  [_response appendContentString:@"</b>"];
  else if (!isAccount) [_response appendContentString:@"</i>"];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  // TODO: split up this huge method
  // TODO: improve labels
  // TODO: replace font tag with CSS
  WOComponent    *co = [_ctx component];
  id             a;
  NSString       *c;
  NSString       *lc;
  NSCalendarDate *wD;
  id             owner;
  NSString       *oc, *tc, *loc;
  BOOL           link, priv, sevD, noAcc;
  
  a    = [self->appointment      valueInComponent:co];
  wD   = [self->weekday          valueInComponent:co];
  c    = [self->color            stringValueInComponent:co];
  lc   = [self->linkColor        stringValueInComponent:co];
  oc   = [self->ownerColor       stringValueInComponent:co];
  tc   = [self->titleColor       stringValueInComponent:co];
  loc  = [self->locationColor    stringValueInComponent:co];
  link = [self->isClickable      boolValueInComponent:co];
  priv = [self->isPrivate        boolValueInComponent:co];
  sevD = [self->isForSeveralDays boolValueInComponent:co];
  
  noAcc = ([a valueForKey:@"accessTeamId"] == nil) ? YES : NO;
  owner = [a valueForKey:@"ownerId"];
    
  if (lc == nil) lc = c;

  if ((self->action != nil) && link) {
    [_response appendContentString:@"<a href=\""];
#if 0
    [_response appendContentString:[_ctx url]];
#else
    /* direct action */
    {
      NSString *url;
      int      oid;
      NSString *tz;
      unsigned serial;
      
      oid = [[a valueForKey:@"dateId"] intValue];
      tz  = [[[a valueForKey:@"startDate"] timeZone] abbreviation];
      serial = getpid() + time(NULL);
      
      tz = [tz stringByEscapingURL];
      
      url = [NSString stringWithFormat:
                        @"oid=%i&tz=%@&o=%d&%@=%@",
                        oid, tz, serial,
                        WORequestValueSessionID,
                        [[_ctx session] sessionID]];
      
      url = [_ctx urlWithRequestHandlerKey:@"wa"
                  path:@"/viewApt"
                  queryString:url];
      [_response appendContentString:url];
    }
#endif
    [_response appendContentString:@"\">"];
  }
  { // link content
    if (lc) {
      // TODO: use stylesheets!
      [_response appendContentString:@"<font color=\""];
      [_response appendContentString:lc];
      [_response appendContentString:@"\">"];
    }
    
    {
      NSString       *fm = @"%H:%M";
      NSCalendarDate *sD = [a valueForKey:@"startDate"];

      if (!sevD &&
          (([sD dayOfYear]       <  [wD dayOfYear]) &&
           ([sD yearOfCommonEra] <= [wD yearOfCommonEra]))) {
        fm = @"%H:%M(%m-%d)";
#if 0
        NSLog(@"sd doy  %i vs %i", [sD dayOfYear], [wD dayOfYear]);
        NSLog(@"  title:   %@", [a valueForKey:@"title"]);
        NSLog(@"  start:   %@", sD);
        NSLog(@"  weekday: %@", wD);
#endif
      }
      else if (sevD) {
        fm = @"%Y-%m-%d %H:%M";
      }
      
      // TODO: descriptionWithCalendarFormat is slow!
      [_response appendContentHTMLString:
		   [sD descriptionWithCalendarFormat:fm]];
    }

    if (lc) [_response appendContentString:@"</font>"];
  }
  if ((self->action != nil) && link)
    [_response appendContentString:@"</a>"];

  if (c) {
    // TODO: use stylesheets
    [_response appendContentString:@"<font color=\""];
    [_response appendContentString:c];
    [_response appendContentString:@"\">"];
  }

  [_response appendContentHTMLString:@" - "];
  {
    NSString       *fm = @"%H:%M";
    NSCalendarDate *eD = [a valueForKey:@"endDate"];

    if (!sevD &&
        ([wD dayOfYear] < [eD dayOfYear] &&
         ([eD yearOfCommonEra] >= [wD yearOfCommonEra]))) {
      fm = @"%H:%M(%m-%d)";
#if 0
      NSLog(@"ed doy  %i vs %i", [eD dayOfYear], [wD dayOfYear]);
      NSLog(@"  title:   %@", [a valueForKey:@"title"]);
      NSLog(@"  end:     %@", eD);
      NSLog(@"  weekday: %@", wD);
#endif
    }      
    else if (sevD) {
      fm = @"%Y-%m-%d %H:%M";
    }

    // TODO: descriptionWithCalendarFormat is slow!
    [_response appendContentHTMLString:[eD descriptionWithCalendarFormat:fm]];
  }

  [_response appendContentString:@"<br />"];

  // participants
  {
    id      loginPKey = nil;
    NSArray *p        = nil;
    int     i, count;

    loginPKey = [[[_ctx session] activeAccount] valueForKey:@"companyId"];
    p         = [self->participants valueInComponent:[_ctx component]];
    
    p = [p sortedArrayUsingKeyOrderArray:isAccountThenLoginOrderings];
    count = [p count];
    if (count == 0) {
      /* no participants ?? */
    }
    else if (count <= 5) {
      for (i = 0; i < count; i++) {
        id participant = [p objectAtIndex:i];

        if (i != 0) [_response appendContentHTMLString:@", "];
      
        [self _appendParticipant:participant
              login:loginPKey
              owner:owner
              toResponse:_response inContext:_ctx];
      }
      [_response appendContentString:@"<br />"];
    }
    else {
      unsigned accountCount;
      
      for (i = 0, accountCount = 0; i < count; i++) {
        id participant = [p objectAtIndex:i];
        
        if ([[participant valueForKey:@"isAccount"] boolValue]) {
          if (accountCount != 0) [_response appendContentHTMLString:@", "];
          
          [self _appendParticipant:participant
                login:loginPKey
                owner:owner
                toResponse:_response inContext:_ctx];
          accountCount++;
        }
      }
      
      if (accountCount != count)
        [_response appendContentHTMLString:@", ..."];
      
      [_response appendContentString:@"<br />"];
    }
  }

  // title
  { 
    if (tc) {
      // TODO: use CSS
      [_response appendContentString:@"<font color=\""];
      [_response appendContentString:tc];
      [_response appendContentString:@"\">"];
    }
    {
      NSString *t = nil;
      
      if ([self->isPrivate boolValueInComponent:co]) {
        t = [self->privateLabel stringValueInComponent:co];
      }
      else {
	// TODO: use CSS
        if (noAcc) [_response appendContentString:@"<i>"];
        t = [a valueForKey:@"title"];
        if (t == nil) t = [self->privateLabel stringValueInComponent:co];
      }
      
      t = [t stringValue];
      if ([t length] > 20) {
        t = [t substringToIndex:17];
        t = [t stringByAppendingString:@"..."];
      }
      
      [_response appendContentHTMLString:t];
      if (noAcc) [_response appendContentString:@"</i>"];
      [_response appendContentString:@"<br />"];
    }
    if (tc) [_response appendContentString:@"</font>"];
  }
  
  // location
  {
    if (![self->isPrivate boolValueInComponent:co]) {
      NSString *l = [a valueForKey:@"location"];
      if (loc) {
	// TODO: use CSS
        [_response appendContentString:@"<font color=\""];
        [_response appendContentString:loc];
        [_response appendContentString:@"\">"];
      }        
      if (l != nil && ([l length] > 0) && ![l isEqualToString:@" "]) {
        if (noAcc) [_response appendContentString:@"<i>"]; // TODO: use CSS
        [_response appendContentHTMLString:[l stringValue]];
        if (noAcc) [_response appendContentString:@"</i>"];
        [_response appendContentString:@"<br />"];
      }
      if (loc) [_response appendContentString:@"</font>"];
    }
  }
  // absence
  {
    if (![self->isPrivate boolValueInComponent:co] && sevD) {
      NSString *ab = [a valueForKey:@"absence"];
      if (loc) {
	// TODO: use CSS
        [_response appendContentString:@"<font color=\""];
        [_response appendContentString:loc];
        [_response appendContentString:@"\">"];
      }        
      if (ab != nil && ([ab length] > 0) && ![ab isEqualToString:@" "]) {
        [_response appendContentHTMLString:[ab stringValue]];
      }
      if (loc) [_response appendContentString:@"</font>"];
    }
  }
    
  if (c) [_response appendContentString:@"</font>"];
}

@end /* LSWSchedulerDateCell */
