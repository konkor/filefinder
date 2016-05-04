/* -*- Mode: C; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * main.vala
 * Copyright (C) 2016 Kostiantyn Korienkov <kkorienkov [at] gmail.com>
 * 
 * srtmerge is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * srtmerge is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;

static int main (string[] args) {

	Filefinder.debugging = true;

    foreach (string s in args) {
		if ((s == "-h") || (s == "--help"))
		{
			stdout.printf ("%s\n", Text.app_help);
			return 0;
		}
		if ((s == "-v") || (s == "--version"))
		{
			stdout.printf ("%s\n", Text.app_name + " " + Text.app_version);
			return 0;
		}
		if (s == "--license")
		{
			stdout.printf ("%s\n", "\n" + Text.app_info + "\n\n" + Text.app_license + "\n");
			return 0;
		}
		else if (s == "--debug")
		{
			Filefinder.debugging = true;
		}
	}

	var app = new Filefinder (args);

	return app.run ();
}
