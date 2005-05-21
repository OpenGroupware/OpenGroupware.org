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
 SkySchedulerDateCell
 
 TODO: document what it does.
 */

@class WOAssociation;

@interface SkySchedulerDateCell : WODynamicElement
{
	@protected
	WOAssociation *appointment;  // appointment record (EO)
	WOAssociation *weekday;      // NSCalendarDate of current weekday
	WOAssociation *participants; // array of participants (company EO's)
	WOAssociation *isClickable;
	WOAssociation *isPrivate;
	WOAssociation *privateLabel;  // private appointment title
	WOAssociation *action;
	WOAssociation *aptTypeLabel;  // label for appointment type
	WOAssociation *isAllDay;
	
	WOAssociation *icon;          // icon filename (default: apt_10x10.gif)
	WOElement     *template;
}

@end

#include "SkyAppointmentFormatter.h"
#include "common.h"
#include <NGHttp/NGUrlFormCoder.h>
#include <time.h>

extern unsigned getpid();

@implementation SkySchedulerDateCell

static NSArray *participantSortOrderings = nil;
//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
+ (int)version 
{
	return [super version] + 0;
}
//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
+ (void)initialize 
{
	participantSortOrderings = [[NSArray alloc] initWithObjects:
		[EOSortOrdering sortOrderingWithKey:@"isTeam"
								   selector:EOCompareAscending],
		[EOSortOrdering sortOrderingWithKey:@"isAccount"
								   selector:EOCompareAscending],
		[EOSortOrdering sortOrderingWithKey:@"login"
								   selector:EOCompareAscending],
		nil];
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (id)initWithName:(NSString *)_name associations:(NSDictionary *)_config  template:(WOElement *)_t
{
	if ((self = [super initWithName:_name associations:_config template:_t]))
	{
		self->appointment  = OWGetProperty(_config, @"appointment");
		self->weekday      = OWGetProperty(_config, @"weekday");
		self->participants = OWGetProperty(_config, @"participants");
		self->isClickable  = OWGetProperty(_config, @"isClickable");
		self->isPrivate    = OWGetProperty(_config, @"isPrivate");
		self->privateLabel = OWGetProperty(_config, @"privateLabel");
		self->action       = OWGetProperty(_config, @"action");
		self->icon         = OWGetProperty(_config, @"icon");
		self->isAllDay     = OWGetProperty(_config, @"isAllDay");
		self->template     = [_t retain];
	}
	return self;
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (void)dealloc 
{
	[self->template     release];
	[self->isClickable  release];
	[self->isPrivate    release];
	[self->participants release];
	[self->appointment  release];
	[self->weekday      release];
	[self->privateLabel release];
	[self->action       release];
	[self->icon         release];
	[super dealloc];
}

/* responder */

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (void)_appendParticipant:(id)_person login:(id)_loginPKey owner:(id)_ownerPKey showFullName:(BOOL)_showFull toResponse:(WOResponse *)_response inContext:(WOContext *)_ctx
{
	NSNumber *pkey;
	NSString *label1        = nil;
	NSString *label2        = nil;
	BOOL     isLoginAccount = NO;
	BOOL     isAccount      = NO;
	BOOL     isOwner        = NO;
	BOOL     isDeleted      = NO;
	id       dbStatus       = nil;
	NSString *cssClass;
	
	cssClass = @"skydatecell_other";
	
	pkey      = [_person valueForKey:@"companyId"];
	dbStatus  = [_person valueForKey:@"dbStatus"];
	
	isDeleted = (dbStatus != nil) ? [dbStatus isEqualToString:@"archived"] : NO;
	
	if ([[_person valueForKey:@"isAccount"] boolValue])
	{
		if (_showFull)
		{
			label1 = [_person valueForKey:@"firstname"];
			label1 = ([label1 length]) ? [label1 stringByAppendingFormat:@" %@",[_person valueForKey:@"name"]] : [_person valueForKey:@"name"];
		}
		else
			label1         = [_person valueForKey:@"login"];
		
		isLoginAccount = [_loginPKey isEqual:pkey];
		isOwner        = [_ownerPKey isEqual:pkey];
		isAccount      = YES;
	}
	else if ([[_person valueForKey:@"isTeam"] boolValue])
	{
		if ((label1 = [_person valueForKey:@"info"]) == nil)
			label1 = [_person valueForKey:@"description"];
		isAccount = YES;
	}
	else
	{
		if (_showFull)
		{
			label1 = [_person valueForKey:@"firstname"];
			label1 = ([label1 length])	? [label1 stringByAppendingFormat:@" %@",[_person valueForKey:@"name"]]	: [_person valueForKey:@"name"];
		}
		else
			label1 = [_person valueForKey:@"name"];
		
		if (label1 == nil)
			label1 = [_person valueForKey:@"description"];
	}
	if (![label1 isNotNull])
		label1 = nil;
	if (![label2 isNotNull]) 
		label2 = nil;
	
	if ((label1 == nil) && (label2 != nil))
	{
		label1 = label2;
		label2 = nil;
	}
	
	if (label1 == nil)
		label1 = @"*";
	
	if (isDeleted)
	{
		cssClass = @"skydatecell_delparts";
	}
	else if (isLoginAccount)
	{
		cssClass = (isOwner) ? @"skydatecell_ownerAndLogin"	: @"skydatecell_login";
	}
	else if (!isAccount)
	{
		cssClass = @"skydatecell_person";
	}
	else if (isOwner)
	{
		cssClass = @"skydatecell_owner";
	}
	else
	{
		cssClass = @"skydatecell_other";
	}
	
	[_response appendContentString:@"<span class=\""];
	[_response appendContentString:cssClass];
	[_response appendContentString:@"\">"];
	
	[_response appendContentHTMLString:label1];
	if (label2)
	{
		[_response appendContentHTMLString:@", "];
		[_response appendContentHTMLString:label2];
	}
	
	[_response appendContentString:@"</span>"];
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (NSString *)fromDateStringForAppointment:(id)_apt showAMPM:(BOOL)_showAMPM inContext:(WOContext *)_ctx
{
	// TODO: should be a formatter?
	NSString       *fm;
	NSCalendarDate *sD, *wD;
	BOOL           allDay;
	id             comp;
	
	comp = [_ctx component];
	fm  = _showAMPM ? @"%I:%M %p" : @"%H:%M";
	sD = [_apt valueForKey:@"startDate"];
	wD = [self->weekday valueInComponent:comp];
	
	allDay = [self->isAllDay boolValueInComponent:comp];
	
	if (allDay)
	{
		if ([sD yearOfCommonEra] < [wD yearOfCommonEra]) 
			fm = @"%Y-%m-%d";
		else if (([sD dayOfYear]       <  [wD dayOfYear]) && ([sD yearOfCommonEra] <= [wD yearOfCommonEra])) 
			fm = @"%m-%d";
		else
			fm = @""; // today
	}
	else
	{
		if ([sD yearOfCommonEra] < [wD yearOfCommonEra]) 
			fm = [fm stringByAppendingString:@"(%Y-%m-%d)"];
		else if (([sD dayOfYear]       <  [wD dayOfYear]) && ([sD yearOfCommonEra] <= [wD yearOfCommonEra])) 
			fm = [fm stringByAppendingString:@"(%m-%d)"];
	}
	
	return [sD descriptionWithCalendarFormat:fm];
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (NSString *)endDateStringForAppointment:(id)_apt showAMPM:(BOOL)_showAMPM	inContext:(WOContext *)_ctx
{
	// TODO: should be a formatter?
	NSString       *fm;
	NSCalendarDate *eD, *wD;
	BOOL           allDay;
	id             comp;
	
	comp = [_ctx component];
	fm = _showAMPM ? @"%I:%M %p" : @"%H:%M";
	eD = [_apt valueForKey:@"endDate"];
	wD = [self->weekday valueInComponent:comp];
	
	allDay = [self->isAllDay boolValueInComponent:comp];
	
	if (allDay)
	{
		if ([eD yearOfCommonEra] > [wD yearOfCommonEra]) 
			fm = @"%Y-%m-%d";
		else if ([wD dayOfYear] < [eD dayOfYear] &&	 ([eD yearOfCommonEra] >= [wD yearOfCommonEra])) 
			fm = @"%m-%d";
		else
			fm = @""; // today
	}
	else
	{
		if ([eD yearOfCommonEra] > [wD yearOfCommonEra]) 
			fm = [fm stringByAppendingString:@"(%Y-%m-%d)"];
		else if ([wD dayOfYear] < [eD dayOfYear] &&	 ([eD yearOfCommonEra] >= [wD yearOfCommonEra])) 
			fm = [fm stringByAppendingString:@"(%m-%d)"];
	}
	
	return [eD descriptionWithCalendarFormat:fm];
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (NSString *)titleStringForAppointment:(id)_apt maxLength:(int)_len inContext:(WOContext *)_ctx
{
	NSString    *t = nil;
	WOComponent *co;
	
	co = [_ctx component];
	
	if ([self->isPrivate boolValueInComponent:co])
	{
		t = [self->privateLabel stringValueInComponent:co];
	}
	else
	{
		t = [_apt valueForKey:@"title"];
		if (![t isNotNull]) t = [self->privateLabel stringValueInComponent:co];
	}
	
	t = [t stringValue];
	
	if (_len != -1)
	{
		if ([t length] > _len)
		{ // TODO: should be a formatter
			t = [t substringToIndex:(_len - 2)];
			t = [t stringByAppendingString:@".."];
		}
	}
	
	if ([t length] == 0)
		t = @"*";
	
	return t;
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (NSString *)resourceStringForAppointment:(id)_apt maxLength:(int)_len inContext:(WOContext *)_ctx
{
	NSString *r = nil;
	
	r = [_apt valueForKey:@"resourceNames"];
	r = [r stringValue];
	
	if (_len != -1) 
	{
		if ([r length] > _len) 
		{
			r = [r substringToIndex:(_len - 2)];
			r = [r stringByAppendingString:@".."];
		}
	}
	return r;
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (NSString *)shortTextForAppointment:(id)_apt newline:(BOOL)_nl showFullNames:(BOOL)_showFull showAMPM:(BOOL)_showAMPM	inContext:(WOContext *)_ctx
{
	SkyAppointmentFormatter *f;
	
	f = [SkyAppointmentFormatter formatterWithFormat:_nl ? @"%S - %E;\n%T;\n%L;\n%10P;\n%50R" : @"%S - %E; %T; %L; %10P; %50R"];
	[f setShowFullNames:_showFull];
	[f setRelationDate:[self->weekday valueInComponent:[_ctx component]]];
	if ([self->isAllDay boolValueInComponent:[_ctx component]])
	{
		[f setDateFormat:@"%m-%d"];
		[f setOtherDayDateFormat:@"%m-%d"];
		[f setOtherYearDateFormat:@"%Y-%m-%d"];
	}
	else if (_showAMPM)
		[f switchToAMPMTimes:YES];
	
	return [f stringForObjectValue:_apt];
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (void)appendDAToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx  appointment:(id)_apt
{
	NSString *url;
	int      oid;
	NSString *tz;
	unsigned serial;
	NSString *alt;
	BOOL     showFull;
	BOOL     showAMPM;
	id       ud;
	
	ud       = [[_ctx session] userDefaults];
	showFull = [ud boolForKey:@"scheduler_overview_full_names"];
	showAMPM = [ud boolForKey:@"scheduler_AMPM_dates"];
	
	[_response appendContentString:@"<a class=\"skydatecell_link\" href=\""];
	
	oid = [[_apt valueForKey:@"dateId"] intValue];
	tz  = [[[_apt valueForKey:@"startDate"] timeZone] abbreviation];
	alt = [self shortTextForAppointment:_apt newline:YES showFullNames:showFull showAMPM:showAMPM inContext:_ctx];
	serial = getpid() + time(NULL);
	
	tz = [tz stringByEscapingURL];
	
	url = [NSString stringWithFormat:@"oid=%i&tz=%@&o=%d&%@=%@",oid, tz, serial,WORequestValueSessionID,[[_ctx session] sessionID]];
	
	url = [_ctx urlWithRequestHandlerKey:@"wa" path:@"/viewApt" queryString:url];
	[_response appendContentString:url];
	
	[_response appendContentString:@"\" title=\""];
	[_response appendContentHTMLAttributeValue:alt];
	
	if ([[[_ctx session] valueForKey:@"isJavaScriptEnabled"] boolValue])
	{
		
		alt = [self shortTextForAppointment:_apt newline:NO  showFullNames:showFull showAMPM:showAMPM inContext:_ctx];
		
		if ([alt length] > 0)
		{
			alt = [[alt componentsSeparatedByString:@"'"] componentsJoinedByString:@"&rsquo;"];
			
			[_response appendContentString:@"\" onMouseOver=\"window.status='"];
			[_response appendContentHTMLAttributeValue:alt];
			[_response appendContentString:@"';return true\" onMouseOut="];
			[_response appendContentString:@"\"window.status='SKYRIX';return true"];
		}
	}
	
	[_response appendContentString:@"\">"];
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (void)appendComponentActionToRespons:(WOResponse *)_response inContext:(WOContext *)_ctx  appointment:(id)_apt
{
	NSString     *url;
	NSString     *alt;
	BOOL         showFull;
	BOOL         showAMPM;
	id           ud;
	ud       = [[_ctx session] userDefaults];
	showFull = [ud boolForKey:@"scheduler_overview_full_names"];
	showAMPM = [ud boolForKey:@"scheduler_AMPM_dates"];
	
	alt = [self shortTextForAppointment:_apt newline:YES showFullNames:showFull showAMPM:showAMPM inContext:_ctx];
	
	url = [_ctx componentActionURL];
	
	//  NSLog(@"<SkySchedulerDateCell> Appending Component action: %@", url);
	
	[_response appendContentString:@"<a class=\"skydatecell_link\" href=\""];
	
	[_response appendContentHTMLAttributeValue:url];
	
	[_response appendContentString:@"\" title=\""];
	[_response appendContentHTMLAttributeValue:alt];
	
	if ([[[_ctx session] valueForKey:@"isJavaScriptEnabled"] boolValue])
	{
		alt = [self shortTextForAppointment:_apt newline:NO showFullNames:showFull showAMPM:showAMPM inContext:_ctx];
		
		if ([alt length] > 0)
		{
			alt = [[alt componentsSeparatedByString:@"'"] componentsJoinedByString:@"\\'"];
			
			[_response appendContentString:@"\" onMouseOver=\"window.status='"];
			[_response appendContentString:alt];
			[_response appendContentString:@"';return true\" onMouseOut="];
			[_response appendContentString:@"\"window.status='SKYRIX';return true"];
		}
	}
	
	[_response appendContentString:@"\">"];
	
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (void)appendIconToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx appointment:(id)_apt
{
	NSString *src;
	NSArray  *languages;
	BOOL     showFull;
	BOOL     showAMPM;
	id       ud;
	ud       = [[_ctx session] userDefaults];
	showFull = [ud boolForKey:@"scheduler_overview_full_names"];
	showAMPM = [ud boolForKey:@"scheduler_AMPM_dates"];
	
	languages = [[_ctx session] languages];
	
	src = [self->icon valueInComponent:[_ctx component]];
	if ([src length] < 1)
		src = @"apt_10x10.gif";
	src = [[[_ctx application] resourceManager] urlForResourceNamed:src	inFramework:nil languages:languages	request:[_ctx request]];
	if ([src length] > 0)
	{
		NSString *alt = nil;
		
		alt = [self shortTextForAppointment:_apt newline:YES showFullNames:showFull showAMPM:showAMPM inContext:_ctx];
		
		[_response appendContentString:@"<img border='0' valign='top' src=\""];
		[_response appendContentHTMLAttributeValue:src];
		
		if ([alt length] > 0)
		{
			[_response appendContentString:@"\" alt=\""];
			[_response appendContentHTMLAttributeValue:alt];
		}
		
		[_response appendContentString:@"\" />"];
	}
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (void)appendToResponse:(WOResponse *)_response inContext:(WOContext *)_ctx
{
	WOComponent    *co = [_ctx component];
	id             a     = nil;
	NSCalendarDate *wD   = nil;
	id             owner = nil;
	BOOL           link  = NO;
	BOOL           priv  = NO;
	BOOL           sevD  = NO;
	BOOL           noAcc = NO;
	BOOL           shortInfo     = YES;
	BOOL           withResources = NO;
	BOOL           componentAction = NO;
	BOOL           showFull = NO;
	BOOL           showAMPM = NO;
	NSUserDefaults *defaults = nil;
	
	defaults = [(OGoSession *)[_ctx session] userDefaults];
	
	shortInfo     = [defaults boolForKey:@"scheduler_overview_short_info"];
	withResources = [defaults boolForKey:@"scheduler_overview_with_resources"];
	showFull      = [defaults boolForKey:@"scheduler_overview_full_names"];
	showAMPM      = [defaults boolForKey:@"scheduler_AMPM_dates"];
	
	a    = [self->appointment      valueInComponent:co];
	wD   = [self->weekday          valueInComponent:co];
	link = [self->isClickable      boolValueInComponent:co];
	priv = [self->isPrivate        boolValueInComponent:co];
	
	noAcc = ([a valueForKey:@"accessTeamId"] == nil);
	owner = [a valueForKey:@"ownerId"];
	
	if (link)
		componentAction = ([a valueForKey:@"dateId"] == nil) ? YES : NO;
	
	if (link)
	{
		if (componentAction)
			[self appendComponentActionToRespons:_response inContext:_ctx appointment:a];
		else
			[self appendDAToResponse:_response inContext:_ctx appointment:a];
	}
	
	[self appendIconToResponse:_response inContext:_ctx appointment:a];
	
	{ /* link content */
		NSString *s;
		
		if ((s = [self fromDateStringForAppointment:a showAMPM:showAMPM
										  inContext:_ctx]))
			[_response appendContentHTMLString:s];
	}

	if (!shortInfo)
	{
		NSString *s;
		
		[_response appendContentString:@"<span class=\"skydatecell_text\">"];
		
		s = [self endDateStringForAppointment:a showAMPM:showAMPM inContext:_ctx];
		if ([s length] > 0)
		{
			[_response appendContentHTMLString:@" - "];
			[_response appendContentHTMLString:s];
		}
		[_response appendContentString:@"</span>"];
	}
	else
	{
		/* short info: gen title after start-time */
		NSString *t = nil;
		
		[_response appendContentString:	noAcc ? @" <span class=\"skydatecell_titlePrivate\">" : @" <span class=\"skydatecell_title\">"];
		
		t = [self titleStringForAppointment:a maxLength:14 inContext:_ctx];
		[_response appendContentHTMLString:t];
		
		[_response appendContentString:@"</span>"];
	}
	if (link)
		[_response appendContentString:@"</a>"];

	[_response appendContentString:@"<br />"];
	
	/* participants */
	{
		NSNumber *loginPKey;
		NSArray  *p;
		int      i, count;
	
		loginPKey = [[(id)[_ctx session] activeAccount] valueForKey:@"companyId"];
    
		p = [self->participants valueInComponent:[_ctx component]];
		p = [p sortedArrayUsingKeyOrderArray:participantSortOrderings];
    
		if ((count = [p count]) == 0)
		{
			/* no participants ?? */
		}
		else if (count <= 5)
		{
			for (i = 0; i < count; i++)
			{
				id participant = [p objectAtIndex:i];
			
				if (i != 0)
					[_response appendContentHTMLString:@", "];
			
				[self _appendParticipant:participant login:loginPKey owner:owner showFullName:showFull toResponse:_response inContext:_ctx];
			}
			[_response appendContentString:@"<br />"];
		}
		else
		{
			unsigned accountCount;
		
			for (i = 0, accountCount = 0; i < count; i++)
			{
				id participant = [p objectAtIndex:i];
			
				if ([[participant valueForKey:@"isAccount"] boolValue] || [[participant valueForKey:@"isTeam"] boolValue])
				{
					if (accountCount != 0) [_response appendContentHTMLString:@", "];
				
					[self _appendParticipant:participant login:loginPKey owner:owner showFullName:showFull toResponse:_response inContext:_ctx];
					accountCount++;
				
					if (accountCount > 4)
						break;
				}
			}
		
			if (accountCount != count)
				[_response appendContentHTMLString:@", ..."];
		
			[_response appendContentString:@"<br />"];
		}
	}

	/* resources */

	if (withResources)
	{
		if (![self->isPrivate boolValueInComponent:co])
		{
			NSString *r;
			
			r = [self resourceStringForAppointment:a maxLength:24 inContext:_ctx];
			
			if (r != nil && ([r length] > 0) && ![r isEqualToString:@" "])
			{
				[_response appendContentString:
					@"<span class=\"skydatecell_resources\">"];
				[_response appendContentHTMLString:[r stringValue]];
				[_response appendContentString:@"</span>"];
				[_response appendContentString:@"<br />"];
			}
		}
	}

	/* title */
	if (!shortInfo)
	{
		NSString *t = nil;
		
		[_response appendContentString:noAcc ? @" <span class=\"skydatecell_titlePrivate\">" : @" <span class=\"skydatecell_title\">"];
		
		t = [self titleStringForAppointment:a maxLength:24 inContext:_ctx];
		[_response appendContentHTMLString:t];
		[_response appendContentString:@"</span><br />"];
	}

	/* location */
	if (!shortInfo)
	{
		if (![self->isPrivate boolValueInComponent:co])
		{
			NSString *l;
			
			l = [[a valueForKey:@"location"] stringValue];
			
			if (l != nil && ([l length] > 0) && ![l isEqualToString:@" "])
			{
				[_response appendContentString:
					@"<span class=\"skydatecell_location\">"];
				[_response appendContentHTMLString:l];
				[_response appendContentString:@"</span><br />"];
			}
		}
	}

	/* absence */
	if (![self->isPrivate boolValueInComponent:co] && sevD)
	{
		NSString *ab;
		
		ab = [a valueForKey:@"absence"];
		
		if (ab != nil && ([ab length] > 0) && ![ab isEqualToString:@" "])
		{
			[_response appendContentString:	@"<span class=\"skydatecell_absence\">"];
			[_response appendContentHTMLString:[ab stringValue]];
			[_response appendContentString:@"</span>"];
		}
	}
}

/* handling requests */

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (void)takeValuesFromRequest:(WORequest *)_rq inContext:(WOContext *)_ctx 
{
	[self->template takeValuesFromRequest:_rq inContext:_ctx];
}

//*********************************************************************************************************
//
//
//
//
//*********************************************************************************************************
- (id)invokeActionForRequest:(WORequest *)_rq inContext:(WOContext *)_ctx
{
	WOComponent *co  = [_ctx component];
	BOOL        link = NO;
	
	link = [self->isClickable boolValueInComponent:co];
	
	if (link)
	{
		id a;
		
		a = [self->appointment valueInComponent:co];
		if ([a valueForKey:@"dateId"] == nil)
			return [self->action valueInComponent:[_ctx component]];
	}
	
	return [self->template invokeActionForRequest:_rq inContext:_ctx];
}

@end /* SkySchedulerDateCell */
