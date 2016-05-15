dnl Process this file with autoconf to produce a configure script.
dnl Created by Anjuta application wizard.

AC_INIT(filefinder, 0.1)

AC_CONFIG_HEADERS([config.h])

AM_INIT_AUTOMAKE([subdir-objects])

AM_SILENT_RULES([yes])

AC_PROG_CC

NAUTILUS_REQUIRED=3.0.0


LT_INIT

dnl Check for vala
AM_PROG_VALAC([0.10.0])


PKG_CHECK_MODULES(FILEFINDER, [
  gtk+-3.0
  gio-2.0
  gio-unix-2.0])

PKG_CHECK_MODULES([NAUTILUS],[
  libnautilus-extension >= $NAUTILUS_REQUIRED
  gio-2.0
  gio-unix-2.0])

# Make dependency CFLAGS and LIBS available
AC_SUBST(NAUTILUS_CFLAGS)
AC_SUBST(NAUTILUS_LIBS)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

nautilusextensiondir='${libdir}/nautilus/extensions-3.0'
#nautilusextensiondir=`$PKG_CONFIG --variable=extensiondir libnautilus-extension`
AC_ARG_WITH([nautilus-dir],
  [AS_HELP_STRING([--with-nautilus-dir=PATH],[Nautilus extensions directory])],
  [nautilusextensiondir="$withval"],
  [nautilusextensiondir='${libdir}/nautilus/extensions-3.0'])
AC_SUBST([nautilusextensiondir])

AC_MSG_NOTICE([installing nautilus plugin in ${nautilusextensiondir}])
AC_SUBST([NAUTILUS_EXTENSION_DIR],[${nautilusextensiondir}])

AC_OUTPUT([
Makefile
src/Makefile
src/nautilus/Makefile
data/icons/Makefile
data/Makefile
])
