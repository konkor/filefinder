## Process this file with automake to produce Makefile.in
## Created by Anjuta

SUBDIRS = data src 

dist_doc_DATA = \
	README \
	COPYING \
	AUTHORS \
	ChangeLog \
	INSTALL \
	NEWS

EXTRA_DIST = \
	vapi/nautilus.vapi \
	vapi/config.vapi 

# Remove doc directory on uninstall
uninstall-local:
	-rm -r $(docdir)

DISTCLEANFILES = aclocal.m4 ar-lib compile config.guess config.sub \
	config.status configure depcomp install-sh libtool ltmain.sh \
	missing Makefile.in

distclean-local:
	rm -rf autom4te.cache
