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


#import "SOPEXConsole.h"
#import "SOPEXToolbarController.h"


#define DNC [NSNotificationCenter defaultCenter]


@interface SOPEXConsole (PrivateAPI)
- (NSFont *)stdoutFont;
- (NSFont *)stderrFont;
- (NSColor *)stdoutFontColor;
- (NSColor *)stderrFontColor;

- (void)appendConsoleData:(NSData *)data usingAttributes:(NSDictionary *)attributes;
@end


@implementation SOPEXConsole

#pragma mark -
#pragma mark ### INIT & DEALLOC ###


- (id)init
{
    [super init];

    [NSBundle loadNibNamed:@"SOPEXConsole" owner:self];
    NSAssert(self->window != nil, @"Problem loading SOPEXConsole.nib!");

    self->toolbar = [[SOPEXToolbarController alloc] initWithIdentifier:@"SOPEXConsole" target:self];
    [self->toolbar applyOnWindow:self->window];

    self->stdoutAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[self stdoutFont], NSFontAttributeName, [self stdoutFontColor], NSForegroundColorAttributeName, nil];
    self->stderrAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[self stderrFont], NSFontAttributeName, [self stderrFontColor], NSForegroundColorAttributeName, nil];
    return self;
}

- (id)initWithStandardOutput:(id)standardOutput standardError:(id)standardError
{
    [self init];
    [self setStandardOutput:standardOutput standardError:standardError];
    return self;
}

- (void)dealloc
{
    [DNC removeObserver:self];
    [self->window orderOut:self];
    [self->stdoutPipe release];
    [self->stderrPipe release];
    [self->stdoutAttributes release];
    [self->stderrAttributes release];
    [super dealloc];
}


#pragma mark -
#pragma mark ### CONSOLE PROPERTIES ###


- (NSFont *)stdoutFont
{
    return [NSFont fontWithName:@"Courier" size:12];
}

- (NSFont *)stderrFont
{
    return [NSFont fontWithName:@"Courier" size:12];
}

- (NSColor *)stdoutFontColor
{
    return [NSColor blackColor];
}

- (NSColor *)stderrFontColor
{
    return [NSColor redColor];
}


#pragma mark -
#pragma mark ### WINDOW HANDLING & DELEGATE ###


- (IBAction)orderFront:(id)sender
{
    [self->window makeKeyAndOrderFront:sender];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
}


#pragma mark -
#pragma mark ### ACTIONS ###


- (IBAction)clear:(id)sender
{
    NSTextStorage *textStorage;

    textStorage = [self->text textStorage];
    [textStorage beginEditing];
    [textStorage deleteCharactersInRange:NSMakeRange(0, [textStorage length])];
    [textStorage endEditing];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return [self validateMenuItem:(id <NSMenuItem>)theItem];
}

- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem
{
    SEL action = [menuItem action];
    
    if(action == @selector(clear:))
        return [[self->text textStorage] length] > 0;
    return YES;
}


#pragma mark -
#pragma mark ### STDOUT & STDERR ###


- (void)setStandardOutput:(id)standardOutput standardError:(id)standardError
{
    if(self->stdoutPipe != nil)
    {
        [DNC removeObserver:self name:NSFileHandleReadCompletionNotification object:self->stdoutPipe];
        [self->stdoutPipe release];
    }
    self->stdoutPipe = [standardOutput retain];
    if(self->stderrPipe != nil)
    {
        [DNC removeObserver:self name:NSFileHandleReadCompletionNotification object:self->stderrPipe];
        [self->stderrPipe release];
    }
    self->stderrPipe = [standardError retain];

    // register for NSFileHandle notifications
    [DNC addObserver:self selector:@selector(readData:) name:NSFileHandleReadCompletionNotification object:[self->stdoutPipe fileHandleForReading]];
    [DNC addObserver:self selector:@selector(readData:) name:NSFileHandleReadCompletionNotification object:[self->stderrPipe fileHandleForReading]];
    
    // start reading in background
    [[self->stdoutPipe fileHandleForReading] readInBackgroundAndNotify];
    [[self->stderrPipe fileHandleForReading] readInBackgroundAndNotify];
}


#pragma mark -
#pragma mark ### POLLING ###


- (void)readData:(NSNotification *)notification
{
    NSData *data;
    NSFileHandle *fileHandle;
    NSDictionary *attributes;

    fileHandle = [notification object];
    data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];

    if([data length] == 0)
    {
        NSLog(@"%s pipe closed the connection!", __PRETTY_FUNCTION__);
        return;
    }
    
    [fileHandle readInBackgroundAndNotify];

    if(fileHandle == [self->stdoutPipe fileHandleForReading])
        attributes = self->stdoutAttributes;
    else
        attributes = self->stderrAttributes;

    [self appendConsoleData:data usingAttributes:attributes];
}

- (void)appendConsoleData:(NSData *)data usingAttributes:(NSDictionary *)attributes
{
    NSTextStorage *textStorage;
    NSString *message;
    unsigned int location;

    textStorage = [self->text textStorage];

//    NSLog(@"%s ping ... %@", __PRETTY_FUNCTION__, textStorage);

    message = [[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding];

    [textStorage beginEditing];
    location = [textStorage length];
    [textStorage replaceCharactersInRange:NSMakeRange(location, 0) withString:message];
    [textStorage setAttributes:attributes range:NSMakeRange(location, [textStorage length] - location)];

    if([textStorage length] > 50 * 1024)
        [textStorage deleteCharactersInRange:NSMakeRange(0, [textStorage length] - 50 * 1024)];
    [textStorage endEditing];

    [message release];

    // scroll to bottom if verticalScroller is at bottom
    if([[(NSScrollView*)[[self->text superview] superview] verticalScroller] floatValue] == 1.0)
        [self->text scrollRangeToVisible:NSMakeRange([textStorage length], 1)];
}

@end
