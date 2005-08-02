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

  TODO: document!
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
static WOAssociation *cfgAptLink    = nil;
static WOAssociation *cfgOwnerColor = nil;
static WOAssociation *cfgTitleColor = nil;
static WOAssociation *cfgLocColor   = nil;
static WOAssociation *cfgTextColor  = nil;

+ (int)version {
  return [super version] + 0;
}

static inline WOAssociation *lswNewKeyBinding(NSString *kp) {
  return [[WOAssociation associationWithKeyPath:kp] retain];
}

+ (void)_setupStaticBindings {
  cfgAptLink    = lswNewKeyBinding(@"config.colors_appointmentLink");
  cfgOwnerColor = lswNewKeyBinding(@"config.colors_ownerColor");
  cfgTitleColor = lswNewKeyBinding(@"config.colors_titleColor");
  cfgLocColor   = lswNewKeyBinding(@"config.colors_locationColor");
  cfgTextColor  = lswNewKeyBinding(@"config.colors_contentText");
}

+ (void)initialize {
  static BOOL didInit = NO;
  if (didInit) return;
  
  if (isAccountThenLoginOrderings == nil) {
    EOSortOrdering *lso, *aso;
    
    aso = [EOSortOrdering sortOrderingWithKey:@"isAccount"
			  selector:EOCompareAscending];
    lso = [EOSortOrdering sortOrderingWithKey:@"login" 
                          selector:EOCompareAscending];
    isAccountThenLoginOrderings = [[NSArray alloc] initWithObjects:
						     aso, lso, nil];
  }

  [self _setupStaticBindings];
  
  didInit = YES;
}

- (void)_setupDefaultBindings {
  // TODO: check whether those bindings are ever rewritten!
  // TODO: replace bindings with CSS
  if (self->linkColor     == nil) self->linkColor     = [cfgAptLink    retain];
  if (self->ownerColor    == nil) self->ownerColor    = [cfgOwnerColor retain];
  if (self->titleColor    == nil) self->titleColor    = [cfgTitleColor retain];
  if (self->locationColor == nil) self->locationColor = [cfgLocColor   retain];
  if (self->color         == nil) self->color         = [cfgTextColor  retain];
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_t
{
  if ((self = [super initWithName:_name associations:_config template:_t])) {
    self->appointment      = OWGetProperty(_config, @"appointment");
    self->weekday          = OWGetProperty(_config, @"weekday");
    self->participants     = OWGetProperty(_config, @"participants");
    self->isClickable      = OWGetProperty(_config, @"isClickable");
    self->isPrivate        = OWGetProperty(_config, @"isPrivate");
    self->isForSeveralDays = OWGetProperty(_config, @"isForSeveralDays");
    self->privateLabel     = OWGetProperty(_config, @"privateLabel");
    self->action           = OWGetProperty(_config, @"action");
    
    /* color bindings */ // TODO: replace by CSS
    self->linkColor        = OWGetProperty(_config, @"linkColor");
    self->color            = OWGetProperty(_config, @"color");
    self->ownerColor       = OWGetProperty(_config, @"ownerColor");
    self->titleColor       = OWGetProperty(_config, @"titleColor");
    self->locationColor    = OWGetProperty(_config, @"locationColor");
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

- (NSString *)daLinkToApt:(id)a inContext:(WOContext *)_ctx {
  NSString     *url, *s;
  unsigned int oid;
  NSString     *tz;
  unsigned     serial;

  if (a == nil) return nil;
  
  oid    = [[a valueForKey:@"dateId"] unsignedIntValue];
  tz     = [[[a valueForKey:@"startDate"] timeZone] abbreviation];
  serial = getpid() + time(NULL); // TODO: can't we use the context-id?
  
  tz = [tz stringByEscapingURL];
      
  s = [[NSString alloc] initWithFormat:@"oid=%d&tz=%@&o=%d&%@=%@",
                          oid, tz, serial, WORequestValueSessionID,
                          [[_ctx session] sessionID]];
  
  url = [_ctx urlWithRequestHandlerKey:@"wa"
              path:@"/viewApt"
              queryString:s];
  [s release];
  return url;
}

- (unsigned int)appendParticipants:(NSArray *)_parts
  withOwnerId:(NSNumber *)owner
  toResponse:(WOResponse *)_response inContext:(WOContext *)_ctx
{
  /* returns the number of generated items */
  NSNumber     *loginPKey;
  NSArray      *p;
  unsigned int i, count;
  unsigned     accountCount;
  
  /* sort for display */
  p = [_parts sortedArrayUsingKeyOrderArray:isAccountThenLoginOrderings];
  
  if ((count = [p count]) == 0) /* no participants ?? */
    return 0;
  
  loginPKey = [[[_ctx session] activeAccount] valueForKey:@"companyId"];
  
  if (count <= 5) {
    for (i = 0; i < count; i++) {
      id participant = [p objectAtIndex:i];

      if (i != 0) [_response appendContentHTMLString:@", "];
      
      [self _appendParticipant:participant
            login:loginPKey
            owner:owner
            toResponse:_response inContext:_ctx];
    }
    return count;
  }
  
  // TODO: document what it does (just keep accounts?)
  
  for (i = 0, accountCount = 0; i < count; i++) {
    id participant = [p objectAtIndex:i];
    
    if (![[participant valueForKey:@"isAccount"] boolValue])
      continue;

    if (accountCount != 0) [_response appendContentHTMLString:@", "];
          
    [self _appendParticipant:participant
          login:loginPKey
          owner:owner
          toResponse:_response inContext:_ctx];
    accountCount++;
  }
  
  if (accountCount != count)
    [_response appendContentHTMLString:@", ..."];
  
  return accountCount;
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  // TODO: split up this huge method
  // TODO: improve labels
  // TODO: replace font tag with CSS
  /*
    Note: private and no-access is not the same! 'private' just says whether
          the apt itself is marked private.
  */
  WOComponent    *co = [_ctx component];
  id             a;
  NSString       *c;
  NSString       *lc;
  NSCalendarDate *wD;
  NSNumber       *owner;
  NSString       *oc, *tc, *loc;
  BOOL           link, priv, sevD, noAcc;
  unsigned       count;
  
  if ((a = [self->appointment valueInComponent:co]) == nil) {
    [self errorWithFormat:@"got no appointment?"];
    return;
  }
  
  /* get values of bindings */
  
  wD   = [self->weekday          valueInComponent:co];
  link = [self->isClickable      boolValueInComponent:co];
  sevD = [self->isForSeveralDays boolValueInComponent:co];
  priv = [self->isPrivate        boolValueInComponent:co];
  
  noAcc = [[a valueForKey:@"accessTeamId"] isNotNull] ? NO : YES;
  owner = [a valueForKey:@"ownerId"];
  
  /* get values of colors bindings TODO: replace with CSS! */
  c    = [self->color         stringValueInComponent:co];
  lc   = [self->linkColor     stringValueInComponent:co];
  oc   = [self->ownerColor    stringValueInComponent:co];
  tc   = [self->titleColor    stringValueInComponent:co];
  loc  = [self->locationColor stringValueInComponent:co];
  if (lc == nil) lc = c;
  
  // TODO: checks action?! => we generate a DA => probably we need a "genLink"
  if ((self->action != nil) && link) {
    [_response appendContentString:@"<a href=\""];
    [_response appendContentString:[self daLinkToApt:a inContext:_ctx]];
    [_response appendContentString:@"\">"];
  }
  { // link content
    if (lc) {
      // TODO: use stylesheets!
      [_response appendContentString:@"<font color=\""];
      [_response appendContentString:lc];
      [_response appendContentString:@"\">"];
    }
    
    { // TODO: make that an apt-formatter?
      NSCalendarDate *sD;
      char buf[32];
      
      sD = [a valueForKey:@"startDate"];
      if (!sevD &&
          (([sD dayOfYear]       <  [wD dayOfYear]) &&
           ([sD yearOfCommonEra] <= [wD yearOfCommonEra]))) {
        snprintf(buf, sizeof(buf), "%02d:%02d(%02d-%02d)", /* %H:%M(%m-%d) */
                 [sD hourOfDay], [sD minuteOfHour],
                 [sD monthOfYear], [sD dayOfMonth]);
      }
      else if (sevD) {
        snprintf(buf, sizeof(buf),
                 "%04d-%02d-%02d %02d:%02d", /* %Y-%m-%d %H:%M */
                 [sD yearOfCommonEra], [sD monthOfYear], [sD dayOfMonth],
                 [sD hourOfDay], [sD minuteOfHour]);
      }
      else {
        snprintf(buf, sizeof(buf), "%02d:%02d",  /* %H:%M */
                 [sD hourOfDay], [sD minuteOfHour]);
      }
      
      /* does not contain HTML specials */
      [_response appendContentCString:(unsigned char *)buf];
    }

    if (lc) [_response appendContentString:@"</font>"];
  }
  if ((self->action != nil) && link)
    [_response appendContentString:@"</a>"];

  if (c) {
    /* TODO: use stylesheets */
    [_response appendContentString:@"<font color=\""];
    [_response appendContentString:c];
    [_response appendContentString:@"\">"];
  }

  [_response appendContentHTMLString:@" - "];
  {
    NSCalendarDate *eD;
    char buf[32];
    
    eD = [a valueForKey:@"endDate"];
    if (!sevD &&
        ([wD dayOfYear] < [eD dayOfYear] &&
         ([eD yearOfCommonEra] >= [wD yearOfCommonEra]))) {
      snprintf(buf, sizeof(buf), "%02d:%02d(%02d-%02d)", /* %H:%M(%m-%d) */
               [eD hourOfDay],   [eD minuteOfHour],
               [eD monthOfYear], [eD dayOfMonth]);
    }      
    else if (sevD) {
      snprintf(buf, sizeof(buf),
               "%04d-%02d-%02d %02d:%02d", /* %Y-%m-%d %H:%M */
               [eD yearOfCommonEra], [eD monthOfYear], [eD dayOfMonth],
               [eD hourOfDay], [eD minuteOfHour]);
    }
    else {
      snprintf(buf, sizeof(buf), "%02d:%02d",  /* %H:%M */
               [eD hourOfDay], [eD minuteOfHour]);
    }
    
    /* does not contain HTML specials */
    [_response appendContentCString:(unsigned char *)buf];
  }

  [_response appendContentString:@"<br />"];
  
  /* participants */
  
  count = [self appendParticipants:[self->participants valueInComponent:co]
                withOwnerId:owner
                toResponse:_response inContext:_ctx];
  if (count > 0)
    [_response appendContentString:@"<br />"];
  
  /* title */
  { 
    if (tc) {
      // TODO: use CSS
      [_response appendContentString:@"<font color=\""];
      [_response appendContentString:tc];
      [_response appendContentString:@"\">"];
    }
    {
      NSString *t = nil;
      
      if (priv)
        t = [self->privateLabel stringValueInComponent:co];
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
  
  /* location */
  {
    if (!priv) {
      NSString *l;
      
      l = [a valueForKey:@"location"];
      if (loc) {
	// TODO: use CSS
        [_response appendContentString:@"<font color=\""];
        [_response appendContentString:loc];
        [_response appendContentString:@"\">"];
      }
      if ([l isNotEmpty] && ![l isEqualToString:@" "]) {
        if (noAcc) [_response appendContentString:@"<i>"]; // TODO: use CSS
        [_response appendContentHTMLString:[l stringValue]];
        if (noAcc) [_response appendContentString:@"</i>"];
        [_response appendContentString:@"<br />"];
      }
      if (loc) [_response appendContentString:@"</font>"];
    }
  }
  /* absence */
  {
    if (!priv && sevD) {
      NSString *ab;
      
      ab = [a valueForKey:@"absence"];
      if (loc) {
	// TODO: use CSS
        [_response appendContentString:@"<font color=\""];
        [_response appendContentString:loc];
        [_response appendContentString:@"\">"];
      }
      if ([ab isNotEmpty] && ![ab isEqualToString:@" "])
        [_response appendContentHTMLString:[ab stringValue]];
      
      if (loc) [_response appendContentString:@"</font>"];
    }
  }
    
  if (c != nil) [_response appendContentString:@"</font>"];
}

@end /* LSWSchedulerDateCell */
