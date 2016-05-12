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

public class QueryEditor : Gtk.Box {
	public GLib.List<QueryRow> rows;
	
	public QueryEditor () {
		GLib.Object (orientation:Gtk.Orientation.VERTICAL, spacing:0);
		this.homogeneous = false;
		this.get_style_context ().add_class ("search-bar");
		this.margin = 0;
		rows = new GLib.List<QueryRow> ();
	}

	public void add_row (QueryRow row) {
		//pack_start (row, false, true, 0);
		add (row);
		row.closed.connect (on_row_close);
		rows.append (row);
		//row.label.label = "Query " + rows.length().to_string ();
		//Debug.log (this.name, "added row");
	}

	 private void on_row_close (QueryRow row) {
		rows.remove (row);
		row.dispose ();
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
		row.files_btn.label = path;
		if (row.files.files.length () > 1)
			row.files_btn.label += " ... (%u selected items)".printf (
				row.files.files.length());	
	}
}

