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
	public bool first_run = true;

	public Preferences () {
		//title = Text.app_name + " Preferences";
		_mime_count = _mime_type_groups.length;

		build_gui ();
		load ();
		refresh_gui ();
		refresh_groups ();

		delete_event.connect (on_delete);
		focus_in_event.connect (on_focus_in);
		destroy_event.connect (on_destroy);
	}

	public void show_window () {
		if (!visible)
			show ();
		else
			present ();
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
		if (is_changed == false) return true;
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
			Debug.info ("preferences", e.message);
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
			dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
												"check_autohide", check_autohide.to_string ()));
			dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
												"cb_dark", cb_dark.active.to_string ()));
			dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
												"cb_single", cb_single.active.to_string ()));
			dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
												"spin_rows", ((int) spin_rows.get_value()).to_string ()));
			foreach (ViewColumn p in columns) {
				dos.put_string ("%d %s %s\n".printf (PreferenceType.COLUMN,
								p.name, p.get_value ()));
			}
			for (bool next = store_excluded.get_iter_first (out iter); next; next = store_excluded.iter_next (ref iter)) {
				store_excluded.get_value (iter, 0, out val);
				dos.put_string ("%d %s %s\n".printf (PreferenceType.GENERAL,
								"excluded", (string) val));
			}
			for (int i = _mime_count; i < _mime_type_groups.length; i++) {
				dos.put_string ("%d %s %s\n".printf (PreferenceType.MIME,
								_mime_type_groups[i].name.replace (" ", "%20"), _mime_type_groups[i].get_value ()));
			}
		} catch (Error e) {
			Debug.error ("preferences", e.message);
			return false;
		}

		is_changed = false;
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
						case "check_autohide":
							cb_autohide.active = bool.parse (val);
							break;
						case "cb_dark":
							cb_dark.active = bool.parse (val);
							Gtk.Settings.get_default().set ("gtk-application-prefer-dark-theme", cb_dark.active);
							break;
						case "cb_single":
							cb_single.active = bool.parse (val);
							break;
						case "spin_rows":
							spin_rows.set_value (int.parse (val));
							break;
					}
					} else if (t == PreferenceType.COLUMN) {
						string[] stringValues = val.split(":");
						int id = int.parse(stringValues[0]);
						int w = int.parse(stringValues[1]);
						bool vis = bool.parse(stringValues[2]);
						columns [id].width = w;
						columns [id].visible = vis;
					} else if (t == PreferenceType.MIME) {
						MimeGroup mg = MimeGroup();
						mg.name = name.replace ("%20", " ");
						mg.mimes = val.split(" ");
						_mime_type_groups += mg;
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
		//refresh_mime ();
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
		//cb_vertical.active
	}

	private void refresh_groups (int index = 0) {
		cb_group.remove_all ();
		for (int i = _mime_count; i < _mime_type_groups.length; i++) {
			cb_group.append_text (_mime_type_groups[i].name);
		}
		cb_group.active = index;
		if (cb_group.active < 0) {
			entry.text = "New Group";
		}
	}

	private void refresh_mimes () {
		Gtk.TreeIter it;
		store_mimes.clear ();
		if (cb_group.active > -1) {
			foreach (string s in _mime_type_groups[_mime_count + cb_group.active].mimes) {
				store_mimes.append (out it);
				store_mimes.set (it, 0, s, -1);
			}
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

	private Gtk.ComboBoxText cb_group;
	private Gtk.Entry entry;

	private Gtk.TreeView view_mimes;
	private Gtk.ListStore store_mimes;

	private Gtk.CheckButton cb_vertical;
	private Gtk.CheckButton cb_autohide;
	private Gtk.CheckButton cb_dark;
	private Gtk.CheckButton cb_single;
	private Gtk.SpinButton spin_rows;

	private void build_gui () {
		Gtk.Label label;
		Gtk.ScrolledWindow scroll;
		Gtk.Box box, hbox, vbox;
		Gtk.TreeView view;
		Gtk.Button button;

		Gtk.HeaderBar hb = new Gtk.HeaderBar ();
		hb.has_subtitle = false;
		hb.title = Text.app_name + " Preferences";
		hb.set_show_close_button (true);
		set_titlebar (hb);

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
		cb_hidden.active = true;

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
		button.tooltip_text = "Remove Selected Location";
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

		cb_autohide = new Gtk.CheckButton.with_label ("Autohide The Filter Panel On Results");
		cb_autohide.tooltip_text = "Autohide The Filter Panel On Results";
		box.add (cb_autohide);
		cb_autohide.toggled.connect (()=>{
			check_autohide = cb_autohide.active;
			is_changed = true;
		});
		cb_autohide.active = false;

		cb_dark = new Gtk.CheckButton.with_label ("Dark Theme");
		cb_dark.tooltip_text = "Prefer Dark Theme";
		box.add (cb_dark);
		cb_dark.toggled.connect (()=>{
			Gtk.Settings.get_default().set ("gtk-application-prefer-dark-theme", cb_dark.active);
			is_changed = true;
		});
		cb_dark.active = false;

		hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		box.pack_start (hbox, false, false, 0);

		cb_single = new Gtk.CheckButton.with_label ("Single Filter Per Row");
		cb_single.tooltip_text = "There is one filter per line";
		hbox.add (cb_single);
		cb_single.active = true;
		spin_rows = new Gtk.SpinButton.with_range (1, 50, 1);
		spin_rows.value_changed.connect (()=>{
			if (Filefinder.window == null) return;
			Filefinder.window.set_max_filters ((int)spin_rows.get_value ());
			is_changed = true;
		});
		spin_rows.sensitive = !cb_single.active;
		hbox.pack_end (spin_rows, false, false, 0);
		hbox.pack_end (new Label ("Maximum filters per row "), false, false, 0);
		cb_single.toggled.connect (()=>{
			spin_rows.sensitive = !cb_single.active;
			if (cb_single.active) spin_rows.set_value (1);
			is_changed = true;
		});

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

		//MIME Groups
		box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
		box.border_width = 6;
		notebook.add (box);
		label = new Label ("MIME Groups");
		notebook.set_tab_label (box, label);

		label = new Label ("<b>User defined MIME Groups.</b>");
		label.use_markup = true;
		label.xalign = 0;
		box.add (label);

		hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		box.pack_start (hbox, false, false, 0);

		cb_group = new Gtk.ComboBoxText.with_entry ();
		cb_group.margin_end = 6;
		entry = (Entry)cb_group.get_child();
		/*entry.changed.connect (()=>{
			entry.text = entry.text.replace (" ", "");
		});*/
		hbox.pack_start (cb_group, true, true, 0);

		button = new Button.from_icon_name ("list-add-symbolic", IconSize.BUTTON);
		button.tooltip_text = "Add New MIME Group";
		button.clicked.connect (()=>{
			entry.text = entry.text.strip ();
			if (entry.text.length == 0) return;
			MimeGroup mg = MimeGroup ();
			mg.name = entry.text;
			_mime_type_groups += mg;
			cb_group.append_text (mg.name);
			cb_group.active = cb_group.model.iter_n_children (null) - 1;
			is_changed = true;
		});
		hbox.pack_start (button, false, false, 0);

		button = new Button.from_icon_name ("list-remove-symbolic", IconSize.BUTTON);
		button.tooltip_text = "Remove Selected MIME Group";
		button.clicked.connect (()=>{
			if (cb_group.active < 0) return;
			int ind = cb_group.active -1;
			MimeGroup[] mg1 = _mime_type_groups[0:_mime_count + cb_group.active];
			if (_mime_type_groups.length > (_mime_count + cb_group.active + 1)) {
				for (int i = _mime_count + cb_group.active + 1; i < _mime_type_groups.length; i++) 
					mg1 += _mime_type_groups[i];
				ind++;
			}
			_mime_type_groups = mg1;
			refresh_groups (ind);
			is_changed = true;
		});
		hbox.pack_start (button, false, false, 0);

		hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		box.pack_start (hbox, true, true, 0);

		scroll = new ScrolledWindow (null, null);
		scroll.shadow_type = Gtk.ShadowType.OUT;
		hbox.pack_start (scroll, true, true, 0);

		view_mimes = new Gtk.TreeView ();
		view_mimes.get_selection().mode = SelectionMode.MULTIPLE;
		store_mimes = new Gtk.ListStore (1, typeof (string));
		view_mimes.set_model (store_mimes);
		view_mimes.insert_column_with_attributes (-1, "MIME Types", new Gtk.CellRendererText (), "text", 0, null);
		scroll.add (view_mimes);

		vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		hbox.pack_start (vbox, false, false, 0);

		button = new Gtk.Button.with_label ("Add");
		button.tooltip_text = "Add New MIME Type";
		button.clicked.connect (()=>{
			if (cb_group.active == -1) return;
			DialogMimeChooser c = new DialogMimeChooser (this);
			if (c.run () == Gtk.ResponseType.ACCEPT) {
				string[] ss = _mime_type_groups[_mime_count+cb_group.active].mimes;
				foreach (string s in c.mimes.split (" ")) ss +=s;
				if (c.mimes.split (" ").length > 0) {
					_mime_type_groups[_mime_count+cb_group.active].mimes = ss;
					is_changed = true;
					refresh_mimes ();
				}
			}
			c.dispose ();
		});
		vbox.add (button);

		button = new Gtk.Button.with_label ("Remove");
		button.tooltip_text = "Remove Selected MIME Types";
		button.clicked.connect (()=>{
			if (cb_group.active == -1) return;
			List<TreePath> paths = view_mimes.get_selection ().get_selected_rows (null);
			if (paths.length () == 0) return;
			string[] ss = {};
			bool f;
			int i = 0;
			foreach (string s in _mime_type_groups[_mime_count + cb_group.active].mimes) {
				f = true;
				foreach (TreePath p in paths)
					if (p.get_indices ()[0] == i)
						f = false;
				if (f) ss += s;
				i++;
			}
			_mime_type_groups[_mime_count + cb_group.active].mimes = ss;
			refresh_mimes ();
			is_changed = true;
		});
		vbox.add (button);

		button = new Gtk.Button.with_label ("Clear");
		button.tooltip_text = "Clear All Types Of The MIME Group";
		button.clicked.connect (()=>{
			if (cb_group.active == -1) return;
			_mime_type_groups[_mime_count + cb_group.active].mimes = {};
			refresh_mimes ();
			is_changed = true;
		});
		vbox.add (button);

		cb_group.changed.connect (()=>{
			refresh_mimes ();
		});
		set_default_size (640, 480);
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

	public bool split_verticaly {
		get {return cb_vertical.active;}
		set {cb_vertical.active = value;}
	}

	public bool check_autohide {get; set;}

	public void set_autohide (bool enable) {
		if (check_autohide != enable)
			cb_autohide.active = enable;
	}

	public int filter_count {
		get {
			return (int) spin_rows.get_value ();
		}
	}

	public void add_mimes (int group_index, string[] mimes) {
		MimeGroup mg;
		if (group_index == -1) {
			mg = MimeGroup ();
			mg.name = "New Group";
		} else {
			mg = _mime_type_groups[_mime_count + group_index];
		}
		string[] ss = mg.mimes;
		foreach (string s in mimes) ss +=s;
		if (mimes.length > 0) {
			if (group_index == -1) {
				mg.mimes = ss;
				_mime_type_groups += mg;
				cb_group.append_text (mg.name);
			} else {
				_mime_type_groups[_mime_count + group_index].mimes = ss;
			}
			refresh_mimes ();
		}
		is_changed = true;
	}

	private ViewColumn[] _custom;
	public ViewColumn[] custom_mime_type_groups {
		get {
			_custom = {};
			for (int i = _mime_count; i < _mime_type_groups.length; i++) {
				_custom += ViewColumn () {id = i - _mime_count, name = _mime_type_groups[i].name};
			}
			return _custom;
		}
	}

	public MimeGroup[] mime_type_groups {
		get { return _mime_type_groups;}
	}

	private int _mime_count;
	private MimeGroup[] _mime_type_groups = {
	MimeGroup (){ name = "Text Files",
	mimes = { "text/plain",
		"text/css",
		"text/html",
		"text/troff",
		"text/x-authors",
		"text/x-changelog",
		"text/x-chdr",
		"text/x-c++hdr",
		"text/x-copying",
		"text/x-csrc",
		"text/x-c++src",
		"text/x-csharp",
		"text/x-fortran",
		"text/x-gettext-translation",
		"text/x-go",
		"text/x-java",
		"text/x-install",
		"text/x-log",
		"text/x-makefile",
		"text/x-markdown",
		"text/x-matlab",
		"text/x-microdvd",
		"text/x-tex",
		"text/x-vala"}
	},
	MimeGroup (){ name = "Archives",
	mimes = { "application/x-7z-compressed",
		"application/x-compressed-tar",
		"application/x-bzip-compressed-tar",
		"application/x-xz-compressed-tar",
		"application/x-bzip",
		"application/x-rar",
		"application/x-tarz",
		"application/gzip",
		"application/zip"}
	},
	MimeGroup (){ name = "Temporary",
	mimes = { "application/x-trash"}
	},
	MimeGroup (){ name = "Executables",
	mimes = { "application/x-executable"}
	},
	MimeGroup (){ name = "Documents",
	mimes = { "application/rtf",
		"application/msword",
		"application/vnd.sun.xml.writer",
		"application/vnd.sun.xml.writer.global",
		"application/vnd.sun.xml.writer.template",
		"application/vnd.oasis.opendocument.text",
		"application/vnd.oasis.opendocument.text-template",
		"application/x-abiword",
		"application/x-applix-word",
		"application/x-mswrite",
		"application/docbook+xml",
		"application/x-kword",
		"application/x-kword-crypt",
		"application/x-lyx",
		"application/xml",
		"application/illustrator",
		"application/vnd.corel-draw",
		"application/vnd.stardivision.draw",
		"application/vnd.oasis.opendocument.graphics",
		"application/x-dia-diagram",
		"application/x-karbon",
		"application/x-killustrator",
		"application/x-kivio",
		"application/x-kontour",
		"application/x-wpg",
		"application/vnd.lotus-1-2-3",
		"application/vnd.ms-excel",
		"application/vnd.stardivision.calc",
		"application/vnd.sun.xml.calc",
		"application/vnd.oasis.opendocument.spreadsheet",
		"application/x-applix-spreadsheet",
		"application/x-gnumeric",
		"application/x-kspread",
		"application/x-kspread-crypt",
		"application/x-quattropro",
		"application/x-sc",
		"application/x-siag",
		"application/vnd.ms-powerpoint",
		"application/vnd.sun.xml.impress",
		"application/vnd.oasis.opendocument.presentation",
		"application/x-magicpoint",
		"application/x-kpresenter",
		"application/pdf",
		"application/postscript",
		"application/x-dvi",
		"image/x-eps",
		"image/vnd.djvu"}
	},
	MimeGroup (){ name = "Music",
	mimes = { "application/ogg",
		"audio/x-vorbis+ogg",
		"audio/ac3",
		"audio/basic",
		"audio/midi",
		"audio/x-flac",
		"audio/mp4",
		"audio/mpeg",
		"audio/x-mpeg",
		"audio/x-ms-asx",
		"audio/x-pn-realaudio",
		"audio/x-mpegurl"}
	},
	MimeGroup (){ name = "Videos",
	mimes = { "video/mp4",
		"video/3gpp",
		"video/3gpp2",
		"video/dv",
		"video/mp2t",
		"video/mpeg",
		"video/ogg",
		"video/quicktime",
		"video/vivo",
		"video/webm",
		"video/x-avi",
		"video/x-flv",
		"video/x-matroska",
		"video/x-matroska-3d",
		"video/x-mng",
		"video/x-ms-asf",
		"video/x-ms-wmp",
		"video/x-ms-wmv",
		"video/x-msvideo",
		"video/x-nsv",
		"video/x-ogm+ogg",
		"video/x-theora+ogg",
		"video/x-vnd.rn-realvideo"}
	},
	MimeGroup (){ name = "Pictures",
	mimes = { "application/vnd.oasis.opendocument.image",
		"application/x-krita",
		"image/bmp",
		"image/cgm",
		"image/gif",
		"image/jpeg",
		"image/jpeg2000",
		"image/png",
		"image/svg+xml",
		"image/tiff",
		"image/x-compressed-xcf",
		"image/x-pcx",
		"image/x-photo-cd",
		"image/x-psd",
		"image/x-tga",
		"image/x-xcf",
		"image/vnd.djvu",
		"image/vnd.microsoft.icon"}
	},
	MimeGroup (){ name = "Raw Images",
	mimes = { "image/x-adobe-dng",
		"image/x-canon-cr2",
		"image/x-canon-crw",
		"image/x-dcraw",
		"image/x-fuji-raf",
		"image/x-hdr",
		"image/x-kde-raw",
		"image/x-kodak-dcr",
		"image/x-kodak-k25",
		"image/x-kodak-kdc",
		"image/x-minolta-mrw",
		"image/x-nikon-nef",
		"image/x-olympus-orf",
		"image/x-panasonic-raw",
		"image/x-panasonic-raw2",
		"image/x-pentax-pef",
		"image/x-sigma-x3f",
		"image/x-sony-arw",
		"image/x-sony-sr2",
		"image/x-sony-srf"}
	}
};
}

public enum PreferenceType {
	GENERAL,
	COLUMN,
	MIME
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

public struct MimeGroup {
	public string name;
	public string[] mimes;

	public string get_value () {
		string res = "";
		int i = 0;
		foreach (string s in mimes) {
			if (i > 0) res += " ";
			res += s;
			i++;
		}
		return res;
	}

}