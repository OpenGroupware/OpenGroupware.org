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
//  Created by znek on Mon Jan 26 2004.

#ifndef	__SOPEXConsole_H_
#define	__SOPEXConsole_H_

#import <AppKit/AppKit.h>

@class SOPEXToolbarController;


@interface SOPEXConsole : NSObject
{
    IBOutlet NSWindow *window;
    IBOutlet NSTextView *text;

    SOPEXToolbarController *toolbar;

    NSPipe *stdoutPipe, *stderrPipe;
    NSDictionary *stdoutAttributes, *stderrAttributes;
}

- (id)initWithStandardOutput:(id)standardOutput standardError:(id)standardError;

- (void)setStandardOutput:(id)standardOutput standardError:(id)standardError;

- (IBAction)orderFront:(id)sender;
- (IBAction)clear:(id)sender;

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem;

@end

#endif	/* __SOPEXConsole_H_ */
