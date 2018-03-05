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

public interface iFilter : Object {
  public abstract types filter_type ();
}

public class Filter {
	private FilterNone none;
	private FilterLocation location;
	private FilterFiles file;
	private FilterMask mask;
	private FilterModified modified;
	private FilterMime mime;
	private FilterText text;
	private FilterBin bin;
	private FilterSize size;

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
			case types.FILES:
				return file;
			case types.FILEMASK:
				return mask;
			case types.MIMETYPE:
				return mime;
			case types.TEXT:
				return text;
			case types.BINARY:
				return bin;
			case types.SIZE:
				return size;
			case types.MODIFIED:
				return modified;
			default:
				return none;
		}
		}
		set {
		if (value == null) {
			filter_type = types.NONE;
			return;
		}
		//switch (value.get_type ().name ()) {
		switch (((iFilter)value).filter_type ()) {
			case types.LOCATION:
				filter_type = types.LOCATION;
				location =(FilterLocation) value;
				break;
			case types.FILES:
				filter_type = types.FILES;
				file =(FilterFiles) value;
				break;
			case types.FILEMASK:
				filter_type = types.FILEMASK;
				mask =(FilterMask) value;
				break;
			case types.MIMETYPE:
				filter_type = types.MIMETYPE;
				mime =(FilterMime) value;
				break;
			case types.TEXT:
				filter_type = types.TEXT;
				text =(FilterText) value;
				break;
			case types.BINARY:
				filter_type = types.BINARY;
				bin =(FilterBin) value;
				break;
			case types.SIZE:
				filter_type = types.SIZE;
				size =(FilterSize) value;
				break;
			case types.MODIFIED:
				filter_type = types.MODIFIED;
				modified =(FilterModified) value;
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
	SIZE,
	MODIFIED,
	NONE
}

public static const string[] type_names = {
	"Folder",
	"Files",
	"File Mask",
	"Mimetype",
	"Text",
	"Binary",
	"Size",
	"Modified"
};
