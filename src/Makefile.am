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
	filefinder.vala config.vapi

filefinder_VALAFLAGS =  \
	--pkg gtk+-3.0


filefinder_LDFLAGS = \
	-Wl,--export-dynamic

filefinder_LDADD = $(FILEFINDER_LIBS)




