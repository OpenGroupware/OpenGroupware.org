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

#ifndef	__AppController_H_
#define	__AppController_H_

#import <AppKit/AppKit.h>
#import "SOPEXDocument.h"

@class SOPEXBrowserWindow;
@class WebView;
@class SOPEXToolbarController;
@class SOPEXWebConnection;
@class SOPEXConsole;
@class SOPEXSNSController;
@class SOPEXStatisticsController;


@interface SOPEXAppController : NSObject <SOPEXDocumentController>
{
    IBOutlet SOPEXBrowserWindow *mainWindow;
    IBOutlet NSMenu *mainMenu;
    IBOutlet NSTabView *tabView;

    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSTextField *statusBarTextField;

    IBOutlet WebView  *webView;

    IBOutlet NSTextField *woxNameField;
    IBOutlet NSTextView *woxSourceView;
    IBOutlet NSTextField *woComponentNameField;
    IBOutlet NSTextView *woSourceView;
    IBOutlet NSTextView *woDefinitionView;

    IBOutlet NSTextView *htmlView;
    
    IBOutlet NSTableView *responseHeaderInfoTableView;
    NSMutableArray *responseHeaderValues;

    IBOutlet NSMenuItem *debugMenuItem;
    IBOutlet NSMenuItem *viewSeparatorMenuItem;

    IBOutlet NSMenuItem *viewApplicationMenuItem;
    IBOutlet NSMenuItem *viewSourceMenuItem;
    IBOutlet NSMenuItem *viewHTMLMenuItem;
    IBOutlet NSMenuItem *viewHTTPMenuItem;

    IBOutlet NSMenuItem *aboutMenuItem;
    IBOutlet NSMenuItem *hideMenuItem;
    IBOutlet NSMenuItem *quitMenuItem;


    SOPEXWebConnection *connection;
    SOPEXToolbarController *toolbarController;
    SOPEXSNSController *snsd;
    SOPEXConsole *console;
    SOPEXStatisticsController *statsController;
    NSTask *daemonTask;

    SOPEXDocument *document;
}

- (NSTextView *)document:(SOPEXDocument *)document textViewForType:(NSString *)fileType;

- (BOOL)isInRADMode;

- (IBAction)restartDaemonTask:(id)sender;
- (IBAction)stopDaemonTask:(id)sender;

/* hook to provide custom launch arguments. remember to call super! */
- (void)appendToDaemonLaunchArguments:(NSMutableArray *)_args;

- (IBAction)reload:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)viewApplication:(id)sender;
- (IBAction)viewSource:(id)sender;
- (IBAction)viewHTML:(id)sender;
- (IBAction)viewHTTP:(id)sender;

- (IBAction)editInXcode:(id)sender;

- (IBAction)openConsole:(id)sender;
- (IBAction)openStatistics:(id)sender;
- (IBAction)clear:(id)sender;

/* debugging */
- (IBAction)toggleToolbar:(id)sender;

@end

#endif	/* __AppController_H_ */
