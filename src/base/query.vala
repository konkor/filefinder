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
	public List<string> files;
	public List<FilterMask> masks;
	public List<FilterModified> modifieds;
	public List<string> mimes;
	public List<FilterText> texts;
	public List<FilterBin> bins;

	public bool exclude_mounts { get; private set; }

	public Query () {
		locations = new List<FilterLocation> ();
		files = new List<string> ();
		masks = new List<FilterMask> ();
		modifieds = new List<FilterModified> ();
		mimes = new List<string> ();
		texts = new List<FilterText> ();
		bins = new List<FilterBin> ();

		exclude_mounts = true;
	}

	public void add_filter (Filter filter) {
		if (filter == null) return;
		switch (filter.filter_type) {
			case types.LOCATION:
				if (!location_exist ((FilterLocation)filter.filter_value))
					locations.append ((FilterLocation)filter.filter_value);
				break;
			case types.FILES:
				foreach (string s in ((FilterFiles)filter.filter_value).files) {
					if (!file_exist (s))
						files.append (s);
				}
				break;
			case types.FILEMASK:
				if (!mask_exist ((FilterMask)filter.filter_value))
					masks.append ((FilterMask)filter.filter_value);
				break;
			case types.TEXT:
				if (!text_exist ((FilterText)filter.filter_value))
					texts.append ((FilterText)filter.filter_value);
				break;
			case types.MODIFIED:
				if (!mod_exist ((FilterModified)filter.filter_value))
					modifieds.append ((FilterModified)filter.filter_value);
				break;
			case types.BINARY:
				if (!bin_exist ((FilterBin)filter.filter_value))
					bins.append ((FilterBin)filter.filter_value);
				break;
			case types.MIMETYPE:
				foreach (string s in ((FilterMime)filter.filter_value).mime) {
					if (!mime_exist (s))
						mimes.append (s);
				}
				//mimes.append ((FilterMime)filter.filter_value);
				break;
		}
	}

	private bool location_exist (FilterLocation f) {
		foreach (FilterLocation p in locations) {
			if (p.folder == f.folder) {
				if (p.recursive != f.recursive) {
					p.recursive = true;
				}
				return true;
			}
		}
		return false;
	}

	private bool file_exist (string file) {
		foreach (string s in files) {
			if (s == file) return true;
		}
		return false;
	}

	private bool mask_exist (FilterMask f) {
		foreach (FilterMask p in masks) {
			if (p.mask == f.mask) {
				if (p.case_sensetive != f.case_sensetive) {
					p.case_sensetive = false;
				}
				return true;
			}
		}
		return false;
	}

	private bool text_exist (FilterText f) {
		foreach (FilterText p in texts) {
			if ((p.text == f.text) && (p.is_utf8 == f.is_utf8)){
				if (p.case_sensetive != f.case_sensetive) {
					p.case_sensetive = false;
				}
				return true;
			}
		}
		return false;
	}

	private bool mod_exist (FilterModified f) {
		foreach (FilterModified p in modifieds) {
			if ((p.date.compare (f.date) == 0) && (p.operator == f.operator)){
				return true;
			}
		}
		return false;
	}

	private bool bin_exist (FilterBin f) {
		foreach (FilterBin p in bins) {
			if (p.bin == f.bin){
				return true;
			}
		}
		return false;
	}

	private bool mime_exist (string m) {
		foreach (string s in mimes) {
			if (s == m) return true;
		}
		return false;
	}
}

