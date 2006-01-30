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

@class EOGlobalID;
@class LSCommandContext;

@interface OGoAptFormLetter : WODirectAction
{
  LSCommandContext *cmdctx;
  EOGlobalID *gid;
}

@end

#include <NGObjWeb/WORequest.h>
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
  [self->cmdctx release];
  [self->gid    release];
  [super dealloc];
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
  return @"%Y-%m-%d %H:%M";
}

- (NSString *)stringValueForObject:(id)_obj ofKey:(NSString *)_key {
  if (![_obj isNotNull])
    return @"";
  
  if ([_obj isKindOfClass:[NSDate class]]) {
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

- (void)applyBindingsForCompany:(id)_company ofAppointment:(id)_aptEO
  onDictionary:(NSMutableDictionary *)_md
{
  NSDictionary *d;
  NSEnumerator *e;
  NSString     *key;
  id address;
  
  /* company EO */
  
  d = [_company valuesForKeys:personKeys];
  e = [d keyEnumerator];
  while ((key = [e nextObject]) != nil) {
    [_md setObject:[self stringValueForObject:[d objectForKey:key] ofKey:key]
	 forKey:key];
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

- (void)appendPreambleToResponse:(WOResponse *)_r {
}
- (void)appendPostambleToResponse:(WOResponse *)_r {
}

- (void)appendRecord:(NSDictionary *)_bindings toResponse:(WOResponse *)_r {
  [_r appendContentString:[_bindings description]];
  [_r appendContentString:@"\n"];
}

- (void)appendAttendees:(NSArray *)_contacts ofAppointment:(id)_aptEO
  toResponse:(WOResponse *)_r
{
  NSMutableDictionary *bindings;
  unsigned i, count;
  
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
    [self appendRecord:bindings toResponse:_r];
    
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
  
  [self appendPreambleToResponse:r];
  [self appendAttendees:[apt valueForKey:@"participants"] 
	ofAppointment:apt
	toResponse:r];
  [self appendPostambleToResponse:r];
  
  return r;
}

@end /* OGoAptFormLetter */
