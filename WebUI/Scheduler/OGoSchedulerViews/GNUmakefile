# $Id: GNUmakefile 1 2004-08-20 11:17:52Z znek $

include ../common.make

WOBUNDLE_NAME = OGoSchedulerViews

OGoSchedulerViews_PRINCIPAL_CLASS = SkySchedulerViewsModule

OGoSchedulerViews_OBJC_FILES = \
	SkySchedulerViewsModule.m       \
	\
	SkyInlineAptDataSourceView.m	\
	SkySchedulerDateCell.m          \
	SkyMonthRepetition.m            \
	SkyMonthBrowser.m		\
	SkySchedulerConflictCell.m	\
	SkyAppointmentFormatter.m	\
	\
	SkyInlineDayOverview.m		\
	SkyInlineWeekOverview.m		\
	SkyInlineMonthOverview.m	\
	SkyInlineYearOverview.m		\
	SkyInlineDayChart.m             \
	SkyInlineWeekChart.m		\
	SkyInlineDayHChart.m		\
	SkyInlineWeekHChart.m		\
	SkyPrintWeekOverview.m		\
	SkyPrintMonthOverview.m         \
	SkyInlineWeekColumnView.m       \
	\
	SkyAppointmentList.m		\
	SkyNewsAppointmentList.m	\
	SkyAptResourceList.m		\
	SkyAptResourceGroupsList.m	\

OGoSchedulerViews_COMPONENTS = \
	SkySchedulerConflictCell.wo	\
	SkyMonthBrowser.wo		\
	\
	SkyInlineDayOverview.wo		\
	SkyInlineWeekOverview.wo	\
	SkyInlineMonthOverview.wo	\
	SkyInlineYearOverview.wo	\
	SkyInlineDayChart.wo		\
	SkyInlineWeekChart.wo		\
	SkyInlineDayHChart.wo		\
	SkyInlineWeekHChart.wo		\
	SkyPrintWeekOverview.wo		\
	SkyPrintMonthOverview.wo    	\
	SkyInlineWeekColumnView.wo  	\
	\
	SkyAppointmentList.wo      	\
	SkyAptResourceList.wo		\
	SkyNewsAppointmentList.wo   	\
	SkyAptResourceGroupsList.wo	\

OGoSchedulerViews_RESOURCE_FILES += Defaults.plist Version
OGoSchedulerViews_LOCALIZED_RESOURCE_FILES += OGoSchedulerViews.ccfg

OGoSchedulerViews_LANGUAGES = \
	English		\
	English_blue 	\
	English_orange

-include SKYRIX.make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
