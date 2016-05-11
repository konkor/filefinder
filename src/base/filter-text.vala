/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * filter-text.vala
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

public class FilterText : GLib.Object, iFilter {

	public FilterText () {
	}

	public types filter_type () {
		return types.TEXT;
	}

	private string _text = "";
	public string text {
		get {
			return _text;
		}
		set {
			_text = value;
		}
	}

	private string _enc = "UTF-8";
	public string encoding {
		get {
			return _enc;
		}
		set {
			_enc = value;
		}
	}

	private bool _case = false;
	public bool case_sensetive {
		get {
			return _case;
		}
		set {
			_case = value;
		}
	}

	public bool is_utf8 {
		get {
			return encoding == "UTF-8";
		}
	}

}
