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

#import "SOPEXAppController.h"
#import <WebKit/WebKit.h>
#import <NGObjWeb/NGObjWeb.h>
#import <NGObjWeb/WOTemplateBuilder.h>
#import <NGStreams/NGStreams.h>
#import <NGStreams/NGNet.h>
#import "SOPEXConsole.h"
#import "SOPEXToolbarController.h"
#import "SOPEXWebConnection.h"
#import "SOPEXSNSController.h"
#import "SOPEXStatisticsController.h"
#import "SOPEXConstants.h"
#import "WebView+Ext.h"
#import "SOPEXBrowserWindow.h"
#import "SOPEXRangeUtilities.h"
#import "SOPEXDocument.h"
#import "SOPEXWOXDocument.h"
#import "SOPEXWODocument.h"
#import "SOPEXSheetRunner.h"

#define DNC [NSNotificationCenter defaultCenter]
#define UD [NSUserDefaults standardUserDefaults]


#define SNS_CHILD_DEBUG 0


@interface SOPEXAppController (PrivateAPI)
- (void)_setup;
- (void)_setupDaemonTask;
- (void)_launchDaemonTask;
- (void)setStatus:(NSString *)_msg;
- (void)setStatus:(NSString *)_msg isError:(BOOL)isError;
- (void)flushDocument;
- (void)createDocumentFromResponse;
- (void)_selectTabWithIdentifier:(NSString *)identifier menuItem:(NSMenuItem *)menuItem;
@end

@implementation SOPEXAppController

static BOOL debugOn = NO;
static BOOL isInRADMode = YES;

+ (void)initialize
{
    static BOOL isInitialized = NO;
    
    if(isInitialized)
        return;
    
    debugOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"SOPEXDebugEnabled"];
    isInitialized = YES;
}


#pragma mark -
#pragma mark ### INIT & DEALLOC ###

- (id)init {
    self = [super init];
    if(self) {
        NSArray *args;
        
        // check, if Application has been launched by Finder
        args = [[NSProcessInfo processInfo] arguments];
        if([[args lastObject] hasPrefix:@"-psn_"])
            isInRADMode = NO;
    }
    return self;
}

- (void)dealloc
{
    [DNC removeObserver:self];
    [self->responseHeaderValues release];
    [self->statsController release];
    [self->snsd release];
    [self->daemonTask release];
    [self->console release];
    [super dealloc];
}


#pragma mark -
#pragma mark ### SETUP ###


- (void)awakeFromNib
{
    NSString *appName;
    
    [self->webView setGroupName:@"WebUI"];

    // Fix menu items
    appName = [[NSProcessInfo processInfo] processName];
    [self->aboutMenuItem setTitle:[NSString stringWithFormat:[self->aboutMenuItem title], appName]];
    [self->hideMenuItem setTitle:[NSString stringWithFormat:[self->hideMenuItem title], appName]];
    [self->quitMenuItem setTitle:[NSString stringWithFormat:[self->quitMenuItem title], appName]];

    self->responseHeaderValues = [[NSMutableArray alloc] initWithCapacity:20];
#if 0
    [DNC addObserver:self selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:nil];
#endif
    [self viewApplication:nil];
}


- (void)_setup
{
    if(! [self isInRADMode]) {
        NSMenu *viewMenu;

        // remove RAD menuItems
        [self->mainMenu removeItem:self->debugMenuItem];
        viewMenu = [self->viewSeparatorMenuItem menu];
        [viewMenu removeItem:self->viewSeparatorMenuItem];
        [viewMenu removeItem:self->viewApplicationMenuItem];
        [viewMenu removeItem:self->viewSourceMenuItem];
        [viewMenu removeItem:self->viewHTMLMenuItem];
        [viewMenu removeItem:self->viewHTTPMenuItem];
    }

    self->snsd = [[SOPEXSNSController alloc] init];
    [self->snsd setDelegate:self];
    [self->snsd start];

    if(debugOn)
        NSLog(@"%s snsd's address:%@", __PRETTY_FUNCTION__, [snsd socketAddress]);

    self->console = [[SOPEXConsole alloc] init];

    self->toolbarController = [[SOPEXToolbarController alloc] initWithIdentifier:@"SOPEXWebUI" target:self];
    
    [self _setupDaemonTask];
}

- (void)_setupDaemonTask
{
    NSString *daemonPath;
    NSMutableArray *args;
    NSString *woPort;

    self->daemonTask = [[NSTask alloc] init];
    daemonPath = [[NSBundle mainBundle] executablePath];
    
    // prepare the task
    [self->daemonTask setLaunchPath:daemonPath];
    [self->daemonTask setStandardInput:[NSPipe new]];
#if(SNS_CHILD_DEBUG == 0)
    [self->daemonTask setStandardOutput:[NSPipe new]];
    [self->daemonTask setStandardError:[NSPipe new]];
#endif
    
    // prepare arguments
    args = [[NSMutableArray alloc] initWithCapacity:20];
    [args addObject:SOPEXDaemonFlag]; // this triggers 'daemon' mode
    [args addObject:@"-WOContactSNS"];
    [args addObject:@"YES"];
    // increase responsiveness in case we terminate by accident
    [args addObject:@"-SNSPingInterval"];
    [args addObject:@"10"];
#if SNS_CHILD_DEBUG
#warning ** ZNeK: Debugging SNS in child
    [args addObject:@"-SNSLogActivity"];
    [args addObject:@"YES"];
#endif
    [args addObject:@"-SNSPort"];
    [args addObject:[snsd socketAddress]];
    [args addObject:@"-WOPort"];
    woPort = [UD stringForKey:@"WOPort"];
    if(woPort != nil)
        [args addObject:woPort];
    else
        [args addObject:@"auto"];
    [self appendToDaemonLaunchArguments:args];
    [self->daemonTask setArguments:args];
    [args release];
}

- (void)_launchDaemonTask
{
    if(debugOn)
        NSLog(@"%s", __PRETTY_FUNCTION__);
    [DNC addObserver:self selector:@selector(daemonTaskDidTerminate:) name:NSTaskDidTerminateNotification object:self->daemonTask];

#if(SNS_CHILD_DEBUG == 0)
    [self->console setStandardOutput:[self->daemonTask standardOutput] standardError:[self->daemonTask standardError]];
#endif
    
    [self->daemonTask launch];
}

- (void)appendToDaemonLaunchArguments:(NSMutableArray *)_args {
    // the next entry works, because  executable's cwd is the project directory
    // (set in project's launch options)
    if([self isInRADMode]) {
        [_args addObject:@"-WOProjectDirectory"];
        [_args addObject:[[NSFileManager defaultManager] currentDirectoryPath]];
        
        // Debugging options
        [_args addObject:@"-WOCachingEnabled"];
        [_args addObject:@"NO"];
        [_args addObject:@"-WODebuggingEnabled"];
        [_args addObject:@"YES"];
#if 0
        [_args addObject:@"-WODebugComponentLookup"];
        [_args addObject:@"YES"];
        [_args addObject:@"-WODebugResourceLookup"];
        [_args addObject:@"YES"];
#endif
#if 0
        [_args addObject:@"-WOxComponentElemBuilderDebugEnabled"];
        [_args addObject:@"YES"];
        [_args addObject:@"-WOxElemBuilder_LogAssociationMapping"];
        [_args addObject:@"YES"];
        [_args addObject:@"-WOxElemBuilder_LogAssociationCreation"];
        [_args addObject:@"YES"];
#endif
#if 0
#warning ** ZNeK: Profiling information
        [_args addObject:@"-WOProfileComponents"];
        [_args addObject:@"YES"];
        [_args addObject:@"-WOProfileElements"];
        [_args addObject:@"YES"];
        [_args addObject:@"-WOProfileHttpAdaptor"];
        [_args addObject:@"YES"];
#endif
    }
}

#pragma mark -
#pragma mark ### ACCESSORS ###


- (BOOL)isInRADMode {
    return isInRADMode;
}


#pragma mark -
#pragma mark ### ACTIONS ###


- (IBAction)restartDaemonTask:(id)sender
{
    [DNC removeObserver:self name:NSTaskDidTerminateNotification object:self->daemonTask];

    // we're done writing
    [[[self->daemonTask standardInput] fileHandleForWriting] closeFile];

    [self->daemonTask terminate];
    [self->daemonTask waitUntilExit];
    [self->daemonTask release];
    [self _setupDaemonTask];
    [self _launchDaemonTask];
}

- (IBAction)stopDaemonTask:(id)sender
{
    if(debugOn)
        NSLog(@"%s", __PRETTY_FUNCTION__);
    [self->progressIndicator startAnimation:self];
    
    // we're done writing
    [[[self->daemonTask standardInput] fileHandleForWriting] closeFile];

    [self->daemonTask terminate];
    [self->daemonTask waitUntilExit];
    [NSApp terminate:self];
}

- (IBAction)reload:(id)sender
{
    if(sender == nil)
    {
        NSURLRequest *rq;
        
        rq = [NSURLRequest requestWithURL:[self->connection url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10.0];
        if(debugOn)
            NSLog(@"%s request: %@", __PRETTY_FUNCTION__, rq);
        [[self->webView mainFrame] loadRequest:rq];
    }
    else
    {
        [self->webView reload:self];
    }
    [self viewApplication:sender];
}

- (IBAction)back:(id)sender
{
    [self->webView goBack];
}

- (IBAction)viewApplication:(id)sender
{
    [self _selectTabWithIdentifier:@"application" menuItem:self->viewApplicationMenuItem];
}

- (IBAction)viewSource:(id)sender
{
    NSString *componentName;

    componentName = [[self->document path] lastPathComponent];
    if([componentName hasSuffix:@"wo"])
    {
        [self->woComponentNameField setStringValue:componentName];
        [self _selectTabWithIdentifier:@"wo" menuItem:self->viewSourceMenuItem];
    }
    else
    {
        [self->woxNameField setStringValue:componentName];
        [self _selectTabWithIdentifier:@"wox" menuItem:self->viewSourceMenuItem];
    }
}

- (IBAction)viewHTML:(id)sender
{
    WebDataSource *dataSource;
    id <WebDocumentRepresentation> representation;
    NSString *source;

    dataSource = [[self->webView mainFrame] dataSource];
    NSAssert(dataSource != nil, @"dataSource not yet committed?!");
    NSAssert([dataSource isLoading] == NO, @"dataSource not finished loading?!");

    representation = [dataSource representation];

    if([representation canProvideDocumentSource])
        source = [representation documentSource];
    else
        source = @"";

    [self->htmlView setString:source];
    [self _selectTabWithIdentifier:@"html" menuItem:self->viewHTMLMenuItem];
}

- (IBAction)viewHTTP:(id)sender
{
    WebDataSource *dataSource;
    NSHTTPURLResponse *response;
    NSDictionary *headerFields;
    NSArray *headers;
    int count, i;

    dataSource = [[self->webView mainFrame] dataSource];
    response = (NSHTTPURLResponse *)[dataSource response];

    headerFields = [response allHeaderFields];
    headers = [headerFields allKeys];
    count = [headers count];
    
    [self->responseHeaderValues removeAllObjects];

    for(i = 0; i < count; i++)
    {
        NSString *header, *value;
        NSDictionary *headerValueInfo;
        
        header = [headers objectAtIndex:i];
        value = [headerFields objectForKey:header];
        headerValueInfo = [[NSDictionary alloc] initWithObjectsAndKeys:value, @"value", header, @"header", nil];
        [self->responseHeaderValues addObject:headerValueInfo];
        [headerValueInfo release];
    }

    [self->responseHeaderInfoTableView reloadData];
    [self _selectTabWithIdentifier:@"http" menuItem:self->viewHTTPMenuItem];
}

- (void)_selectTabWithIdentifier:(NSString *)identifier menuItem:(NSMenuItem *)menuItem
{
    [self->tabView selectTabViewItemWithIdentifier:identifier];
    if(isInRADMode)
    {
        [self->viewApplicationMenuItem setState:menuItem == self->viewApplicationMenuItem ? NSOnState : NSOffState];
        [self->viewSourceMenuItem setState:menuItem == self->viewSourceMenuItem ? NSOnState : NSOffState];
        [self->viewHTMLMenuItem setState:menuItem == self->viewHTMLMenuItem ? NSOnState : NSOffState];
        [self->viewHTTPMenuItem setState:menuItem == self->viewHTTPMenuItem ? NSOnState : NSOffState];
    }
}

- (IBAction)saveDocument:(id)sender
{
    if(self->document != nil)
    {
        if([self->document hasChanges])
        {
            if(![self->document performSave])
            {
                NSBeep();
                return;
            }
            [self->mainWindow setDocumentEdited:NO];
        }
    }
}

- (IBAction)revertDocumentToSaved:(id)sender
{
    [self->document revertChanges];
    [self->mainWindow setDocumentEdited:NO];
}

- (IBAction)openConsole:(id)sender
{
#if(SNS_CHILD_DEBUG == 0)
    [self->console orderFront:sender];
#endif
}

- (IBAction)openStatistics:(id)sender
{
    [self->statsController orderFront:sender];
}

- (IBAction)clear:(id)sender
{
    [self->console clear:sender];
}

- (IBAction)toggleToolbar:(id)sender
{
    if([self->mainWindow toolbar] == nil)
        [self->toolbarController applyOnWindow:self->mainWindow];
    else
        [self->mainWindow setToolbar:nil];
}

- (IBAction)editInXcode:(id)sender
{
    NSString *path;
    
    path = [self->document path];

    [[NSWorkspace sharedWorkspace] openFile:path withApplication:@"Xcode" andDeactivate:YES]; 
}


#pragma mark ### VALIDATION ###


- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return [self validateMenuItem:(id <NSMenuItem>)theItem];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    SEL action = [menuItem action];

#if 0
    NSLog(@"%s action:%@", __PRETTY_FUNCTION__, NSStringFromSelector(action));
#endif
    if(action == @selector(openStatistics:))
        return self->statsController != nil;
    if(action == @selector(clear:))
        return [self->console validateMenuItem:menuItem];
    if(action == @selector(back:))
        return [self->webView canGoBack];
    if(action == @selector(viewHTML:))
    {
        WebDataSource *dataSource = [[self->webView mainFrame] dataSource];
        if(dataSource == nil)
            return NO;
        return [dataSource isLoading] == NO;
    }
    if(action == @selector(viewSource:))
        return self->document != nil;
    if(action == @selector(saveDocument:) || action == @selector(revertDocumentToSaved:))
        if(self->document == nil)
            return NO;
        else
            return [self->document hasChanges];
        
    return YES;
}


#pragma mark -
#pragma mark ### SOPEXDocumentController PROTOCOL ###


- (NSTextView *)document:(SOPEXDocument *)_document textViewForType:(NSString *)_fileType
{
    if([_document isKindOfClass:[SOPEXWODocument class]]) {
        if([_fileType isEqualToString:@"html"])
            return self->woSourceView;
        return self->woDefinitionView;
    }
    return self->woxSourceView;
}

- (void)document:(SOPEXDocument *)document didValidateWithError:(NSError *)error forType:(NSString *)fileType
{
    [self viewSource:self];
}


#pragma mark -
#pragma mark ### NOTIFICATIONS ###


- (void)daemonTaskDidTerminate:(NSNotification *)notification
{
    if(debugOn)
        NSLog(@"%s", __PRETTY_FUNCTION__);
    [self->progressIndicator stopAnimation:self];
}


#pragma mark -
#pragma mark ### APPLICATION DELEGATE ###


- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [self setStatus:nil];
    [self _setup];
    [self _launchDaemonTask];
    if(isInRADMode)
        [self openConsole:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app
{
    return YES;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app
{
    if(! [self windowShouldClose:self->mainWindow])
        return NSTerminateLater;
    return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [self stopDaemonTask:self];
}


#pragma mark -
#pragma mark ### TEXTVIEW DELEGATE ###

// ZNeK: This is something I'd like to out-source somplace else, but it just doesn't feel right
// to do it at the moment.

- (void)textViewDidChangeSelection:(NSNotification *)notification
{
    NSTextView *textView = [notification object];
    NSEvent *event;
    NSRange selRange;
    
    selRange = [textView selectedRange];
    event = [NSApp currentEvent];

    if(([event type] == NSLeftMouseUp) && ([event clickCount] == 2))
    {
        NSRange matchRange = SOPEX_findMatchingTagForRangeInString(selRange, [textView string]);
        
        if(matchRange.location != NSNotFound)
        {
            selRange = NSUnionRange(selRange, matchRange);
            [textView setSelectedRange:selRange affinity:NSSelectionAffinityUpstream stillSelecting:YES];
            [textView scrollRangeToVisible:matchRange];
        }
    }
}


#pragma mark -
#pragma mark ### PRIVATE API ###


- (void)setStatus:(NSString *)_msg
{
    [self setStatus:_msg isError:NO];
}

- (void)setStatus:(NSString *)_msg isError:(BOOL)isError
{
    if(_msg == nil)
        _msg = @"";
    [self->statusBarTextField setStringValue:_msg];
}

- (void)flushDocument
{
    [self->document release];
    self->document = nil;
    [self->mainWindow setDocumentEdited:NO];
}

- (void)createDocumentFromResponse
{
    WebDataSource *dataSource;
    NSHTTPURLResponse *response;
    NSDictionary *headerFields;
    NSString *templatePath;

    dataSource = [[self->webView mainFrame] dataSource];
    response = (NSHTTPURLResponse *)[dataSource response];
    
    if([response isKindOfClass:[NSHTTPURLResponse class]]) {
        headerFields = [response allHeaderFields];
        // NOTE: WebKit cuddly-capses header keys!
        templatePath = [headerFields objectForKey:@"X-Sope-Template-Path"];
        if(templatePath == nil)
            return;
        
        if([templatePath hasSuffix:@"wo"])
            self->document = [[SOPEXWODocument alloc] initWithPath:templatePath controller:self];
        else
            self->document = [[SOPEXWOXDocument alloc] initWithPath:templatePath controller:self];
    }
}


#pragma mark -
#pragma mark ### SNS CONTROLLER DELEGATE ###


- (void)snsController:(SOPEXSNSController *)controller registerInstance:(NSDictionary *)instanceDescription
{
    NGInternetSocketAddress *applicationAddress;
    NSString *applicationName, *url;
    NSBundle *resourceBundle;
    NSString *path;

    applicationName = [instanceDescription objectForKey:SNSApplicationNameKey];
    applicationAddress = [instanceDescription objectForKey:SNSApplicationAddressKey];

    url = [NSString stringWithFormat:@"http://localhost:%d/%@", [applicationAddress port], applicationName];

    [self->connection release];

    // In Rapid Development mode the mainBundle path is the current working directory,
    // which is where the source code is located
    if(isInRADMode) {
        path = [[NSFileManager defaultManager] currentDirectoryPath];
    }
    else {
        path = [[NSBundle mainBundle] resourcePath];
    }

    // However, SOPE:X applications have a special WebServerResources folder
    path = [path stringByAppendingPathComponent:@"WebServerResources"];
    resourceBundle = [[[NSBundle alloc] initWithPath:path] autorelease];

    self->connection = [(SOPEXWebConnection *)[SOPEXWebConnection alloc] initWithURL:url localResourceBundle:resourceBundle];

    if(debugOn)
        NSLog(@"%s OGo connection: %@", __PRETTY_FUNCTION__, self->connection);

    self->statsController = [[SOPEXStatisticsController alloc] initWithApplicationURL:url];

    if(debugOn)
        NSLog(@"%s instance:%@", __PRETTY_FUNCTION__, instanceDescription);
    [self reload:nil];
}

- (void)snsController:(SOPEXSNSController *)controller unregisterInstance:(NSDictionary *)instanceDescription
{
    NSLog(@"%s WARNING!! Child did terminate!", __PRETTY_FUNCTION__);
}


#pragma mark -
#pragma mark ### WINDOW DELEGATE ###


- (BOOL)windowShouldClose:(id)sender
{
#if 0
    if(debugOn)
        NSLog(@"%s sender:%@", __PRETTY_FUNCTION__, sender);
#endif

    if(sender != self->mainWindow)
        return YES;

    if(self->document != nil && [self->document hasChanges])
    {
        id panel;
        int rc;

        panel = NSGetAlertPanel(
                                NSLocalizedString(@"Do you want to save changes to the source code before closing?", "Title of the alert sheet when window should close but changes are still not saved"),
                                NSLocalizedString(@"If you don\\u2019t save, your changes will be lost.", "Message of the alert sheet when unsaved changes are about to be lost"),
                                NSLocalizedString(@"Save", "Default button text for the alert sheet"),
                                NSLocalizedString(@"Don\\u2019t save", "Alternate button text for the alert sheet"),
                                NSLocalizedString(@"Cancel", "Other button text for the alert sheet")
                                );

        rc = SOPEXRunSheetModalForWindow(panel, self->mainWindow);
        NSReleaseAlertPanel(panel);
        
        // NSAlertOtherReturn == Cancel
        // NSAlertAlternateReturn == Don't save
        // NSAlertDefaultReturn == Save
        
        if(rc == NSAlertOtherReturn)
            return NO;
        if(rc == NSAlertDefaultReturn)
            [self saveDocument:self];
        [self flushDocument];
    }
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
#if 0
    if(debugOn)
        NSLog(@"%s notification:%@", __PRETTY_FUNCTION__, notification);
#endif
    if([notification object] == self->mainWindow)
        [NSApp terminate:self];
}


#pragma mark -
#pragma mark ### TableView DATASOURCE ###


- (int)numberOfRowsInTableView:(NSTableView *)_tableView
{
    return [self->responseHeaderValues count];
}

- (id)tableView:(NSTableView *)_tableView objectValueForTableColumn:(NSTableColumn *)_tableColumn row:(int)_rowIndex
{
    return [[self->responseHeaderValues objectAtIndex:_rowIndex] objectForKey:[_tableColumn identifier]];
}


#pragma mark -
#pragma mark ### WebResource Load DELEGATE ###


- (id)webView:(WebView *)_sender 
  identifierForInitialRequest:(NSURLRequest *)_rq 
  fromDataSource:(WebDataSource *)_ds
{
    return [[_rq URL] absoluteString];
}

- (NSURLRequest *)webView:(WebView *)_sender 
                 resource:(id)_id
          willSendRequest:(NSURLRequest *)_rq
         redirectResponse:(NSURLResponse *)redirectResponse 
           fromDataSource:(WebDataSource *)_ds
{
    /* use that to patch resource requests to local files ;-) */
    NSURL    *url, *rurl;
    
    url = [_rq URL];
    if(debugOn)
        NSLog(@"%s: %@ request: %@ url: %@", __PRETTY_FUNCTION__, _id, _rq, url);
    
    if (![self->connection shouldRewriteRequestURL:url])
        return _rq;
    
    if ((rurl = [self->connection rewriteRequestURL:url]) == nil)
        return _rq;
    if ([rurl isEqual:url])
        return _rq;
    
    return [NSURLRequest requestWithURL:rurl
                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                        timeoutInterval:5.0];
}

- (void)webView:(WebView *)_sender resource:(id)_rid 
  didReceiveContentLength:(unsigned)_length 
 fromDataSource:(WebDataSource *)_ds
{
    //NSLog(@"%s: %@ len: %d", __PRETTY_FUNCTION__, _rid, _length);
}

- (void)webView:(WebView *)_sender resource:(id)_rid 
  didFinishLoadingFromDataSource:(WebDataSource *)_ds
{
    NSURLResponse *r = [_ds response];
    
    if(debugOn)
    {
        NSLog(@"%s: %@ ds: %@\n  data-len: %i\n  response: %@\n  type: %@\n  enc: %@", 
              __PRETTY_FUNCTION__, _rid, _ds,
              [[_ds data] length], r, [r MIMEType], [r textEncodingName]);
    }
    [self->connection processResponse:[_ds response] data:[_ds data]];
}

- (void)webView:(WebView *)_sender resource:(id)_rid
  didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge 
 fromDataSource:(WebDataSource *)_ds
{
    if(debugOn)
        NSLog(@"%s: %@ ds: %@", __PRETTY_FUNCTION__, _rid, _ds);
}

- (void)webView:(WebView *)_sender 
       resource:(id)_identifier 
  didReceiveResponse:(NSURLResponse *)_response 
 fromDataSource:(WebDataSource *)_ds
{
    if (debugOn) {
        NSLog(@"%s: view: %@\n  resource: %@\n  received: %@\n"
              @"  datasource: %@\n  data-len: %i%s",
              __PRETTY_FUNCTION__,
              _sender, _identifier, _response, _ds, 
              [[_ds data] length], [_ds isLoading]?" LOADING":"");
    }
}


#pragma mark -
#pragma mark ### WebFrame Load DELEGATE ###


- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
    if(self->document != nil && [self->document hasChanges])
    {
        id panel;
        int rc;
        
        panel = NSGetAlertPanel(
                                NSLocalizedString(@"Do you want to save changes to the source code before proceeding?", "Title of the alert sheet when user wants to proceed but changes are still not saved"),
                                NSLocalizedString(@"If you don\\u2019t save, your changes will be lost.", "Message of the alert sheet when unsaved changes are about to be lost"),
                                NSLocalizedString(@"Save", "Default button text for the alert sheet"),
                                NSLocalizedString(@"Don\\u2019t save", "Alternate button text for the alert sheet"),
                                NULL);
        
        rc = SOPEXRunSheetModalForWindow(panel, self->mainWindow);
        NSReleaseAlertPanel(panel);
        
        // NSAlertOtherReturn == Cancel
        // NSAlertAlternateReturn == Don't save
        // NSAlertDefaultReturn == Save
        
        if(rc == NSAlertDefaultReturn)
            [self saveDocument:self];
    }
    [self flushDocument];
    [self->progressIndicator startAnimation:self];
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)_title forFrame:(WebFrame *)_frame
{
    [self->mainWindow setTitle:_title];
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
    [self->progressIndicator stopAnimation:self];

#if 0
#warning ** setFavIcon enabled ... doesnt really make sense
    [self->mainWindow setFavIcon:[sender pageIcon]];
#endif
    [self createDocumentFromResponse];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    [self->progressIndicator stopAnimation:self];
    [self setStatus:[error localizedDescription] isError:YES];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
    [self webView:sender didFailLoadWithError:error forFrame:frame];
}


#pragma mark -
#pragma mark ### WebView UI DELEGATE ###


- (BOOL)webViewIsStatusBarVisible:(WebView *)sender
{
    return YES;
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(unsigned int)modifierFlags
{
    NSURL *url;

#if 0
    NSLog(@"%s elementInformation:%@", __PRETTY_FUNCTION__, elementInformation);
#endif


    url = [elementInformation objectForKey:WebElementImageURLKey];
    if(url != nil)
    {
        NSString *altString;
        NSRect imageRect;
        NSImage *image;
        NSMutableString *status;

        altString = [elementInformation objectForKey:WebElementImageAltStringKey];
        imageRect = [[elementInformation objectForKey:WebElementImageRectKey] rectValue];
        image = [elementInformation objectForKey:WebElementImageKey];

        status = [NSMutableString string];

        if(altString == nil)
            altString = [url absoluteString];

        url = [elementInformation objectForKey:WebElementLinkURLKey];
        if(url != nil)
            [status appendFormat:@"%@    ", [url absoluteString]];

        [status appendFormat:@"[%@]   (w:%.0f h:%.0f)", altString, imageRect.size.width, imageRect.size.height];
        if(NSEqualSizes([image size], imageRect.size) == NO)
        {
            NSSize size = [image size];
            [status appendFormat:@" -> scaled from (w:%.0f h:%.0f)!", size.width, size.height];
        }

        [self setStatus:status];
        return;
    }

    url = [elementInformation objectForKey:WebElementLinkURLKey];
    if(url != nil)
    {
        [self setStatus:[url absoluteString]];
        return;
    }
    
    [self setStatus:nil];
}

@end
