/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * filter-modified.vala
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

public class FilterModified : GLib.Object, iFilter {

	public FilterModified () {
		DateTime d = new DateTime.now_utc();
		_date = new DateTime.utc (d.get_year (),
		                            d.get_month (),
		                            d.get_day_of_month(),
		                            0, 0, 0);
	}

	public types filter_type () {
		return types.MODIFIED;
	}

	private date_operator _op = date_operator.EQUAL;
	public date_operator operator {
		get {
			return _op;
		}
		set {
			_op = value;
		}
	}

	private DateTime _date;
	public DateTime date {
		get {
			return _date;
		}
		set {
			_date = value;
		}
	}

}

public enum date_operator {
	NOT_EQUAL,
	LESS,
	LESS_EQUAL,
	EQUAL,
	MORE_EQUAL,
	MORE
}

public static const string[] date_operators = {
	"not equal",
	"less",
	"less or equal",
	"equal",
	"more or equal",
	"more"
};
