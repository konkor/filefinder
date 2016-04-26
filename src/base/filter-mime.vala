/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * filter-mime.vala
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

public class FilterMime : GLib.Object {

	public FilterMime () {
		_mime = new GLib.List<string>();
	}

	private List<string> _mime;
	public List<string> mime {
		get {
			return _mime;
		}
	}

	public void add_mime (string? mimetype) {
		if (mimetype == null) return;
		_mime.append (mimetype);
	}

	public void clear () {
		_mime = new GLib.List<string>();
	}
}

