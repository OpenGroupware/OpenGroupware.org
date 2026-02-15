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

#ifndef __Skyrix_Logic_SkyContacts_SkyContactAddressDataSource__
#define __Skyrix_Logic_SkyContacts_SkyContactAddressDataSource__

/**
 * @class SkyContactAddressDataSource
 * @brief Datasource for postal addresses belonging to
 *        a specific contact (person or enterprise).
 *
 * Fetches, creates, inserts, updates, and deletes
 * SkyAddressDocument objects for a given contact
 * identified by its global ID. Uses the address::get,
 * address::new, address::set, and address::delete
 * Logic commands.
 *
 * Fetch specification hints:
 *   - addDocumentsAsObserver: NSNumber (default: YES)
 *
 * @see SkyAddressDocument
 * @see SkyCompanyDocument
 */

#import <EOControl/EODataSource.h>

@class EOFetchSpecification;

@interface SkyContactAddressDataSource: EODataSource
{
@protected
  id                   contactGID;
  id                   context;
  EOFetchSpecification *fetchSpecification;
}

- (id)initWithContext:(id)_context contact:(id)_gid;

/* accessors */

- (id)context;

@end

/**
 * @category SkyContactAddressDataSource(ConcretePrivats)
 * @brief Subclass hooks for contact-type-specific
 *        address configuration.
 */
@interface SkyContactAddressDataSource(ConcretePrivats)
- (NSString *)contactType;   // Person or Enterprise
- (NSArray *)validAddressTypes; // valid address types for contact
@end

#endif /* __Skyrix_Logic_SkyContacts_SkyContactAddressDataSource__ */
