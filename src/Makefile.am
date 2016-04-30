## Process this file with automake to produce Makefile.in

SUBDIRS = nautilus

AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(FILEFINDER_CFLAGS)

AM_CFLAGS =\
	 -Wall\
	 -g

bin_PROGRAMS = filefinder

filefinder_SOURCES = \
	main.vala \
	filefinder.vala \
	common/text.vala \
	common/debug.vala \
	gui/file-finder-window.vala \
	gui/query-row.vala \
	gui/query-editor.vala \
	gui/results-view.vala \
	gui/preferences.vala \
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
	base/result.vala \
	base/filter-files.vala \
	base/filter-size.vala

#config.vapi 

filefinder_VALAFLAGS =  \
	--target-glib=2.38 \
	--pkg gtk+-3.0 \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	-g --save-temps

filefinder_LDFLAGS = \
	-Wl,--export-dynamic

filefinder_LDADD = $(FILEFINDER_LIBS)


CLEANFILES = \
	$(filefinder_SOURCES:%.vala=%.c) \
	*.stamp \
	*~

dist-hook:
	rm -f $(CLEANFILES)

