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
// Created by Helge Hess on Sun Feb 03 2002.

#ifndef __skysystemd_TaskMethodSignature__
#define __skysystemd_TaskMethodSignature__

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@class NSString, NSArray, NSDictionary, NSData, NSMutableDictionary;

@interface TaskMethodSignature : NSObject
{
  NSArray          *signature;  /* result,a,b,c, .. */
  NSArray          *cmdargs;    /* eg: $1$          */
  NSString         *input;      /* eg: $1$\n        */
  NSStringEncoding encoding;
  NSString         *result;     /* eg: $stdout$     */
  NSString         *resultType; /* eg: arrayOfLines */

  /* used if resultType is 'arrayOfCSVEntries' */
  NSArray          *csvKeys;
  NSString         *csvSeparator;

  short            argCount;

  NSDictionary        *tempFiles;
  NSMutableDictionary *tempFileMapping;
}

- (id)initWithSignature:(NSString *)_sig config:(NSDictionary *)_dict;

/* accessors */

- (NSArray *)xmlRpcSignature;
- (unsigned)numberOfArguments;

/* matching */

- (BOOL)doesMatchArguments:(NSArray *)_args;
- (BOOL)canProcessArguments:(NSArray *)_args;

/* operations */

- (void)addTemporaryFileName:(NSString *)_fileName
  forBinding:(NSString *)_binding;

- (NSArray *)argumentsWithPatternDictionary:(NSDictionary *)_dict;
- (id)resultWithPatternDictionary:(NSDictionary *)_pd;

- (NSData *)standardInputWithPatternDictionary:(NSDictionary *)_pd 
  parameters:(NSArray *)_paras;
- (NSString *)standardOutputStringWithData:(NSData *)_data;
- (NSString *)standardErrorStringWithData:(NSData *)_data;

@end

#endif /* __skysystemd_TaskMethodSignature__ */
