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

/*
   <> visibility           this or visibilityDefault is required
    > visibilityDefault    
    > title                default = nil
    > condition            default = NO 
    > structuredMode       default = NO

    > fragmentIdentifier   default = nil
    > submitActionName     default = nil
    > action               default = nil // if submit button,
                                         // use submitActionName instead

    > openedImageFileName  default = "expanded.gif"
    > closedImageFileName  default = "collapsed.gif"
    > openedLabel          default = nil
    > closedLabel          default = nil
    > titleColor           default = config.colors_mainButtonRow
    > titleColspan         default = 2
*/

#include <OGoFoundation/OGoFoundation.h>
#include <WEExtensions/WEContextConditional.h>

@interface SkyCollapsibleContent : OGoComponent
{
  NSString *title;
  NSString *openedImageFileName;
  NSString *closedImageFileName;
  NSString *titleColor;
  NSString *fragmentIdentifier;
  NSString *submitActionName;
  NSString *visibilityDefault;
  int      titleColspan;
  struct {
    int visibility:1;
    int structuredMode:1;
    int isClicked:1;
    int condition:1;
    int reserved:28;
  } sccFlags;
}

- (void)setOpenedImageFileName:(NSString *)_fileName;
- (NSString *)openedImageFileName;
- (void)setClosedImageFileName:(NSString *)_fileName;
- (NSString *)closedImageFileName;
- (void)setTitle:(NSString *)_title;
- (NSString *)title;
- (void)setTitleColor:(NSString *)_titlecolor;
- (NSString *)titleColor;
- (void)setFragmentIdentifier:(NSString *)_fragment;
- (NSString *)fragmentIdentifier;
- (void)setSubmitActionName:(NSString *)_name;
- (NSString *)submitActionName;

- (void)setTitleColspan:(int)_colspan;
- (int)titleColspan;
- (void)setVisibility:(BOOL)_visibility;
- (BOOL)visibility;
- (void)setStructuredMode:(BOOL)_mode;
- (BOOL)structuredMode;
- (void)setIsClicked:(BOOL)_clicked;
- (BOOL)isClicked;

@end

#include "common.h"

@implementation SkyCollapsibleContent

- (id)init {
  if ((self = [super init])) {
    NSArray *tmp;
    
    [self takeValue:@"expanded.gif"  forKey:@"openedImageFileName"];
    [self takeValue:@"collapsed.gif" forKey:@"closedImageFileName"];
    [self takeValue:@"2"             forKey:@"titleColspan"];
    
    [self takeValue:[[self config] valueForKey:@"colors_mainButtonRow"]
          forKey:@"titleColor"];
    
    tmp = [[[self context] elementID] componentsSeparatedByString:@"."];
      
    [self takeValue:[tmp componentsJoinedByString:@"_"]
          forKey:@"fragmentIdentifier"];
  }
  return self;
}

- (void)dealloc {
  [self->title               release];
  [self->openedImageFileName release];
  [self->closedImageFileName release];
  [self->titleColor          release];
  [self->fragmentIdentifier  release];
  [self->submitActionName    release];
  [self->visibilityDefault   release];
  [super dealloc];
}

/* defaults */

- (NSUserDefaults *)userDefaults {
  return [[self session] userDefaults];
}

- (void)setVisibilityDefaultValue:(BOOL)_flag {
  if (self->visibilityDefault == nil) {
    [self logWithFormat:@"WARNING: no visibility default name set!"];
    return;
  }
  [[self userDefaults] setObject:[NSNumber numberWithBool:_flag] 
		       forKey:self->visibilityDefault];
}
- (BOOL)visibilityDefaultValue {
  if (self->visibilityDefault == nil) {
    [self logWithFormat:@"WARNING: no visibility default name set!"];
    return YES;
  }
  return [[[self userDefaults] objectForKey:self->visibilityDefault] 
	         boolValue];
}

/* accessors */

- (BOOL)isTitleSet {
  return (self->title != nil) ? YES : NO;
}

- (void)setTitle:(NSString *)_title {
  ASSIGNCOPY(self->title, _title);
}
- (NSString *)title {
  return self->title;
}

- (void)setOpenedImageFileName:(NSString *)_fileName {
  ASSIGNCOPY(self->openedImageFileName, _fileName);
}
- (NSString *)openedImageFileName {
  return self->openedImageFileName;
}

- (void)setClosedImageFileName:(NSString *)_fileName {
  ASSIGNCOPY(self->closedImageFileName, _fileName);
}
- (NSString *)closedImageFileName {
  return self->closedImageFileName;
}

- (void)setTitleColor:(NSString *)_titlecolor {
  ASSIGNCOPY(self->titleColor, _titlecolor);
}
- (NSString *)titleColor {
  return self->titleColor;
}

- (void)setFragmentIdentifier:(NSString *)_fragment {
  ASSIGNCOPY(self->fragmentIdentifier, _fragment);
}
- (NSString *)fragmentIdentifier {
  return self->fragmentIdentifier;
}

- (void)setSubmitActionName:(NSString *)_name {
  ASSIGNCOPY(self->submitActionName, _name);
}
- (NSString *)submitActionName {
  return self->submitActionName;
}

- (void)setTitleColspan:(int)_colspan {
  self->titleColspan = _colspan;  
}
- (int)titleColspan {
  return self->titleColspan;
}

- (void)setVisibilityDefault:(NSString *)_defName {
  ASSIGNCOPY(self->visibilityDefault, _defName);
}
- (NSString *)visibilityDefault {
  return self->visibilityDefault;
}

- (void)setVisibility:(BOOL)_visibility {
  self->sccFlags.visibility = _visibility ? 1 : 0;
  if (self->visibilityDefault)
     [self setVisibilityDefaultValue:self->sccFlags.visibility ? YES : NO];
}
- (BOOL)visibility {
  if (self->visibilityDefault)
    self->sccFlags.visibility = [self visibilityDefaultValue] ? 1 : 0;
  return self->sccFlags.visibility ? YES : NO;
}

- (void)setCondition:(BOOL)_condition {
  self->sccFlags.condition = _condition ? 1 : 0;  
}
- (BOOL)condition {
  return self->sccFlags.condition ? YES : NO;
}

- (void)setStructuredMode:(BOOL)_mode {
  self->sccFlags.structuredMode = _mode ? 1 : 0;  
}
- (BOOL)structuredMode {
  return self->sccFlags.structuredMode ? YES : NO;
}

- (void)setIsClicked:(BOOL)_clicked {
  self->sccFlags.isClicked = _clicked ? 1 : 0;  
}
- (BOOL)isClicked {
  return self->sccFlags.isClicked ? YES : NO;
}

@end /* SkyCollapsibleContent */


/* context conditionals */

@interface SkyCollapsibleTitleMode : WEContextConditional
@end

@implementation SkyCollapsibleTitleMode

- (NSString *)_contextKey {
  return @"SkyCollapsible_TitleMode";
}

@end /* SkyCollapsibleTitleMode */

@interface SkyCollapsibleButtonMode : WEContextConditional
@end

@implementation SkyCollapsibleButtonMode

- (NSString *)_contextKey {
  return @"SkyCollapsible_ButtonMode";
}

@end /* SkyCollapsibleButtonMode */

@interface SkyCollapsibleContentMode : WEContextConditional
@end

@implementation SkyCollapsibleContentMode

- (NSString *)_contextKey {
  return @"WECollapsible_ContentMode";
}

@end /* SkyCollapsibleContentMode */
