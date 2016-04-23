## Process this file with automake to produce Makefile.in

## Created by Anjuta



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
	main.vala filefinder.vala config.vapi text.vala file-finder-window.vala debug.vala query-row.vala query-editor.vala

filefinder_VALAFLAGS =  \
	--pkg gtk+-3.0


filefinder_LDFLAGS = \
	-Wl,--export-dynamic

filefinder_LDADD = $(FILEFINDER_LIBS)



nautilus_extensiondir = $(NAUTILUS_EXTENSION_DIR)
nautilus_extension_LTLIBRARIES = libnautilus-filefinder.la

libnautilus_filefinder_la_SOURCES = nautilus-extension.c
libnautilus_filefinder_la_VALAFLAGS = \
	--pkg gio-2.0 \
	--pkg gio-unix-2.0 \
	--pkg gtk+-3.0 \
	--pkg nautilus \
	--vapidir=\$(top_srcdir)/vapi
nautilus-extension.c:
	$(AM_V_VALAC) $(VALAC) $(libnautilus_filefinder_la_VALAFLAGS) -C nautilus-extension.vala && \
	$(SED) -i "s/(GType\*\* types/(const GType\*\* types/" nautilus-extension.c

libnautilus_filefinder_la_CPPFLAGS = \
	-DTERM_LOCALEDIR="\"$(datadir)/locale\"" \
	$(AM_CPPFLAGS)

libnautilus_filefinder_la_CFLAGS = \
	$(NAUTILUS_CFLAGS) \
	$(GLIB_CFLAGS) \
	$(WARN_CFLAGS) \
	$(AM_CFLAGS)

##if DEBUG
##libnautilus_filefinder_la_CFLAGS += -DND_DEBUG
##else
##libnautilus_filefinder_la_CFLAGS += -DG_DISABLE_ASSERT -DG_DISABLE_CHECKS
##endif

libnautilus_filefinder_la_LDFLAGS = \
	-module -avoid-version \
	-export-symbols $(srcdir)/nautilus.symbols \
	$(AM_LDFLAGS)

libnautilus_filefinder_la_LIBADD = \
	$(NAUTILUS_LIBS) $(GLIB_LIBS)

CLEANFILES = \
	$(filefinder_SOURCES:%.vala=%.c) \
	*.stamp

EXTRA_DIST = \
	src/nautilus.symbols

dist-hook:
	cd $(srcdir); rm -f $(CLEANFILES)

