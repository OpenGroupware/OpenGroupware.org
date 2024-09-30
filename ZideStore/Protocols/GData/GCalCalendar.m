/*
  Copyright (C) 2006 Helge Hess

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

#include "GCalCalendar.h"
#include "GCalEvent.h"
#include "GLinkTypes.h"
#include <ZSBackend/SxAptManager.h>
#include <LSFoundation/LSCommandContext.h>
#include <LSFoundation/LSCommandKeys.h>
#include <SaxObjC/XMLNamespaces.h>
#include "common.h"

@interface NSObject(SxAppointmentFolder)
- (SxAptManager *)aptManagerInContext:(id)_ctx;
- (SxAptSetIdentifier *)aptSetID;
@end

@interface GCalCalendar(Privates)
- (void)appendToResponse:(WOResponse *)_r inContext:(WOContext *)_ctx;
@end

@implementation GCalCalendar

static NSTimeZone *utc = nil;

+ (void)initialize {
  if (utc == nil)
    utc = [[NSTimeZone timeZoneWithAbbreviation:@"GMT"] retain];
}

- (id)initWithUserFolder:(id)_userFolder {
  if ((self = [super init]) != nil) {
    self->userFolder = [_userFolder retain];
  }
  return self;
}

- (void)dealloc {
  [self->calendarFolder release];
  [self->userFolder release];
  [self->visibility release];
  [self->projection release];
  [super dealloc];
}

/* accessors */

- (NSString *)nameInContainer {
  return [[self userFolder] nameInContainer];
}

- (NSString *)visibility {
  return self->visibility;
}
- (NSString *)projection {
  return self->projection;
}

- (id)userFolder {
  return self->userFolder;
}

/* OGo objects */

- (LSCommandContext *)commandContextInContext:(id)_ctx {
  return [[self userFolder] commandContextInContext:_ctx];
}
- (id)accountInContext:(id)_ctx {
  return [[self commandContextInContext:_ctx] valueForKey:LSAccountKey];
}

/* paging */

- (int)startIndexInContext:(WOContext *)_ctx {
  return [[[_ctx request] formValueForKey:@"start-index"] intValue];
}
- (NSString *)numberOfItemsPerPageAsString {
  return @"25";
}

/* links */

- (NSString *)selfURLInContext:(WOContext *)_ctx {
  NSString *s;
  int i;
  
  s = [self baseURLInContext:_ctx];
  s = [s stringByAppendingString:@"?max-results="];
  s = [s stringByAppendingString:[self numberOfItemsPerPageAsString]];
  
  i = [self startIndexInContext:_ctx];
  if (i > 0) {
    s = [s stringByAppendingString:@"&amp;start-index"];
    s = [s stringByAppendingFormat:@"%i", i];
  }
  
  return s;
}

- (NSString *)nextURLInContext:(WOContext *)_ctx {
  NSString *s;
  int i;
  
  s = [self baseURLInContext:_ctx];
  s = [s stringByAppendingString:@"?max-results="];
  s = [s stringByAppendingString:[self numberOfItemsPerPageAsString]];
  
  i = [self startIndexInContext:_ctx];
  i = i + [[self numberOfItemsPerPageAsString] intValue];
  s = [s stringByAppendingString:@"&amp;start-index"];
  s = [s stringByAppendingFormat:@"%i", i];
  
  return s;
}

- (NSString *)feedURLInContext:(WOContext *)_ctx {
  return [self baseURLInContext:_ctx];
}
- (NSString *)postURLInContext:(WOContext *)_ctx {
  return [self baseURLInContext:_ctx];
}

/* lookup */

- (id)calendarFolderForVisibility:(NSString *)_vis inContext:(id)_ctx {
  if (![_vis isNotEmpty]) return nil;
  
  if ([_vis isEqualToString:@"public"]) {
    id pubFolder;

    pubFolder = [[self userFolder] lookupName:@"public" inContext:_ctx
				   acquire:NO];
    if (pubFolder == nil) {
      [self errorWithFormat:@"did not find 'public' folder!"];
      return nil;
    }
    if ([pubFolder isKindOfClass:[NSException class]])
      return pubFolder;
    
    return [pubFolder lookupName:@"Calendar" inContext:_ctx acquire:NO];
  }
  
  if ([_vis isEqualToString:@"private"]) {
    // TODO: maybe we should map that to 'Overview"?
    return [[self userFolder] lookupName:@"Calendar" inContext:_ctx
			      acquire:NO];
  }
  
  [self errorWithFormat:@"unsupported visibility: '%@'", _vis];
  return nil;
}

- (GCalEvent *)lookupEvent:(NSString *)_name inContext:(id)_ctx {
  // Note: we do not check the ID, this is done by the actions in the event
  return [[[GCalEvent alloc] initWithName:_name inContainer:self] autorelease];
}

- (id)lookupName:(NSString *)_name inContext:(id)_ctx acquire:(BOOL)_flag {
  /* first step, set visibility */

  if (self->visibility == nil) {
    if (self->calendarFolder != nil) /* contains an error */
      return self->calendarFolder;
    
    self->calendarFolder =
      [[self calendarFolderForVisibility:_name inContext:_ctx]
             retain];
    if (self->calendarFolder == nil || 
	[self->calendarFolder isKindOfClass:[NSException class]])
      return nil;
    
    self->visibility = [_name copy];
    return self;
  }

  /* next step, set projection */

  if (self->projection == nil) {
    self->projection = [_name copy];
    return self;
  }
  
  /* now we either have an event-id in the URL or its a method */

  if (isdigit([_name characterAtIndex:0]))
    return [self lookupEvent:_name inContext:_ctx];
  
  /* treat everything else like a method */
  
  return [super lookupName:_name inContext:_ctx acquire:NO];
}

/* actions */

- (id)GETAction:(WOContext *)_ctx {
  WOResponse *r = [_ctx response];
  [self appendToResponse:r inContext:_ctx];
  return r;
}

/* response generation */

- (void)appendEntry:(id)_info
  toResponse:(WOResponse *)_r inContext:(WOContext *)_ctx
{
  NSCalendarDate *date;
  NSString *entryURL, *s;

  // [self logWithFormat:@"INFO: %@", _info];
  
  entryURL = [self baseURLInContext:_ctx];
  entryURL = [entryURL stringByAppendingFormat:@"/%@", 
		       [_info valueForKey:@"dateId"]];
  
  [_r appendContentString:@"<entry>"];
  [_r appendContentString:@"<id>"];
  [_r appendContentString:[entryURL stringByEscapingXMLString]];
  [_r appendContentString:@"</id>"];

  // TODO: 'published', 'updated' - we don't have those

  [_r appendContentString:@"<category scheme='"];
  [_r appendContentString:GScheme_Kind_2005];
  [_r appendContentString:@"' term='"];
  [_r appendContentString:GTerm_Event_2005];
  [_r appendContentString:@"'>"];
  // TODO: delivery apt-type? or the Outlook categories?
  [_r appendContentString:@"</category>"];

  if ([(s = [_info valueForKey:@"title"]) isNotEmpty]) {
    [_r appendContentString:@"<title type='text'>"];
    [_r appendContentString:[s stringByEscapingXMLString]];
    [_r appendContentString:@"</title>"];
  }

  /* content */
  
  if ([(s = [_info valueForKey:@"comment"]) isNotEmpty]) {
    // TODO: is 'comment' a relationship?
    [_r appendContentString:@"<content type='text'>"];
    [_r appendContentString:[s stringByEscapingXMLString]];
    [_r appendContentString:@"</content>"];
  }

  // TODO: links
  // link rel=alternate type=text/html href=... title=...

  [_r appendContentString:
	@"<link rel='self' type='application/atom+xml' href='"];
  [_r appendContentString:[entryURL stringByEscapingXMLString]];
  [_r appendContentString:@"' />"];

  [_r appendContentString:
	@"<link rel='edit' type='application/atom+xml' href='"];
  [_r appendContentString:[entryURL stringByEscapingXMLString]];
  [_r appendContentString:@"/"];
  [_r appendContentString:[[_info valueForKey:@"objectVersion"] stringValue]];
  [_r appendContentString:@"' />"];
  
  // TODO: author
  // map to creator

  // TODO: eventStatus

  // TODO: visibility

  /* comments */
  // full:      comments are not included inline, but specified as a feedlink
  // composite: inlined comments (<atom:feed> inside feedlink) (TODO)
  
  [_r appendContentString:@"<gd:comments><gd:feedLink href='"];
  s = [entryURL stringByAppendingString:@"/comments/"];
  [_r appendContentString:[s stringByEscapingXMLString]];
  [_r appendContentString:@"' /></gd:comments>"];

  // TODO: transparency

  /* location */
  
  if ([(s = [_info valueForKey:@"location"]) isNotEmpty]) {
    [_r appendContentString:@"<gd:where valueString=\'"];
    [_r appendContentString:[s stringByEscapingXMLString]];
    [_r appendContentString:@"' />"];
  }
  
  /* when */

  [_r appendContentString:@"<gd:when startTime='"];
  
  date = [_info valueForKey:@"startDate"];
  [date setTimeZone:utc]; // TODO: better use timezone?
  [_r appendContentString:
	[date descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z"]];

  [_r appendContentString:@"' endTime='"];
  date = [_info valueForKey:@"endDate"];
  [date setTimeZone:utc]; // TODO: better use timezone?
  [_r appendContentString:
	[date descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z"]];

  [_r appendContentString:@"'>"];
  
  s = [_info valueForKey:@"notificationTime"];
  if ([s isNotEmpty]) {
    if ([s intValue] > 0) {
      s = [s stringValue];
      [_r appendContentString:@"<gd:reminder minutres='"];
      [_r appendContentString:s];
      [_r appendContentString:@"' />"];
    }
  }
  
  [_r appendContentString:@"</gd:when>"];
  
  [_r appendContentString:@"</entry>"];
}

- (void)appendToResponse:(WOResponse *)r inContext:(WOContext *)_ctx {
  NSCalendarDate *now;
  NSString       *escapedBaseURL;
  id             account;
  int            startIndex;
  NSString       *s;
  
  account = [self accountInContext:_ctx];

  now = [NSCalendarDate date];
  [now setTimeZone:utc];

  // Note: below we assume that the URL contains no query parameters
  escapedBaseURL = [[self baseURLInContext:_ctx] stringByEscapingXMLString];

  startIndex = [[[_ctx request] formValueForKey:@"start-index"] intValue];

  /* start rendering */
  
  [r setHeader:@"application/atom+xml; charset=utf-8" forKey:@"content-type"];
  
  [r appendContentString:@"<feed xmlns=\""];
  [r appendContentString:XMLNS_ATOM_2005];
  [r appendContentString:@"\" xmlns:gCal=\""];
  [r appendContentString:XMLNS_GOOGLE_CAL_2005];
  [r appendContentString:@"\" xmlns:openSearch=\""];
  [r appendContentString:XMLNS_OPENSEARCH_RSS];
  [r appendContentString:@"\" xmlns:gd=\""];
  [r appendContentString:XMLNS_GOOGLE_2005];
  [r appendContentString:@"\">"];

  [r appendContentString:@"<id>"];
  [r appendContentString:escapedBaseURL];
  [r appendContentString:@"</id>"];

  /* 
     We always use the current time since we can't keep track of a set of
     records yet (this would be the 'folder version', see SxFolder).
  */
  [r appendContentString:@"<updated>"];
  [r appendContentString:
       [now descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%S.000Z"]];
  [r appendContentString:@"</updated>"];

  /* title */
  // TODO: improve

  [r appendContentString:@"<title type='text'>"];
  [r appendContentString:[[_ctx activeUser] login]];
  [r appendContentString:@"</title>"];
  [r appendContentString:@"<subtitle type='text'>"];
  [r appendContentString:[[_ctx activeUser] login]];
  [r appendContentString:@"</subtitle>"];
  
  /* links */

  [r appendContentString:@"<link rel='"];
  [r appendContentString:GLinkType_Feed_2005];
  [r appendContentString:@"' type='application/atom+xml' href='"];
  [r appendContentString:
       [[self feedURLInContext:_ctx] stringByEscapingXMLString]];
  [r appendContentString:@"' />"];
  
  [r appendContentString:@"<link rel='"];
  [r appendContentString:GLinkType_Post_2005];
  [r appendContentString:@"' type='application/atom+xml' href='"];
  [r appendContentString:
       [[self postURLInContext:_ctx] stringByEscapingXMLString]];
  [r appendContentString:@"' />"];
  
  // TODO: fix cursor parameters in 'self' and 'next', this depends on the
  //       current value

  [r appendContentString:
       @"<link rel='self' type='application/atom+xml' href='"];
  [r appendContentString:
       [[self selfURLInContext:_ctx] stringByEscapingXMLString]];
  [r appendContentString:@"' />"];

  [r appendContentString:
       @"<link rel='next' type='application/atom+xml' href='"];
  [r appendContentString:
       [[self nextURLInContext:_ctx] stringByEscapingXMLString]];
  [r appendContentString:@"' />"];
  
  /* author */
  /*   the author of a feed is the login ... */
  
  [r appendContentString:@"<author><name>"];
  if ([(s = [account valueForKey:@"firstname"]) isNotEmpty]) {
    [r appendContentString:[s stringByEscapingXMLString]];
    [r appendContentString:@" "];
  }
  if ([(s = [account valueForKey:@"name"]) isNotEmpty])
    [r appendContentString:[s stringByEscapingXMLString]];
  [r appendContentString:@"</name>"];

  if ([(s = [account valueForKey:@"email1"]) isNotEmpty]) {
    [r appendContentString:@"<email>"];
    [r appendContentString:[s stringByEscapingXMLString]];
    [r appendContentString:@"</email>"];
  }
  [r appendContentString:@"</author>"];

  /* generator */
  
  [r appendContentString:@"<generator version=\"1.5\" uri=\""];
  [r appendContentString:@"http://www.opengroupware.org/"];
  [r appendContentString:@"\">OpenGroupware.org</generator>"];
  
  [r appendContentString:@"<openSearch:itemsPerPage>"];
  [r appendContentString:[self numberOfItemsPerPageAsString]];
  [r appendContentString:@"</openSearch:itemsPerPage>"];
  
  [r appendContentString:@"<gCal:timezone xmlns:gCal=\""];
  [r appendContentString:XMLNS_GOOGLE_CAL_2005];
  [r appendContentString:@"\" value=\""];
  [r appendContentString:@"Europe/Berlin"]; // TODO: retrieve from user-defs
  [r appendContentString:@"\" />"];
  
  /* fetch full info */
  // TODO: improve fetches (base on projection, fetch proper things)
  //       probably we want to look at the backend commands
  {
    SxAptManager *backend;
    NSArray      *infos;
    unsigned     i, count;
    
    backend = [self->calendarFolder aptManagerInContext:_ctx];
    infos   = [backend gidsOfAppointmentSet:[self->calendarFolder aptSetID]];
    infos   = [backend zlAppointmentsWithIDs:infos];
    
    for (i = 0, count = [infos count]; i < count; i++) {
      [self appendEntry:[infos objectAtIndex:i] toResponse:r inContext:_ctx];
    }
  }

  [r appendContentString:@"</feed>"];
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return YES; // TODO: make that a default
}

- (NSString *)description {
  NSMutableString *ms = [NSMutableString stringWithCapacity:128];
  
  [ms appendFormat:@"<%p[%@]:", self, NSStringFromClass([self class])];
  
  [ms appendFormat:@" name='%@'", [self nameInContainer]];
  [ms appendFormat:@" projection=%@", [self projection]];
  [ms appendFormat:@" visibility=%@", [self visibility]];
  
  [ms appendString:@">"];
  return ms;
}

@end /* GCalCalendar */
