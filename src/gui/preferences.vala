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
using Gtk;

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
		Debug.info ("preferences", "save");
		File file;
		DataOutputStream dos = null;
		Gtk.TreeIter iter;
		GLib.Value val;
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
			dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
			                                     "check_mounts", check_mounts.to_string ()));
			dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
			                                     "check_links", check_links.to_string ()));
			dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
			                                     "check_hidden", check_hidden.to_string ()));
			dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
			                                     "check_backup", check_backup.to_string ()));
			dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
			                                     "split_orientation", cb_vertical.active.to_string ()));
			foreach (ViewColumn p in columns) {
				dos.put_string ("%d %s %s\n".printf (PreferenceType.COLUMN,
								p.name, p.get_value ()));
			}
			for (bool next = store_excluded.get_iter_first (out iter); next; next = store_excluded.iter_next (ref iter)) {
				store_excluded.get_value (iter, 0, out val);
				dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
								"excluded", (string) val));
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
		Gtk.TreeIter iter;
		string config = Path.build_filename (Environment.get_user_data_dir (),
		                                     "filefinder", "filefinder.conf");
		File file = File.new_for_path (config);
		if (!file.query_exists ())
			return false;
		try {
		DataInputStream dis = new DataInputStream (file.read ());
		while ((line = dis.read_line (null)) != null) {
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
						case "check_backup":
							cb_backup.active = bool.parse (val);
							break;
						case "check_hidden":
							cb_hidden.active = bool.parse (val);
							break;
						case "check_links":
							cb_links.active = bool.parse (val);
							break;
						case "check_mounts":
							cb_mounts.active = bool.parse (val);
							break;
						case "excluded":
							store_excluded.append (out iter, null);
							store_excluded.set (iter, 0, val, -1);
							break;
						case "split_orientation":
							cb_vertical.active = bool.parse (val);
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
		is_changed = false;
		return true;
	}

	private void refresh_gui () {
		refresh_general ();
		refresh_ui ();
	}

	private void refresh_general () {
	}

	private void refresh_ui () {
		Gtk.TreeIter it;
		store.clear ();
		foreach (ViewColumn p in columns) {
			store.append (out it, null);
			store.set (it, 0, p.visible, 1, p.title, -1);
		}
	}

	public void update_column (int column, int width, bool visible) {
		if (column < 0) return;
		if (columns [column].width != width && width != -1) {
			columns [column].width = width;
			is_changed = true;
		}
		if (columns [column].visible != visible) {
			columns [column].visible = visible;
			is_changed = true;
		}
	}

	private Gtk.Notebook notebook;

	private Gtk.CheckButton cb_mounts;
	private Gtk.CheckButton cb_links;
	private Gtk.CheckButton cb_hidden;
	private Gtk.CheckButton cb_backup;
	private Gtk.TreeView view_excluded;
	private Gtk.TreeStore store_excluded;
	private Gtk.TreeStore store;

	private Gtk.CheckButton cb_vertical;

	private void build_gui () {
		Gtk.Label label;
		Gtk.ScrolledWindow scroll;
		Gtk.Box box, hbox, vbox;
		Gtk.TreeView view;
		
		Gtk.Button button;
		
		notebook = new Gtk.Notebook ();
		add (notebook);

		//Excluded locations
		scroll = new ScrolledWindow (null, null);
		notebook.add (scroll);
		box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
		box.border_width = 6;
		scroll.add (box);
		label = new Label ("General");
		notebook.set_tab_label (scroll, label);

		cb_mounts = new Gtk.CheckButton.with_label ("Exclude mount points");
		box.add (cb_mounts);
		cb_mounts.toggled.connect (()=>{
			check_mounts = cb_mounts.active;
			is_changed = true;
		});
		cb_mounts.active = true;

		cb_links = new Gtk.CheckButton.with_label ("Don't follow to symbolic links");
		box.add (cb_links);
		cb_links.toggled.connect (()=>{
			check_links = cb_links.active;
			is_changed = true;
		});
		cb_links.active = false;

		cb_hidden = new Gtk.CheckButton.with_label ("Exclude hidden locations");
		box.add (cb_hidden);
		cb_hidden.toggled.connect (()=>{
			check_hidden = cb_hidden.active;
			is_changed = true;
		});
		cb_hidden.active = false;

		cb_backup = new Gtk.CheckButton.with_label ("Exclude backups");
		box.add (cb_backup);
		cb_backup.toggled.connect (()=>{
			check_backup = cb_backup.active;
			is_changed = true;
		});
		cb_backup.active = false;

		label = new Label ("<b>User defined excluded locations</b>");
		label.use_markup = true;
		label.xalign = 0;
		box.add (label);

		hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		box.pack_start (hbox, true, true, 0);

		scroll = new ScrolledWindow (null, null);
		scroll.shadow_type = Gtk.ShadowType.OUT;
		hbox.pack_start (scroll, true, true, 0);
		view_excluded = new Gtk.TreeView ();
		store_excluded = new Gtk.TreeStore (1, typeof (string));
		view_excluded.set_model (store_excluded);
		view_excluded.insert_column_with_attributes (-1, "Path", new Gtk.CellRendererText (), "text", 0, null);
		scroll.add (view_excluded);

		vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		hbox.pack_end (vbox, false, false, 0);
		button = new Gtk.Button.with_label ("Add");
		button.tooltip_text = "Add New Locations";
		button.clicked.connect (()=>{
			bool exist = false;
			string filename;
			Gtk.TreeIter iter;
			Value val;
			Gtk.FileChooserDialog c = new Gtk.FileChooserDialog ("Select Folder",
											Filefinder.window,
											Gtk.FileChooserAction.SELECT_FOLDER ,
											"_Cancel",
											Gtk.ResponseType.CANCEL,
											"_Open",
											Gtk.ResponseType.ACCEPT);
			if (c.run () == Gtk.ResponseType.ACCEPT) {
				filename = c.get_filename ();
				for (bool next = store_excluded.get_iter_first (out iter); next; next = store_excluded.iter_next (ref iter)) {
					store_excluded.get_value (iter, 0, out val);
					if (filename == (string) val) {
						exist = true;
						break;
					}
				}
				if (!exist) {
					store_excluded.append (out iter, null);
					store_excluded.set (iter, 0, filename, -1);
					is_changed = true;
				}
			}
			c.close ();
		});
		vbox.add (button);

		button = new Gtk.Button.with_label ("Remove");
		button.tooltip_text = "Remove Selected Locations";
		button.clicked.connect (()=>{
			Gtk.TreeIter iter;
			Gtk.TreeSelection selection = view_excluded.get_selection ();
			if (selection.count_selected_rows () == 0)
				return;
			if (store_excluded.get_iter (out iter, selection.get_selected_rows (null).first().data))
				store_excluded.remove (ref iter);
			is_changed = true;
		});
		vbox.add (button);

		button = new Gtk.Button.with_label ("Clear");
		button.tooltip_text = "Clear All Locations";
		button.clicked.connect (()=>{
			store_excluded.clear ();
			is_changed = true;
		});
		vbox.add (button);

		//UI Settings
		box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
		box.border_width = 6;
		notebook.add (box);
		label = new Label ("Interface");
		notebook.set_tab_label (box, label);

		cb_vertical = new Gtk.CheckButton.with_label ("Split Vertical");
		cb_vertical.tooltip_text = "Setting Split Orientation of the Results View";
		box.add (cb_vertical);
		cb_vertical.toggled.connect (()=>{
			if (cb_vertical.active) {
				split_orientation = Gtk.Orientation.VERTICAL;
			} else {
				split_orientation = Gtk.Orientation.HORIZONTAL;
			}
			if (Filefinder.window != null)
				Filefinder.window.split_orientation (split_orientation);
			is_changed = true;
		});
		cb_vertical.active = true;

		label = new Label ("<b>Choose the information to appear in the result view.</b>");
		label.use_markup = true;
		label.xalign = 0;
		box.add (label);

		hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		box.pack_start (hbox, true, true, 0);

		scroll = new ScrolledWindow (null, null);
		scroll.shadow_type = Gtk.ShadowType.OUT;
		hbox.pack_start (scroll, true, true, 0);

		view = new Gtk.TreeView ();
		store = new Gtk.TreeStore (2, typeof (bool), typeof (string));
		view.set_model (store);
		view.headers_visible = false;
		Gtk.CellRendererToggle toggle = new Gtk.CellRendererToggle ();
		toggle.toggled.connect ((toggle, path) => {
			Gtk.TreePath tree_path = new Gtk.TreePath.from_string (path);
			Gtk.TreeIter iter;
			int i = tree_path.get_indices ()[0];
			store.get_iter (out iter, tree_path);
			store.set (iter, 0, !toggle.active);
			columns[i].visible = !columns[i].visible;
			if (Filefinder.window != null)
				Filefinder.window.set_column_visiblity (i, columns[i].visible);
		});
		view.insert_column_with_attributes (-1, "Active", toggle, "active", 0, null);
		view.insert_column_with_attributes (-1, "Name", new Gtk.CellRendererText (), "text", 1, null);
		scroll.add (view);
				
		set_default_size (640, 400);
		show_all ();
		hide ();
	}

	public bool check_mounts {get; protected set;}

	public bool check_links {get; protected set;}

	public bool check_hidden {get; protected set;}

	public bool check_backup {get; protected set;}

	public string[] get_user_excluded () {
		string[] locations = {};
		Gtk.TreeIter iter;
		GLib.Value val;
		for (bool next = store_excluded.get_iter_first (out iter); next; next = store_excluded.iter_next (ref iter)) {
			store_excluded.get_value (iter, 0, out val);
			locations += (string) val;
		}
		return locations;
	}

	public GLib.FileQueryInfoFlags follow_links {
		get {
			if (check_links)
				return GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS;
			else
				return GLib.FileQueryInfoFlags.NONE;
		}
	}

	public Gtk.Orientation split_orientation {get; protected set;}

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