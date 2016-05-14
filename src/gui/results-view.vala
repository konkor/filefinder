/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * results-view.vala
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

public class ResultsView : Gtk.TreeView {
	public signal void changed_selection ();

	private Gtk.Menu menu;
	private Gtk.Menu menu_columns;

	public ResultsView () {
		results_selection = new Service.Results ();

		can_focus = true;
		headers_clickable = true;
		get_selection ().mode = Gtk.SelectionMode.MULTIPLE;

		build_columns ();
		build_menus ();

		button_press_event.connect (on_tree_button);
		get_selection ().changed.connect (on_selection_changed);
	}

	private void build_columns () {
		Gtk.TreeViewColumn col0;
		Gtk.CellRendererText colr;
		int i = 0;
		foreach (ViewColumn p in Filefinder.preferences.columns) {
			colr = new Gtk.CellRendererText ();
			Gtk.TreeViewColumn col = new Gtk.TreeViewColumn.with_attributes (p.title, colr, markup:null);
			col.add_attribute(colr, "markup", 0);
			//col.title = p.title;
			col.expand = false;
			col.fixed_width = p.width;
			col.resizable = true;
			col.sizing = TreeViewColumnSizing.FIXED;
			col.sort_column_id = i;
			
			//col.pack_start (colr, false);
			col.set_cell_data_func (colr, render_text);
			col.visible = p.visible;
			append_column (col);
			col.notify["width"].connect (()=>{
				Filefinder.preferences.update_column (col.sort_column_id,
													col.width, col.visible);
			});
			i++;
		}

		col0 = new Gtk.TreeViewColumn ();
		col0.title = " ";
		col0.sizing = TreeViewColumnSizing.AUTOSIZE;
		colr = new Gtk.CellRendererText ();
		col0.pack_start (colr, false);
		append_column (col0);

		set_model (Filefinder.service);
	}

	public void connect_model () {
		set_model (Filefinder.service);
	}

	public void disconnect_model () {
		set_model (null);
	}

	private void build_menus () {
		menu_columns = new Gtk.Menu ();
		foreach (ViewColumn p in Filefinder.preferences.columns) {
			ColumnMenuItem mic = new ColumnMenuItem (p);
			mic.active = p.visible;
			mic.toggled.connect (()=>{
				Filefinder.preferences.update_column (mic.column_id, -1, mic.active);
				get_column (mic.column_id).visible = mic.active;
			});
			mic.show ();
			menu_columns.add (mic);
		}

		menu = new Gtk.Menu ();
		Gtk.MenuItem mi = new Gtk.MenuItem.with_label ("Open");
		menu.add (mi);
		mi.activate.connect (()=>{
			open_selected ();
		});
		//menu.add (new Gtk.SeparatorMenuItem ());
		mi = new Gtk.MenuItem.with_label ("Open Location");
		menu.add (mi);
		mi.activate.connect (()=>{
			AppInfo appinfo = GLib.AppInfo.get_default_for_type ("inode/directory", false);
			if (appinfo == null) return;
			try {
				appinfo.launch (get_selected_dirs (), null);
			} catch (Error e) {
				var dlg = new Gtk.MessageDialog (Filefinder.window, 0,
					Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "Failed to launch: %s",
					e.message);
				dlg.run ();
				dlg.destroy ();
			}
		});
		menu.add (new Gtk.SeparatorMenuItem ());
		mi = new Gtk.MenuItem.with_label ("Move to...");
		menu.add (mi);
		mi.activate.connect (()=>{
			Gtk.FileChooserDialog c = new Gtk.FileChooserDialog ("Select Destination Folder",
																Filefinder.window,
																Gtk.FileChooserAction.SELECT_FOLDER,
																"_Cancel",
																Gtk.ResponseType.CANCEL,
																"_Select",
																Gtk.ResponseType.ACCEPT);
			c.create_folders = true;
			if (c.run () == Gtk.ResponseType.ACCEPT) {
				move_to (get_selected_files (), c.get_filename ());
			}
			c.destroy ();
		});
		mi = new Gtk.MenuItem.with_label ("Copy to...");
		menu.add (mi);
		mi.activate.connect (()=>{
			Gtk.FileChooserDialog c = new Gtk.FileChooserDialog ("Select Destination Folder",
																Filefinder.window,
																Gtk.FileChooserAction.SELECT_FOLDER,
																"_Cancel",
																Gtk.ResponseType.CANCEL,
																"_Select",
																Gtk.ResponseType.ACCEPT);
			c.create_folders = true;
			if (c.run () == Gtk.ResponseType.ACCEPT) {
				copy_to (get_selected_files (), c.get_filename ());
			}
			c.destroy ();
		});
		menu.add (new Gtk.SeparatorMenuItem ());
		mi = new Gtk.MenuItem.with_label ("Move to Trash");
		menu.add (mi);
		mi.activate.connect (()=>{
			move_to_trash (get_selected_files ());
		});
		menu.add (new Gtk.SeparatorMenuItem ());
		mi = new Gtk.MenuItem.with_label ("Properties");
		menu.add (mi);
		mi.activate.connect (()=>{
			on_show_properties ();
		});
		menu.show_all ();
		menu.show.connect (()=>{
			Gtk.TreeIter iter;
			GLib.Value val;
			GLib.AppInfo app;
			int count = get_selection ().count_selected_rows ();
			foreach (Widget p in menu.get_children ()) {
				p.sensitive = count != 0;
			}
			if (count == 0) {
				return;
			}
			Gtk.MenuItem item = (Gtk.MenuItem) menu.get_children ().nth_data (0);
			item.label = "Open";
			if (count == 1) {
				if (model.get_iter (out iter, get_selection ().get_selected_rows(null).nth_data (0))) {
					model.get_value (iter, Columns.MIME, out val);
					if (((string)val) != "application/x-executable") {
						app = GLib.AppInfo.get_default_for_type ((string)val, false);
						if (app != null) {
							item.label = "Open With " + app.get_name ();
						}
					} else {
						item.label = "Run";
					}
				}
			} else {
				item.sensitive = false;
			}
			return ;
		});
	}

	private void render_text (Gtk.CellLayout layout, Gtk.CellRenderer cell, Gtk.TreeModel model, Gtk.TreeIter iter) {
		GLib.Value v;
		switch ((layout as TreeViewColumn).sort_column_id) {
			case Columns.POSITION:
				model.get_value (iter, Columns.POSITION, out v);
				if (v.get_int64() == -1) {
					(cell as Gtk.CellRendererText).text = "";
				} else {
					(cell as Gtk.CellRendererText).text = v.get_int64().to_string();
				}
				break;
			case Columns.DISPLAY_NAME:
				model.get_value (iter, Columns.DISPLAY_NAME, out v);
				(cell as Gtk.CellRendererText).text = v.get_string();
				break;
			case Columns.SIZE:
				model.get_value (iter, Columns.SIZE, out v);
				(cell as Gtk.CellRendererText).text = get_bin_size (v.get_uint64());
				break;
			case Columns.TYPE:
				model.get_value (iter, Columns.TYPE, out v);
				(cell as Gtk.CellRendererText).text = get_filetype_string (v.get_int());
				break;
			case Columns.TIME_MODIFIED:
				model.get_value (iter, Columns.TIME_MODIFIED, out v);
				DateTime d = new DateTime.from_unix_local ((int64) v.get_uint64());
				(cell as Gtk.CellRendererText).text = d.format ("%F %T");
				break;
			case Columns.PERMISSIONS:
				model.get_value (iter, Columns.PERMISSIONS, out v);
				(cell as Gtk.CellRendererText).text = v.get_string();
				break;
			case Columns.MIME:
				model.get_value (iter, Columns.MIME, out v);
				(cell as Gtk.CellRendererText).text = v.get_string();
				break;
			case Columns.PATH:
				model.get_value (iter, Columns.PATH, out v);
				(cell as Gtk.CellRendererText).text = v.get_string();
				break;
			case Columns.ROW:
				model.get_value (iter, Columns.ROW, out v);
				(cell as Gtk.CellRendererText).text = v.get_string();
				break;
		}
	}

	private string get_filetype_string (int filetype) {
		switch (filetype) {
			case 0: return "Unknown";
			case 1: return "Regular";
			case 2: return "Directory";
			case 3: return "Symlink";
			case 4: return "Special";
			case 5: return "Shortcut";
			case 6: return "Mountable";
		}
		return "";
	}
	protected override bool button_press_event (Gdk.EventButton event) {
		if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == 3) {
			return true;
		} else {
			return base.button_press_event (event);
		}
	}

	private bool on_tree_button (Gdk.EventButton event) {
		if (event.button == 3) { //right click
			if (event.y <= 16.0) {
				menu_columns.popup (null, null, null, event.button, event.time);
			} else {
				menu.popup (null, null, null, event.button, event.time);
			}
		} else if (event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) {
			open_selected ();
		}
		return false;
	}

	public Service.Results results_selection;
	private void on_selection_changed () {
		results_selection = new Service.Results ();
		results_selection.position = 0;
		Gtk.TreeIter iter;
		GLib.Value val;
		int t;
		foreach (TreePath p in get_selection ().get_selected_rows (null)) {
			if (model.get_iter (out iter, p)) {
				if (results_selection.position == 0) {
					model.get_value (iter, Columns.DISPLAY_NAME, out val);
					results_selection.display_name = (string) val;
					model.get_value (iter, Columns.TIME_MODIFIED, out val);
					results_selection.time_modified = (uint64) val;
					model.get_value (iter, Columns.SIZE, out val);
					results_selection.size = (uint64) val;
					model.get_value (iter, Columns.MIME, out val);
					results_selection.mime = (string) val;
					model.get_value (iter, Columns.TYPE, out val);
					t = (int) val;
					results_selection.type = (GLib.FileType) t;
					model.get_value (iter, Columns.PATH, out val);
					results_selection.path = (string) val;
					results_selection.position = 1;
				} else {
					model.get_value (iter, Columns.DISPLAY_NAME, out val);
					if (results_selection.display_name != (string) val)
						results_selection.display_name = "--";
					model.get_value (iter, Columns.PATH, out val);
					if (results_selection.path != (string) val)
						results_selection.path = "--";
					model.get_value (iter, Columns.TYPE, out val);
					if (((int)results_selection.type) != (int) val)
						results_selection.type = (FileType) 0;
					model.get_value (iter, Columns.MIME, out val);
					if (results_selection.mime != (string) val)
						results_selection.mime = "--";
					model.get_value (iter, Columns.TIME_MODIFIED, out val);
					if (results_selection.time_modified != (uint64) val)
						results_selection.time_modified = 0;
					model.get_value (iter, Columns.SIZE, out val);
					results_selection.size += (uint64) val;
					results_selection.position++;
				}
			}
		}
		changed_selection ();
	}

	private void on_show_properties () {
		if (results_selection.position == 0) return;
		string msg = "" +
			"<b>Selected %ju files</b>\n\n" +
			"<b>File Name:</b> %s\n" +
			"<b>MIME Type:</b> %s\n" +
			"<b>Size:</b> %s (%ju bytes)\n\n" +
			"<b>Location:</b> %s\n\n" +
			"<b>File Type:</b> %s\n";
		msg = msg.printf (results_selection.position,
						  results_selection.display_name,
						  results_selection.mime,
						  get_bin_size (results_selection.size),
						  results_selection.size,
						  results_selection.path,
						  get_filetype_string (results_selection.type).down ());
		if (results_selection.time_modified != 0) {
			DateTime d = new DateTime.from_unix_local ((int64)results_selection.time_modified);
			msg += "<b>Modified:</b> %s\n".printf (d.format ("%F %T"));
		}
		var dlg = new Gtk.MessageDialog.with_markup (Filefinder.window, 0,
					Gtk.MessageType.INFO, Gtk.ButtonsType.CLOSE,
					msg);
		dlg.run ();
		dlg.destroy ();
		
	}

	public string get_bin_size (uint64 i) {
		string s = i.to_string ();
		int len = s.length;
		if (len > 9) {
			return "%.1f GiB".printf ((double) i / 1073741824.0);
		} else if (len > 6) {
			return "%.1f MiB".printf ((double) i / 1048576.0);
		} else if (len > 5) {
			return "%.1f KiB".printf ((double) i / 1024.0);
		}
		return s;
	}

	private GLib.List<GLib.File>? get_selected_dirs () {
		GLib.List<GLib.File> files = new GLib.List<GLib.File> ();
		Gtk.TreeIter iter;
		GLib.Value val;
		string[] paths = {};
		foreach (TreePath p in get_selection ().get_selected_rows (null)) {
			if (model.get_iter (out iter, p)) {
				model.get_value (iter, Columns.PATH, out val);
				var file = File.new_for_path ((string) val);
				if (file.query_exists ()) {
					if (!(((string) val) in paths)) {
						files.append (file);
						paths += (string) val;
					}
				}
			}
		}
		if (files.length() == 0)
			return null;
		return files;
	}

	private GLib.List<GLib.File>? get_selected_files () {
		GLib.List<GLib.File> files = new GLib.List<GLib.File> ();
		Gtk.TreeIter iter;
		GLib.Value val;
		//string[] paths = {};
		string path;
		foreach (TreePath p in get_selection ().get_selected_rows (null)) {
			if (model.get_iter (out iter, p)) {
				model.get_value (iter, Columns.PATH, out val);
				path = (string) val;
				model.get_value (iter, Columns.DISPLAY_NAME, out val);
				path = Path.build_filename (path, (string) val);
				var file = File.new_for_path (path);
				files.append (file);
				/*if (file.query_exists ()) {
					if (!((string) val in paths)) {
						files.append (file);
						paths += (string) val;
					}
				}*/
			}
		}
		if (files.length() == 0) return null;
		return files;
	}

	private void remove_selected_file (File file) {
		Gtk.TreeIter iter;
		GLib.Value val;
		string path;
		foreach (TreePath p in get_selection ().get_selected_rows (null)) {
			if (model.get_iter (out iter, p)) {
				model.get_value (iter, Columns.PATH, out val);
				path = (string) val;
				model.get_value (iter, Columns.DISPLAY_NAME, out val);
				path = Path.build_filename (path, (string) val);
				if (path == file.get_path ()) {
					Filefinder.service.remove (iter);
					break;
				}
			}
		}
		return;
	}

	private void open_selected () {
		Gtk.TreeIter iter;
		GLib.Value val;
		GLib.AppInfo app;
		int count = get_selection ().count_selected_rows ();
		if (count == 0) {
			return;
		}
		if (count == 1) {
			if (model.get_iter (out iter, get_selection ().get_selected_rows(null).nth_data (0))) {
				model.get_value (iter, Columns.MIME, out val);
				if (((string)val) != "application/x-executable") {
					app = GLib.AppInfo.get_default_for_type ((string)val, false);
					if (app != null) {
						try {
							app.launch (get_selected_files (), null);
						} catch (Error e) {
							var dlg = new Gtk.MessageDialog (Filefinder.window, 0,
								Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "Failed to launch: %s",
								e.message);
							dlg.run ();
							dlg.destroy ();
						}
					} else {
						var dlg = new Gtk.MessageDialog (Filefinder.window, 0,
							Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "No registered application to file type to:\n%s",
							(string)val);
						dlg.run ();
						dlg.destroy ();
					}
				} else {
					try {
						app = AppInfo.create_from_commandline (((File)get_selected_files ().nth_data(0)).get_path (), null, AppInfoCreateFlags.NONE);
						app.launch (null, null);
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

	private int files_count_ready;
	private int files_processed;
	private uint files_count;
	private DateTime last_info;
	private bool skip_all;
	private bool replace_all;
	private void copy_to (GLib.List<GLib.File>? files, string destination) {
		if ((files == null) || (destination == null)) return;
		while (files_count != 0) {
			GLib.Thread.usleep (2500);
		}
		File file;
		files_count_ready = files_processed = 0;
		files_count = files.length ();
		last_info = new DateTime.now_local ();
		skip_all = false;
		replace_all = false;
		foreach (File f in files) {
			file = File.new_for_path (Path.build_filename (destination, f.get_basename ()));
			if (file.query_exists ()) {
				if (skip_all) {
					files_processed++;
					if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
					continue;
				}
				if (!replace_all) {
					var dlg = new Gtk.MessageDialog (Filefinder.window, 0,
						Gtk.MessageType.WARNING, Gtk.ButtonsType.NONE,
						"The destination file is exist.\nDo you want replace it?\n\n%s",
						file.get_path());
					dlg.add_buttons ("Skip All", Gtk.ResponseType.CANCEL + 100,
									 "Replace All", Gtk.ResponseType.ACCEPT + 100,
									 "Skip", Gtk.ResponseType.CANCEL,
									 "Replace", Gtk.ResponseType.ACCEPT);
					int r = dlg.run ();
					dlg.destroy ();
					switch (r) {
					case Gtk.ResponseType.ACCEPT:
						if (!delete_file (file)) {
							files_processed++;
							if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
							continue;
						}
						break;
					case Gtk.ResponseType.CANCEL:
						files_processed++;
						if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
						continue;
					case Gtk.ResponseType.ACCEPT + 100:
						replace_all = true;
						if (!delete_file (file)) {
							files_processed++;
							if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
							continue;
						}
						break;
					case Gtk.ResponseType.CANCEL + 100:
						skip_all = true;
						files_processed++;
						if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
						continue;
					default:
						files_processed++;
						if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
						continue;
					}
				} else {
					if (!delete_file (file)) {
						files_processed++;
						if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
						continue;
					}
				}
			}
			f.copy_async.begin (file, 0, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => {
				DateTime d = new DateTime.now_local ();
				if (d.difference (last_info) > (2*TimeSpan.SECOND)) {
					lock (files_count_ready) {
						last_info = new DateTime.now_local ();
						Filefinder.window.show_info ("%s of %s copied.".printf (get_bin_size (current_num_bytes), get_bin_size(total_num_bytes)));
					}
				}
				}, (obj, res) => {
					try {
						files_processed++;
						f.copy_async.end (res);
					lock (files_count_ready) {
						files_count_ready++;
						Filefinder.window.show_info ("File(s) copied %d of the %u".printf (files_count_ready, files_count));
						if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
					}
					} catch (Error e) {
						if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
						Filefinder.window.show_error (e.message);
					}
				});
		}
	}

	private bool delete_file (File file) {
		try {
			return file.delete ();
		} catch (Error e) {
			var dlg = new Gtk.MessageDialog (Filefinder.window, 0,
						Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE,
						"Can't replace the destination file.\n\n%s\n\n%s",
						file.get_path(), e.message);
			dlg.run ();
			dlg.destroy ();
			return false;
		}
	}

	private void move_to (GLib.List<GLib.File>? files, string destination) {
		if ((files == null) || (destination == null)) return;
		File file;
		while (files_count != 0) {
			GLib.Thread.usleep (2500);
		}
		files_count_ready = 0;
		files_count = files.length ();
		last_info = new DateTime.now_local ();
		skip_all = false;
		replace_all = false;
		foreach (File f in files) {
			files_processed++;
			file = File.new_for_path (Path.build_filename (destination, f.get_basename ()));
			if (file.query_exists ()) {
				if (skip_all) {
					if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
					continue;
				}
				if (!replace_all) {
					var dlg = new Gtk.MessageDialog (Filefinder.window, 0,
						Gtk.MessageType.WARNING, Gtk.ButtonsType.NONE,
						"The destination file is exist.\nDo you want replace it?\n\n%s",
						file.get_path());
					dlg.add_buttons ("Skip All", Gtk.ResponseType.CANCEL + 100,
									"Replace All", Gtk.ResponseType.ACCEPT + 100,
									"Skip", Gtk.ResponseType.CANCEL,
									"Replace", Gtk.ResponseType.ACCEPT);
					int r = dlg.run ();
					dlg.destroy ();
					switch (r) {
					case Gtk.ResponseType.ACCEPT:
						if (!delete_file (file)) {
							if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
							continue;
						}
						break;
					case Gtk.ResponseType.CANCEL:
						if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
						continue;
					case Gtk.ResponseType.ACCEPT + 100:
						replace_all = true;
						if (!delete_file (file)) {
							if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
							continue;
						}
						break;
					case Gtk.ResponseType.CANCEL + 100:
						skip_all = true;
						if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
						continue;
					default:
						if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
						continue;
					}
				} else {
					if (!delete_file (file)) {
						if (files_processed == files_count) files_count = files_processed = files_count_ready = 0;
						continue;
					}
				}
			}
			try {
				f.move (file, FileCopyFlags.NONE, null, (current_num_bytes, total_num_bytes) => {
					DateTime d = new DateTime.now_local ();
					if (d.difference (last_info) > (2*TimeSpan.SECOND)) {
						lock (files_count_ready) {
							last_info = new DateTime.now_local ();
							Filefinder.window.show_info (("%s of %s copied.\n" +
							"File(s) moved %d of the %u").printf (get_bin_size (current_num_bytes),
							get_bin_size(total_num_bytes),files_count_ready, files_count));
						}
					}
				});
				files_count_ready++;
			} catch (Error e) {
				Filefinder.window.show_error (e.message);
			}
		}
		Filefinder.window.show_info ("File(s) moved %d of the %u".printf (files_count_ready, files_count));
		files_count = files_processed = files_count_ready = 0;
	}

	private void move_to_trash (GLib.List<GLib.File>? files) {
		if (files == null) return;
		while (files_count != 0) {
			GLib.Thread.usleep (2500);
		}
		var dlg = new Gtk.MessageDialog (Filefinder.window, 0,
					Gtk.MessageType.WARNING, Gtk.ButtonsType.YES_NO,
					"Are you realy want trash %u file(s)?\n",
					files.length ());
		int r = dlg.run ();
		dlg.destroy ();
		if (r != Gtk.ResponseType.YES) {
			return;
		}
		files_count_ready = 0;
		files_count = files.length ();
		last_info = new DateTime.now_local ();
		foreach (File f in files) {
			files_processed++;
			try {
				f.trash (null);
				lock (files_count_ready) {
					files_count_ready++;
					DateTime d = new DateTime.now_local ();
					if (d.difference (last_info) > (2*TimeSpan.SECOND)) {
						last_info = new DateTime.now_local ();
						Filefinder.window.show_info ("File(s) trashed %d of the %u".printf (files_count_ready, files_count));
					}
				}
				remove_selected_file (f);
			} catch (Error e) {
				Filefinder.window.show_error (e.message);
			}
		}
		files_count = files_processed = files_count_ready = 0;
	}
}
