/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * filter-files.vala
 * Copyright (C) 2016 Kostiantyn Korienkov <kkorienkov <at> gmail.com>
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

public class FilterFiles : GLib.Object, iFilter {

	public FilterFiles () {
		_files = new GLib.List<string>();
	}

	public types filter_type () {
		return types.FILES;
	}

	private List<string> _files;
	public List<string> files {
		get {
			return _files;
		}
	}

	public void add (string? path) {
		if (path == null) return;
		_files.append (path);
	}

	public void clear () {
		_files = new GLib.List<string>();
	}
}
