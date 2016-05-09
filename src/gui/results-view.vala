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
	private Gtk.Menu menu;
	private Gtk.Menu menu_columns;

	public ResultsView () {
		can_focus = true;
		headers_clickable = true;
		get_selection ().mode = Gtk.SelectionMode.MULTIPLE;

		build_columns ();
		build_menus ();

		button_press_event.connect (on_tree_button);
	}

	private void build_columns () {
		Gtk.TreeViewColumn col0;
		Gtk.CellRendererText colr;
		int i = 0;
		foreach (ViewColumn p in Filefinder.preferences.columns) {
			Gtk.TreeViewColumn col = new Gtk.TreeViewColumn ();
			col.title = p.title;
			col.expand = false;
			col.fixed_width = p.width;
			col.resizable = true;
			col.sizing = TreeViewColumnSizing.FIXED;
			col.sort_column_id = i;
			colr = new Gtk.CellRendererText ();
			col.pack_start (colr, false);
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
				switch (v.get_int()) {
					case 0:
						(cell as Gtk.CellRendererText).text = "Unknown";
						break;
					case 1:
						(cell as Gtk.CellRendererText).text = "Regular";
						break;
					case 2:
						(cell as Gtk.CellRendererText).text = "Directory";
						break;
					case 3:
						(cell as Gtk.CellRendererText).text = "Symlink";
						break;
					case 4:
						(cell as Gtk.CellRendererText).text = "Special";
						break;
					case 5:
						(cell as Gtk.CellRendererText).text = "Shortcut";
						break;
					case 6:
						(cell as Gtk.CellRendererText).text = "Mountable";
						break;
				}
				break;
			case Columns.TIME_MODIFIED:
				model.get_value (iter, Columns.TIME_MODIFIED, out v);
				DateTime d = new DateTime.from_unix_utc ((int64) v.get_uint64());
				(cell as Gtk.CellRendererText).text = d.to_string();
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

	private bool on_tree_button (Gdk.EventButton event) {
		if (event.button == 3) { //right click
			int x, y;
			get_pointer (out x, out y);
			if (y <= 32) {
        		menu_columns.popup (null, null, null, 3, get_current_event_time ());
			}
		} else if (event.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) {
			//global_actions.OnPlaySelected (this, null);
		}
        return false;
	}

	private string get_bin_size (uint64 i) {
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
}

