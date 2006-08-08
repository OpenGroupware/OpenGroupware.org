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

#include <OGoFoundation/OGoComponent.h>

/* 
   OGoPersonQCreatePanel
   
   This component manages a person-creation form in a separate HTML windows.
   
   The panel needs to deal carefully with the main page which is open in the
   navigational stack and indeed should refresh the main page if possible to
   ensure a consistent WO transaction state.
*/

@interface OGoPersonQCreatePanel : OGoComponent
{
  NSMutableDictionary *values;
}

@end

#include <OGoContacts/SkyPersonDataSource.h>
#include <NGExtensions/NSString+Ext.h>
#include "common.h"

@implementation OGoPersonQCreatePanel

static NSString *qCreateAddrType = @"mailing";

+ (void)initialize {
  NSAssert2([super version] == 2,
            @"invalid superclass (%@) version %i !",
            NSStringFromClass([self superclass]), [super version]);
}

- (id)init {
  if ((self = [super init]) != nil) {
    self->values = [[NSMutableDictionary alloc] initWithCapacity:16];
  }
  return self;
}

- (void)dealloc {
  [self->values release];
  [super dealloc];
}

/* accessors */

- (NSMutableDictionary *)values {
  return self->values;
}

/* session management for separate page */

- (id)session {
  /*
    Note: This is a hack to avoid that the OGoComponent automatically creates
          a session.
	  This component should never create a session (sessions should be
	  created by the login action).
	  
    Sideeffect: OGoComponent will reset the session of this component
                if any session expires (should be ok).
  */
  if ([[self context] hasSession])
    return [super session];
  
  return nil;
}

/* notifications */

- (NSNotificationCenter *)notificationCenter {
  static NSNotificationCenter *nc = nil;
  if (nc == nil) nc = [[NSNotificationCenter defaultCenter] retain];
  return nc;
}

- (void)postPersonCreated:(id)_person {
  [[self notificationCenter] postNotificationName:SkyNewPersonNotification
                             object:_person];
}

/* handle record */

- (NSArray *)_createPhoneRecords {
  NSMutableArray *phones;
  NSDictionary   *tel;
  NSString       *s;

  phones = [NSMutableArray arrayWithCapacity:2];
  
  if ([(s = [self->values objectForKey:@"01_tel"]) isNotEmpty]) {
    tel = [[NSDictionary alloc] initWithObjectsAndKeys:
				  s, @"number", @"01_tel", @"type", nil];
    [phones addObject:tel];
    [tel release]; tel = nil;
  }
  if ([(s = [self->values objectForKey:@"03_tel_funk"]) isNotEmpty]) {
    tel = [[NSDictionary alloc] initWithObjectsAndKeys:
				  s, @"number", @"03_tel_funk", @"type", nil];
    [phones addObject:tel];
    [tel release]; tel = nil;
  }
  
  return phones;
}

- (id)updateAddressOfContact:(id)_eo {
  NSMutableDictionary *avalues;
  NSString *n, *fn, *ln;
  id       addr;

  /* fetch existing address EO */
  
  addr = [self runCommand:@"address::get",
	         @"companyId",  [_eo valueForKey:@"companyId"],
	         @"type",       qCreateAddrType,
	         @"operator",   @"AND",
  	         @"comparator", @"EQUAL",
	       nil];
  if ([addr isKindOfClass:[NSArray class]])
    addr = [addr isNotEmpty] ? [addr lastObject] : nil;

  /* setup values */
  
  avalues = [NSMutableDictionary dictionaryWithCapacity:16];
  [avalues setObject:qCreateAddrType                forKey:@"type"];
  [avalues setObject:[_eo valueForKey:@"companyId"] forKey:@"companyId"];
  
  fn = [self->values objectForKey:@"firstname"];
  ln = [self->values objectForKey:@"name"];
  if ([fn isNotEmpty] && [ln isNotEmpty])
    n = [[fn stringByAppendingString:@" "] stringByAppendingString:ln];
  else if ([fn isNotEmpty])
    n = fn;
  else if ([ln isNotEmpty])
    n = ln;
  else
    n = nil;
  if ([n isNotEmpty])
    [avalues setObject:n forKey:@"name1"];

  if ([(n = [self->values objectForKey:@"street"]) isNotEmpty])
    [avalues setObject:n forKey:@"street"];
  if ([(n = [self->values objectForKey:@"zip"]) isNotEmpty])
    [avalues setObject:n forKey:@"zip"];
  if ([(n = [self->values objectForKey:@"city"]) isNotEmpty])
    [avalues setObject:n forKey:@"city"];
  
  /* update/create address */
  
  if (addr == nil)
    addr = [self runCommand:@"address::new" arguments:avalues];
  else {
    [avalues setObject:addr forKey:@"object"];
    [self runCommand:@"address::set" arguments:avalues];
  }
  
  return addr;
}

- (id)createPersonRecord {
  NSNumber *loginId;
  NSString *fn, *ln, *em1, *sal;
  id eo;
  
  loginId = [[[self existingSession] activeAccount] valueForKey:@"companyId"];

  if ((sal = [self->values objectForKey:@"salutation"]) == nil)
    sal = (id)[NSNull null];
  
  if ((fn = [self->values objectForKey:@"firstname"]) == nil)
    fn = (id)[NSNull null];
  if ((ln = [self->values objectForKey:@"name"]) == nil) 
    ln = (id)[NSNull null];
  if ((em1 = [self->values objectForKey:@"email1"]) == nil)
    em1 = (id)[NSNull null];

  /* create record */
  
  eo = [self runCommand:@"person::new",
	       @"firstname",  fn,
	       @"name",       ln, 
	       @"salutation", sal,
	       @"email1",     em1,
	       @"ownerId",    loginId,
	       @"telephones", [self _createPhoneRecords],
	     nil];
  
  [self updateAddressOfContact:eo];
  
  [self postPersonCreated:eo];

  return eo;
}

- (void)_cleanupValues {
  NSDictionary *vs;
  NSEnumerator *keys;
  NSString *k;
  
  vs = [self->values copy];
  
  keys = [vs keyEnumerator];
  while ((k = [keys nextObject]) != nil) {
    NSString *v;
    
    v = [vs objectForKey:k];
    if ([v isNotEmpty])
      v = [v stringByTrimmingSpaces];
    
    if ([v isNotEmpty])
      [self->values setObject:v forKey:k];
    else
      [self->values removeObjectForKey:k];
  }
}

/* actions */

- (BOOL)shouldTakeValuesFromRequest:(WORequest *)_rq inContext:(WOContext*)_c {
  return YES;
}

- (NSException *)validateForSave {
  if (![[self->values objectForKey:@"name"] isNotEmpty]) {
    return [NSException exceptionWithName:@"MissingName"
			reason:@"Missing name field"
			userInfo:nil];
  }
  return nil;
}

- (id)saveAction {
  WOResponse  *r;
  NSException *error;
  id eo;
  
  [self _cleanupValues];
  
  if ((error = [self validateForSave]) != nil)
    // TODO: show error
    return self;
  
  eo = [self createPersonRecord];
  [self->values removeAllObjects]; // clear editor

  r = [[self context] response];
  
  [r setHeader:@"text/html" forKey:@"content-type"];

  [r appendContentString:@"<html><head>"];
  [r appendContentString:@"<script language='JavaScript'>\n"];

  /* close panel window */
  [r appendContentString:@"window.close()\n"];
  
  /* refresh apt editor with new participant */
  
  // TODO: make this configurable to allow usage of the panel in different
  //       contexts
  [r appendContentString:@"opener.LSWAptEditor_addNewContact("];
  [r appendContentString:[[eo valueForKey:@"companyId"] stringValue]];
  [r appendContentString:@");\n"];
  
  [r appendContentString:@"</script></head><body></body></html>"];
  return r;
}

@end /* OGoPersonQCreatePanel */
