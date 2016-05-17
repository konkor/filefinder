/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * menu-item-id.vala
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

public class MenuItemIndex : Gtk.MenuItem {
	private int _id = -1;

	public MenuItemIndex (int index = -1, string text = "") {
		_id = index;
		label = text;
	}

	public int id {
		get {
			return _id;
		}
	}

}

