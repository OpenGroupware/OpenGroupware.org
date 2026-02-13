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

#ifndef __LSWebInterface_LSWFoundation_LSWNotifications_H__
#define __LSWebInterface_LSWFoundation_LSWNotifications_H__

#import <Foundation/NSString.h>

/**
 * @file LSWNotifications.h
 * @brief Notification name constants for OGo WebUI change
 *        notifications.
 *
 * Defines string constants for NSNotification names posted
 * when OGo entities are created, updated, or deleted.
 * Covers contacts (person, enterprise), appointments,
 * projects, documents, accounts, teams, tasks, mail,
 * news articles, catalogs, and object links. Components
 * observe these notifications to refresh their state when
 * data changes.
 */

#define LSWNewAddressNotificationName          @"LSWNewAddress"

#define LSWNewEnterpriseNotificationName       @"LSWNewEnterprise"
#define LSWUpdatedEnterpriseNotificationName   @"LSWUpdatedEnterprise"
#define LSWDeletedEnterpriseNotificationName   @"LSWDeletedEnterprise"

#define LSWNewPersonNotificationName           @"LSWNewPerson"
#define LSWUpdatedPersonNotificationName       @"LSWUpdatedPerson"
#define LSWDeletedPersonNotificationName       @"LSWDeletedPerson"

#define LSWUpdatedAccountPreferenceNotificationName @"LSWUpdatedAccountPreference"

#define LSWNewDocumentNotificationName         @"LSWNewDocument"
#define LSWUpdatedDocumentNotificationName     @"LSWUpdatedDocument"
#define LSWDeletedDocumentNotificationName     @"LSWDeletedDocument"
#define LSWMovedDocumentNotificationName       @"LSWMovedDocument"

#define LSWNewFolderNotificationName           @"LSWNewFolder"
#define LSWUpdatedFolderNotificationName       @"LSWUpdatedFolder"

#define LSWNewObjectLinkProjectNotificationName  @"LSWNewObjectLinkProject"
#define LSWNewObjectLinkEnterpriseNotificationName @"LSWNewObjectLinkEnterprise"
#define LSWNewObjectLinkNotificationName       @"LSWNewObjectLink"

#define LSWUpdatedObjectLinkNotificationName   @"LSWUpdatedObjectLink"
#define LSWDeletedObjectLinkNotificationName   @"LSWDeletedObjectLink"

#define LSWNewNoteNotificationName             @"LSWNewNote"
#define LSWUpdatedNoteNotificationName         @"LSWUpdatedNote"
#define LSWDeletedNoteNotificationName         @"LSWDeletedNote"

#define LSWNewProjectNotificationName          @"LSWNewProject"
#define LSWUpdatedProjectNotificationName      @"LSWUpdatedProject"
#define LSWDeletedProjectNotificationName      @"LSWDeletedProject"

#define LSWNewTextDocumentNotificationName     @"LSWNewTextDocument"
#define LSWUpdatedTextDocumentNotificationName @"LSWUpdatedTextDocument"
#define LSWDeletedTextDocumentNotificationName @"LSWDeletedTextDocument"

#define LSWNewAppointmentNotificationName      @"LSWNewAppointment"
#define LSWUpdatedAppointmentNotificationName  @"LSWUpdatedAppointment"
#define LSWDeletedAppointmentNotificationName  @"LSWDeletedAppointment"

#define LSWNewAccountNotificationName          @"LSWNewAccount"
#define LSWUpdatedAccountNotificationName      @"LSWUpdatedAccount"
#define LSWDeletedAccountNotificationName      @"LSWDeletedAccount"

#define LSWUpdatedPasswordNotificationName     @"LSWUpdatedAccountPassword"

#define LSWNewTeamNotificationName             @"LSWNewTeam"
#define LSWUpdatedTeamNotificationName         @"LSWUpdatedTeam"
#define LSWDeletedTeamNotificationName         @"LSWDeletedTeam"

#define LSWJobHasChanged                       @"LSWJobHasChanged"

#define LSWUpdatedCategoriesNotificationName   @"LSWUpdatedCategories"
#define LSWUpdatedArticleNotificationName      @"LSWUpdatedArticle"
#define LSWUpdatedArticlesNotificationName     @"LSWUpdatedArticles"
#define LSWDeletedArticleNotificationName      @"LSWDeletedArticle"

#define LSWNewNewsArticleNotificationName      @"LSWNewNewsArticle"
#define LSWUpdatedNewsArticleNotificationName  @"LSWUpdatedNewsArticle"
#define LSWDeletedNewsArticleNotificationName  @"LSWDeletedNewsArticle"

#define LSWNewCatalogNotificationName          @"LSWNewCatalog"
#define LSWUpdatedCatalogNotificationName      @"LSWUpdatedCatalog"
#define LSWDeletedCatalogNotificationName      @"LSWDeletedCatalog"

#define LSWMailFilterDidChangeNotificationName @"LSWMailFilterDidChange"
#define LSWNewMailFolderNotificationName       @"LSWNewMailFolder"
#define LSWDeletedEmailNotificationName        @"LSWDeletedEmail"

#define LSWNewJobLinkNotificationName          @"LSWNewJobLink"

#define LSWMailDeletedNotification             @"LSWMailDeleted"
#define LSWMailMovedNotification               @"LSWMailMoved"

#define LSWUpdatedUrlNotificationName          @"LSWUpdatedUrl"

#endif /* __LSWebInterface_LSWFoundation_LSWNotifications_H__ */
