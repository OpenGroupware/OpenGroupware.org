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

#include "LSWAddressEditor.h"
#include <OGoFoundation/LSWNotifications.h>
#include <GDLAccess/EOEntity+Factory.h>
#include "common.h"

@implementation LSWAddressEditor

static NSDictionary *faxPrivateDict = nil;
static NSDictionary *telPrivateDict = nil;

+ (void)initialize {
  static BOOL didInit = NO;
  if (didInit) return;
  didInit = YES;
  
  faxPrivateDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					   @"15_fax_private", @"type", nil];
  telPrivateDict = [[NSDictionary alloc] initWithObjectsAndKeys:
					   @"05_tel_private", @"type", nil];
}

- (void)dealloc {
  [self->company release];
  [super dealloc];
}

/* commands */

- (id)_fetchAddressOfType:(NSString *)_type companyId:(NSNumber *)_companyId {
  return [self runCommand:@"address::get",
  	         @"companyId", _companyId, @"type", _type, 
	         @"operator", @"AND", nil];
}

/* defaults */

- (NSDictionary *)teleTypeMapDefault {
  return [[[self session] userDefaults] dictionaryForKey:@"LSTeleType"];
}
- (NSDictionary *)addressTypeMapDefault {
  return [[[self session] userDefaults] dictionaryForKey:@"LSAddressType"];
}

/* operations */

- (NSMutableArray *)_telephones {
  NSMutableArray *t;
  
  if ((t = [[self snapshot] valueForKey:@"telephones"]) == nil) {
    t = [NSMutableArray arrayWithCapacity:16];
    [[self snapshot] takeValue:t forKey:@"telephones"];
  }
  else if (![t isKindOfClass:[NSMutableArray class]]) {
    t = [[t mutableCopy] autorelease];
    [[self snapshot] takeValue:t forKey:@"telephones"];
  }
  return t;
}

- (void)clearEditor {
  [[self _telephones] removeAllObjects];
  [self setAddressType:nil];
  [self->company release]; self->company = nil;
  [super clearEditor];
}

- (void)_copyTelephonesFromEOInWizardMode:(id)_obj {
  NSMutableDictionary *md;
    
  md = [faxPrivateDict mutableCopy];
  [[self _telephones] addObject:md];
  [md release];
    
  md = [telPrivateDict mutableCopy];
  [[self _telephones] addObject:md];
  [md release];
}

- (void)_copyTelephonesFromEO:(id)_obj {
  // TODO: split up this huge method!
  
  if ([self isInWizardMode]) {
    [self _copyTelephonesFromEOInWizardMode:_obj];
    return;
  }
  if (_obj == nil)
    return;
  
  // TODO: split up?
  {
    NSMutableArray *types      = nil;
    NSArray        *tels       = nil;
    id             toTelephone;
    int            i, cnt;
    
    toTelephone = [_obj valueForKey:@"toTelephone"];
    types       = [[NSMutableArray alloc] init];
    toTelephone = [_obj valueForKey:@"toTelephone"];
 
    if ([toTelephone respondsToSelector:@selector(clear)])
      [toTelephone clear];
    tels = [_obj valueForKey:@"toTelephone"];
    cnt  = [tels count];
    
    if (tels) {
      for (i = 0; i < cnt; i++) {
        NSMutableDictionary *teleDict;
        id                  tel;
	
	tel = [tels objectAtIndex:i];
        teleDict = (id)[tel valuesForKeys:[[tel entity] attributeNames]];
        teleDict = [teleDict mutableCopy];    
        [[self _telephones] addObject:teleDict];    
        [types addObject:[tel valueForKey:@"type"]];
        [teleDict release]; teleDict = nil;
      }
    }

    {
      NSDictionary *cfg;
      NSArray      *cfgTypes;
      
      cfg      = [self teleTypeMapDefault];
      cfgTypes = [cfg objectForKey:[[_obj entity] name]];
    
      cnt = [cfgTypes count];
    
      for (i = 0; i < cnt; i++) {
        id type = [cfgTypes objectAtIndex:i];
      
        if (![types containsObject:type]) {
          NSMutableDictionary *teleDict;
          id tel;
	  
	  tel = [self runCommand:
                         @"telephone::new",
                         @"companyId", [_obj valueForKey:@"companyId"],
                         @"type", type, nil];
          teleDict = (id)[tel valuesForKeys:[[tel entity] attributeNames]];
          teleDict = [teleDict mutableCopy];
          [[self _telephones] addObject:teleDict];
          [teleDict release]; teleDict = nil;
        }
      }
    }
    [types release]; types = nil;
  }
}

/* activation */

- (BOOL)prepareForNewCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  [self _copyTelephonesFromEO:self->company];
  return YES;
}

- (BOOL)prepareForEditCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  id           obj;
  NSDictionary *cfg = nil;

  if ((obj = [self object]) == nil)
    return NO;
  
  cfg = [self addressTypeMapDefault];
  
  // TODO: uses to-relation => replace with proper command!
  if ([[cfg objectForKey:@"Person"] containsObject:[self type]])
    self->company = [[obj valueForKey:@"toPerson"] retain];
  else if ([[cfg objectForKey:@"Enterprise"] containsObject:[self type]])
    self->company = [[obj valueForKey:@"toEnterprise"] retain];
  
  if (self->company)
    [self _copyTelephonesFromEO:self->company];
  
  return YES;
}

- (BOOL)prepareForActivationCommand:(NSString *)_command
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  [self setWindowTitle:[[self labels] valueForKey:@"addresseditor_title"]];
  
  return [super prepareForActivationCommand:_command type:_type
                configuration:_cmdCfg];
}

/* accessors */

- (NSMutableDictionary *)address {
  return [self snapshot];
}

- (void)setCompany:(id)_company {
  ASSIGN(self->company, _company);
}
- (id)company {
  return self->company;
}

- (void)setAddressType:(NSString *)_type {
  if (_type != nil) 
    [[self snapshot] takeValue:_type forKey:@"addressType"];
  else
    [[self snapshot] removeObjectForKey:@"addressType"];
}
- (NSString *)addressType {
  return [[self snapshot] valueForKey:@"addressType"];
}

- (NSString *)type {
  NSString *value;
  
  value = [[self snapshot] valueForKey:@"type"];
  return ![value isNotNull] ? [self addressType] : value;  
}

- (NSString *)typeLabel {
  NSString *typeL;
  
  typeL = [@"addresstype_" stringByAppendingString:[self type]];
  return [[self labels] valueForKey:typeL];
}

- (void)setTelephone:(id)_tel {
  self->telephone = _tel;
}
- (id)telephone {
  return self->telephone;
}

- (NSArray *)telephones {
  return [self _telephones];
}

- (NSString *)telephoneLabel {
  return [[self labels] valueForKey:[self->telephone valueForKey:@"type"]];
}

- (void)setTeleInfo:(NSString *)_info {
  id value1;
  
  value1 = [self->telephone valueForKey:@"info"];
  
  if ((_info == nil) ^ (value1 == nil)) // ?? what is ^ ?
    self->telephoneChanged = YES;
  else if (_info == nil && value1 == nil)
    ; // do nothing
  else if (![_info isEqualToString:value1])
    self->telephoneChanged = YES;

  [self->telephone takeValue:_info forKey:@"info"];
}

- (NSString *)teleInfo {
  return [self->telephone valueForKey:@"info"];
}

- (void)setTeleContent:(id)_content {
  id value1 = [self->telephone valueForKey:@"number"];
  
  if ((_content == nil) ^ (value1 == nil))
    self->telephoneChanged = YES;
  else if (_content == nil && value1 == nil); // do nothing
  else if (![_content isEqualToString:value1])
    self->telephoneChanged = YES;

  [self->telephone takeValue:_content forKey:@"number"];
}

- (NSString *)teleContent {
  return [self->telephone valueForKey:@"number"];
}

- (BOOL)isTelephonePrivate {
  return [[self->telephone valueForKey:@"type"] hasSuffix:@"private"] &&
    [[self type] isEqualToString:@"private"] ? YES : NO;
}

- (NSString *)insertNotificationName {
  return LSWNewAddressNotificationName;
}

/* actions */

- (void)_save {
  NSString *cmd;
  
  if (!self->telephoneChanged)
    return;
  
  if ([[self navigation] activePage] == self)
    return;
  
  cmd = [[[self->company entity] name] lowercaseString];

  cmd = [cmd stringByAppendingString:@"::set"];
  [self->company takeValue:[self _telephones] forKey:@"telephones"];
  
  [self->company run:cmd, @"telephones", [self _telephones], nil];
  
  if (![self commit]) {
    [self logWithFormat:@"could not save address (tx failed)"];
    [self rollback];
    // TODO: localize!
    [self setErrorString:
	    @"Address could not be saved, transaction rolled back"];
  }
}

- (id)save {
  [self saveAndGoBackWithCount:1];
  [self _save];
  return nil;
}

- (id)insertObject {
  NSArray *result;
  id      address;

  address = [self snapshot];
  
  if (self->company == nil || [self addressType] == nil) {  
    // TODO: improve error handling
    [self setErrorString:@"Cannot insert new address!"];
    return nil;
  }
  
  result = [self _fetchAddressOfType:[self addressType] 
		 companyId:[self->company valueForKey:@"companyId"]];
  
  if ([result count] == 1) {
    [self setObject:[result lastObject]];
    return [self updateObject];
  }
  
  if ([result count] == 0) {
    [address takeValue:
	       [self->company valueForKey:@"companyId"] 
	     forKey:@"companyId"];
    [address takeValue:[self addressType] forKey:@"type"];    

    return [self runCommand:@"address::new" arguments:address];
  }
  
  // TODO: improve error handling
  [self setErrorString:@"There are always more than one addresses!"];
  return nil;
}

- (id)updateObject {
  NSMutableDictionary *addr;
  
  addr = [self address];
  if (self->telephoneChanged)
    [addr setObject:[NSNumber numberWithBool:NO] forKey:@"shouldLog"];
  return [self runCommand:@"address::set" arguments:addr];
}

@end /* LSWAddressEditor */
