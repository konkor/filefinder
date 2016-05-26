/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * page-plugin.vala
 * Copyright (C) 2016 konkor <kkorienkov <at> gmail.com>
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

public class PagePlugin : Gtk.ScrolledWindow {
	Gtk.TreeView view;
	Gtk.ListStore store;

	public PagePlugin () {
		build ();
	}

	private int selection = -1;

	private void build () {
		Gtk.Box box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
		box.border_width = 6;
		add (box);

		Gtk.Label label = new Label ("<b>Extension Manager</b>");
		label.use_markup = true;
		label.xalign = 0;
		box.add (label);

		Gtk.Box hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		box.pack_start (hbox, true, true, 0);

		ScrolledWindow scroll = new ScrolledWindow (null, null);
		scroll.shadow_type = Gtk.ShadowType.OUT;
		hbox.pack_start (scroll, true, true, 0);

		view = new Gtk.TreeView ();
		store = new Gtk.ListStore (4, typeof (bool), typeof (string), typeof (string), typeof (string));
		view.set_model (store);
		Gtk.CellRendererToggle toggle = new Gtk.CellRendererToggle ();
		toggle.toggled.connect ((toggle, path) => {
			Gtk.TreePath tree_path = new Gtk.TreePath.from_string (path);
			Gtk.TreeIter iter;
			int i = tree_path.get_indices ()[0];
			bool active = !toggle.active;
			store.get_iter (out iter, tree_path);
			store.set (iter, 0, !toggle.active);
			try {
				foreach (Plugin f in Filefinder.preferences.plugins)
					f.default_action = false;
				Plugin p = (Plugin) Filefinder.preferences.plugins.nth_data (i);
				p.default_action = !toggle.active;
				if (active) {
					Filefinder.preferences.default_plugin = Filename.to_uri(p.uri);
				} else {
					Filefinder.preferences.default_plugin = "";
				}
				reload ();
				Filefinder.preferences.is_changed = true;
			} catch (Error e) {
				Debug.error ("default_plugin", e.message);
			}
		});
		view.insert_column_with_attributes (-1, "Default", toggle, "active", 0, null);
		view.insert_column_with_attributes (-1, "Name", new Gtk.CellRendererText (), "text", 1, null);
		view.insert_column_with_attributes (-1, "Hotkey", new Gtk.CellRendererText (), "text", 2, null);
		view.insert_column_with_attributes (-1, "Description", new Gtk.CellRendererText (), "text", 3, null);
		view.get_column (3).visible = false;
		view.set_tooltip_column (3);
		scroll.add (view);
		view.get_selection ().changed.connect (on_selection);

		Gtk.Box vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		hbox.pack_start (vbox, false, false, 0);

		Gtk.Button button = new Gtk.Button.with_label ("New");
		button.tooltip_text = "Add New Extension From Template";
		button.clicked.connect (()=>{
			var d = new InputDialog (Filefinder.preferences);
			d.label.label = "Input a new extension file name";
			d.entry.text = "my_extension";
			int r = d.run ();
			string pname = d.entry.text.down().strip ().replace (" ", "_");
			pname = pname.replace ("/", "_");
			pname = pname.replace ("\"", "");
			pname = pname.replace ("?", "");
			pname = pname.replace (":", "_");
			pname = pname.replace ("\\", "_");
			d.destroy ();
			if (r == Gtk.ResponseType.ACCEPT) {
				if (pname.length > 0) {
					File? plug = Filefinder.preferences.create_plug (pname);
					if (plug != null) {
						List<File> flist = new List<File> ();
						flist.append (plug);
						AppInfo app = GLib.AppInfo.get_default_for_type ("application/x-shellscript", false);
						if (app != null) {
							try {
								app.launch (flist, null);
								reload ();
							} catch (Error e) {
								var dlg = new Gtk.MessageDialog (Filefinder.window, 0,
									Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "Failed to launch: %s",
									e.message);
								dlg.run ();
								dlg.destroy ();
							}
						}
					}
				}
			}
		});
		vbox.add (button);

		button = new Gtk.Button.with_label ("Edit");
		button.tooltip_text = "Edit Selected Extension";
		button.clicked.connect (()=>{
			if (selection == -1) return;
			List<File> flist = new List<File> ();
			flist.append (File.new_for_path (Filefinder.preferences.plugins.nth_data (selection).uri));
			AppInfo app = GLib.AppInfo.get_default_for_type ("application/x-shellscript", false);
			if (app != null) {
				try {
					app.launch (flist, null);
					reload ();
				} catch (Error e) {
					var dlg = new Gtk.MessageDialog (Filefinder.window, 0,
						Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "Failed to launch: %s",
						e.message);
					dlg.run ();
					dlg.destroy ();
				}
			}
		});
		vbox.add (button);

		vbox.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
		button = new Gtk.Button.with_label ("Install");
		button.tooltip_text = "Install Extensions From Drive";
		button.clicked.connect (()=>{
			Gtk.FileChooserDialog c = new Gtk.FileChooserDialog ("Select Extensions",
																Filefinder.window,
																Gtk.FileChooserAction.OPEN,
																"_Cancel",
																Gtk.ResponseType.CANCEL,
																"_Select",
																Gtk.ResponseType.ACCEPT);
			c.select_multiple = true;
			Gtk.FileFilter filter_text = new FileFilter ();
			filter_text.set_filter_name ("Shell Script");
			filter_text.add_mime_type ("application/x-shellscript");
			c.set_filter (filter_text);
			if (c.run () == Gtk.ResponseType.ACCEPT) {
				install (c.get_filenames ());
				reload ();
			}
			c.destroy ();
		});
		vbox.add (button);

		button = new Gtk.Button.with_label ("Delete");
		button.tooltip_text = "Delete Selected Extensions";
		button.clicked.connect (()=>{
			if (selection == -1) return;
			ResultsView.delete_file (File.new_for_path (Filefinder.preferences.plugins.nth_data (selection).uri));
			reload ();
		});
		vbox.add (button);
	}

	public void reload () {
		TreeIter it;
		if (Filefinder.preferences == null) return;
		Filefinder.preferences.load_plugs ();
		store.clear ();
		foreach (Plugin p in Filefinder.preferences.plugins) {
			store.append (out it);
			store.set (it, 
					   0, p.default_action,
					   1, p.label,
					   2, p.hotkey,
					   3, p.description, -1);
		}
	}

	private void on_selection () {
		uint count = view.get_selection ().get_selected_rows (null).length();
		if (count == 0) {
			selection = -1;
			return;
		}
		selection = view.get_selection ().get_selected_rows (null).nth_data(0).get_indices()[0];
	}

	private bool skip_all;
	private bool replace_all;

	private void install (SList<string> list) {
		File f1, f2;
		string path = Path.build_filename (Environment.get_user_data_dir (),
											"filefinder", "extensions");
		f2 = File.new_for_path (path);
		if (!f2.query_exists ())
			DirUtils.create (path, 0744);
		replace_all = skip_all = false;
		foreach (string s in list) {
			f1 = File.new_for_path (s);
			f2 = File.new_for_path (Path.build_filename (path, f1.get_basename()));
			if (f2.query_exists () && !replace_all) {
				if (skip_all) continue;
				var dlg = new Gtk.MessageDialog (Filefinder.window, 0,
						Gtk.MessageType.WARNING, Gtk.ButtonsType.NONE,
						"The destination file is exist.\nDo you want replace it?\n\n%s",
						f2.get_path());
				dlg.add_buttons ("Skip All", Gtk.ResponseType.CANCEL + 100,
								 "Replace All", Gtk.ResponseType.ACCEPT + 100,
								 "Skip", Gtk.ResponseType.CANCEL,
								 "Replace", Gtk.ResponseType.ACCEPT);
				int r = dlg.run ();
				dlg.destroy ();
				switch (r) {
					case Gtk.ResponseType.CANCEL:
						continue;
					case Gtk.ResponseType.ACCEPT + 100:
						replace_all = true;
						break;
					case Gtk.ResponseType.CANCEL + 100:
						skip_all = true;
						continue;
				}
			}
			if (f2.query_exists ()) {
				if (!ResultsView.delete_file (f2)) {
					continue;
				}
			}
			try {
				f1.copy (f2, 0, null, null);
			} catch (Error e) {
				Debug.error ("install_plugs", e.message);
			}
		}
	}
}

