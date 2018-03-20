## Process this file with automake to produce Makefile.in

SUBDIRS = nautilus

AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	-DTEMPLATE_DIR=\""$(pkgdatadir)/templates"\" \
	$(FILEFINDER_CFLAGS)

AM_CFLAGS =\
	 -Wall\
	 -g

bin_PROGRAMS = filefinder

filefinder_sources = \
	filefinder.vala \
	common/text.vala \
	common/debug.vala \
	gui/file-finder-window.vala \
	gui/query-row.vala \
	gui/query-editor.vala \
	gui/results-view.vala \
	gui/column-menu-item.vala \
	gui/preferences.vala \
	gui/dialog-mime-chooser.vala \
	base/query.vala \
	base/filter.vala \
	base/filter-location.vala \
	base/filter-none.vala \
	base/filter-mask.vala \
	base/filter-mime.vala \
	base/filter-text.vala \
	base/filter-bin.vala \
	base/filter-modified.vala \
	base/service.vala \
	base/filter-files.vala \
	base/filter-size.vala \
	gui/menu-item-id.vala \
	gui/mime-button.vala \
	base/plugin.vala \
	gui/page-plugin.vala \
	gui/input-dialog.vala \
	gui/toolbar.vala \
	gui/tool-button.vala \
	gui/filter-bar.vala

#config.vapi 

filefinder_SOURCES = \
	main.vala \
	$(filefinder_sources)

filefinder_VALAFLAGS =  \
	--target-glib=2.38 \
	--pkg gtk+-3.0 \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	--pkg posix \
	--pkg config \
	--vapidir=\$(top_srcdir)/vapi
#	-g --save-temps

if HAVE_VALA36
filefinder_VALAFLAGS += -D HAVE_VALA36
endif

if HAVE_GTK320
filefinder_VALAFLAGS += -D HAVE_GTK320
endif

filefinder_LDFLAGS = \
	-Wl,--export-dynamic

filefinder_LDADD = $(FILEFINDER_LIBS)

## Unit tests for filefinder
## to run $ make check
check_PROGRAMS = tests_filefinder
noinst_PROGRAMS = $(check_PROGRAMS)
TESTS = $(check_PROGRAMS)

# the entry point and test methods for the test program
tests_filefinder_SOURCES =  \
	$(filefinder_sources) \
	tests.vala
	
tests_filefinder_VALAFLAGS = \
	$(filefinder_VALAFLAGS) \
	-g 

tests_filefinder_LDFLAGS = \
	$(filefinder_LDFLAGS)

tests_filefinder_LDADD = \
	$(filefinder_LDADD)
	
tests_filefinder_CPPFLAGS = \
	$(AM_CPPFLAGS)
	
tests_filefinder_CFLAGS = \
	$(AM_CFLAGS) \
	-DTEST_DATA_DIR=\"$(abs_srcdir)/data\"

CLEANFILES = \
	$(filefinder_SOURCES:%.vala=%.c) \
	*.stamp \
	*~ \
	*.log \
	*.trs \
	tests.c

dist-hook:
	rm -f $(CLEANFILES)

