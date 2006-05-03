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

#include "OGoAptMailOpener.h"
#include <OGoFoundation/LSWMailEditorComponent.h>
#include "common.h"

@interface WOComponent(MailEditorPage)
- (void)setIsAppointmentNotification:(BOOL)_flag;
@end


@implementation OGoAptMailOpener

static int        isMailEnabled = -1; // THREAD
static NSNumber   *yesNum     = nil;
static NSNumber   *noNum      = nil;
static NGMimeType *eoDateType = nil;

+ (void)initialize {
  yesNum = [[NSNumber numberWithBool:YES] retain];
  noNum  = [[NSNumber numberWithBool:NO]  retain];
  
  if (eoDateType == nil)
    eoDateType = [[NGMimeType mimeType:@"eo" subType:@"date"] copy];
}

+ (BOOL)isMailEnabled {
  if (isMailEnabled == -1) {
    NGBundleManager *bm;
    
    bm = [NGBundleManager defaultBundleManager];
    if ([bm bundleProvidingResource:@"LSWImapMailEditor"
            ofType:@"WOComponents"] != nil)
      isMailEnabled = 1;
    else {
      isMailEnabled = 0;
      NSLog(@"OGoAptMailOpener: did not find LSWImapMailEditor!");
    }
  }
  return isMailEnabled ? YES : NO;
}


+ (id)mailEditorForObject:(id)_object action:(NSString *)_action
  page:(OGoComponent *)_component
{
  OGoAptMailOpener *opener;
  
  opener = [self mailOpenerForObject:_object action:_action page:_component];
  return [opener mailEditor];
}


+ (id)mailOpenerForObject:(id)_object action:(NSString *)_action
  page:(OGoComponent *)_component
{
  OGoAptMailOpener *opener;
  
  if (![self isMailEnabled])
    return nil;
  
  opener = [[OGoAptMailOpener alloc] 
	     initWithObject:_object action:_action page:_component];
  return [opener autorelease];
}

- (id)initWithObject:(id)_object action:(NSString *)_action
  page:(OGoComponent *)_component
{
  if ((self = [super init]) != nil) {
    if (_object == nil) {
      [self errorWithFormat:@"got passed no object."];
      [self release];
      return nil;
    }

    self->object   = [_object    retain];
    self->action   = [_action    copy];
    self->page     = [_component retain];
    
    self->defaults = [[[_component session] userDefaults] retain];
    self->labels   = [[_component labels] retain];

    self->cmdctx   = [(OGoSession *)[_component session] commandContext];
    
    /* Important: 'comment' and 'participants' must be fetched! */
    self->comment      = [[_component valueForKey:@"comment"] copy];
    self->participants = [[_component valueForKey:@"participants"] retain];
  }
  return self;
}

- (id)init {
  return [self initWithObject:nil action:nil page:nil];
}

- (void)dealloc {
  [self->templateBindings release];
  [self->defaults     release];
  [self->labels       release];
  [self->cmdctx       release];
  [self->page         release];
  [self->participants release];
  [self->comment      release];
  [self->action       release];
  [self->object       release];
  [super dealloc];
}

/* common functionality */

- (id)labels {
  return self->labels;
}

- (id)pageWithName:(NSString *)_name {
  return [self->page pageWithName:_name];
}

/* configurations */

- (NSUserDefaults *)userDefaults {
  return self->defaults;
}

- (NSString *)ccForNotificationMails {
  // TODO: check whether we can use -stringForKey:
  //       (maybe it can return an array)
  return [[self userDefaults]
	        objectForKey:@"scheduler_ccForNotificationMails"];
}

- (NSString *)mailTemplateDateFormat {
  return [[self userDefaults]
	        stringForKey:@"scheduler_mail_template_date_format"];
}

- (BOOL)shouldAttachAppointmentsToMails {
  id val;
  
  val = [self->defaults valueForKey:@"scheduler_attach_apts_to_mails"];
  if (val == nil) return YES;
  return [val boolValue];
}


/* commands */

- (id)_fetchAccountForPrimaryKey:(id)_pkey {
  id c;
  if (_pkey == nil) return nil;
  
  c = [self->cmdctx runCommand:@"account::get", @"companyId", _pkey, nil];
  if ([c isKindOfClass:[NSArray class]])
    c = [c lastObject];
  return c;
}


/* formatting objects */

- (NSString *)_personName:(id)_person {
  // TODO: this should be a formatter!
  NSString *n, *f;
  
  if (_person == nil)
    return @"";
  if ([[_person valueForKey:@"isTeam"] boolValue])
    return [_person valueForKey:@"description"];
  
  n = [_person valueForKey:@"name"];
  f = [_person valueForKey:@"firstname"];
  if ([n isNotNull] && [f isNotNull]) {
    NSMutableString *str;
    
    str = [NSMutableString stringWithCapacity:64];
    [str appendString:f];
    [str appendString:@" "];
    [str appendString:n];
    return str;
  }
  
  if ([n isNotNull]) return n;
  if ([f isNotNull]) return f;
  return @"";
}

- (NSString *)stringByJoiningParticipantNames:(NSArray *)_parts {
  NSEnumerator    *enumerator;
  id              part;
  NSMutableString *str;
  
  if (![_parts isNotNull]) return nil;
  
  str        = nil;
  enumerator = [_parts objectEnumerator];
  
  while ((part = [enumerator nextObject])) {
    if (str == nil)
      str = [NSMutableString stringWithCapacity:128];
    else
      [str appendString:@", "];
      
    [str appendString:[self _personName:part]];
  }
  return str;
}


/* setup */

- (NSDictionary *)templateBindingsForAppointment:(id)obj {
  /* TODO: move to method, split up */
  NSMutableDictionary *bindings;
  id                  c;
  NSString            *format, *title, *location, *resNames;
  NSCalendarDate      *sd, *ed;
  
  format = [self mailTemplateDateFormat];
  
  sd = [obj valueForKey:@"startDate"];
  if (format != nil && [sd isNotNull])
    [sd setCalendarFormat:format];
  ed = [obj valueForKey:@"endDate"];
  if (format != nil && [ed isNotNull])
    [ed setCalendarFormat:format];
  
  bindings = [NSMutableDictionary dictionaryWithCapacity:8];
  [bindings setObject:sd forKey:@"startDate"];
  [bindings setObject:ed forKey:@"endDate"];
  
  if ((title = [obj valueForKey:@"title"]) != nil)
    [bindings setObject:title forKey:@"title"];
  if ((location = [obj valueForKey:@"location"]) != nil)
    [bindings setObject:location forKey:@"location"];
  if ((resNames = [obj valueForKey:@"resourceNames"]) != nil)
    [bindings setObject:resNames forKey:@"resourceNames"];        
  
  [bindings setObject:
	      ([self->comment isNotNull] ? self->comment : (NSString *)@"")
	    forKey:@"comment"];
  
  /* set creator */
  
  c = [self _fetchAccountForPrimaryKey:[obj valueForKey:@"ownerId"]];
  [bindings setObject:[self _personName:c] forKey:@"creator"];
  
  /* set participants */
  
  c = [self stringByJoiningParticipantNames:
	      [obj valueForKey:@"participants"]];
  if (c != nil) [bindings setObject:c forKey:@"participants"];
  
  /* add some labels */
  
  if ((c = [self->labels valueForKey:@"appointment"]) != nil)
    [bindings setObject:c forKey:@"label_apt"];
  
  /* action and action-label */
  
  if ([self->action isNotEmpty]) {
    [bindings setObject:self->action forKey:@"action"];
    if ((c = [self->labels valueForKey:self->action]) != nil)
      [bindings setObject:c forKey:@"label_action"];
  }
  
  return bindings;
}

- (NSDictionary *)templateBindings {
  if (self->templateBindings == nil) {
    self->templateBindings =
      [[self templateBindingsForAppointment:self->object] copy];
  }
  return self->templateBindings;
}

- (NSString *)contentForTemplateOfDefault:(NSString *)_defName {
  NSString *s;
  
  s = [[self userDefaults] stringForKey:_defName];
  if ([s isNotEmpty]) {
    s = [s stringByReplacingVariablesWithBindings:[self templateBindings]
	   stringForUnknownBindings:@""];
  }
  else
    s = @"";
  return s;
}

- (NSString *)mailSubject {
  /*
    Actions: created, edited, deleted, moved
  */
  return [self contentForTemplateOfDefault:@"scheduler_mailsubject_template"];
}

- (NSString *)mailContent {
  return [self contentForTemplateOfDefault:@"scheduler_mail_template"];
}

- (void)_addParticipants:(NSArray *)_ps toMailEditor:(id)mailEditor {
  NSEnumerator *recEn;
  id           rec;
  BOOL         first;
  
  recEn = [_ps objectEnumerator];
  for (first = YES; (rec = [recEn nextObject]) != nil;) {
    if (first) {
      [mailEditor addReceiver:rec];
      first = NO;
    }
    else 
      [mailEditor addReceiver:rec type:@"cc"];
  }
}

- (OGoContentPage *)mailEditor {
  id<LSWMailEditorComponent, OGoContentPage> mailEditor;
  NSString *cc;
  
  if (![[self class] isMailEnabled]) {
    [self warnWithFormat:@"mail is not enabled, not entering the editor .."];
    return nil;
  }

  if ((mailEditor = (id)[self pageWithName:@"LSWImapMailEditor"]) == nil) {
    [self logWithFormat:@"did not find mail editor component"];
    return nil;
  }
  
  // TODO: document this specialty
  
  if ([self->action isEqualToString:@"created"])
    [(WOComponent *)mailEditor setIsAppointmentNotification:YES];
  
  /* set default cc */
  
  cc = [self ccForNotificationMails];
  if ([cc isNotEmpty]) [mailEditor addReceiver:cc type:@"cc"];
  
  /* subject and content */
  
  [mailEditor setSubject:[self mailSubject]];
  [mailEditor setContentWithoutSign:[self mailContent]];

  /* recipients */

  [self _addParticipants:self->participants toMailEditor:mailEditor];
  
  /* attach appointment */
  
  [mailEditor addAttachment:self->object type:eoDateType
	      sendObject:([self shouldAttachAppointmentsToMails]
			  ? yesNum : noNum)];
#if 0 /* this was in saveAndSendMail */
  attach = [self shouldAttachAppointmentsToMails];
  if (!attach) {
    str = [template stringByTrimmingWhiteSpaces];
    [mailEditor addAttachment:obj type:eoDateType
                sendObject:[str isNotEmpty] ? noNum : yesNum];
  }
  else 
    [mailEditor addAttachment:obj type:eoDateType];
#endif
  
  return (OGoContentPage *)mailEditor;
}

@end /* OGoAptMailOpener */
