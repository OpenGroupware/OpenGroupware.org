/*
  Copyright (C) 2000-2004 SKYRIX Software AG

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

#import <Foundation/NSObject.h>

@class NSString;

@interface InstallSieve : NSObject
{
  NSString *fileName;
  NSString *port;
  NSString *serverName;
  NSString *login;
  NSString *password;
}
- (id)initWithFileName:(NSString *)_file
  port:(NSString *)_port
  serverName:(NSString *)_serverName
  login:(NSString *)_login
  password:(NSString *)_password;
- (BOOL)deleteScript;
- (BOOL)installScript;

@end

#if COCOA_Foundation_LIBRARY || APPLE_Foundation_LIBRARY || NeXT_Foundation_LIBRARY
#  include <NGExtensions/NGObjectMacros.h>
#endif

#include <NGImap4/NGSieveClient.h>
#include <NGMail/NGMail.h>
#include <NGStreams/NGInternetSocketAddress.h>
#include <NGStreams/NGSocketExceptions.h>
#import <Foundation/Foundation.h>

id _getArg(NSDictionary *_arg, NSArray *_keys) {
  id           obj;
  NSEnumerator *enumerator;

  enumerator = [_keys objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    id o = nil;
    if ((o = [_arg objectForKey:obj]) != nil)
      return o;
  }
  return nil;
}

NSString *convertFileToSieveFormat(NSString *_fileName) {
  // TODO: cleanup this huge file!
  NSArray         *f;
  NSMutableString *sieveFilter;
  NSEnumerator    *enumerator;
  BOOL            firstEntry;
  id              aFilter;
  NSDictionary    *vacation, *forward;
  
  f = [[NSArray alloc] initWithContentsOfFile:_fileName];

  if (![f count])
    return nil;
  
  enumerator  = [f objectEnumerator];

  vacation = nil;
  forward   = nil;
  
  while ((aFilter = [enumerator nextObject])) {
    if ([[aFilter objectForKey:@"kind"] isEqualToString:@"vacation"])
      vacation = aFilter;
    else if ([[aFilter objectForKey:@"kind"] isEqualToString:@"forward"])
      forward = aFilter;

    if (forward && vacation) {
      break;
    }
  }
  firstEntry  = YES;
  sieveFilter = [[NSMutableString alloc] init];
  [sieveFilter appendString:@"require [\"fileinto\"];\n"];

  if (forward)
    [sieveFilter appendString:@"require [\"reject\"];\n"];

  if (vacation) {
    NSEnumerator *addenum;
    id           addr;
    BOOL         isFirst;
    
    [sieveFilter appendString:@"require [\"vacation\"];\n\n"];

    [sieveFilter appendFormat:@"vacation :days %@ :addresses [",
                 [vacation objectForKey:@"repeatInterval"]];

    addenum = [[vacation objectForKey:@"emails"] objectEnumerator];

    isFirst = YES;
    
    while ((addr = [addenum nextObject])) {
      if (isFirst)
        isFirst = NO;
      else
        [sieveFilter appendString:@", "];
      
      [sieveFilter appendFormat:@"\"%@\"", addr];
    }
    [sieveFilter appendString:@"]"];

    if ([[vacation objectForKey:@"subject"] length]) {
      [sieveFilter appendFormat:@" :subject \"%@\"",
                   [vacation objectForKey:@"subject"]];
    }
    [sieveFilter appendFormat:@" text:\n%@\n.\n;\n",
                 [vacation objectForKey:@"text"]];
  }

  if (forward) {
    NSEnumerator *enumerator;
    NSString     *m;

    enumerator = [[forward objectForKey:@"emails"] objectEnumerator];
    while ((m = [enumerator nextObject])) {
      [sieveFilter appendFormat:@"redirect \"%@\";\n", m];
    }
    if ([[forward objectForKey:@"keepMails"] boolValue])
      [sieveFilter appendString:@"keep;\n"];
  }
  
  enumerator = [f objectEnumerator];

  while ((aFilter = [enumerator nextObject])) {
    id           entries, aEntry;
    NSEnumerator *entrEnum;

    entries   = [aFilter objectForKey:@"entries"];
    
    if ([aFilter objectForKey:@"kind"])
      continue;
    
    if ([entries count] > 0) {
      BOOL     isFirst;
      NSString *fileName;

      isFirst   = YES;
      
      if (firstEntry == YES) {
        [sieveFilter appendString:@"if "];
        firstEntry = NO;
      }
      else
        [sieveFilter appendString:@"elsif "];

      if ([[aFilter objectForKey:@"match"] isEqualToString:@"or"] == YES)
        [sieveFilter appendString:@"anyof ("];
      else
        [sieveFilter appendString:@"allof ("];

      entrEnum = [entries objectEnumerator];
      while ((aEntry = [entrEnum nextObject])) {
        NSString *kind;

        kind = [aEntry objectForKey:@"filterKind"];
        
        if (isFirst == YES)
          isFirst = NO;
        else
          [sieveFilter appendString:@", "];

        if ([kind isEqualToString:@"contains"] == YES)
          [sieveFilter appendString:@"header :contains"];
        else if ([kind isEqualToString:@"doesn`t contain"] == YES)
          [sieveFilter appendString:@"not header :contains"];
        else if ([kind isEqualToString:@"is"] == YES)
          [sieveFilter appendString:@"header :is"];
        else if ([kind isEqualToString:@"isn`t"] == YES)
          [sieveFilter appendString:@"not header :is"];
        else if ([kind isEqualToString:@"begins with"] == YES)
          [sieveFilter appendString:@"header :matches"];
        else if ([kind isEqualToString:@"ends with"] == YES)
          [sieveFilter appendString:@"header :matches"];
        else
          NSLog(@"couldn`t use entry %@", aEntry);

        {
          NSEnumerator *e;
          id           obj;
          
          e = [[[aEntry objectForKey:@"headerField"]
                        componentsSeparatedByString:@":"] objectEnumerator];
          isFirst = YES;

          [sieveFilter appendString:@" ["];
          while ((obj = [e nextObject])) {
            if (isFirst)
              isFirst = NO;
            else
              [sieveFilter appendString:@","];

            [sieveFilter appendString:@"\""];
            [sieveFilter appendString:obj];
            [sieveFilter appendString:@"\""];
          }
          [sieveFilter appendString:@"] \""];
        }
        if ([kind isEqualToString:@"ends with"] == YES)
          [sieveFilter appendString:@"*"];

        [sieveFilter appendString:[aEntry objectForKey:@"string"]];

        if ([kind isEqualToString:@"begins with"] == YES)
          [sieveFilter appendString:@"*"];

        [sieveFilter appendString:@"\""];
      }
      [sieveFilter appendString:@")\n {\n"];

      if ([[aFilter objectForKey:@"folder"] length] > 0) {
        [sieveFilter appendString:@"fileinto \""];

        fileName = [aFilter objectForKey:@"folder"];
        if ([fileName hasPrefix:@"/"] == YES)
          fileName = [fileName substringWithRange:
                               NSMakeRange(1, [fileName length] - 1)];

        fileName = [[fileName componentsSeparatedByString:@"/"]
                              componentsJoinedByString:@"."];
        [sieveFilter appendString:fileName];
        [sieveFilter appendString:@"\";\n "];
      }
      else if ([[aFilter objectForKey:@"forwardAddress"] length] > 0) {
        NSString *str;
        NGMailAddressParser *parser;
        
        [sieveFilter appendString:@"redirect \""];

        fileName = [aFilter objectForKey:@"forwardAddress"];

        if ([fileName length] == 0) {
          NSLog(@"missing forwardAddress for %@", aFilter);
          str = @"";
        }
        else {
          parser = [NGMailAddressParser mailAddressParserWithString:fileName];
          str    = [(NGMailAddress *)[parser parse] address];

          if ([str length] == 0) {
            NSLog(@"couldn`t parse address %@", fileName);
            str = @"";
          }
        }
        [sieveFilter appendString:str];
        [sieveFilter appendString:@"\";\n "];
      }
      [sieveFilter appendString:@"}\n"];
    }
  }
  ASSIGN(f, nil);
  return [sieveFilter autorelease];
}

NSDictionary *getArgs() {
  /* determine argument domain take from NSUserDefaults */
  NSMutableDictionary *defArgs = nil;
  NSArray             *args;
  int                 n, i;

  args    = [[NSProcessInfo processInfo] arguments];
  *(&n)   = [args count];
  defArgs = [NSMutableDictionary dictionaryWithCapacity:(n / 2)];

  for (*(&i) = 0; i < n; i++) {
    NSString *argument;

    *(&argument) = [args objectAtIndex:i];

    if ([argument hasPrefix:@"-"] && [argument length] > 1) {
      // found option
      if ((i + 1) == n) { // is last option ?
        fprintf(stderr,
                "Missing value for command line default '%s'.\n",
                [[argument substringFromIndex:1] cString]);
      }
      else { // is not the last option
        id value = [args objectAtIndex:(i + 1)];

        argument = [argument substringFromIndex:1];

        // parse property list value
        NS_DURING {
          *(&value) = [value stringValue];
        }
        NS_HANDLER {}
        NS_ENDHANDLER;

        if (value == nil) {
          fprintf(stderr,
                  "Could not process value %s "
                  "of command line default '%s'.\n",
                  [argument cString],
                  [[args objectAtIndex:(i + 1)] cString]);
        }
        else {
          [defArgs setObject:value forKey:argument];
        }
        i++; // skip value
      }
    }
  }
  return defArgs;
}  

int main(int argc, const char **argv, char **env) {
  int result;
  NSAutoreleasePool *pool;

  *(&result) = 0;
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void*)argv count:argc environment:env];
  [NSAutoreleasePool enableDoubleReleaseCheck:NO];
#endif
  //NGInitTextStdio();

  pool = [NSAutoreleasePool new];
  if (argc == 1) {
    printf("  sky_install_sieve 2.0\n");
    printf("\n");
    printf("  Author Jan Reichmann (jr@skyrix.com)\n\n");    
    printf("  Install cyrus sieve filters.\n");
    printf("  \n");
    printf("  Defaults/Arguments\n");
    printf("\n");
    printf("  login                or l   nil  Login    \n");
    printf("  pwd                  or p   nil  Password (Default = '')\n");
    printf("  server               or s   nil  server name (Default = '"
           "localhost')\n");
    printf("  port                 or po  nil  port (Default = '2000')\n");
    printf("  install-dictionary   or id  nil  filename with filters as dictionary"
           " format to install\n");
    printf("  install-sieve        or is  nil  filename with filters as sieve "
           "format to install\n");
    printf("\n");
    printf("  return values : 0   - OK\n");
    printf("\n");
    return 0;
  }
  NS_DURING {
    NSDictionary *args;
    NSString     *login, *password, *server, *port, *dictName;
    NSString     *sievName, *filter, *scriptName;

    

    args     = getArgs();
    login    = _getArg(args, [NSArray arrayWithObjects:@"login", @"l", nil]);
    password = _getArg(args, [NSArray arrayWithObjects:@"pwd", @"p", nil]);
    port     = _getArg(args, [NSArray arrayWithObjects:@"port", @"po", nil]);
    server   = _getArg(args, [NSArray arrayWithObjects:@"server", @"s", nil]);
    dictName = _getArg(args, [NSArray arrayWithObjects:@"install-dictionary",
                                      @"id", nil]);
    sievName = _getArg(args, [NSArray arrayWithObjects:@"install-sieve",
                                      @"is", nil]);

    filter     = nil;

    scriptName = [[NSUserDefaults standardUserDefaults]
                                  stringForKey:@"SieveScriptName"];

    if (![scriptName length])
      scriptName = @"ogo";

    if (login == nil) {
      NSLog(@"missing login");
      return 1;
    }
    if (password == nil) {
      password = @"";
      return 1;
    }
    if (port == nil) {
      port = @"2000";
      return 1;
    }
    if (server == nil) {
      server = @"localhost";
      return 1;
    }
    if (dictName != nil) {
      if (![[NSFileManager defaultManager] fileExistsAtPath:dictName]) {
        NSLog(@"missing file at path %@", dictName);
        return 1;
      }
      filter = convertFileToSieveFormat(dictName);
    }
    else if (sievName != nil) {
      if (![[NSFileManager defaultManager] fileExistsAtPath:dictName]) {
        NSLog(@"missing file at path %@", dictName);
        return 1;
      }
      filter = [NSString stringWithContentsOfFile:sievName];
    }
    else {
      NSLog(@"missing action");
      return 1;
    }
    {
      NGSieveClient           *client;
      NGInternetSocketAddress *addr;
      NSDictionary            *res;

      addr   = [NGInternetSocketAddress addressWithPort:[port intValue]
                                        onHost:server];
      client = [(NGSieveClient *)[NGSieveClient alloc] initWithAddress:addr];


      [client openConnection];
      
      res = [client login:login password:password];

      if ([[res objectForKey:@"result"] boolValue] == NO) {
        NSLog(@"login failed for %@ user %@", client, login);
        exit(3);
      }
      if ([filter length]) {
        [client putScript:scriptName script:filter]; 
        [client setActiveScript:scriptName]; 
        [client closeConnection];
      }
      else {
        [client deleteScript:scriptName]; 
        [client closeConnection];
      }
    }
  }
  NS_HANDLER {
    printf("got exception %s\n", [[localException description] cString]);

    if ([localException isKindOfClass:[NGCouldNotConnectException class]]) {
      printf("couldn`t connect to server\n");
      exit(4);
    }
    [localException raise];
  }
  NS_ENDHANDLER;
  RELEASE(pool);
  return result;
}
