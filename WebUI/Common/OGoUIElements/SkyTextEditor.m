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

#include "SkyTextEditor.h"
#include "common.h"
#include <SaxObjC/SaxObjC.h>

@interface SkyTextEditor(Privates)

- (void)_validateXML;
- (void)_validateHTML;
- (NSString *)_formatSaxExceptions:(NSArray *)_exceptions;

@end

@implementation SkyTextEditor

- (void)dealloc {
  [self->htmlErrorString release];
  [self->xmlErrorString release];
  [self->text release];
  [self->name release];
  [self->wrap release];
  [super dealloc];
}

/* accessors */

- (void)setText:(NSString *)_text {
  if (([_text length] == 0) && ([self->text length] == 0))
    return;
  if ([_text isEqualToString:self->text])
    return;
  
  ASSIGNCOPY(self->text, _text);
    
  self->didValidateXML  = NO;
  self->didValidateHTML = NO;
}
- (NSString *)text {
  return self->text;
}

- (BOOL)hasName {
  return [self->name length]?YES:NO;
}

- (void)setWrap:(NSString *)_wrap {
  ASSIGN(self->wrap, _wrap);
}

- (void)setName:(NSString *)_n {
  ASSIGNCOPY(self->name, _n);
}
- (NSString *)name {
  return self->name;
}

- (NSString *)validationText {
  return [self text] ? [self text] : @"";
}

- (void)setNoSizeControls:(BOOL)_flag {
  self->noSizeControls = _flag;
}
- (BOOL)noSizeControls {
  return self->noSizeControls;
}

- (void)setEnableEpoz:(BOOL)_flag {
  self->steFlags.enableEpoz = _flag ? 1 : 0;
}
- (BOOL)enableEpoz {
  return self->steFlags.enableEpoz ? YES : NO;
}

- (void)setShowValidateXML:(BOOL)_flag {
  self->showValidateXML = _flag;
}
- (BOOL)showValidateXML {
  return self->showValidateXML;
}
- (void)setShowValidateHTML:(BOOL)_flag {
  self->showValidateHTML = _flag;
}
- (BOOL)showValidateHTML {
  return self->showValidateHTML;
}

- (BOOL)isValidXML {
  if (!self->didValidateXML)
    [self _validateXML];
  return self->xmlErrorString ? NO : YES;
}
- (BOOL)isValidHTML {
  if (!self->didValidateHTML)
    [self _validateHTML];
  return self->htmlErrorString ? NO : YES;
}
- (NSString *)xmlErrorString {
  return self->xmlErrorString;
}
- (NSString *)htmlErrorString {
  return self->htmlErrorString;
}

- (BOOL)didValidateXML {
  return self->didValidateXML;
}
- (BOOL)didValidateHTML {
  return self->didValidateHTML;
}

- (void)setRows:(int)_rows {
  self->rows = _rows;
}
- (int)rows {
  return self->rows < 1 ? 1 : self->rows;
}
- (void)setColumns:(int)_cols {
  self->columns = _cols;
}
- (int)columns {
  return self->columns < 3 ? 3 : self->columns;
}

- (NSString *)dimensionString {
  return [NSString stringWithFormat:@"%ix%i", [self columns], [self rows]];
}

/* validations */

- (NSString *)_formatSaxExceptions:(NSArray *)_exceptions {
  NSMutableString *ms;
  NSEnumerator    *e;
  SaxException    *exception;
  
  if ([_exceptions count] == 0)
    return nil;
  
  ms = [NSMutableString stringWithCapacity:64];
  
  e = [_exceptions objectEnumerator];
  while ((exception = [e nextObject])) {
    id line;

    if ((line = [[exception userInfo] objectForKey:@"line"]))
      [ms appendFormat:@"%@:", line];

    if ((line = [[exception userInfo] objectForKey:@"errorMessage"]))
      [ms appendString:line];
    else
      [ms appendString:[exception reason]];

    if (![ms hasSuffix:@"\n"])
      [ms appendString:@"\n"];
  }
  if ([ms hasSuffix:@"\n"])
    return [ms substringToIndex:([ms length] - 1)];
  return ms;
}

/* actions */

- (id)increaseX {
  self->columns++;
  return nil;
}
- (id)increaseY {
  self->rows++;
  return nil;
}
- (id)decreaseX {
  self->columns--;
  if (self->columns < 3)
    self->columns = 3;
  return nil;
}
- (id)decreaseY {
  self->rows--;
  if (self->rows < 1)
    self->rows = 1;
  return nil;
}

- (id)validateXML {
  //[self logWithFormat:@"validate: %@", [self text]];
  [self _validateXML];
  return nil;
}
- (id)validateHTML {
  [self _validateHTML];
  return nil;
}

@end /* SkyTextEditor */
