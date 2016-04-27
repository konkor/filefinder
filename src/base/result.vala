/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * result.vala
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

public class Result : GLib.Object {

	public Result () {
	}

	private string _filename;
	public string? filename {
		get {
			return _filename;
		}
		set {
			_filename = value;
		}
	}

	private uint _nrow = 0;
	public uint nrow {
		get {
			return _nrow;
		}
		set {
			_nrow = value;
		}
	}

	private string _row;
	public string? row {
		get {
			return _row;
		}
		set {
			_row = value;
		}
	}

}

