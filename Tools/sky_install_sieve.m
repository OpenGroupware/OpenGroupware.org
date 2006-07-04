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

static id _getArg(NSDictionary *_arg, NSArray *_keys) {
  id           obj;
  NSEnumerator *enumerator;
  
  enumerator = [_keys objectEnumerator];
  while ((obj = [enumerator nextObject]) != nil) {
    id o;
    
    if ((o = [_arg objectForKey:obj]) != nil)
      return o;
  }
  return nil;
}

- (NSString *)sieveQualifierPrefixForKind:(NSString *)_kind {
  // TODO: this might conflict with UI labels?! (happened in bug 698)
  if ([_kind isEqualToString:@"contains"])
    return @"header :contains";

  if ([_kind isEqualToString:@"doesn`t contain"] ||
      [_kind isEqualToString:@"doesn't contain"])
    return @"not header :contains";
  
  if ([_kind isEqualToString:@"is"])
    return @"header :is";
  if ([_kind isEqualToString:@"isn`t"] || [_kind isEqualToString:@"isn't"])
    return @"not header :is";
  if ([_kind isEqualToString:@"begins with"])
    return @"header :matches";
  if ([_kind isEqualToString:@"ends with"])
    return @"header :matches";
  
  NSLog(@"ERROR: could not process filter with kind: '%@'", _kind);
  return nil;
}

- (void)appendHeaderFields:(NSArray *)_fields
  toFilterString:(NSMutableString *)sieveFilter
{
  NSEnumerator *e;
  NSString *obj;
  BOOL isFirst; // TODO: this was shared before - probably was a bug!
  
  e       = [_fields objectEnumerator];
  isFirst = YES;

  [sieveFilter appendString:@" ["];
  while ((obj = [e nextObject]) != nil) {
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

- (NSString *)sieveOperatorForMatchKey:(NSString *)_key {
  return [_key isEqualToString:@"or"] ? @"anyof" : @"allof";
}

- (void)appendFilterEntry:(NSDictionary *)aEntry
  toFilterString:(NSMutableString *)sieveFilter
{
  NSString *kind;
  NSString *sqs;

  kind = [aEntry objectForKey:@"filterKind"];
        
  if ((sqs = [self sieveQualifierPrefixForKind:kind]) != nil)
    [sieveFilter appendString:sqs];
        
  [self appendHeaderFields:
          [[aEntry objectForKey:@"headerField"]
            componentsSeparatedByString:@":"]
        toFilterString:sieveFilter];
  
  if ([kind isEqualToString:@"ends with"])
    [sieveFilter appendString:@"*"];
        
  [sieveFilter appendString:[aEntry objectForKey:@"string"]];

  if ([kind isEqualToString:@"begins with"])
    [sieveFilter appendString:@"*"];
  
  [sieveFilter appendString:@"\""];
}

- (void)appendVacation:(NSDictionary *)vacation
  toFilterString:(NSMutableString *)sieveFilter
{
  NSEnumerator *addenum;
  id           addr;
  BOOL         isFirst;

  if (vacation == nil)
    return;
  
  [sieveFilter appendString:@"require [\"vacation\"];\n\n"];

  [sieveFilter appendFormat:@"vacation :days %@ :addresses [",
               [vacation objectForKey:@"repeatInterval"]];

  addenum = [[vacation objectForKey:@"emails"] objectEnumerator];
  
  isFirst = YES;
    
  while ((addr = [addenum nextObject]) != nil) {
    if (isFirst)
      isFirst = NO;
    else
      [sieveFilter appendString:@", "];
      
    [sieveFilter appendFormat:@"\"%@\"", addr];
  }
  [sieveFilter appendString:@"]"];

  if ([[vacation objectForKey:@"subject"] length] > 0) {
    [sieveFilter appendFormat:@" :subject \"%@\"",
                 [vacation objectForKey:@"subject"]];
  }
  [sieveFilter appendFormat:@" text:\n%@\n.\n;\n", 
                 [vacation objectForKey:@"text"]];
}

- (NSString *)sieveFilenameForString:(NSString *)fileName {
  if ([fileName hasPrefix:@"/"]) {
    fileName = [fileName substringWithRange:
                           NSMakeRange(1, [fileName length] - 1)];
  }
  fileName = [[fileName componentsSeparatedByString:@"/"]
                        componentsJoinedByString:@"."];
  return fileName;
}
- (NSString *)sieveRedirectAddressForString:(NSString *)fileName {
  NGMailAddressParser *parser;
  NSString *str;
  
  if ([fileName length] == 0)
    return nil;
  
  parser = [NGMailAddressParser mailAddressParserWithString:fileName];
  str    = [(NGMailAddress *)[parser parse] address];
      
  if ([str length] == 0) {
    NSLog(@"ERROR: could not parse address %@", fileName);
    return nil;
  }
  return str;
}

- (void)appendFilter:(NSDictionary *)aFilter isFirst:(BOOL)firstEntry
  toFilterString:(NSMutableString *)sieveFilter
{
  BOOL         isFirst;
  id           entries, aEntry;
  NSEnumerator *entrEnum;
    
  entries = [aFilter objectForKey:@"entries"];
  
  if ([aFilter objectForKey:@"kind"] != nil)
    // TODO: do we need to log an error?
    return;
    
  if ([entries count] == 0)
    return;

  isFirst = YES;
  
  [sieveFilter appendString:firstEntry ? @"if " : @"elsif "];
  
  [sieveFilter appendString:[self sieveOperatorForMatchKey:
                                    [aFilter objectForKey:@"match"]]];
  [sieveFilter appendString:@" ("];
      
  entrEnum = [entries objectEnumerator];
  while ((aEntry = [entrEnum nextObject]) != nil) {
    if (isFirst)
      isFirst = NO;
    else
      [sieveFilter appendString:@", "];
    
    [self appendFilterEntry:aEntry toFilterString:sieveFilter];
  }
      
  [sieveFilter appendString:@")\n {\n"];

  if ([[aFilter objectForKey:@"folder"] length] > 0) {
    NSString *fileName;
    
    [sieveFilter appendString:@"fileinto \""];
    
    fileName = [self sieveFilenameForString:[aFilter objectForKey:@"folder"]];
    [sieveFilter appendString:fileName];
    [sieveFilter appendString:@"\";\n "];
  }
  else if ([[aFilter objectForKey:@"forwardAddress"] length] > 0) {
    NSString *str;
    
    [sieveFilter appendString:@"redirect \""];

    str = [self sieveRedirectAddressForString:
                  [aFilter objectForKey:@"forwardAddress"]];
    if (str == nil)
      // TODO: shouldn't we abort in case we found an error?
      NSLog(@"ERROR: missing/invalid forwardAddress for filter: %@", aFilter);
    
    [sieveFilter appendString:(str != nil ? str : (NSString *)@"")];
    [sieveFilter appendString:@"\";\n "];
  }
  [sieveFilter appendString:@"}\n"];
}

- (NSString *)convertFileToSieveFormat:(NSString *)_fileName {
  // TODO: cleanup this huge method!
  NSArray         *f;
  NSMutableString *sieveFilter;
  NSEnumerator    *enumerator;
  BOOL            firstEntry;
  NSDictionary    *aFilter;
  NSDictionary    *vacation, *forward;
  
  f = [[NSArray alloc] initWithContentsOfFile:_fileName];
  
  if (f == nil)
    return nil;
  if ([f count] == 0) /* we may not return nil! */
    return @"";
  
  vacation = nil;
  forward  = nil;
  
  enumerator = [f objectEnumerator];
  while ((aFilter = [enumerator nextObject]) != nil) {
    if ([[aFilter objectForKey:@"kind"] isEqualToString:@"vacation"])
      vacation = aFilter;
    else if ([[aFilter objectForKey:@"kind"] isEqualToString:@"forward"])
      forward = aFilter;
    
    if (forward != nil && vacation != nil)
      break;
  }
  sieveFilter = [NSMutableString stringWithCapacity:4096];
  [sieveFilter appendString:@"require [\"fileinto\"];\n"];
  
  if (forward)
    [sieveFilter appendString:@"require [\"reject\"];\n"];
  
  [self appendVacation:vacation toFilterString:sieveFilter];
  
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
  firstEntry = YES;
  while ((aFilter = [enumerator nextObject]) != nil) {
    [self appendFilter:aFilter isFirst:firstEntry toFilterString:sieveFilter];
    firstEntry = NO;
  }
  [f release]; f = nil;
  return sieveFilter;
}

- (NSException *)handleArgumentException:(NSException *)_exception {
  // TODO: shouldn't we log something?
  return nil;
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
        NS_HANDLER
          [[self handleArgumentException:localException] raise];
        NS_ENDHANDLER;
        
        if (value == nil) {
          fprintf(stderr,
                  "Could not process value %s "
                  "of command line default '%s'.\n",
                  [argument cString],
                  [[args objectAtIndex:(i + 1)] cString]);
        }
        else
          [defArgs setObject:value forKey:argument];
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
  
  if (self->dictName != nil) {
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

- (NGSieveClient *)openConnection {
  NGSieveClient           *client;
  NGInternetSocketAddress *addr;
  NSDictionary            *res;
  
  addr = [NGInternetSocketAddress addressWithPort:[self->port intValue]
                                  onHost:self->server];
  client = [(NGSieveClient *)[NGSieveClient alloc] initWithAddress:addr];
  if (client == nil) {
    [self logWithFormat:@"ERROR: could not connect create client: %@", addr];
    return nil;
  }
  client = [client autorelease];
  
  res = [client openConnection];
  // TODO: check return value!
  
  res = [client login:self->login password:self->password];
  if (![[res objectForKey:@"result"] boolValue]) {
    NSLog(@"ERROR: login failed for %@ user %@", client, login);
    exit(3);
  }
  
  return client;
}

- (int)runWithArguments:(NSArray *)_args {
  if ([_args count] < 2) {
    [self usage];
    return 1;
  }
  
  NS_DURING {
    NGSieveClient *client;
    NSString *filter, *scriptName;
    id result;
    
    if (![self _extractParameters])
      return 1;
    
    filter     = nil;
    scriptName = [self sieveScriptName];
    
    if ((filter = [self _extractFilter]) == nil) {
      NSLog(@"ERROR: got no filter, exiting (dict: %@).", self->dictName);
      return 1;
    }
    
    if ((client = [self openConnection]) == nil) {
      NSLog(@"ERROR: could not connect to Sieve server!");
      exit(3);
    }
      
    if ([filter length] > 0) {
      result = [client putScript:scriptName script:filter]; 
      if (![[result valueForKey:@"result"] boolValue]) {
        [self logWithFormat:@"ERROR: could not upload script '%@': %@",
                scriptName, result];
      }
      else {
        result = [client setActiveScript:scriptName];
        if (![[result valueForKey:@"result"] boolValue]) {
          [self logWithFormat:@"ERROR: could not active script '%@': %@",
                  scriptName, result];
        }
      }
    }
    else {
      result = [client deleteScript:scriptName]; 
      if (![[result valueForKey:@"result"] boolValue])
        [self logWithFormat:@"ERROR: could not delete script '%@': %@",
                scriptName, result];
    }
    [client closeConnection];
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
  
  // Note: do _not_ use argumentsWithoutDefaults (done by tool)
  result =
    [InstallSieve runWithArguments:[[NSProcessInfo processInfo] arguments]];
  
  [pool release];
  return result;
}
