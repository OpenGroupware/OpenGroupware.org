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

#include <NGObjWeb/WODynamicElement.h>

@class WOAssociation;

/*
  LSWSchedulerDateTitle

  TODO: document!

  Used in:
    SkyPalmDateWeekOverview.wo
    SkyPrintWeekOverview.wo
    SkyInlineWeek*.wo
    SkyWeekRepetition.m
  
  Stylesheet classes:
    skydatetitle
    skydatetitlehigh
    skydatetitlelink
    skydatetitlenewlink
*/

@interface LSWSchedulerDateTitle : WODynamicElement
{
@protected
  WOAssociation *title;         // title string of cell (eg 'Monday')
  WOAssociation *date;          // an NSCalendarDate
  WOAssociation *newLabel;      // label string for 'new' link
  WOAssociation *highlight;     // boolean (should we highlight the cell ?)
  WOAssociation *disableAction; // BOOL
  WOAssociation *disableNew;    // BOOL
  WOAssociation *directActionName; // directActionName
  WOAssociation *showAMPMDates; // BOOL
}

@end

#include "common.h"
#include <NGExtensions/NSString+misc.h>

@implementation LSWSchedulerDateTitle

+ (int)version {
  return [super version] + 0;
}

- (id)initWithName:(NSString *)_name
  associations:(NSDictionary *)_config
  template:(WOElement *)_elms
{
  if ((self = [super initWithName:_name associations:_config template:_elms])) {
    id tmp;
    
    self->title         = OWGetProperty(_config, @"title");
    self->date          = OWGetProperty(_config, @"date");
    self->newLabel      = OWGetProperty(_config, @"newLabel");    
    self->highlight     = OWGetProperty(_config, @"highlight");
    self->disableAction = OWGetProperty(_config, @"disableAction");
    self->disableNew    = OWGetProperty(_config, @"disableNew");
    self->showAMPMDates = OWGetProperty(_config, @"showAMPMDates");
    self->directActionName = OWGetProperty(_config, @"directActionName");

    if ((tmp = OWGetProperty(_config, @"action"))) {
      [self warnWithFormat:@"%s 'action' binding is not supported anymore !",
            __PRETTY_FUNCTION__];
      [tmp release]; tmp = nil;
    }
    if ((tmp = OWGetProperty(_config, @"onNew"))) {
      [self warnWithFormat:@"%s 'onNew' binding is not supported anymore !",
            __PRETTY_FUNCTION__];
      [tmp release];
    }
  }
  return self;
}

- (void)dealloc {
  [self->disableAction release];
  [self->disableNew    release];
  [self->showAMPMDates release];
  [self->highlight     release];
  [self->newLabel      release];
  [self->title         release];
  [self->date          release];
  [super dealloc];
}

/* responder */

- (void)appendJS:(NSString *)_d
  toReponse:(WOResponse *)_response
  inContext:(WOContext *)_ctx
{
  [_response appendContentString:
             @" onMouseOut=\""
             @"window.status='OpenGroupware.org'; "
             @"return true\""];
  [_response appendContentString:@" onMouseOver=\""];
  [_response appendContentString:@"window.status=\'"];
  [_response appendContentHTMLString:_d];
  [_response appendContentString:@"\'; return true\""];
}

- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx {
  // TODO: split up this huge method!
  NSCalendarDate *d;
  WOComponent    *sComponent;
  BOOL           doJavaScript;
  
  sComponent = [_ctx component];
  d          = [self->date valueInComponent:sComponent];
  
  doJavaScript =
    [[[_ctx session] valueForKey:@"isJavaScriptEnabled"] boolValue];
  
  [_response appendContentString:
             @"<table cellpadding=\"0\" width=\"100%\" "
             @"border=\"0\" cellspacing=\"0\">"
             @"<tr>"];
    
  { /* date cell */
    NSString *dd;
    
    dd = [d descriptionWithCalendarFormat:@"%d"];
    
    [_response appendContentString:
               @"<td align=\"left\" valign=\"top\" "
               @"class=\"skydatetitlelink\">"];
    
    if (![self->disableAction boolValueInComponent:sComponent]) {
      NSString *url;
      NSString *da;
      NSString *tz;
      static unsigned serial = 0;
      char buf[256];
        
      [_response appendContentString:@"<a class=\"skydatetitlelink\" href=\""];
      
      serial++;
      tz = [[d timeZone] abbreviation];
      tz = [tz stringByEscapingURL];
      if (tz == nil) tz = @"GMT";
      
      snprintf(buf, sizeof(buf), "year=%ld&month=%ld&day=%ld&tz=%s",
	       [d yearOfCommonEra], [d monthOfYear], [d dayOfMonth],
	       [tz UTF8String]);
      url = [NSString stringWithCString:buf];
      
      if ([_ctx hasSession]) {
	// TODO: use some WOContext URL generation method?
        WOSession *sn;
	
	sn = [_ctx session];
	url = [[url stringByAppendingString:@"&wosid="]
		    stringByAppendingString:[sn sessionID]];
	
#if 0 /* not used in OGo anyway */
        if (![sn isDistributionEnabled]) {
          url = [NSString stringWithFormat:@"%@&woinst=%@", url,
                          [[WOApplication application] number]];
        }
#endif
      }
      
      da  = [self->directActionName stringValueInComponent:sComponent];
      da  = (da != nil) ? da : (NSString *)@"viewDay";
      da  = [@"/" stringByAppendingString:da];
      url = [_ctx urlWithRequestHandlerKey:@"wa"
                  path:da
                  queryString:url];
      [_response appendContentString:url];
      
      [_response appendContentCharacter:'"'];

      if (doJavaScript) {
        NSString *desc;
        char buf[16];
        
        snprintf(buf, sizeof(buf), "%04ld-%02ld-%02ld",
                 [d yearOfCommonEra], [d monthOfYear], [d dayOfMonth]);
        desc = [[NSString alloc] initWithCString:buf];
        [self appendJS:desc toReponse:_response inContext:_ctx];
        [desc release];
      }

      [_response appendContentCharacter:'>'];      
      [_response appendContentHTMLString:dd ? dd : (NSString *)@"<nil>"];      
      [_response appendContentString:@"</a>"];
    }
    else {
      [_response appendContentHTMLString:dd ? dd : (NSString *)@"<nil>"];
    }
    
    [_response appendContentString:@"</td>"];
  }
  
  { /* new cell */
    NSString *l   = nil;
    BOOL     doHi = NO;
    
    l = [self->title stringValueInComponent:sComponent];
    if (l == nil) l = [d descriptionWithCalendarFormat:@"%A"];
    doHi = [self->highlight boolValueInComponent:sComponent];
      
    [_response appendContentString:
                 @"<td align='center' valign='top' width='97%' class=\""];
    [_response appendContentString:
                 doHi ? @"skydatetitlehigh" : @"skydatetitle"];
    [_response appendContentString:@"\">"];
    
    [_response appendContentHTMLString:
		 (l != nil) ? l : (NSString *)@"<missing>"];
    
    [_response appendContentString:@"<br />"];
    
    /* new button ... */
    
    if (![self->disableNew boolValueInComponent:sComponent]) {
      NSString *nt, *alt, *url, *tz, *calFormat;
      static unsigned serial = 0;
      
      calFormat = [self->showAMPMDates boolValueInComponent:sComponent]
        ? @"%Y-%m-%d 11:00 AM %Z" : @"%Y-%m-%d 11:00 %Z";
      if ([d isNotNull]) {
	if ((calFormat = [d descriptionWithCalendarFormat:calFormat]) == nil) {
	  [self warnWithFormat:@"could not format date: %@", d];
	  calFormat = @"-";
	}
      }
      else /* happens on MacOS */
	calFormat = @"-";
      
      nt  = [self->newLabel stringValueInComponent:sComponent];
      alt = @"Create new appointment on ";
      alt = calFormat != nil ? [alt stringByAppendingString:calFormat] : alt;
      
      [_response appendContentString:
                   @"[<a class=\"skydatetitlenewlink\" href=\""];
      
      serial++;
      tz = [[d timeZone] abbreviation];
      tz = [tz stringByEscapingURL];
          
      url = [NSString stringWithFormat:
                        @"year=%i&month=%i&day=%i&hour=11&"
                        @"tz=%@&c=%@&%@=%@",
                        [d yearOfCommonEra],
                        [d monthOfYear],
                        [d dayOfMonth],
                        tz,
                        [_ctx contextID],
                        WORequestValueSessionID,
                        [[_ctx session] sessionID]];
          
      url = [_ctx urlWithRequestHandlerKey:@"wa"
                  path:@"/newApt"
                  queryString:url];
      [_response appendContentString:url];
      [_response appendContentCharacter:'"'];
        
      if (doJavaScript) 
        [self appendJS:alt toReponse:_response inContext:_ctx];
      
      [_response appendContentCharacter:'>'];        
      [_response appendContentHTMLString:
		   (nt != nil ? nt : (NSString *)@"new")];
      [_response appendContentString:@"</a>]"];
    }
    
    [_response appendContentString:@"</td>"];
  }

  [_response appendContentString:@"</tr></table>"];
}

@end /* LSWSchedulerDateTitle */
