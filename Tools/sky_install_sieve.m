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

@class NSString, NSArray;

@interface InstallSieve : NSObject
{
  NSString *login;
  NSString *password;
  NSString *server;
  NSString *port;
  NSString *dictName;
  NSString *sievName;
}

+ (int)runWithArguments:(NSArray *)_args;

@end

#if COCOA_Foundation_LIBRARY || APPLE_Foundation_LIBRARY || \
    NeXT_Foundation_LIBRARY
#  include <NGExtensions/NGObjectMacros.h>
#endif

#include <NGImap4/NGSieveClient.h>
#include <NGMail/NGMail.h>
#include <NGStreams/NGInternetSocketAddress.h>
#include <NGStreams/NGSocketExceptions.h>
#include "common.h"

// TODO: this is a mess! needs a lot of cleanup

@implementation InstallSieve

id _getArg(NSDictionary *_arg, NSArray *_keys) {
  id           obj;
  NSEnumerator *enumerator;

  enumerator = [_keys objectEnumerator];
  while ((obj = [enumerator nextObject])) {
    id o;
    
    if ((o = [_arg objectForKey:obj]) != nil)
      return o;
  }
  return nil;
}

- (NSString *)convertFileToSieveFormat:(NSString *)_fileName {
  // TODO: cleanup this huge method!
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
  
  while ((aFilter = [enumerator nextObject]) != nil) {
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
      
      if (firstEntry) {
        [sieveFilter appendString:@"if "];
        firstEntry = NO;
      }
      else
        [sieveFilter appendString:@"elsif "];

      if ([[aFilter objectForKey:@"match"] isEqualToString:@"or"])
        [sieveFilter appendString:@"anyof ("];
      else
        [sieveFilter appendString:@"allof ("];

      entrEnum = [entries objectEnumerator];
      while ((aEntry = [entrEnum nextObject])) {
        NSString *kind;

        kind = [aEntry objectForKey:@"filterKind"];
        
        if (isFirst)
          isFirst = NO;
        else
          [sieveFilter appendString:@", "];

        // TODO: this might conflict with UI labels?!
        if ([kind isEqualToString:@"contains"])
          [sieveFilter appendString:@"header :contains"];
        else if ([kind isEqualToString:@"doesn`t contain"])
          [sieveFilter appendString:@"not header :contains"];
        else if ([kind isEqualToString:@"is"])
          [sieveFilter appendString:@"header :is"];
        else if ([kind isEqualToString:@"isn`t"])
          [sieveFilter appendString:@"not header :is"];
        else if ([kind isEqualToString:@"begins with"])
          [sieveFilter appendString:@"header :matches"];
        else if ([kind isEqualToString:@"ends with"])
          [sieveFilter appendString:@"header :matches"];
        else
          NSLog(@"couldn`t use entry '%@'", aEntry);

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
        if ([kind isEqualToString:@"ends with"])
          [sieveFilter appendString:@"*"];

        [sieveFilter appendString:[aEntry objectForKey:@"string"]];

        if ([kind isEqualToString:@"begins with"])
          [sieveFilter appendString:@"*"];

        [sieveFilter appendString:@"\""];
      }
      [sieveFilter appendString:@")\n {\n"];

      if ([[aFilter objectForKey:@"folder"] length] > 0) {
        [sieveFilter appendString:@"fileinto \""];

        fileName = [aFilter objectForKey:@"folder"];
        if ([fileName hasPrefix:@"/"])
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

- (NSDictionary *)getArgs {
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

- (void)usage {
    printf("  sky_install_sieve\n");
    printf("\n");
    printf("  Install Cyrus Sieve filters.\n");
    printf("  \n");
    printf("  Defaults/Arguments\n");
    printf("\n");
    printf("  login                or l   nil  Login    \n");
    printf("  pwd                  or p   nil  Password (Default = '')\n");
    printf("  server               or s   nil  server name (Default = '"
           "localhost')\n");
    printf("  port                 or po  nil  port (Default = '2000')\n");
    printf("  install-dictionary   or id  nil  filename with filters as "
           "dictionary format to install\n");
    printf("  install-sieve        or is  nil  filename with filters as sieve "
           "format to install\n");
    printf("\n");
    printf("  return values : 0   - OK\n");
    printf("\n");
}

/* running */

- (void)handleException:(NSException *)_exception {
  if (_exception == nil)
    return;

  [self logWithFormat:@"ERROR: got exception: %@", _exception];

  if ([_exception isKindOfClass:[NGCouldNotConnectException class]]) {
    printf("couldn`t connect to server\n");
    exit(4);
  }
  
  exit(5);
}

- (NSString *)sieveScriptName {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  NSString *scriptName;
  
  scriptName = [ud stringForKey:@"SieveScriptName"];
  if ([scriptName length] == 0)
    scriptName = @"ogo";
  return scriptName;
}

- (id)_getArg:(NSString *)_k1:(NSString *)_k2 from:(NSDictionary *)_args {
  return _getArg(_args, [NSArray arrayWithObjects:_k1, _k2, nil]);
}
- (BOOL)_extractParameters {
  NSDictionary *args;

  args = [self getArgs];
  
  self->login    = [[self _getArg:@"login":@"l"  from:args] copy];
  self->password = [[self _getArg:@"pwd":@"p"    from:args] copy];
  self->port     = [[self _getArg:@"port":@"po"  from:args] copy];
  self->server   = [[self _getArg:@"server":@"s" from:args] copy];
  self->dictName = [[self _getArg:@"install-dictionary":@"id" from:args] copy];
  self->sievName = [[self _getArg:@"install-sieve":@"is" from:args] copy];

  /* validate */
  
  if ([login length] == 0) {
    NSLog(@"missing login");
    return NO;
  }
  if (password == nil)
    return NO;
  
  if (port == nil)
    self->port = @"2000";
  if (server == nil)
    self->server = @"localhost";
  
  return YES;
}

- (NSString *)_extractFilter {
  NSString *filter;
  
  if (dictName != nil) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:dictName]) {
      NSLog(@"missing file at path %@", dictName);
      return nil;
    }
    filter = [self convertFileToSieveFormat:dictName];
  }
  else if (sievName != nil) {
    if (![[NSFileManager defaultManager] fileExistsAtPath:dictName]) {
      NSLog(@"missing file at path %@", dictName);
      return nil;
    }
    filter = [NSString stringWithContentsOfFile:sievName];
  }
  else {
    NSLog(@"missing action");
    return nil;
  }
  return filter;
}

- (int)runWithArguments:(NSArray *)_args {
  if ([_args count] < 2) {
    [self usage];
    return 1;
  }
  
  NS_DURING {
    NSString *filter, *scriptName;
    
    if (![self _extractParameters])
      return 1;
    
    filter     = nil;
    scriptName = [self sieveScriptName];
    
    if ((filter = [self _extractFilter]) == nil)
      return 1;
    
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
      if ([filter length] > 0) {
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
  NS_HANDLER
    [self handleException:localException];
  NS_ENDHANDLER;

  return 0;
}
+ (int)runWithArguments:(NSArray *)_args {
  return [[[[self alloc] init] autorelease] runWithArguments:_args];
}

@end /* InstallSieve */

int main(int argc, const char **argv, char **env) {
  int result;
  NSAutoreleasePool *pool;
  
  *(&result) = 0;
  pool = [[NSAutoreleasePool alloc] init];
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void *)argv count:argc 
                 environment:env];
  [NSAutoreleasePool enableDoubleReleaseCheck:NO];
#endif
  
  result =
    [InstallSieve runWithArguments:
                    [[NSProcessInfo processInfo] argumentsWithoutDefaults]];
  
  [pool release];
  return result;
}
