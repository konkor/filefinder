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
		GLib.Object (orientation:Gtk.Orientation.VERTICAL, spacing:2);
		rows = new GLib.List<QueryRow> ();
	}

	public void add_row (QueryRow row) {
		pack_start (row, false, true, 2);
		row.closed.connect (on_row_close);
		rows.append (row);
		row.label.label = "Query " + rows.length().to_string ();
		Debug.log (this.name, "added row"); 
	}

	 private void on_row_close (QueryRow row) {
		rows.remove (row);
		row.dispose ();
	}

}

