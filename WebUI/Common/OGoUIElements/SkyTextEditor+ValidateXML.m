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

#include "SkyTextEditor.h"
#include "common.h"
#include <SaxObjC/SaxObjC.h>

@interface _SkyText_XMLValidationHandler : SaxDefaultHandler
{
  NSMutableArray *exceptions;
  BOOL isValid;
}
@end

@implementation _SkyText_XMLValidationHandler

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

@end /* _SkyText_XMLValidationHandler */

@implementation SkyTextEditor(XMLValidation)

static id xmlParser = nil;
static id xmlSAX    = nil;

- (id)_xmlParser {
  if (xmlSAX == nil)
    xmlSAX = [[_SkyText_XMLValidationHandler alloc] init];
  
  if ((xmlParser == nil) && (xmlSAX != nil)) {
    id sax;
    
    xmlParser =
      [[SaxXMLReaderFactory standardXMLReaderFactory]
                            createXMLReaderWithName:@"libxmlSAXDriver"];
    RETAIN(xmlParser);
    
    sax = xmlSAX;
    [xmlParser setContentHandler:sax];
    [xmlParser setDTDHandler:sax];
    [xmlParser setErrorHandler:sax];
  }
  return xmlParser;
}

- (void)_validateXML {
  NSAutoreleasePool *pool;
  NSException *exception;
  id source;
  
  if ((source = [self validationText]) == nil)
    [self logWithFormat:@"validation source is empty .."];
  
  pool = [[NSAutoreleasePool alloc] init];
  
  exception = nil;
  RELEASE(self->xmlErrorString); self->xmlErrorString = nil;
  
  NS_DURING {
    [xmlSAX reset];
    [[self _xmlParser] parseFromSource:source];
  }
  NS_HANDLER
    exception = RETAIN(localException);
  NS_ENDHANDLER;

  if (exception) {
    [self logWithFormat:@"XML: %@", exception];
    self->xmlErrorString = [[exception reason] copy];
  }
  else if (![xmlSAX isValid]) {
    self->xmlErrorString =
      [[self _formatSaxExceptions:[xmlSAX exceptions]] copy];
  }
  
  [xmlSAX reset];

  RELEASE(pool); pool = nil;
  
  self->didValidateXML = YES;
}

@end /* SkyTextEditor(XMLValidation) */
