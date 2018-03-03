## Process this file with automake to produce Makefile.in
## Created by Anjuta

SUBDIRS = man data src 

DISTCHECK_CONFIGURE_FLAGS = \
	--without-nautilus-extension \
	$(NULL)

dist_doc_DATA = \
	README \
	README.md \
	COPYING \
	AUTHORS \
	ChangeLog \
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
