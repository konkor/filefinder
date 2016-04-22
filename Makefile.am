## Process this file with automake to produce Makefile.in
## Created by Anjuta

SUBDIRS = src 

dist_doc_DATA = \
	README \
	COPYING \
	AUTHORS \
	ChangeLog \
	INSTALL \
	NEWS

EXTRA_DIST = \
	vapi/nautilus.vapi \
	src/nautilus.symbols 

# Remove doc directory on uninstall
uninstall-local:
	-rm -r $(docdir)
