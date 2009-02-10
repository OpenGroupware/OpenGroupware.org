/*
  Copyright (C) 2006-2008 Helge Hess

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
#include <NGExtensions/NSString+Ext.h>
#include "common.h"

@implementation OGoAptFormLetter

static BOOL    debugOn     = NO;
static NSArray *aptKeys    = nil;

- (id)initWithContext:(WOContext *)_ctx {
  if ((self = [super initWithContext:_ctx]) != nil) {
    // TODO: for unknown reasons this doesn't work in +initialize ...
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
    if (aptKeys == nil) {
      aptKeys = [[ud arrayForKey:@"schedulerformletter_aptkeys"] copy];
      debugOn = [ud boolForKey:@"OGoSchedulerFormLetterDebugEnabled"];
    }
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
- (NSString *)quoteQuotes {
  return [[self formLetterDefinition] valueForKey:@"quoteQuotes"];
}
- (BOOL)doubleQuoteQuote {
  return [[[self formLetterDefinition] valueForKey:@"doubleQuoteQuote"]
	   boolValue];
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
  NSDictionary *df;
  
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
  
  if ([_obj isKindOfClass:[EOGenericRecord class]] ||
      [_obj isKindOfClass:[NSDictionary class]]) {
    // Note: this is kinda hackish, but well
    // its used to catch "CompanyInfo" generic records ('comment' key which
    // leads to the EOGenericRecord which in turn contains a 'comment' key)
    return [self stringValueForObject:[_obj valueForKey:_key] ofKey:_key];
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

- (void)applyBindingsOfTelephone:(id)_tel
  onDictionary:(NSMutableDictionary *)_md
{
  static NSString *keys[] = {
    @"number", @"info", @"url", @"dbStatus", nil
  };
  NSString *p;
  unsigned i;
  
  p = [[_tel valueForKey:@"type"] stringByAppendingString:@"_"];
  for (i = 0; keys[i] != nil; i++) {
    NSString *pk;
    
    pk = [p stringByAppendingString:keys[i]];
    [_md setObject:[self stringValueForObject:[_tel valueForKey:keys[i]] 
			 ofKey:pk]
	 forKey:pk];
  }
}

- (WOResourceManager *)resourceManager {
  return [[[self context] application] resourceManager];
}

- (void)applyBindingsForCompany:(NSDictionary *)_company
  addresses:(NSArray *)_addresses
  telephones:(NSArray *)_tels
  ofAppointment:(id)_aptEO
  withProperties:(NSDictionary *)_aptProps
  onDictionary:(NSMutableDictionary *)_md
{
  WOResourceManager *rm;
  NSDictionary *d;
  NSEnumerator *e;
  NSString     *key;
  id address, tel;
  
  rm = [self resourceManager];
  
  /* company EO */
  
  d = _company;
  e = [d keyEnumerator];
  while ((key = [e nextObject]) != nil) {
    [_md setObject:[self stringValueForObject:[d objectForKey:key] ofKey:key]
	 forKey:key];
  }
  
  /* fixup (rename) comment to person_comment so that it doesn't conflict */
  
  if ((key = [_md objectForKey:@"comment"]) != nil) {
    [_md setObject:key forKey:@"person_comment"];
    [_md removeObjectForKey:@"comment"];
  }
  if ((key = [_md objectForKey:@"keywords"]) != nil) {
    if ([key isNotEmpty]) {
      NSArray  *kw;
      unsigned i, count;
      
      kw = [key componentsSeparatedByString:@", "];
      for (i = 0, count = [kw count]; i < count; i++) {
	[_md setObject:[kw objectAtIndex:i] 
	     forKey:[NSString stringWithFormat:@"person_keyword%i", i + 1]];
      }
    }
    [_md setObject:key forKey:@"person_keywords"];
    [_md removeObjectForKey:@"keywords"];
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

  e = [_addresses objectEnumerator];
  while ((address = [e nextObject]) != nil)
    [self applyBindingsOfAddress:address onDictionary:_md];
  
  /* telephones */

  e = [_tels objectEnumerator];
  while ((tel = [e nextObject]) != nil)
    [self applyBindingsOfTelephone:tel onDictionary:_md];
  
  /* appointment properties */
  
  e = [_aptProps keyEnumerator];
  while ((key = [e nextObject]) != nil) {
    [_md setObject:
	   [self stringValueForObject:[_aptProps objectForKey:key] ofKey:key]
	 forKey:[key xmlLocalName]];
  }

  /* appointment EO */
  
  d = [_aptEO valuesForKeys:aptKeys];
  e = [d keyEnumerator];
  while ((key = [e nextObject]) != nil) {
    [_md setObject:[self stringValueForObject:[d objectForKey:key] ofKey:key]
	 forKey:key];
  }

  /* split up keywords (expose as keyword1, keyword2, etc) */

  if ([(key = [_md objectForKey:@"keywords"]) isNotEmpty]) {
    NSArray  *kw;
    unsigned i, count;
    
    kw = [key componentsSeparatedByString:@", "];
    for (i = 0, count = [kw count]; i < count; i++) {
      NSString *s = [[NSString alloc] initWithFormat:@"keyword%i", i + 1];
      [_md setObject:[kw objectAtIndex:i] forKey:s];
      [s release]; s = nil;
    }
  }
}


/* content generation */

- (NSString *)formLetterContentType {
  NSString *s = [[self formLetterDefinition] objectForKey:@"contenttype"];
  return [s isNotEmpty] ? s : @"text/plain";
}

- (void)appendLine:(id)_line withBindings:(NSDictionary *)_bindings
  toResponse:(WOResponse *)_r
{
  /* Note: be careful with trimming spaces, they could be intended in CSV! */
  NSString *s;

  if (![_line isNotNull])
    return;

  if ([_line isKindOfClass:[NSArray class]]) {
    /* Line is an array, special support for CSV. Each line item is treated
     * as a column.
     */
    unsigned i, count;
    NSString *fs, *ls, *quote;
    NSString *quoteQuote = nil;
    
    fs    = [self fieldSeparator]; // eg '\t'
    ls    = [self lineSeparator];  // eg '\n'
    quote = [self quoteFields];    // eg '"'
    if ([self doubleQuoteQuote])
      quoteQuote = quote;
    if (quoteQuote == nil)
      quoteQuote = @"\\";
    

    if (debugOn) {
      [self debugWithFormat:@"  field separator: %@", 
	      [fs stringByApplyingCEscaping]];
      [self debugWithFormat:@"  line separator: %@", 
	      [ls stringByApplyingCEscaping]];
    }
    
    /* for each column */
    for (i = 0, count = [_line count]; i < count; i++) {
      NSString *pat;
      
      // IMPORTANT: do NOT use isEmpty here! it strips spaces in the first char
      if (i > 0 && [fs length] != 0)
	[_r appendContentString:fs];
      
      pat = [_line objectAtIndex:i];
      if ([_bindings isNotEmpty]) {
	pat = [pat stringByReplacingVariablesWithBindings:_bindings
		   stringForUnknownBindings:@""];
      }

      /* add opening quote char */

      if ([quote isNotEmpty]) { /* open quote */
	/* check whether the column value contains the quote */
      
	if ([pat rangeOfString:quote].length > 0) {
	  /* we quote the quote with a backslash "a\"bc" */
	  // TODO: we might want to have this configurable?
	  pat = [pat stringByReplacingString:quote
		     withString:[quoteQuote stringByAppendingString:quote]];
	}
	
	[_r appendContentString:quote];
      }

      /* add column value */
      
      if (pat != nil) {
	/* Note: if the content contains the field separator, use quotes! */
	// TODO: we might want to add some escaping in addition?
	NSString *autoQuotes = nil;
	
	if (![quote isNotEmpty]) { /* quote is empty */
	  if ([fs length] > 0 && [pat rangeOfString:fs].length > 0) {
	    [self warnWithFormat:
		    @"found field separator in content, use quotes!"];
	    autoQuotes = @"\"";
	  }
	  if ([ls length] > 0 && [pat rangeOfString:ls].length > 0) {
	    [self warnWithFormat:
		    @"found line separator in content, use quotes!"];
	    autoQuotes = @"\"";
	  }
	  
	  if ([autoQuotes isNotEmpty] &&
	      [pat rangeOfString:autoQuotes].length > 0) {
	    pat = [pat stringByReplacingString:quote
		       withString:[quoteQuote stringByAppendingString:quote]];
	  }
	}
	
	if ([autoQuotes isNotEmpty]) [_r appendContentString:autoQuotes];
	[_r appendContentString:pat];
	if ([autoQuotes isNotEmpty]) [_r appendContentString:autoQuotes];
      }
      
      /* add closing quote char */
      
      if ([quote isNotEmpty]) /* close quote */
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
  withProperties:(NSDictionary *)_aptProps
  toResponse:(WOResponse *)_r
{
  NSMutableDictionary *bindings;
  unsigned i, count;
  
  _contacts = [_contacts sortedArrayUsingFunction:sortContact context:nil];
  
  bindings = [NSMutableDictionary dictionaryWithCapacity:32];

  if (debugOn) [self debugWithFormat:@"append attendees ..."];
  
  for (i = 0, count = [_contacts count]; i < count; i++) {
    NSDictionary *companyAttrs;
    NSArray      *addresses;
    NSArray      *tels;
    
    companyAttrs = [_contacts objectAtIndex:i];
    
    /* fetch addresses of company */
    
    addresses = [self->cmdctx runCommand:@"address::get",
		     @"companyId",  [companyAttrs valueForKey:@"companyId"],
		     @"returnType", intObj(LSDBReturnType_ManyObjects),
		     nil];
    tels      = [self->cmdctx runCommand:@"telephone::get",
		     @"companyId",  [companyAttrs valueForKey:@"companyId"],
		     @"returnType", intObj(LSDBReturnType_ManyObjects),
		     nil];
    
    /* filter */
    
    if (![self includeTeams]) {
      if ([[companyAttrs valueForKey:@"isTeam"] boolValue]) {
	if (debugOn) [self debugWithFormat:@"  skipping team"];
	continue;
      }
    }
    if (![self includeAccounts]) {
      if ([[companyAttrs valueForKey:@"isAccount"] boolValue]) {
	if (debugOn) [self debugWithFormat:@"  skipping account"];
	continue;
      }
    }
    
    /* setup bindings */
    
    [bindings removeAllObjects];
    
    [self applyBindingsForCompany:companyAttrs
	  addresses:addresses telephones:tels
	  ofAppointment:_aptEO withProperties:_aptProps
	  onDictionary:bindings];
    
    if (debugOn) {
      [self debugWithFormat:@"  add attendee with bindings: %@",
	    bindings];
    }
    
    [self appendLine:[self linePattern] withBindings:bindings toResponse:_r];
    
    [bindings removeAllObjects];
  }

  if (debugOn) [self debugWithFormat:@"finished appending attendees."];
}

/* actions */

- (id<WOActionResults>)defaultAction {
  WOResponse   *r;
  NSString     *s;
  NSDictionary *aptProps;
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
	     @"gid",        self->gid,
	     @"attributes", aptKeys,
	     nil];
  if ([apt isKindOfClass:[NSArray class]])
    apt = [apt lastObject];
  
  if (debugOn) [self debugWithFormat:@"fetched record: %@", apt];
  
  aptProps =
    [[self->cmdctx propertyManager] propertiesForGlobalID:
				      [apt valueForKey:@"globalID"]
				    namespace:XMLNS_OGoExtAttrPropNamespace];
  
  /* generate response */
  
  r = [[self context] response];
  [r setHeader:[self formLetterContentType] forKey:@"content-type"];
  
  s = [[self formLetterDefinition] objectForKey:@"contentdisposition"];
  if ([s isNotEmpty])
    [r setHeader:s forKey:@"content-disposition"];
  
  [self appendLine:[self preamble] withBindings:nil toResponse:r];
  
  [self appendAttendees:[apt valueForKey:@"participants"] 
	ofAppointment:apt withProperties:aptProps
	toResponse:r];
  
  [self appendLine:[self postamble] withBindings:nil toResponse:r];

  if (debugOn) {
    NSString *s;
    
    s = [r contentAsString];
    s = [s stringByReplacingString:@"\t" withString:@"[TAB]"];
    [self debugWithFormat:@"FORM:\n---\n%@\n---", s];
  }
  
  return r;
}

/* debugging */

- (BOOL)isDebuggingEnabled {
  return debugOn;
}

@end /* OGoAptFormLetter */
