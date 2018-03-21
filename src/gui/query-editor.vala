/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * query-editor.vala
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

public class QueryEditor : Gtk.FlowBox {
	public signal void changed_rows ();
	public signal void search ();

	public GLib.List<QueryRow> rows;
	//private FilterBar fbar;

	public QueryEditor () {
		//GLib.Object (orientation:Gtk.Orientation.VERTICAL, spacing:0);
		Debug.info ("QueryEditor", "init");
		this.homogeneous = false;
		this.get_style_context ().add_class ("search-bar");
		this.margin = 0;
		selection_mode = Gtk.SelectionMode.NONE;
		max_children_per_line = 1;
		if (Filefinder.preferences != null)
			max_children_per_line = Filefinder.preferences.filter_count;
		valign = Gtk.Align.START;
		set_sort_func (sort_boxes);

		//fbar = new FilterBar ();
		//add (fbar);

		rows = new GLib.List<QueryRow> ();
		show_all ();
	}

	private int sort_boxes (Gtk.FlowBoxChild child1, Gtk.FlowBoxChild child2) {
		var row1 = child1.get_child ();
		var row2 = child2.get_child ();

		if (row1 == null) return 1;
		if (row2 == null) return -1;

		return sort_rows ((row1 as QueryRow).filter, (row2 as QueryRow).filter);
	}

	private int sort_rows (Filter row1, Filter row2) {
		if (row1.filter_type == row2.filter_type) return 0;
		if (row1.filter_type < row2.filter_type)
			return -1;
		return 1;
	}

	public void add_row (QueryRow row) {
		Debug.info ("QueryEditor", "add_row (%s)".printf(row.row_type.to_string()));
		add (row);
		row.closed.connect (on_row_close);
		row.search.connect (()=>{search ();});
		row.changed_type.connect ((r)=>{
			invalidate_sort ();
			changed_rows ();
		});
		rows.append (row);
		invalidate_sort ();
		changed_rows ();
		//row.parent.grab_focus ();
	}

	public void remove_rows (types filter_type = types.NONE) {
		Debug.info ("QueryEditor", "remove_rows (%s)".printf(filter_type.to_string()));
		//remove all filters by default
		uint i = 0;
		while (i < rows.length ()) {
			if (filter_type == types.NONE) {
				on_row_close (rows.nth_data (i));
			} else if (rows.nth_data (i).filter.filter_type == filter_type) {
				on_row_close (rows.nth_data (i));
			} else i++;
		}
	}

	private void on_row_close (QueryRow row) {
		Debug.info ("QueryEditor", "on_row_close");
		rows.remove (row);
		row.get_parent().dispose ();
		invalidate_sort ();
		changed_rows ();
	}

	private Query _q;
	public Query query {
		get {
			_q = new Query ();
			foreach (QueryRow p in rows) {
				_q.add_filter (p.filter);
			}
			_q.apply_masks = (_q.masks.length ()>0) ||
				(_q.modifieds.length ()>0) ||
				(_q.mimes.length ()>0) ||
				(_q.texts.length ()>0) ||
				(_q.bins.length ()>0) ||
				(_q.sizes.length ()>0);
			return _q;
		}
	}

	public uint text_filters_count {
		get {
			uint i = 0;
			foreach (QueryRow p in rows) {
				if (p.filter.filter_type == types.TEXT) i++;
			}
			return i;
		}
	}

	public void add_filter (types filter_type = types.LOCATION) {
		Debug.info ("QueryEditor", "add_filter (%s)".printf(filter_type.to_string()));
		QueryRow row = new QueryRow ();
		row.row_type = filter_type;
		add_row (row);
	}

	public void add_folder (string path) {
		Debug.info ("QueryEditor", "add_folder (%s)".printf(path));
		QueryRow row = new QueryRow ();
		row.chooser.select_filename (path);
		row.location.folder = path;
		add_row (row);
	}

	public void add_file (string path) {
		Debug.info ("QueryEditor", "add_file (%s)".printf(path));
		int tt = 0;
		string t = "";
		QueryRow row = null;
		foreach (QueryRow p in rows) {
			if (p.row_type == types.FILES) {
				row = p;
				break;
			}
		}
		if (row == null) {
			row = new QueryRow ();
			row.row_type = types.FILES;
			add_row (row);
		}
		row.files.add (path);
		if (path.index_of ("/") > -1)
			row.files_btn.label = path.substring (path.last_index_of ("/"));
		else
			row.files_btn.label = path;
		if (row.files.files.length () > 1)
			row.files_btn.label += " ... (%u selected items)".printf (
				row.files.files.length());
		foreach (string s in row.files.files) {
			if (tt < 20) t += s + "\n";
			tt++;
		}
		t += " ...\n(%u selected items)".printf (row.files.files.length());
		row.files_btn.tooltip_text = t;
	}

	public bool location_exist (File file) {
		if (file.query_file_type (FileQueryInfoFlags.NONE) == FileType.DIRECTORY)
			return folder_exist (file);
		else
			return file_exist (file);
	}

	public bool folder_exist (File file) {
		foreach (QueryRow p in rows) {
			if (p.filter.filter_type == types.LOCATION)
				if (((FilterLocation) p.filter.filter_value).folder == file.get_path ()) return true;
		}
		return false;
	}

	public bool file_exist (File file) {
		FilterFiles filter = null;
		foreach (QueryRow p in rows) {
			if (p.row_type == types.FILES) {
				filter = (FilterFiles) p.filter.filter_value;
				break;
			}
		}
		foreach (string s in filter.files) {
			if (s == file.get_path ()) return true;
		}
		return false;
	}

}

