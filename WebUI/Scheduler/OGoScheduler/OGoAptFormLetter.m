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

#import <NGObjWeb/WODirectAction.h>

/*
  OGoAptFormLetter
  
  This is a direct action which renders a textfile from an appointment for use
  in serial letters.
*/

@class NSString;
@class EOGlobalID;
@class LSCommandContext;

@interface OGoAptFormLetter : WODirectAction
{
  LSCommandContext *cmdctx;
  EOGlobalID *gid;
  NSString   *formLetterType;
}

@end

#include <NGObjWeb/WORequest.h>
#include <NGObjWeb/WOResourceManager.h>
#include <LSFoundation/LSFoundation.h>
#include "common.h"

@implementation OGoAptFormLetter

static NSArray *personKeys = nil;
static NSArray *aptKeys    = nil;

- (id)initWithContext:(WOContext *)_ctx {
  if ((self = [super initWithContext:_ctx]) != nil) {
    // TODO: for unknown reasons this doesn't work in +initialize ...
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
    if (personKeys == nil)
      personKeys = [[ud arrayForKey:@"schedulerformletter_personkeys"] copy];
    if (aptKeys == nil)
      aptKeys    = [[ud arrayForKey:@"schedulerformletter_aptkeys"]    copy];
  
    if (personKeys == nil)
      NSLog(@"OGoAptFormLetter: missing person formletter key definitions ..");
    if (aptKeys == nil)
      NSLog(@"OGoAptFormLetter: missing apt formletter key definitions ..");
  }
  return self;
}

- (void)dealloc {
  [self->formLetterType release];
  [self->cmdctx release];
  [self->gid    release];
  [super dealloc];
}


/* definition */

- (NSDictionary *)formLetterDefinitionForType:(NSString *)_type {
  static NSDictionary *def = nil;
  
  if (def == nil) {
    def = [[[NSUserDefaults standardUserDefaults] 
	     dictionaryForKey:@"OGoSchedulerFormLetterTypes"] copy];
    if (def == nil)
      [self errorWithFormat:@"did not find OGoSchedulerFormLetterTypes!"];
  }
  return [_type isNotNull] ? [def objectForKey:_type] : nil;
}

- (NSDictionary *)formLetterDefinition {
  return [self formLetterDefinitionForType:self->formLetterType];
}

- (NSString *)fieldSeparator {
  return [[self formLetterDefinition] valueForKey:@"fieldSeparator"];
}
- (NSString *)lineSeparator {
  return [[self formLetterDefinition] valueForKey:@"lineSeparator"];
}
- (NSString *)quoteFields {
  return [[self formLetterDefinition] valueForKey:@"quoteFields"];
}

- (id)preamble {
  return [[self formLetterDefinition] valueForKey:@"preamble"];
}
- (id)postamble {
  return [[self formLetterDefinition] valueForKey:@"postamble"];
}

- (id)linePattern {
  return [[self formLetterDefinition] valueForKey:@"line"];
}

- (id)dateFormat {
  id s;
  
  s = [[self formLetterDefinition] valueForKey:@"dateformat"];
  if ([s isNotEmpty])
    return s;
  
  return @"%Y-%m-%d %H:%M";
}


/* filter */

- (BOOL)includeAccounts {
  return NO;
}
- (BOOL)includeTeams {
  return NO;
}


/* derive binding dictionary from a record */

- (NSString *)calendarFormatForKey:(NSString *)_key {
  id df;
  
  df = [self dateFormat];
  if ([df isKindOfClass:[NSDictionary class]]) {
    NSString *s;
    
    if ((s = [df objectForKey:_key]) != nil)
      return s;
    if ((s = [df objectForKey:@"*"]) != nil)
      return s;
    if ((s = [df objectForKey:@""]) != nil)
      return s;
    
    return @"%Y-%m-%d %H:%M";
  }

  return [df stringValue];
}

- (NSString *)stringValueForObject:(id)_obj ofKey:(NSString *)_key {
  if (![_obj isNotNull])
    return @"";
  
  if ([_obj isKindOfClass:[NSDate class]]) {
    [_obj setTimeZone:[(OGoSession *)[self session] timeZone]];
    return [_obj descriptionWithCalendarFormat:
		   [self calendarFormatForKey:_key]];
  }
  
  return [_obj stringValue];
}

- (void)applyBindingsOfAddress:(id)_address
  onDictionary:(NSMutableDictionary *)_md
{
  static NSString *keys[] = {
    @"name1", @"name2", @"name3",
    @"street", @"city", @"state", @"country", @"zip",
    nil
  };
  NSString *p;
  unsigned i;
  
  p = [[_address valueForKey:@"type"] stringByAppendingString:@"_"];
  for (i = 0; keys[i] != nil; i++) {
    NSString *pk;
    
    pk = [p stringByAppendingString:keys[i]];
    [_md setObject:[self stringValueForObject:[_address valueForKey:keys[i]] 
			 ofKey:pk]
	 forKey:pk];
  }
}

- (WOResourceManager *)resourceManager {
  return [[[self context] application] resourceManager];
}

- (void)applyBindingsForCompany:(id)_company ofAppointment:(id)_aptEO
  onDictionary:(NSMutableDictionary *)_md
{
  WOResourceManager *rm;
  NSDictionary *d;
  NSEnumerator *e;
  NSString     *key;
  id address;
  
  rm = [self resourceManager];
  
  /* company EO */
  
  d = [_company valuesForKeys:personKeys];
  e = [d keyEnumerator];
  while ((key = [e nextObject]) != nil) {
    [_md setObject:[self stringValueForObject:[d objectForKey:key] ofKey:key]
	 forKey:key];
  }
  
  /* fixup some localized fields */
  
  if ([(key = [_md objectForKey:@"sex"]) isNotEmpty]) {
    key = [rm stringForKey:key inTableNamed:@"PersonsUI"
	      withDefaultValue:key languages:[[self session] languages]];
    [_md setObject:key forKey:@"sex"];
  }
  if ([(key = [_md objectForKey:@"salutation"]) isNotEmpty]) {
    key = [rm stringForKey:key inTableNamed:@"PersonsUI"
	      withDefaultValue:key languages:[[self session] languages]];
    [_md setObject:key forKey:@"salutation"];
  }
  
  /* addresses */

  e = [[_company valueForKey:@"toAddress"] objectEnumerator];
  while ((address = [e nextObject]) != nil)
    [self applyBindingsOfAddress:address onDictionary:_md];
  
  /* appointment EO */
  
  d = [_aptEO valuesForKeys:aptKeys];
  e = [d keyEnumerator];
  while ((key = [e nextObject]) != nil) {
    [_md setObject:[self stringValueForObject:[d objectForKey:key] ofKey:key]
	 forKey:key];
  }
}


/* content generation */

- (NSString *)formLetterContentType {
  return @"text/plain";
}

- (void)appendLine:(id)_line withBindings:(NSDictionary *)_bindings
  toResponse:(WOResponse *)_r
{
  /* Note: be careful with trimming spaces, they could be intended in CSV! */
  NSString *s;

  if (![_line isNotNull])
    return;
  
  if ([_line isKindOfClass:[NSArray class]]) {
    /* special support for CSV */
    unsigned i, count;
    NSString *fs, *quote;
    
    fs    = [self fieldSeparator];
    quote = [self quoteFields];
    
    for (i = 0, count = [_line count]; i < count; i++) {
      NSString *pat;
      
      if (i > 0 && fs != nil)
	[_r appendContentString:fs];
      
      pat = [_line objectAtIndex:i];
      if ([_bindings isNotEmpty]) {
	pat = [pat stringByReplacingVariablesWithBindings:_bindings
		   stringForUnknownBindings:@""];
      }

      if (quote != nil) /* open quote */
	[_r appendContentString:quote];
      
      if (pat != nil) [_r appendContentString:pat];
      
      if (quote != nil) /* close quote */
	[_r appendContentString:quote];
    }
  }
  else {
    _line = [_line stringValue];
    
    if ([_bindings isNotEmpty]) {
      // TODO: we might need to escape the bindings?
      _line = [_line stringByReplacingVariablesWithBindings:_bindings
		     stringForUnknownBindings:@""];
    }
    [_r appendContentString:_line];
  }
  
  /* finish record */
  
  if ((s = [self lineSeparator]) != nil)
    [_r appendContentString:s];
}

static int sortContact(id eo1, id eo2, void *ctx) {
  NSString *s1, *s2;
  NSComparisonResult r;
  
  s1 = [eo1 valueForKey:@"name"];
  s2 = [eo2 valueForKey:@"name"];
  if (![s2 isNotNull]) return NSOrderedAscending;
  if (![s1 isNotNull]) return NSOrderedDescending;
  if ((r = [s1 compare:s2]) != NSOrderedSame) return r;
  
  s1 = [eo1 valueForKey:@"firstname"];
  s2 = [eo2 valueForKey:@"firstname"];
  if (![s2 isNotNull]) return NSOrderedAscending;
  if (![s1 isNotNull]) return NSOrderedDescending;
  if ((r = [s1 compare:s2]) != NSOrderedSame) return r;
  
  return NSOrderedSame;
}

- (void)appendAttendees:(NSArray *)_contacts ofAppointment:(id)_aptEO
  toResponse:(WOResponse *)_r
{
  NSMutableDictionary *bindings;
  unsigned i, count;
  
  _contacts = [_contacts sortedArrayUsingFunction:sortContact context:nil];
  
  bindings = [NSMutableDictionary dictionaryWithCapacity:32];
  
  for (i = 0, count = [_contacts count]; i < count; i++) {
    id companyEO;

    companyEO = [_contacts objectAtIndex:i];

    /* filter */
    
    if (![self includeTeams]) {
      if ([[companyEO valueForKey:@"isTeam"] boolValue])
	continue;
    }
    if (![self includeAccounts]) {
      if ([[companyEO valueForKey:@"isAccount"] boolValue])
	continue;
    }
    
    /* setup bindings */
    
    [bindings removeAllObjects];
    
    [self applyBindingsForCompany:companyEO
	  ofAppointment:_aptEO
	  onDictionary:bindings];
    [self appendLine:[self linePattern] withBindings:bindings toResponse:_r];
    
    [bindings removeAllObjects];
  }
}

/* actions */

- (id<WOActionResults>)defaultAction {
  WOResponse *r;
  NSString   *s;
  id apt;

  /* setup environment */
  
  if (![[self context] hasSession]) {
    [self errorWithFormat:@"missing session."];
    return nil;
  }
  
  if ((self->cmdctx = [[[self session] commandContext] retain]) == nil) {
    [self errorWithFormat:@"missing command context."];
    return nil;
  }
  
  self->formLetterType =
    [[[[self context] request] formValueForKey:@"type"] copy];
  if (![self->formLetterType isNotEmpty]) {
    [self errorWithFormat:@"missing formletter 'type' parameter."];
    return nil;
  }
  
  s = [[[self context] request] formValueForKey:@"oid"];
  self->gid = [[[self->cmdctx typeManager] globalIDForPrimaryKey:s] retain];
  if (self->gid == nil) {
    [self errorWithFormat:@"did not find global-id for oid %@.", s];
    return nil;
  }

  /* fetch appointment */
  
  apt = [self->cmdctx runCommand:@"appointment::get-by-globalid",
	     @"gid", self->gid, nil];
  
  /* generate response */
  
  r = [[self context] response];
  [r setHeader:[self formLetterContentType] forKey:@"content-type"];
  
  [self appendLine:[self preamble] withBindings:nil toResponse:r];
  
  [self appendAttendees:[apt valueForKey:@"participants"] 
	ofAppointment:apt
	toResponse:r];
  
  [self appendLine:[self postamble] withBindings:nil toResponse:r];
  
  return r;
}

@end /* OGoAptFormLetter */
