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

#include "common.h"
#include "LSWNewsArticleViewer.h"
#include <OGoFoundation/LSWNotifications.h>

@interface LSWNewsArticleViewer(Private)
- (void)addReceiver:(id)_id type:(NSString *)_type;
- (void)setContentWithoutSign:(NSString *)_content;
@end

@implementation LSWNewsArticleViewer

static inline BOOL _isAlphaOrDigit(id self, char _ch) {
  if (((_ch > 96) && (_ch < 123)) ||
      ((_ch > 64) && (_ch < 91))  ||
      ((_ch > 47) && (_ch < 58)))    
    return YES;
  return NO;
}

static inline NSString *_getUrl(id self, NSString *_str) {
  int  len     = [_str length];
  int  cnt     = 0;
  char *str    = NULL;
  char *string = NULL;

  string = malloc(sizeof(char) * (len + 1));
  str    = string;
  [_str getCString:str];
  
  while (cnt < len) {
    if ((*str == ' ') || (*str == '\n') || (*str == '\r') || (*str == '\t'))
      break;
    if ((len - cnt) > 1){
      char test = *(str + 1);
      if ((_isAlphaOrDigit(self, *str) == NO) && ((test == '\n') ||
                                                  (test == ' ')  ||
                                                  (test == '\t') ||
                                                  (test == '\r')))
        break;
    }
    str++;
    cnt++;
  }
  if (string) free(string);
  if (cnt == 0) {
    NSLog(@"WARNING: found URL without characters");
    return @"";
  }
  return [_str substringToIndex:cnt];
}

// TODO: move to NSString category?

static inline void _parseForLink(id self, NSMutableArray *_text_,
                                 NSString *_kind) 
{
  id   obj    = nil;
  int  i, cnt = 0;
  
  for (i = 0, cnt = [_text_ count]; i < cnt; i++) {
    NSString *str = nil;
    NSRange  r;
    
    obj = [_text_ objectAtIndex:i];

    if (![[obj objectForKey:@"kind"] isEqualToString:@"text"])
      continue;

    str = [obj objectForKey:@"value"];
    r = [str rangeOfString:_kind];
      
    while (r.length > 0) {
      NSString     *s = nil;
      NSDictionary *d;
	
      [_text_ removeObjectAtIndex:i];
	
      d = [[NSDictionary alloc] initWithObjectsAndKeys:
				  [str substringToIndex:r.location],@"value",
				@"text", @"kind", nil];
      [_text_ insertObject:d atIndex:i];
      [d release];

      s = _getUrl(self, [str substringFromIndex:r.location]);

      if ([s length] > [_kind length]) {
	d = [[NSDictionary alloc] initWithObjectsAndKeys:
				    s,      @"value",
				  _kind,  @"urlKind",
				  @"url", @"kind", nil];
	[_text_ insertObject:d atIndex:i+1];
	[d release];
      }
      else {
	d = [[NSDictionary alloc] initWithObjectsAndKeys:
				    s,       @"value",
				  @"text", @"kind", nil];
	[_text_ insertObject:d atIndex:i+1];
	[d release];
      }
      str = [str substringFromIndex:(r.location + [s length])];

      [_text_ insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
					   str,  @"value",
					 @"text", @"kind", nil]
	      atIndex:i+2];
      cnt += 2;
      i   += 2;
      r = [str rangeOfString:_kind];
    }
  }
}

static inline NSArray *_filterLinks(id self, NSString *_str) {
  NSMutableArray *array     = nil;
  NSEnumerator   *linkKinds = nil;
  NSString       *kind      = nil;
  NSDictionary   *record;

  linkKinds = [[NSArray arrayWithObjects:@"http:",@"https:", @"file:",
                                         @"ftp:", @"news:", @"mailto:", nil]
                        objectEnumerator];

  record = [NSDictionary dictionaryWithObjectsAndKeys:
			   _str, @"value", @"text", @"kind", nil];
  array = [NSMutableArray arrayWithObjects:&record count:1];
  
  while ((kind = [linkKinds nextObject]) != nil)
    _parseForLink(self, array, kind);

  return array;
}
- (id)init {
  if ((self = [super init])) {
    [self registerForNotificationNamed:LSWUpdatedNewsArticleNotificationName];
  }
  return self;
}

- (void)dealloc {
  [self unregisterAsObserver];
  [self->imageUrl        release];
  [self->fileName        release];
  [self->relatedArticles release];
  [self->newsArticle     release];
  [self->item            release];
  [super dealloc];
}

/* operations */

- (void)_setImageUrl {
  NSFileManager  *manager;
  NSUserDefaults *defaults;
  NSString       *url, *imagesUrl, *path;
  id             obj, ext, articleId;
  NSEnumerator   *enumerator;
  
  static NSArray *ExtensionList = nil;

  if (ExtensionList == nil) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    ExtensionList = [[ud arrayForKey:@"NewsArticleExtensionList"] copy];
  }
    
  manager   = [NSFileManager defaultManager];
  defaults  = [[self session] userDefaults];
  obj       = [self object];
  articleId = [obj valueForKey:@"newsArticleId"];
  path      = [defaults stringForKey:@"LSNewsImagesPath"];
  url       = [defaults stringForKey:@"WOResourcePrefix"];
  imagesUrl = [defaults stringForKey:@"LSNewsImagesUrl"];

  if (url != nil) 
    url = [url stringByAppendingPathComponent:imagesUrl];
  else
    url = imagesUrl;

  enumerator = [ExtensionList objectEnumerator];

  [self->imageUrl release]; self->imageUrl = nil;

  while ((ext = [enumerator nextObject])) {
    NSString *fn, *imageFileName;
    
    fn            = [NSString stringWithFormat:@"%@/%@.", path, articleId];
    imageFileName = [NSString stringWithFormat:@"%@%@", fn, ext];

    if (![manager fileExistsAtPath:imageFileName]) {
      ext = [ext uppercaseString];
      imageFileName = [NSString stringWithFormat:@"%@%@", fn, ext];
      if (![manager fileExistsAtPath:imageFileName]) {
        continue;
      }
    }
    self->imageUrl = [[NSString alloc] initWithFormat:@"%@/%@.%@",
                                         url, articleId, ext];
    break;
  }
}

- (void)_setRelatedArticles {
  id      obj = [self object];
  NSArray *rA = nil;

  [obj run:@"newsarticle::get-related-articles", nil];
  rA = [obj valueForKey:@"relatedArticles"];

  ASSIGN(self->relatedArticles, rA);
}

- (BOOL)prepareForActivationCommand:(NSString *)_command 
  type:(NGMimeType *)_type
  configuration:(NSDictionary *)_cmdCfg
{
  if ([super prepareForActivationCommand:_command type:_type
             configuration:_cmdCfg]) {
    id obj;
    NSUserDefaults *defaults;
    NSString       *path;

    defaults = [[self session] userDefaults];
    path     = [defaults stringForKey:@"LSAttachmentPath"];
    obj      = [self object];
    
    self->fileName = 
      [[NSString alloc] initWithFormat:@"%@/%@.txt",
			  path, [obj valueForKey:@"newsArticleId"]];
    
    return YES;
  }
  return NO;
}

- (void)_loadObject {
  NSUserDefaults *defaults;
  NSString       *path;
  id             obj;

  defaults = [[self session] userDefaults];
  path     = [defaults stringForKey:@"LSAttachmentPath"];
    
  obj = [self runCommand:@"newsarticle::get",
	        @"isIndexArticle", [NSNumber numberWithBool:YES], nil];

  if ([obj count] == 0)
    return;

  obj = [obj lastObject];
  [self setObject:obj];

  [self->fileName release]; self->fileName = nil;
  self->fileName = [[NSString alloc] initWithFormat:@"%@/%@.txt",
				       path, 
				       [obj valueForKey:@"newsArticleId"]];
}
- (void)syncAwake {
  [super syncAwake];

  if ([self object] == nil)
    [self _loadObject];
  
  [self _setImageUrl];
  [self _setRelatedArticles];
}

- (NSArray *)fileContent {
  NSString *s;

  if ((s = self->fileName) == nil)
    return nil;
  
  s = [NSString stringWithContentsOfFile:self->fileName];
  return  _filterLinks(self, s);
}

- (BOOL)hasImage {
  return (self->imageUrl == nil) ? NO : YES;
}

- (void)setIsInline:(BOOL)_flag {
  self->isInline = _flag;
}
- (BOOL)isInline {
  return self->isInline;
}

- (NSString *)articleImage {
  return self->imageUrl;
}

- (id)article {
  return [self object];
}

- (void)setNewsArticle:(NSMutableDictionary *)_newsArticle { 
  ASSIGN(self->newsArticle, _newsArticle);
}
- (NSDictionary *)newsArticle {
  return self->newsArticle;
}

- (NSArray *)relatedArticles {
  return self->relatedArticles;
}

/* actions */

- (id)viewNewsArticle {
  NSUserDefaults *defaults;
  NSString       *path;
  id obj = nil;

  [[self session] transferObject:self->newsArticle owner:self];
  
  [self setObject:self->newsArticle];
  obj = [self object];
    
  defaults = [[self session] userDefaults];
  path     = [defaults stringForKey:@"LSAttachmentPath"];
    
  [self->fileName release]; self->fileName = nil;
  self->fileName = 
    [[NSString alloc] initWithFormat:@"%@/%@.txt",
		        path, [obj valueForKey:@"newsArticleId"]];
  
  [self _setImageUrl];
  [self _setRelatedArticles];
  return nil;
}

- (void)setItem:(id)_item {
  ASSIGN(self->item, _item);
}
- (id)item {
  return self->item;
}

- (BOOL)isActionLink {
  if ([[self->item objectForKey:@"urlKind"] isEqualToString:@"mailto:"] &&
      [[[[self session] userDefaults] objectForKey:@"mail_editor_type"]
               isEqualToString:@"internal"]) {
    return YES;
  }
  return NO;
}

/* notifications */

- (id)sendMail {
  WOComponent *mailEditor;
  NSString    *val;
  
  mailEditor = (id)[[self application] pageWithName:@"LSWImapMailEditor"];
  
  if (mailEditor == nil)
    return nil;
  
  val = [self->item objectForKey:@"value"];

  /* remove mailto: */    
  if ([val length] > 7)
    val = [val substringFromIndex:7];
  
  // TODO: fix cast
  [(id)mailEditor addReceiver:val type:@"to"];
  [(id)mailEditor setContentWithoutSign:@""];
  return mailEditor;
}

- (void)noteChange:(NSString *)_cn onObject:(id)_object {
  [super noteChange:_cn onObject:_object];

  [self _setImageUrl];
  [self _setRelatedArticles];
}

@end /* LSWNewsArticleViewer */
