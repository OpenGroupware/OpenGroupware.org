/*
 Copyright (C) 2004 Marcus Mueller <znek@mulle-kybernetik.com>

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
//  Created by znek on Mon Apr 05 2004.

#ifndef	__SOPEXContentValidator_H_
#define	__SOPEXContentValidator_H_

#import <Foundation/NSObject.h>
#import <SaxObjC/SaxObjC.h>
#import <NGObjWeb/WOHTMLParser.h>
#import <NGObjWeb/WODParser.h>


@interface SOPEXContentValidator : NSObject <SaxErrorHandler, WODParserHandler, WOHTMLParserHandler>
{
    NSMutableArray *warnings;
    NSMutableArray *errors;
}

+ (NSError *)validateWOXContent:(id)content;
+ (NSError *)validateWOHTMLContent:(id)content;
+ (NSError *)validateWODContent:(id)content;

- (NSError *)validateWOXContent:(id)content;
- (NSError *)validateWOHTMLContent:(id)content;
- (NSError *)validateWODContent:(id)content;

- (BOOL)hasWarnings;
- (NSArray *)warnings;
- (BOOL)hasErrors;
- (NSArray *)errors;

- (NSError *)status;

@end

extern NSString *SOPEXDocumentValidationErrorDomain;

#endif	/* __SOPEXContentValidator_H_ */
