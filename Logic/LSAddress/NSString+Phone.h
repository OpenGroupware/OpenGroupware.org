/*
  Copyright (C) 2004 Helge Hess

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

#ifndef __LSAddress_NSString_Phone_H__
#define __LSAddress_NSString_Phone_H__

#import <Foundation/NSString.h>

/* 
   parses a number and trys to build a unique number
 
   +<country>-<city>-<number>{-<extension>}
 
   example (the skyrix office):
   +49-391-6623-0
 
   a double zero at the start ('00') is replaced with a '+'
   all other digits are kept.
   any non-digit sequence is replaced with a '-'
   (if it's not a '+' at the start)
*/

@interface NSString(Phone)

- (NSString *)stringByNormalizingOGoPhoneNumber;

@end

#endif /* __LSAddress_NSString_Phone_H__ */
