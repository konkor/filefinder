/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * button-type.vala
 * Copyright (C) 2016 kapa <kkorienkov <at> gmail.com>
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

public class ButtonType : Gtk.Button {
	private types _btype;

	public ButtonType (types btn_type = types.LOCATION, string btn_title = "LOCATION") {
		label = btn_title;
		tooltip_text = "Add " + btn_title + " Filter";
		_btype = btn_type;

		switch (btn_type) {
			case types.LOCATION:
				image = new Gtk.Image.from_icon_name ("folder",
											Gtk.IconSize.BUTTON);
				break;
			case types.FILES:
				image = new Gtk.Image.from_icon_name ("emblem-documents",
											Gtk.IconSize.BUTTON);
				break;
			case types.FILEMASK:
				image = new Gtk.Image.from_icon_name ("edit-select-symbolic",
											Gtk.IconSize.BUTTON);
				break;
			case types.MIMETYPE:
				image = new Gtk.Image.from_icon_name ("applications-multimedia",
											Gtk.IconSize.BUTTON);
				break;
			case types.TEXT:
				image = new Gtk.Image.from_icon_name ("edit-find",
											Gtk.IconSize.BUTTON);
				break;
			case types.MODIFIED:
				image = new Gtk.Image.from_icon_name ("preferences-system-time",
											Gtk.IconSize.BUTTON);
				break;
			case types.BINARY:
				image = new Gtk.Image.from_icon_name ("application-x-executable",
											Gtk.IconSize.BUTTON);
				break;
			case types.SIZE:
				image = new Gtk.Image.from_icon_name ("drive-harddisk",
											Gtk.IconSize.BUTTON);
				break;
		}
		//always_show_image = true;
		xalign = 0.1F;
	}

	public types filter_type {
		get { return _btype;}
	}
}

