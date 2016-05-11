/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * debug.vala
 * Copyright (C) 2016 SEE AUTHORS <>
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

public class Debug : GLib.Object {

	public static string last_error = "";

	public static void log (string source,
							string? output)
	{
		print_msg (domain.DEBUG, source, output);
	}

	public static void info (string source,
							string? output)
	{
		print_msg (domain.INFO, source, output);
	}

	public static void error (string source,
							string? output)
	{
		last_error = source + ":\n" + output;
		print_msg (domain.ERROR, source, output);
	}

	public static void print_msg (domain _domain,
									string source,
									string? output)
	{
		if (Filefinder.debugging || (_domain == domain.ERROR)) {
			DateTime now = new DateTime.now_local();

			stdout.printf ("\x1b[%sm[%02d:%02d:%02d.%06d %s] [%s]\x1b[0m %s\n", // http://ascii-table.com/ansi-escape-sequences.php
						domain_color (_domain),
						now.get_hour(),
						now.get_minute(),
						now.get_second(),
						now.get_microsecond(),
						domain_name (_domain).up(),
						source,
						output);
		}
	}

	public enum domain
	{
		ERROR, INFO, DEBUG;
	}

	private static string domain_color (domain _domain)
	{
		switch (_domain)
		{
			case domain.ERROR:		  return "00;31"; // Red
			case domain.INFO:		   return "00;34"; // Blue
			case domain.DEBUG:		  return "00;32"; // Green

			default:					return "0";
		}
	}

	private static string domain_name (domain _domain)
	{
		switch (_domain)
		{
			case domain.ERROR:		  return "Error";
			case domain.INFO:		   return "Info";
			case domain.DEBUG:		  return "Debug";

			default:					return "Unknown";
		}
	}

}
