/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * preferences.vala
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
public enum Columns {
	POSITION,
	DISPLAY_NAME,
	SIZE,
	TYPE,
	TIME_MODIFIED,
	PERMISSIONS,
	MIME,
	PATH,
	ROW
}

public class Preferences : Gtk.Window {
	public ViewColumn[] columns = {
	ViewColumn() { id = 0, name = "position", title = "Position", width = 64, visible = true },
	ViewColumn() { id = 1, name = "name", title = "Name", width = 180, visible = true },
	ViewColumn() { id = 2, name = "size", title = "Size", width = 60, visible = true },
	ViewColumn() { id = 3, name = "type", title = "Type", width = 60, visible = true },
	ViewColumn() { id = 4, name = "mod", title = "Modified", width = 80, visible = true },
	ViewColumn() { id = 5, name = "permissions", title = "Permissions", width = 60, visible = false },
	ViewColumn() { id = 6, name = "mime", title = "MIME", width = 80, visible = true },
	ViewColumn() { id = 7, name = "path", title = "Location", width = 120, visible = true },
	ViewColumn() { id = 8, name = "row", title = "Content", width = 240, visible = true }
	};

	public bool is_changed = false;
	public bool first_run = false;

	public Preferences () {
		title = Text.app_name + " Preferences";

		build_gui ();
		refresh_gui ();

		delete_event.connect (on_delete);
		focus_in_event.connect (on_focus_in);
		destroy_event.connect (on_destroy);
	}

	private bool on_delete () {
        hide();
        return true;
    }

	private bool on_destroy () {
        save ();
        return false;
    }

	private bool on_focus_in (Gdk.EventFocus evnt) {
		refresh_gui ();
		return false;
	}

	public bool save () {
		//TODO save preferences
		return true;
	}

	private void refresh_gui () {

	}

	private void build_gui () {

	}

}

public enum PreferenceType {
	GENERAL,
	COLUMN,
	PRESETS
}

public struct ViewColumn {
	public int id;
	public string name;
	public string title;
	public int width;
	public bool visible;

	public string get_value () {
		return "%d:%d:%s".printf (id, width, visible.to_string ());
	}

	public string to_string () {
		return "%s;%d;%s".printf (name , width, visible.to_string ());
	}
}