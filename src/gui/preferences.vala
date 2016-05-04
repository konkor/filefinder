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
	DISPLAY_NAME,
	SIZE,
	TYPE,
	TIME_MODIFIED,
	PERMISSIONS,
	MIME,
	PATH,
	POSITION,
	ROW
}

public class Preferences : Gtk.Window {
	public ViewColumn[] columns = {
	ViewColumn() { id = 0, name = "name", title = "Name", width = 400, visible = true },
	ViewColumn() { id = 1, name = "size", title = "Size", width = 72, visible = true },
	ViewColumn() { id = 2, name = "type", title = "Type", width = 60, visible = false },
	ViewColumn() { id = 3, name = "mod", title = "Modified", width = 90, visible = true },
	ViewColumn() { id = 4, name = "permissions", title = "Permissions", width = 60, visible = false },
	ViewColumn() { id = 5, name = "mime", title = "MIME", width = 128, visible = true },
	ViewColumn() { id = 6, name = "path", title = "Location", width = 240, visible = true },
	ViewColumn() { id = 7, name = "position", title = "Position", width = 64, visible = true },
	ViewColumn() { id = 8, name = "row", title = "Content", width = 240, visible = true }
	};

	public bool is_changed = false;
	public bool first_run = false;

	public Preferences () {
		title = Text.app_name + " Preferences";

		build_gui ();
		load ();
		refresh_gui ();

		delete_event.connect (on_delete);
		focus_in_event.connect (on_focus_in);
		destroy_event.connect (on_destroy);
	}

	private bool on_delete () {
        hide();
		save ();
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
		Debug.info ("preferences", "save");
		File file;
		DataOutputStream dos = null;
		string config = Path.build_filename (Environment.get_user_data_dir (),"filefinder");
		if (!FileUtils.test (config, FileTest.IS_REGULAR))
			DirUtils.create (config, 0744);
		config = Path.build_filename (config, "filefinder.conf");
		file = File.new_for_path (config);
		try {
			file.delete ();
		} catch (Error e) {
			Debug.error ("preferences", e.message);
		}
		try {
			dos = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));
			dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
			                                     "first_run", first_run.to_string ()));
			foreach (ViewColumn p in columns) {
				dos.put_string ("%d %s %s\n".printf (PreferenceType.COLUMN,
								p.name, p.get_value ()));
			}
		} catch (Error e) {
			Debug.error ("preferences", e.message);
			return false;
		}
		
		return true;
	}

	public bool load () {
		int i;
		string line, name, val;;
		PreferenceType t;
		string config = Path.build_filename (Environment.get_user_data_dir (),
		                                     "filefinder", "filefinder.conf");
		File file = File.new_for_path (config);
		if (!file.query_exists ())
			return false;
		try {
		DataInputStream dis = new DataInputStream (file.read ());
		while ((line = dis.read_line (null)) != null) {
			//TODO parse params
			i = line.index_of (" ");
			if ((i > 0) && (line.length > i)) {
				t = (PreferenceType) int.parse (line.substring (0, i));
				line = line.substring (i + 1);
				i = line.index_of (" ");
				if ((i > 0) && (line.length > i)) {
					name = line.substring (0, i);
					val = line.substring (i + 1);
					
					if (t == PreferenceType.GENERAL) {
					switch (name) {
						case "first_run":
							first_run = bool.parse (val);
							break;
					}
					} else if (t == PreferenceType.COLUMN) {
						string[] stringValues = val.split(":");
						int id = int.parse(stringValues[0]);
						int w = int.parse(stringValues[1]);
						bool vis = bool.parse(stringValues[2]);
						columns [id].width = w;
						columns [id].visible = vis;
					}
				}
			}
		}
		} catch (Error e) {
			Debug.error ("preferences", e.message);
			return false;
		} 
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