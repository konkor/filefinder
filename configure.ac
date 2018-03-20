dnl Process this file with autoconf to produce a configure script.
dnl Created by Anjuta application wizard.

AC_INIT(filefinder, 0.3.1)

AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([subdir-objects])

AM_SILENT_RULES([yes])

AC_PROG_CC

NAUTILUS_REQUIRED=3.0.0


LT_INIT

dnl Check for vala
AM_PROG_VALAC([0.36.0],
        enable_vala36="yes",
		enable_vala36="no")


PKG_CHECK_MODULES(FILEFINDER, [
  gtk+-3.0
  gio-2.0
  gio-unix-2.0])

# Make dependency CFLAGS and LIBS available
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

if test "x$enable_vala36" = "xyes" ; then
	AC_DEFINE(HAVE_VALA36, 1, [Have VALA36])
	AC_MSG_NOTICE([have vala >= 0.36...])
fi
AM_CONDITIONAL(HAVE_VALA36, test "x$enable_vala36" = "xyes")

PKG_CHECK_EXISTS([gtk+-3.0 >= 3.20.0],
		enable_gtk320="yes",
		enable_gtk320="no")

if test "x$enable_gtk320" = "xyes" ; then
	AC_DEFINE(HAVE_GTK320, 1, [Have GTK 3.20+])
fi
AM_CONDITIONAL(HAVE_GTK320, test "x$enable_gtk320" = "xyes")

AC_ARG_WITH([nautilus-extension],
  [AS_HELP_STRING([--without-nautilus-extension],[Disable nautilus extension])],
  [],
  [with_nautilus_extension=yes])

if test "$with_nautilus_extension" = "yes"; then
  NAUTILUS_REQUIRED=3.0.0

  PKG_CHECK_MODULES([NAUTILUS],[
  libnautilus-extension >= $NAUTILUS_REQUIRED
  gio-2.0
  gio-unix-2.0])

  AC_SUBST(NAUTILUS_EXTENSION_CFLAGS)
  AC_SUBST(NAUTILUS_EXTENSION_LIBS)

  nautilusextensiondir=`$PKG_CONFIG --variable=extensiondir libnautilus-extension`
  AC_ARG_WITH([nautilus-dir],
    [AS_HELP_STRING([--with-nautilus-dir=PATH],[Nautilus extensions directory])],
    [nautilusextensiondir="$withval"],
    [nautilusextensiondir=`$PKG_CONFIG --variable=extensiondir libnautilus-extension`])
  AC_SUBST([nautilusextensiondir])

  AC_MSG_NOTICE([installing nautilus plugin in ${nautilusextensiondir}])
  AC_SUBST([NAUTILUS_EXTENSION_DIR],[${nautilusextensiondir}])
  
fi

AM_CONDITIONAL([WITH_NAUTILUS_EXTENSION],[test "$with_nautilus_extension" = "yes"])

AC_OUTPUT([
Makefile
src/Makefile
src/nautilus/Makefile
data/icons/Makefile
data/templates/Makefile
data/Makefile
man/Makefile
])

echo "
	Version: ${VERSION}
	Using GTK+ 3
	Using GTK+ >= 3.20.0 : ${enable_gtk320}
	Using Vala >= 0.36 : ${enable_vala36}
	Build Nautilus extension : ${with_nautilus_extension}
	
"
