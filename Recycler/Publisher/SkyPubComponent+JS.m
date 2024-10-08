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

#include "SkyPubComponent.h"
#include "SkyPubFileManager.h"
#include "SkyDocument+Pub.h"
#include <NGObjDOM/WOContext+Cursor.h>
#include <DOM/EDOM.h>
#include <NGJavaScript/NGJavaScriptShadow.h>
#include <NGJavaScript/NGJavaScriptObjectMappingContext.h>
#include "common.h"

@interface SkyPubComponent(JSSupport)

- (NGJavaScriptShadow *)_shadow;
- (void)_evaluateTemplateJSInContext:(WOContext *)_ctx;

- (NSException *)_handleException:(NSException *)_exception
  inContext:(WOContext *)_ctx;

@end

@interface SkyPubComponent(Template)
- (WOElement *)template;
@end

@implementation SkyPubComponent(JSSupport)

static BOOL debugJSShadow = NO;

- (NGJavaScriptObjectMappingContext *)jsMapContext {
  return [NGJavaScriptObjectMappingContext activeObjectMappingContext];
}

- (NGJavaScriptShadow *)_shadow {
  if (self->shadow)
    return self->shadow;

  if (debugJSShadow)
    [self logWithFormat:@"creating JavaScript shadow for form ..."];
  
  self->shadow = [[NGJavaScriptShadow alloc] init];
  [self->shadow setMasterObject:self];
  [self->shadow applyStandardClasses];
  
  NSAssert1(self->shadow, @"couldn't create JS shadow object for form '%@' !",
            [self name]);
  
  return self->shadow;
}

- (NSString *)scriptTextFromNode:(id)_node inComponent:(WOComponent *)_c {
  NSMutableString *result;
  
  result = [NSMutableString stringWithCapacity:1024];
  
#if 0 // no src attribute support yet ...
  if ([_node hasAttribute:@"src"]) {
    NSString *src;
    NSData   *data;
    
    src = [_node attribute:@"src"];
#if DEBUG
    [self debugWithFormat:@"loading JS script with source '%@' ..", src];
#endif

    data = ([self respondsToSelector:@selector(contentForComponentRelativeURL:)])
      ? [self contentForComponentRelativeURL:src]
      : [[NSURL URLWithString:src] resourceDataUsingCache:NO];
    
    if ([data length] > 0) {
      NSString *script;
      
      script = [[NSString alloc] initWithData:data
                                 encoding:NSISOLatin1StringEncoding];
      [result appendString:script];
      [script release];
    }
  }
#endif
  
  if ([_node hasChildNodes]) {
    NSEnumerator *e;
    id subnode;
    
    e = [(NSArray *)[_node childNodes] objectEnumerator];
    while ((subnode = [e nextObject]))
      [result appendString:[subnode textValue]];
  }
  return result;
}

- (void)addJavaScriptLog:(NSString *)_s {
  if ([_s length] == 0)
    return;
  
  _s = [NSString stringWithFormat:@"%@: %@", [self name], _s];
  if ([self hasSession])
    [(id)[self session] addJavaScriptLog:_s];
}

- (NSException *)_handleException:(NSException *)_exception
  inContext:(WOContext *)_ctx
  inJavaScript:(NSString *)_script
{
  NSString *error;
  NSString *oldError;
  
  [self addJavaScriptLog:[_exception reason]];
  
  error = [NSString stringWithFormat:@"JS Template Error: %@",
                      [_exception reason]];
  oldError = [[[self context] page] valueForKey:@"errorString"];
  
  if ([oldError length] > 0) {
    error = [[oldError stringByAppendingString:@"\n"]
                       stringByAppendingString:error];
  }
  
  [[[self context] page] takeValue:error forKey:@"errorString"];
  
  [self debugWithFormat:@"Exception in JS: %@", _exception];
  
  return [self _handleException:_exception inContext:_ctx];
}

- (NSException *)_handleException:(NSException *)_exception
  inContext:(WOContext *)_ctx
{
  NSString *error;
  NSString *oldError;
  
  error =
    [NSString stringWithFormat:@"JS Template Error: %@", [_exception reason]];
  oldError = [[[self context] page] valueForKey:@"errorString"];
  
  if ([oldError length] > 0) {
    error = [[oldError stringByAppendingString:@"\n"]
                       stringByAppendingString:error];
  }
  
  [[[self context] page] takeValue:error forKey:@"errorString"];
  
  [self debugWithFormat:@"Exception in JS Template: %@", _exception];
  
#if DEBUG && 0
  if (![[_exception name] isEqualToString:@"JavaScriptError"])
    abort();
#endif
  
  //[_exception raise];
  
  return nil;
}

- (NSException *)_evaluateServerSideJavaScriptsOnDOM:(id)_doc {
  static DOMQueryPathExpression *qpexpr = nil;
  static EOQualifier            *serverQual = nil;
  NSArray      *scriptNodes;
  NSEnumerator *e;
  id           scriptNode;
  NSException  *exception;
  NSAutoreleasePool *pool;

  pool = [[NSAutoreleasePool alloc] init];
  
  if (qpexpr == nil)
    qpexpr = [[DOMQueryPathExpression queryPathWithString:@"script"] retain];
  
  if (serverQual == nil) {
    serverQual =
      [EOQualifier qualifierWithQualifierFormat:@"attributes.runat='server'"];
    serverQual = [serverQual retain];
  }
  
  scriptNodes = [qpexpr evaluateWithNodeList:[_doc childNodes]];
  scriptNodes = [scriptNodes filteredArrayUsingQualifier:serverQual];
  
  if ([scriptNodes count] == 0)
    return nil;
  
  exception = nil;
  e = [scriptNodes objectEnumerator];
  
  while ((exception == nil) && (scriptNode = [e nextObject])) {
    NSString *scriptText;
    
    scriptText = [self scriptTextFromNode:scriptNode inComponent:self];
    if ([scriptText length] == 0)
      continue;
    
    NS_DURING {
      [self evaluateJavaScript:scriptText];
    }
    NS_HANDLER {
#if DEBUG
      printf("%s: exception code: %s\n", __FILE__, [scriptText cString]);
#endif
      exception = [localException retain];
    }
    NS_ENDHANDLER;
  }
  
  [pool release];
  
  return [exception autorelease];
}

- (void)_evaluateTemplateJSInContext:(WOContext *)_ctx {
  id edom;
  NSException *e;
  
  if (![[self template] respondsToSelector:@selector(domInContext:)])
    return;
  
  // TODO: include the proper NGObjDOM header
  if ((edom = [(id)[self template] domInContext:_ctx]) == nil)
    return;
  
#if 0
  [self debugWithFormat:@"evaluating JavaScript .."];
#endif
  
  if ((e = [self _evaluateServerSideJavaScriptsOnDOM:edom]))
    [[self _handleException:e inContext:_ctx] raise];
  
  self->didEvaluate = YES;
}

/* custom properties */

- (id)_jsprop_document {
  return [self document];
}
- (id)_jsprop_isTemplate {
  return [NSNumber numberWithBool:[self isTemplate]];
}
- (id)_jsprop_fileManager {
  return [self fileManager];
}

static NSString *JSDateFormat = @"%a, %d %b %Y %H:%M:%S %Z";

- (id)_jsfunc_SkyDate:(NSArray *)_args {
  unsigned count;
  NSCalendarDate *date;
  NSTimeZone     *tz;

  tz = [(LSWSession *)[self session] timeZone];

  if ((count = [_args count]) == 0) {
    date = [NSCalendarDate date];
  }
  else if (count == 1) {
    // new Date( milliseconds)
    // new Date( dateString)
    id arg0;

    arg0 = [_args objectAtIndex:0];
    
    if ([arg0 isKindOfClass:[NSNumber class]]) {
      NSTimeInterval ti;

      ti = [arg0 unsignedIntValue] * 1000.0;
      date = [[NSCalendarDate alloc] initWithTimeIntervalSince1970:ti];
      AUTORELEASE(date);
    }
    else {
      /* 1. "Mon, 25 Dec 1995 13:30:00 GMT". */
      /* 2. "2001-01-04 13:23:45 GMT" */

      arg0 = [arg0 stringValue];
      date = [NSCalendarDate dateWithString:arg0 calendarFormat:JSDateFormat];
      if (date == nil) {
        date = [NSCalendarDate dateWithString:arg0
                               calendarFormat:@"%Y-%m-%d %H:%M:%S %Z"];
      }
    }
  }
  else {
    // new Date( yr_num, mo_num, day_num[, hr_num, min_num, sec_num])
    short year = 2000, month = 1, day = 1, hour = 0, minute = 0, second = 0;

    if (count > 5) second = [[_args objectAtIndex:5] intValue];
    if (count > 4) minute = [[_args objectAtIndex:4] intValue];
    if (count > 3) hour   = [[_args objectAtIndex:3] intValue];
    if (count > 2) day    = [[_args objectAtIndex:2] intValue];
    if (count > 1) month  = ([[_args objectAtIndex:1] intValue] + 1);
    if (count > 0) year   = [[_args objectAtIndex:0] intValue];
    
    if (year < 100) year += 1900;
    
    date = [[NSCalendarDate alloc] initWithYear:year month:month day:day
                                   hour:hour minute:minute second:second
                                   timeZone:tz];
    date = [date autorelease];
  }
  
  [date setTimeZone:tz];
  [date setCalendarFormat:JSDateFormat];
  return date;
}
- (id)_jsfunc_Date:(NSArray *)_args {
  return [self _jsfunc_SkyDate:_args];
}

- (id)_jsfunc_print:(NSArray *)_args {
  NSEnumerator    *e;
  id              o;
  BOOL            isFirst;
  NSMutableString *ms;
  
  isFirst = YES;
  ms = [NSMutableString stringWithCapacity:128];
  
  e = [_args objectEnumerator];
  while ((o = [e nextObject])) {
    NSString *s;
    
    if (!isFirst) [ms appendString:@" "];
    else isFirst = NO;
    
    s = [o stringValue];
    [ms appendString:s];
  }
  
  [self logWithFormat:@"%@", ms];
  [self addJavaScriptLog:ms];
  
  return self;
}

- (id)_jsfunc_FileManager:(NSArray *)_args {
  return [self fileManager];
}

/* KVC */

#if 1 /* was disabled, why ??? */
#warning this was commented out

#warning fix pushCursor ...
- (id)evaluateJavaScript:(NSString *)_script {
  NGJavaScriptObjectMappingContext *mctx = nil;
  id result;
  
  if ([_script length] == 0)
    return nil;
  
  *(&mctx) = [NGJavaScriptObjectMappingContext activeObjectMappingContext];
  if (mctx != [self jsMapContext]) {
    mctx = nil;
    [[self jsMapContext] pushContext];
  }
  
  NS_DURING {
    *(&result) = [[self _shadow] evaluateJavaScript:_script];
  }
  NS_HANDLER {
    *(&result) = nil;
    [[self _handleException:localException
           inContext:[self context]
           inJavaScript:_script] raise];
  }
  NS_ENDHANDLER;
  
  if (mctx == nil)
    [[self jsMapContext] popContext];
  
  return result;
}
- (id)evaluateScript:(NSString *)_script language:(NSString *)_lang {
  return [self evaluateJavaScript:_script];
}

- (BOOL)takeValue:(id)_value forJSPropertyNamed:(NSString *)_key {
  [[self _shadow] setObject:_value forKey:_key];
  return YES;
}
- (id)valueForJSPropertyNamed:(NSString *)_key {
  //[self debugWithFormat:@"value for prop %@", _key];
  return [[self _shadow] objectForKey:_key];
}

- (void)setObject:(id)_obj forKey:(NSString *)_key {
  //[self debugWithFormat:@"setObject:%@ forKey:%@", _obj, _key];
  [[self _shadow] setObject:_obj forKey:_key];
}
- (id)objectForKey:(NSString *)_key {
  return [[self _shadow] objectForKey:_key];
}

- (id)valueForKey:(NSString *)_key {
  id obj;
  
  //[self debugWithFormat:@"JS: valueForKey:%@", _key];
  
  if ((obj = [[self _shadow] objectForKey:_key])) {
    if ([obj isJavaScriptFunction])
      obj = [[self _shadow] callJavaScriptFunction:_key];
    
    return obj;
  }
  
  return [super valueForKey:_key];
}
#endif

@end /* SkyPubComponent(JSSupport) */
