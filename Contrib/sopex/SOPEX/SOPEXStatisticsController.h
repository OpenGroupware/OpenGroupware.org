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
//  Created by znek on Thu Feb 12 2004.

#ifndef	__SOPEXStatisticsController_H_
#define	__SOPEXStatisticsController_H_

#import <AppKit/AppKit.h>


@interface SOPEXStatisticsController : NSObject
{
    IBOutlet NSWindow *window;
    IBOutlet NSTextField *baseURLTextField;
    IBOutlet NSTextField *pidTextField;
    IBOutlet NSTextField *lastRefreshDateTextField;
    IBOutlet NSTableView *applicationStatsTableView;
    IBOutlet NSOutlineView *pageStatsOutlineView;
    IBOutlet NSButton *refreshButton;
    IBOutlet NSProgressIndicator *refreshProgressIndicator;

    NSURL *applicationURL;
    NSURL *statsURL;
    NSDictionary *natLangDict;
    
    NSString *currentPageKey;
    NSMutableString *characterBuffer;

    NSMutableArray *applicationStats, *pageNames;
    NSMutableDictionary *statsForPageNameLUT;

    NSMutableArray *currentStats; // NOT RETAINED
}

- (id)initWithApplicationURL:(NSString *)url;

- (IBAction)orderFront:(id)sender;
- (IBAction)performRefresh:(id)sender;
- (IBAction)openApplicationInBrowser:(id)sender;

@end

#endif	/* __SOPEXStatisticsController_H_ */
