/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * query.vala
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

public class Query : GLib.Object {

	public List<FilterLocation> locations;
	public List<FilterMask> masks;
	public List<FilterModified> modifieds;
	public List<FilterMime> mimes;
	public List<FilterText> texts;
	public List<FilterBin> bins;

	public Query () {
		locations = new List<FilterLocation> ();
		masks = new List<FilterMask> ();
		modifieds = new List<FilterModified> ();
		mimes = new List<FilterMime> ();
		texts = new List<FilterText> ();
		bins = new List<FilterBin> ();
	}

	public void add_filter (Filter filter) {
		if (filter == null) return;
		switch (filter.filter_type) {
			case types.LOCATION:
				locations.append ((FilterLocation)filter.filter_value);
				break;
			case types.FILEMASK:
				masks.append ((FilterMask)filter.filter_value);
				break;
			case types.TEXT:
				texts.append ((FilterText)filter.filter_value);
				break;
			case types.MODIFIED:
				modifieds.append ((FilterModified)filter.filter_value);
				break;
			case types.BINARY:
				bins.append ((FilterBin)filter.filter_value);
				break;
			case types.MIMETYPE:
				mimes.append ((FilterMime)filter.filter_value);
				break;
		}
	}

}

