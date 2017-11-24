/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * text.vala
 * Copyright (C) 2016 Kostiantyn Korienkov <kkorienkov [at] gmail.com>
 *
 * filefinder is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * filefinder is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class Text : GLib.Object {

	public const  string app_name				  = "File Finder";
	public const  string app_subtitle			  = "lightwieght find tool";
	public const  string app_version			   = "1.0";
	public const  string app_website			   = "https://github.com/konkor/filefinder/";
	public const  string app_website_label		 = "github";
	public static string app_comments;
	public static string app_description;
	public const  string app_copyright			 = "Copyright © 2016 Kostiantyn Korienkov";
	public const  string app_license			   =
@"File Finder is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

filefinder is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program.  If not, see <http://www.gnu.org/licenses/>.";

	public const  string app_info				  =
@"File Finder, a lightwieght find tool.
Copyright © 2016–2016 Kostiantyn Korienkov <kkorienkov@gmail.com>";

	public const  string app_help				  =
@"Usage:
  filefinder [OPTIONS] [[PATH] ...]

Options:
  --help	   Show this help and exit
  --version	Show version number and exit
  --license		Show license and exit
  --debug		  Print debug messages

  PATH		 Path file to search

Examples:
  * Find in /home/user folder:
  filefinder /home/user

" + app_info + "\n";

public const  string first_run = "Press 'Insert' or click '+' to start build search query.";

public const string[] encodings = {
"ARMSCII-8", "BIG-5", "BIG5-HKSCS", "CP868", "CP932", "EUC-JP-MS", "EUC-JP",
"EUC-KR", "EUC-TW", "GB2312", "GB13000", "GBK", "GEORGIAN-ACADEMY", "IBM850",
"IBM852", "IBM855", "IBM857", "IBM862", "IBM864", "ISO-2022-CN", "ISO-2022-JP",
"ISO-2022-KR", "ISO-8859-1", "ISO-8859-2", "ISO-8859-3", "ISO-8859-4", "ISO-8859-5",
"ISO-8859-6", "ISO-8859-7", "ISO-8859-8", "ISO-8859-9", "ISO-8859-10",
"ISO-8859-11", "ISO-8859-13", "ISO-8859-14", "ISO-8859-15", "ISO-8859-16", "ISO-IR-111",
"JOHAB", "KOI8-R", "KOI8R", "KOI8U", "SHIFT-JIS", "SHIFT_JIS", "SHIFT_JISX0213", "SJIS-OPEN", "SJIS-WIN", "TCVN", "TIS-620", "UCS-2", "UCS-4", "UHC",
"UNICODE", "UTF-7", "UTF-8", "UTF-16", "UTF-16BE", "UTF-16LE", "UTF-32", "VISCII",
"WINDOWS-31J", "WINDOWS-874", "WINDOWS-936", "WINDOWS-1250", "WINDOWS-1251",
"WINDOWS-1252", "WINDOWS-1253", "WINDOWS-1254", "WINDOWS-1255", "WINDOWS-1256",
"WINDOWS-1257", "WINDOWS-1258"
};

}
