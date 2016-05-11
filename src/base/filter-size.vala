/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * filter-size.vala
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

public class FilterSize : GLib.Object, iFilter {
	public static uint[] WEIGHT = {1, 1024, 1048576, 1073741824};

	public FilterSize () {
	}

	public types filter_type () {
		return types.SIZE;
	}

	private uint64 _size;
	public uint64 size {
		get {
			return _size;
		}
		set {
			_size = value;
		}
	}

	public uint64 kib {
		get {
			return _size / WEIGHT[1];
		}
		set {
			_size = value * WEIGHT[1];
		}
	}

	public uint64 mib {
		get {
			return _size / WEIGHT[2];
		}
		set {
			_size = value * WEIGHT[2];
		}
	}

	public uint64 gib {
		get {
			return _size / WEIGHT[3];
		}
		set {
			_size = value * WEIGHT[3];
		}

	}

	private date_operator _op = date_operator.MORE_EQUAL;
	public date_operator operator {
		get {
			return _op;
		}
		set {
			_op = value;
		}
	}

}
