/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * filter.vala
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

public class Filter {
	private FilterNone none;
	private FilterLocation location;
	
	public Filter () {
		none = new FilterNone ();
		_type = types.NONE;
	}

	private types _type;
	public types filter_type {
		get {
			return _type;
		}
		set {
			_type = value;
		}
	}

	public Object filter_value {
		get {
		switch (filter_type) {
			case types.LOCATION:
				return location;
			default:
				return none;
		}
		}
		set {
		if (value == null) {
			filter_type = types.NONE;
			return;
		}
		switch (value.get_type ().name ()) {
			case "FilterLocation":
				filter_type = types.LOCATION;
				location =(FilterLocation) value;
				break;
			default:
				filter_type = types.NONE;
				break;
		}
		}
	}

}

public enum types {
	LOCATION,
	FILES,
	FILEMASK,
	MIMETYPE,
	TEXT,
	BINARY,
	MODIFIED,
	NONE
}