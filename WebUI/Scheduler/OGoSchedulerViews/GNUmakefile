# GNUstep makefile

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

OGoSchedulerViews_RESOURCE_FILES += Defaults.plist Version
OGoSchedulerViews_LOCALIZED_RESOURCE_FILES += OGoSchedulerViews.ccfg

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/wobundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make
