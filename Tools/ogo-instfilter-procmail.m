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

// Note: this source *really* needs a LOT of cleanup

#import <Foundation/NSObject.h>

@class NSArray;

@interface SkyInstallProcMail : NSObject
+ (int)runWithArguments:(NSArray *)_args;
@end

#import <Foundation/Foundation.h>
#include <NGExtensions/NGObjectMacros.h>
#include <NGImap4/NGSieveClient.h>
#include <NGStreams/NGInternetSocketAddress.h>

@implementation SkyInstallProcMail

static NSString *ProcmailIncludePath    = nil;
static NSString *procmailInit           = nil;
static NSString *spamAssasinInit        = nil;
static BOOL     EnableSpamassasinFilter = NO;

+ (void)initialize {
  NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
  
  ProcmailIncludePath     = [[ud stringForKey:@"ProcmailIncludePath"] copy];
  procmailInit            = [[ud stringForKey:@"ProcmailInit"]        copy];
  spamAssasinInit         = [[ud stringForKey:@"SpamAssasinInit"]     copy];
  EnableSpamassasinFilter = [ud boolForKey:@"EnableSpamassasinFilter"];
}

- (id)_getArg:(NSDictionary *)_arg keys:(NSArray *)_keys {
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

- (NSString *)conditionForKind:(NSString *)kind 
  andExpression:(NSString *)expression match:(NSString *)match
  rulePrefix:(NSString **)rulePrefix_
{
  if (rulePrefix_) *rulePrefix_ = nil;
  
  if ([kind isEqualToString:@"contains"])
    return [@".*" stringByAppendingString:expression];
  
  if ([kind isEqualToString:@"doesn\'t contain"]) {
    *rulePrefix_ = [match isEqualToString:@"or"] ? @"*  " : @"* !";
    return [@".*" stringByAppendingString:expression];
  }
  
  if ([kind isEqualToString:@"is"])
    return [NSString stringWithFormat:@" <%@>", expression];
  
  if ([kind isEqualToString:@"isn\'t"]) {
    *rulePrefix_ = [match isEqualToString:@"or"] ? @"*  " : @"* ! ";
    return [@".*" stringByAppendingString:expression];
  }
  
  if ([kind isEqualToString:@"begins with"])
    return [@" +" stringByAppendingString:expression];
  
  if ([kind isEqualToString:@"ends with"])
    return [NSString stringWithFormat:@".*%@$", expression];
  
  NSLog(@"unknown kind: '%@'", kind);
  return nil;
}

- (NSString *)selectorForHeaderField:(NSString *)headerField {
  if ([headerField isEqualToString:@"from"])    return @"^From:";
  if ([headerField isEqualToString:@"to"])      return @"^To:";
  if ([headerField isEqualToString:@"subject"]) return @"^Subject: ";
  if ([headerField isEqualToString:@"cc"])      return @"^CC: ";
  NSLog(@"unknown header: '%@'", headerField);
  return nil;
}

- (void)processFilterEntry:(NSDictionary *)aEntry match:(NSString *)_match
  defaultRulePrefix:(NSString *)_defRulePrefix
  andAddToProcMailScript:(NSMutableString *)procmailFilter
{
  NSString *kind, *headerField, *expression;
  NSString *condition, *selector;
  NSString *rulePrefix;
  
  kind        = [aEntry objectForKey:@"filterKind"];
  headerField = [aEntry objectForKey:@"headerField"];
  expression  = [aEntry objectForKey:@"string"];
  
  rulePrefix = _defRulePrefix;
  selector   = [self selectorForHeaderField:headerField];
  condition  = [self conditionForKind:kind andExpression:expression
		     match:_match rulePrefix:&rulePrefix];
  
  /* build rule line */
  [procmailFilter appendString:rulePrefix];
  [procmailFilter appendString:selector];
  [procmailFilter appendString:condition];
  [procmailFilter appendString:@"\n"];
}

- (void)processFilter:(NSDictionary *)aFilter 
  andAddToProcMailScript:(NSMutableString *)procmailFilter
{
  NSMutableString *target;
  NSArray         *mailbox;
  NSString        *match;
  NSString        *rulePrefix;
  id              entries, aEntry;
  NSEnumerator    *entrEnum;
  BOOL            isFirst;
  NSString        *fileName;
  int i;
  
  entries   = [aFilter objectForKey:@"entries"];
  if ([entries count] == 0)
    return;
    
  // NSLog(procmailFilter);
  
  isFirst   = YES;
  
  target = [[NSMutableString alloc] init];
  entrEnum = [entries objectEnumerator];
  match = [aFilter objectForKey:@"match"];
  if ([match isEqualToString:@"or"]) {
    rulePrefix = @"* ! ";
    [target  appendString:@"{ }\n:0 E\n"];
  }
  else
    rulePrefix = @"* ";
  
  /* entries loop ( filterzeilen )*/
  [procmailFilter appendString:@":0\n"];
  while ((aEntry = [entrEnum nextObject])) {
    [self processFilterEntry:aEntry match:match
	  defaultRulePrefix:rulePrefix
	  andAddToProcMailScript:procmailFilter];
  }
  
  fileName = [aFilter objectForKey:@"folder"];
  if ([fileName hasPrefix:@"/"]) {
    NSRange r;
    
    r = NSMakeRange(1, [fileName length] - 1);
    fileName = [fileName substringWithRange:r];
  }
  
  /* process target mailboxs */
  
  [target appendString:@"\\."];
  mailbox = [fileName componentsSeparatedByString:@"/"];
  for (i = 1; i < [mailbox count]; i++)
    [target appendString:[mailbox objectAtIndex:i] ];
  
  [target appendString:@"\n"];
  
  /* process target */
  
  [procmailFilter appendString:target];
  [procmailFilter appendString:@"\n\n"];
}

- (NSString *)convertFileToProcmailFormat:(NSString *)_fileName {
  NSArray         *f;
  NSMutableString *procmailFilter;
  NSEnumerator    *enumerator;
  BOOL            firstEntry;
  id              aFilter;
  NSDictionary    *vacation, *forward;
  
  f = [NSArray arrayWithContentsOfFile:_fileName];
  if ([f count] == 0) {
    NSLog(@"file contains no entries or is not readable: '%@'", _fileName);
    return nil;
  }
  
  enumerator = [f objectEnumerator];
  vacation   = nil;
  forward    = nil;
  firstEntry = YES;
  
  procmailFilter = [NSMutableString stringWithCapacity:2048];
  
  [procmailFilter appendString:procmailInit];
  
  if (EnableSpamassasinFilter) {
    [procmailFilter appendString:spamAssasinInit];
    [procmailFilter appendString:
		      @"\n:0fw: spamassassin.lock\n"
  		      @"* < 256000\n| spamassassin\n:0:\n"
		      @"* ^X-Spam-Level: ***\n.SPAM/"];
  }
  
  /* global loop  */
  
  while ((aFilter = [enumerator nextObject]))
    [self processFilter:aFilter andAddToProcMailScript:procmailFilter];
  
  return procmailFilter;
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

    if (!([argument hasPrefix:@"-"] && [argument length] > 1))
      continue;
    
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
      NS_DURING
	*(&value) = [value stringValue];
      NS_HANDLER
	// TODO: something should be done here ...
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
  return defArgs;
}

/* main */

- (NSString *)procmailPathForLogin:(NSString *)_login {
  NSMutableString *path;
  
  if ([_login length] == 0)
    return nil;
  
  path = [NSMutableString stringWithCapacity:256];
  [path appendString:ProcmailIncludePath];
  [path appendString:@"/"];
  [path appendString:_login];
  [path appendString:@".procmail"];
  return path;
}

- (int)runWithArguments:(NSArray *)_args {
  NSDictionary    *args;
  NSString        *login, *dictName;
  NSString        *filter;
  NSString        *userPath;
  
  args     = [self getArgs];
  login    = [self _getArg:args
		   keys:[NSArray arrayWithObjects:@"login", @"l", nil]];
  dictName = [self _getArg:args
		   keys:[NSArray arrayWithObjects:@"install-dictionary",
				 @"id", nil]];
  
  NSLog(@"ProcmailIncludePath: '%@'", ProcmailIncludePath);
  userPath = [self procmailPathForLogin:login];
  NSLog(@"\nuserPath: '%@'", userPath);
  
  NSLog(@"Procmail Inputdata Dict '%@'" , dictName);
  if ((filter = [self convertFileToProcmailFormat:dictName]) == nil) {
    // TODO: what to do in this case?
    NSLog(@"could not convert to procmail format?");
    return 0;
  }
  
  if (![filter writeToFile:userPath atomically:YES]) {
    NSLog(@"could not write procmail file to '%@'", userPath);
    return 1;
  }
  
  return 0; /* everything OK */
}

+ (int)usage {
  printf("  sky_install_Procmail 0.1\n");
  printf("\n");
  printf("  Author Eric Weiss (e.weiss@Aixtema.de)\n\n");    
  printf("  Install  procmail filters.\n");
  printf("\n");
  printf("  login                or l   nil  Login    \n");
  printf("  install-dictionary   or id  nil  filename with filters as dictionary"
	 " format to install\n");
  return 0;
}

- (NSException *)handleRunException:(NSException *)_exception {
  NSLog(@"catched exception: %@", _exception);
  abort();
  return _exception;
}

+ (int)runWithArguments:(NSArray *)_args {
  SkyInstallProcMail *tool;
  int result;
  
  if ([_args count] < 2)
    return [self usage];

  tool = [[[SkyInstallProcMail alloc] init] autorelease];
  
  *(&result) = 0;
  NS_DURING 
    result = [tool runWithArguments:_args];
  NS_HANDLER {
    [[tool handleRunException:localException] raise];
    result = 1;
  }
  NS_ENDHANDLER;
  
  return result;
}

@end /* SkyInstallProcMail */

int main(int argc, const char **argv, char **env) {
  NSAutoreleasePool *pool;
  int result;
  
  pool = [[NSAutoreleasePool alloc] init];
#if LIB_FOUNDATION_LIBRARY
  [NSProcessInfo initializeWithArguments:(void*)argv count:argc 
		 environment:env];
#endif
  
  result = [SkyInstallProcMail runWithArguments:
				 [[NSProcessInfo processInfo] arguments]];
  
  // [pool release]; // do not release, OS cleans up for us is faster ;-)
  return result;
}
