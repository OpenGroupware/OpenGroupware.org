/*
  Copyright (C) 2000-2003 SKYRIX Software AG

  This file is part of OGo

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
// $Id$

#include <OGoFoundation/LSWContentPage.h>

@class NSArray, NSString;

@interface SkyTelephoneViewer : LSWContentPage
{
@protected
  NSArray  *telephones;
  NSArray  *attributes;
  id       company;
  id       telephone;
  BOOL     isEditEnabled;
  BOOL     noTableAndTitle;
  NSArray  *phoneTypes;
  NSString *telephoneType;
}

- (BOOL)hasInfo;
- (BOOL)hasNumber;

@end

#import "common.h"

@interface NSObject(CompanyObject) // TODO: probably a CompanyDocument ?
- (NSArray *)phoneTypes;
- (id)phoneNumberForType:(NSString *)_phoneType;
- (id)phoneInfoForType:(NSString *)_phoneType;
@end

@implementation SkyTelephoneViewer

- (void)dealloc {
  [self->telephoneType release];
  [self->telephones release];
  [self->telephone  release];
  [self->company    release];
  [self->phoneTypes release];
  [self->attributes release];
  [super dealloc];
}

/* accessors: public */

- (void)setCompany:(id)_company {
  ASSIGN(self->company, _company);
}
- (id)company {
  return self->company;
}

#if 0
- (void)setTelephones:(NSArray *)_telephones {
  ASSIGN(self->telephones, _telephones);
}
#endif
- (NSArray *)telephoneTypes {
  if (self->phoneTypes == nil) {
    NSArray *t = [[self company] phoneTypes];
    
    self->phoneTypes = [[t sortedArrayUsingSelector:@selector(compare:)] copy];
  }
  return self->phoneTypes;
}

- (void)setTelephone:(id)_telephone {
  ASSIGN(self->telephone, _telephone);
}
- (id)telephone {
  return self->telephone;
}
- (void)setTelephoneType:(NSString *)_telephone {
  ASSIGN(self->telephone, _telephone);
}
- (NSString *)telephoneType {
  return self->telephone;
}

- (void)setIsEditEnabled:(BOOL)_isEditEnabled {
  self->isEditEnabled = _isEditEnabled;
}
- (BOOL)isEditEnabled {
  return self->isEditEnabled;
}

- (BOOL)noTableAndTitle {
  return self->noTableAndTitle;
}
- (void)setNoTableAndTitle:(BOOL)_flag {
  self->noTableAndTitle = _flag;
}

- (void)setAttributes:(NSArray *)_attriutes {
  ASSIGN(self->attributes, _attriutes);
}

// -------------------------------------------------

#if 0 // TODO: can be deleted ??
- (BOOL)hasInfo {
  id info;

  info = [self->telephone valueForKey:@"info"];
  return ((info != nil) && [info isNotNull] && ([info length] > 0));
}

- (BOOL)hasNumber {
  id number;

  number = [self->telephone valueForKey:@"number"];
  return ((number != nil) && [number isNotNull] && ([number length] > 0));  
}
#endif

- (BOOL)showNumber {
  if (self->attributes != nil) {
    NSString *type;

    //type = [self->telephone valueForKey:@"type"];
    type = [self valueForKey:@"telephoneType"];

    if (![self->attributes containsObject:type])
      return NO;
    if (![self->attributes containsObject:@"nonEmptyOnly"])
      return YES;
    
    return ([self hasNumber] || [self hasInfo]);
  }
  return YES;
}

- (NSString *)telephoneNumber {
  return [[self company] phoneNumberForType:
                         [self valueForKey:@"telephoneType"]];
}

- (NSString *)telephoneInfo {
  return [[self company] phoneInfoForType:[self valueForKey:@"telephoneType"]];
}

- (BOOL)hasNumber {
  NSString *n = [self telephoneNumber];

  return ((n != nil) && [n isNotNull] && ([n length] > 0));
}

- (BOOL)hasInfo {
  return [[self telephoneInfo] length] > 0;
}

#if 0 // TODO: can be deleted ?
- (NSString *)telephoneType {
  NSString *type = [[self telephone] valueForKey:@"type"];
  NSString *str  = [[self labels] valueForKey:type];

  return (str != nil) ? str : type;
}
#endif

/* actions */

- (id)edit {
  if (self->telephones != nil && [self->telephones count] > 0) {
    id c = [self pageWithName:@"SkyTelephoneEditor"];
    
    [c takeValue:self->telephones forKey:@"telephones"];
    [c takeValue:self->company    forKey:@"company"];
    return c;
  }
  return nil;
}

@end /* SkyTelephoneViewer */
