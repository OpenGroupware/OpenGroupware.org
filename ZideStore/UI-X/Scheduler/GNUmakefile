# GNUstep makefiles

include $(GNUSTEP_MAKEFILES)/common.make
include ../../Version
include ./Version

BUNDLE_NAME        = SchedulerUI
BUNDLE_EXTENSION   = .zsp
BUNDLE_INSTALL_DIR = $(GNUSTEP_BUNDLES)/ZideStore-$(MAJOR_VERSION).$(MINOR_VERSION)

SchedulerUI_PRINCIPAL_CLASS = SchedulerUIProduct

SchedulerUI_OBJC_FILES = \
	SchedulerUIProduct.m	\
	OGoCalView.m		\
	OGoCalWeekView.m	\
	OGoCalMonthView.m	\
	OGoAptTableView.m	\
	\
	OGoCalWeekOverview.m	\
	OGoCalMonthOverview.m	\
	OGoAppointmentView.m	\

SchedulerUI_RESOURCE_FILES += \
	Version										\
	product.plist							\
	\
	OGoAptTableView.wox				\
	OGoCalWeekOverview.wox		\
	OGoCalMonthOverview.wox		\
	OGoAppointmentView.wox		\
	images/next_week.gif			\
	images/previous_week.gif	\

ZIDESTORE=../..

ADDITIONAL_INCLUDE_DIRS += \
	-I. \
	-I$(ZIDESTORE)/Frontend -I$(ZIDESTORE)/Backend -I$(ZIDESTORE)

# make

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
-include ../../fhsbundle.make

ifneq ($(GNUSTEP_BUILD_DIR),)
after-all ::
	@(cp bundle-info.plist \
	  $(GNUSTEP_BUILD_DIR)/$(BUNDLE_NAME)$(BUNDLE_EXTENSION))
else
after-all ::
	@(cd $(BUNDLE_NAME)$(BUNDLE_EXTENSION);\
	  cp ../bundle-info.plist .)
endif
