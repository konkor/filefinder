/* -*- Mode: vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * text.vala
 * Copyright (C) 2016 Kostiantyn Korienkov <kkorienkov [at] gmail.com>
 *
 * strmerge is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * strmerge is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

public class Text : GLib.Object {

    public const  string app_name                  = "File Finder";
    public const  string app_subtitle              = "lightwieght find tool";
    public const  string app_version               = "1.0";
    public const  string app_website               = "https://github.com/konkor/filefinder/";
    public const  string app_website_label         = "github";
    public static string app_comments;
    public static string app_description;
    public const  string app_copyright             = "Copyright © 2016 Kostiantyn Korienkov";
    public const  string app_license               =
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
    
    public const  string app_info                  =
@"File Finder, a lightwieght find tool.
Copyright © 2016–2016 Kostiantyn Korienkov <kkorienkov@gmail.com>";
            
    public const  string app_help                  =
@"Usage:
  filefinder [FOLDER ...]

Options:
  -h, --help       Show this help and exit
  -v, --version    Show version number and exit
  --license        Show license and exit
  --debug          Print debug messages
  -FOLDER        Path file to search

Examples:
  * Find in /home/user folder:
  filefinder /home/user
 
" + app_info + "\n";

}
