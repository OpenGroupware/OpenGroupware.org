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
//  Created by znek on Wed Feb 11 2004.

#import "SOPEXSNSController.h"
#include <netinet/in.h>
#include <sys/types.h>
#include <sys/socket.h>


#define DNC [NSNotificationCenter defaultCenter]
#define UD [NSUserDefaults standardUserDefaults]


NSString *SNSApplicationNameKey    = @"Name";
NSString *SNSApplicationPathKey    = @"Path";
NSString *SNSApplicationPIDKey     = @"PID";
NSString *SNSApplicationAddressKey = @"Address";


typedef enum {
    SNSUnregisterInstance = 0,
    SNSRegisterInstance   = 1,
    SNSRegisterSession    = 2,
    SNSExpireSession      = 3,
    SNSTerminateSession   = 4,
    SNSLookupSession      = 50,
    SNSInstanceAlive      = 100
} SNSMessageCode;


@interface NSFileHandle (SOPEXSNSControllerPrivate)
- (NSData *)_safeReadDataOfLength:(unsigned int)length;
- (NSData *)_snsGetData;
- (NSString *)_snsGetString;
- (int)_snsGetInt;
@end

@implementation NSFileHandle (SOPEXSNSControllerPrivate)
- (NSData *)_safeReadDataOfLength:(unsigned int)length
{
    NSMutableData *safeData;
    NSData *data;
    int stillNeeded;

    data = [self readDataOfLength:length];
    stillNeeded = length - [data length];
    
    if(stillNeeded == 0)
        return data;

    safeData = [[NSMutableData alloc] initWithData:data];
    while(stillNeeded > 0)
    {
        data = [self readDataOfLength:stillNeeded];
        [safeData appendData:data];
        stillNeeded -= [data length];
    }
    return [safeData autorelease];
}

- (NSData *)_snsGetData
{
    NSData *data;
    int length;
    
    // Application Name
    data = [self _safeReadDataOfLength:sizeof(int)];
    length = *(int *)[data bytes];
    data = [self _safeReadDataOfLength:length];
    return data;
}
- (NSString *)_snsGetString
{
    NSData *data = [self _snsGetData];
    return [[[NSString alloc] initWithCString:(const char *)[data bytes] length:[data length]] autorelease];
}
- (int)_snsGetInt
{
    NSData *data;
    int integer;

    data = [self _safeReadDataOfLength:sizeof(int)];
    integer = *(int *)[data bytes];
    return integer;
}

@end


@implementation SOPEXSNSController

#pragma mark -
#pragma mark ### INIT & DEALLOC ###


- (id)init
{
    [super init];
    self->connectionLUT = [[NSMutableDictionary alloc] initWithCapacity:1];
    return self;
}

- (void)dealloc
{
    [self stop];
    [self->connectionLUT release];
    [super dealloc];
}


#pragma mark -
#pragma mark ### DELEGATE ###


- (void)setDelegate:(id)_delegate
{
    self->delegate = _delegate;
    self->dflags.respondsToUnregisterInstance = [_delegate respondsToSelector:@selector(snsController:unregisterInstance:)];
    self->dflags.respondsToRegisterInstance = [_delegate respondsToSelector:@selector(snsController:registerInstance:)];
    self->dflags.respondsToInstanceIsAlive = [_delegate respondsToSelector:@selector(snsController:instanceIsAlive:)];
    self->dflags.respondsToRegisterSession = [_delegate respondsToSelector:@selector(snsController:instance:sessionDidCreate:)];
    self->dflags.respondsToExpireSession = [_delegate respondsToSelector:@selector(snsController:instance:sessionDidExpire:)];
    self->dflags.respondsToTerminateSession = [_delegate respondsToSelector:@selector(snsController:instance:sessionDidTerminate:)];
}

- (id)delegate
{
    return self->delegate;
}


#pragma mark -
#pragma mark ### START & STOP ###


- (void)start
{
    int sd;
    struct sockaddr_in sockaddr;

    // create socket
    sd = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    NSAssert1(sd >= 0, @"Couldn't create server socket: %s", strerror(errno));

    memset(&sockaddr, 0, sizeof(struct sockaddr_in));
    sockaddr.sin_family = AF_INET;
    sockaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    sockaddr.sin_port = [UD integerForKey:@"SNSPort"];

    // bind
    NSAssert1(bind(sd, (struct sockaddr *)&sockaddr, sizeof(sockaddr)) != -1, @"Couldn't bind socket: %s", strerror(errno));

    // listen with backlog of 5
    NSAssert1(listen(sd, 5) != -1, @"Couldn't listen on socket: %s", strerror(errno));

    // create NSFileHandle if all is well
    self->serverSocket = [[NSFileHandle alloc] initWithFileDescriptor:sd closeOnDealloc:YES];

    // we're ready to accept connections now
    [DNC addObserver:self selector:@selector(acceptConnection:) name:NSFileHandleConnectionAcceptedNotification object:self->serverSocket];
    [self->serverSocket acceptConnectionInBackgroundAndNotify];
}

- (void)stop
{
    [DNC removeObserver:self];
    [self->serverSocket release];
    self->serverSocket = nil;
}


#pragma mark -
#pragma mark ### ACCESSORS ###


- (NSString *)socketAddress
{
    int sockaddrLength;
    struct sockaddr_in sockaddr;
    
    sockaddrLength = sizeof(struct sockaddr_in);
    NSAssert1(getsockname([self->serverSocket fileDescriptor], (struct sockaddr *)&sockaddr, &sockaddrLength) != -1, @"Cannot get local port number for socket: %s", strerror(errno));
    return [NSString stringWithFormat:@"localhost:%d", ntohs(sockaddr.sin_port)];
}


#pragma mark -
#pragma mark ### SNSD PROTOCOL ###


- (NSDictionary *)_instanceDescriptionForFileHandle:(NSFileHandle *)fileHandle
{
    return [self->connectionLUT objectForKey:[NSNumber numberWithInt:[fileHandle fileDescriptor]]];
}

- (void)_unregisterInstance:(NSFileHandle *)fileHandle
{
    if(self->dflags.respondsToUnregisterInstance)
        [self->delegate snsController:self unregisterInstance:[self _instanceDescriptionForFileHandle:fileHandle]];
    [self->connectionLUT removeObjectForKey:[NSNumber numberWithInt:[fileHandle fileDescriptor]]];
}

- (void)_registerInstance:(NSFileHandle *)fileHandle description:(NSDictionary *)instanceDescription
{
    [self->connectionLUT setObject:instanceDescription forKey:[NSNumber numberWithInt:[fileHandle fileDescriptor]]];
    if(self->dflags.respondsToRegisterInstance)
        [self->delegate snsController:self registerInstance:instanceDescription];
}


- (void)acceptConnection:(NSNotification *)notification
{
    NSFileHandle *remote;

    remote = [[notification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem];
    [remote retain];

    [DNC addObserver:self selector:@selector(availableData:) name:NSFileHandleDataAvailableNotification object:remote];
    [remote waitForDataInBackgroundAndNotify];
    [self->serverSocket acceptConnectionInBackgroundAndNotify];
}

- (void)availableData:(NSNotification *)notification
{
    NSFileHandle *remote;
    NSData *data;
    SNSMessageCode msg;
    
    remote = [notification object];
    data = [remote readDataOfLength:1];
    if([data length] == 0)
    {
#if 1
        NSLog(@"%s remote end did die!", __PRETTY_FUNCTION__);
#endif
        [DNC removeObserver:self name:NSFileHandleDataAvailableNotification object:remote];
        [self _unregisterInstance:remote];
        [remote release];
        return;
    }
    
    msg = *(char *)[data bytes];
    if(msg == SNSInstanceAlive)
    {
        if(self->dflags.respondsToInstanceIsAlive)
            [self->delegate snsController:self instanceIsAlive:[self _instanceDescriptionForFileHandle:remote]]; 
    }
    else if(msg == SNSRegisterSession)
    {
        NSString *sessionID;
        
        sessionID = [remote _snsGetString];
        if(self->dflags.respondsToRegisterSession)
            [self->delegate snsController:self instance:[self _instanceDescriptionForFileHandle:remote] sessionDidCreate:sessionID];
    }
    else if(msg == SNSExpireSession)
    {
        NSString *sessionID;
        
        sessionID = [remote _snsGetString];
        if(self->dflags.respondsToExpireSession)
            [self->delegate snsController:self instance:[self _instanceDescriptionForFileHandle:remote] sessionDidExpire:sessionID];
    }
    else if(msg == SNSTerminateSession)
    {
        NSString *sessionID;
        
        sessionID = [remote _snsGetString];
        if(self->dflags.respondsToTerminateSession)
            [self->delegate snsController:self instance:[self _instanceDescriptionForFileHandle:remote] sessionDidTerminate:sessionID];
    }
    else if(msg == SNSRegisterInstance)
    {
        NSMutableDictionary *instanceDescription;
        id tmp, applicationAddress;
        int pid;

        instanceDescription = [[NSMutableDictionary alloc] initWithCapacity:3];

        // Application Name
        tmp = [remote _snsGetString];
        [instanceDescription setObject:tmp forKey:SNSApplicationNameKey];

        // Application Path
        tmp = [remote _snsGetString];
        [instanceDescription setObject:tmp forKey:SNSApplicationPathKey];

        // Application PID
        pid = [remote _snsGetInt];
        [instanceDescription setObject:[NSNumber numberWithInt:pid] forKey:SNSApplicationPIDKey];

        // Application Address
        tmp = [remote _snsGetData];
        applicationAddress = [NSUnarchiver unarchiveObjectWithData:tmp];
        [instanceDescription setObject:applicationAddress forKey:SNSApplicationAddressKey];

        [self _registerInstance:remote description:instanceDescription];
        [instanceDescription release];
    }
    else if(msg == SNSUnregisterInstance)
    {
        [self _unregisterInstance:remote];
    }
    else
    {
        NSLog(@"%s ignoring unknown messageCode:%d Dropping %d bytes.", __PRETTY_FUNCTION__, msg, [[remote availableData] length]);
    }
    [remote waitForDataInBackgroundAndNotify];
}

@end
