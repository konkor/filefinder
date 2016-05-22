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

	public GLib.List<QueryRow> rows;
	
	public QueryEditor () {
		//GLib.Object (orientation:Gtk.Orientation.VERTICAL, spacing:0);
		this.homogeneous = false;
		this.get_style_context ().add_class ("search-bar");
		this.margin = 0;
		selection_mode = Gtk.SelectionMode.NONE;
		max_children_per_line = Filefinder.preferences.filter_count;
		valign = Gtk.Align.START;
		set_sort_func (sort_boxes);
		
		rows = new GLib.List<QueryRow> ();
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
		//pack_start (row, false, true, 0);
		add (row);
		row.closed.connect (on_row_close);
		row.changed_type.connect (()=>{invalidate_sort ();});
		rows.append (row);
		invalidate_sort ();
		changed_rows ();
	}

	 private void on_row_close (QueryRow row) {
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

	public void add_filter (types filter_type = types.LOCATION) {
		QueryRow row = new QueryRow ();
		row.row_type = filter_type;
		add_row (row);
	}

	public void add_folder (string path) {
		QueryRow row = new QueryRow ();
		row.chooser.select_filename (path);
		row.location.folder = path;
		add_row (row);
	}

	public void add_file (string path) {
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
	}
}

