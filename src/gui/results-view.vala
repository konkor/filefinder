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

	public ResultsView () {
		can_focus = true;
		headers_clickable = true;
		get_selection ().mode = Gtk.SelectionMode.MULTIPLE;

		build_columns ();
	}

	private void build_columns () {
		Gtk.TreeViewColumn col;
		Gtk.CellRendererText colr;
		int i = 0;
		foreach (ViewColumn p in Filefinder.preferences.columns) {
			col = new Gtk.TreeViewColumn ();
			col.title = p.title;
			col.expand = false;
			col.fixed_width = p.width;
			//TODO col.AddSignalHandler ("notify::width", column_width);
			col.resizable = true;
			col.sizing = TreeViewColumnSizing.FIXED;
			col.sort_column_id = i;
			colr = new Gtk.CellRendererText ();
			col.pack_start (colr, false);
			col.set_cell_data_func (colr, render_text);
			col.visible = p.visible;
			append_column (col);
			i++;
		}

		col = new Gtk.TreeViewColumn ();
		col.title = " ";
		col.sizing = TreeViewColumnSizing.AUTOSIZE;
		colr = new Gtk.CellRendererText ();
		col.pack_start (colr, false);
		append_column (col);

		model = Filefinder.service;
		//TODO sort function
		//int n = i;
		//for (i = 0; i < n; i++) store.SetSortFunc (i, SortTree);
	}

	private void render_text (Gtk.CellLayout layout, Gtk.CellRenderer cell, Gtk.TreeModel model, Gtk.TreeIter iter) {
        Result item;
        GLib.Value v;
        model.get_value (iter, 0, out v);
        item = (Result) v;
		//TODO text cell render
	}
}

