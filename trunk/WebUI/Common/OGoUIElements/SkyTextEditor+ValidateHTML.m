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

@interface _SkyText_HTMLValidationHandler : SaxDefaultHandler
{
  NSMutableArray *exceptions;
  BOOL isValid;
}
@end

@implementation _SkyText_HTMLValidationHandler

- (id)init {
  if ((self = [super init])) {
    self->exceptions = [[NSMutableArray alloc] init];
  }
  return self;
}
- (void)dealloc {
  RELEASE(self->exceptions);
  [super dealloc];
}

- (void)reset {
  [self->exceptions removeAllObjects];
  self->isValid = YES;
}

- (void)warning:(SaxParseException *)_exception {
  if (_exception) [self->exceptions addObject:_exception];
}
- (void)error:(SaxParseException *)_exception {
  if (_exception) [self->exceptions addObject:_exception];
  self->isValid = NO;
}
- (void)fatalError:(SaxParseException *)_exception {
  if (_exception) [self->exceptions addObject:_exception];
  self->isValid = NO;
}

- (NSArray *)exceptions {
  return self->exceptions;
}
- (BOOL)isValid {
  return self->isValid;
}

@end /* _SkyText_HTMLValidationHandler */

@implementation SkyTextEditor(HTMLValidation)

static id htmlParser = nil;
static id htmlSAX    = nil;

- (id)_htmlParser {
  if (htmlSAX == nil)
    htmlSAX = [[_SkyText_HTMLValidationHandler alloc] init];
  
  if (htmlParser == nil) {
    id sax;
    
    htmlParser =
      [[SaxXMLReaderFactory standardXMLReaderFactory]
                            createXMLReaderWithName:@"libxmlHTMLSAXDriver"];
    RETAIN(htmlParser);
    
    sax = htmlSAX;
    [htmlParser setContentHandler:sax];
    [htmlParser setDTDHandler:sax];
    [htmlParser setErrorHandler:sax];
  }
  return htmlParser;
}

- (void)_validateHTML {
  NSAutoreleasePool *pool;
  NSException *exception;
  id source;
  
  if ((source = [self validationText]) == nil)
    [self logWithFormat:@"validation source is empty .."];
  
  pool = [[NSAutoreleasePool alloc] init];

  exception = nil;
  RELEASE(self->htmlErrorString); self->htmlErrorString = nil;
  
  NS_DURING
    [htmlSAX reset];
    [[self _htmlParser] parseFromSource:source];
  NS_HANDLER
    exception = RETAIN(localException);
  NS_ENDHANDLER;
  
  if (exception) {
    [self logWithFormat:@"HTML: %@", exception];
    self->htmlErrorString = [[exception reason] copy];
  }
  else if (![htmlSAX isValid]) {
    self->htmlErrorString =
      [[self _formatSaxExceptions:[htmlSAX exceptions]] copy];
  }
  
  [htmlSAX reset];

  RELEASE(pool); pool = nil;
  
  self->didValidateHTML = YES;
}

@end /* SkyTextEditor(HTMLValidation) */
