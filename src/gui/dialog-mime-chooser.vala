/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * dialog-mime-chooser.vala
 * Copyright (C) 2016 kapa <kkorienkov <at> gmail.com>
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

public class DialogMimeChooser : Gtk.Dialog {
	private List<string> contents;
	public string mimes {get;protected set;}	

	private Gtk.ListStore model;
	private Gtk.IconView view;
	//private Gtk.SearchBar sb;
	private Gtk.Entry entry;

	public DialogMimeChooser (Gtk.Window? w = null) {
		//set_transient_for (w);
		title = "Select MIME Types";
		add_buttons ("Cancel", Gtk.ResponseType.CANCEL,
					"Select", Gtk.ResponseType.ACCEPT);
		set_default_size (840, 512);
		Gtk.Box content = get_content_area () as Gtk.Box;
		content.border_width = 8;
		content.spacing = 6;

		Gtk.TreeIter iter = TreeIter ();
		GLib.Value val = Value (typeof (string));

		entry = new Gtk.Entry ();
		entry.set_icon_from_icon_name (Gtk.EntryIconPosition.PRIMARY, "filefinder");
		entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear");
		entry.icon_press.connect ((pos, event) => {
			if (pos == Gtk.EntryIconPosition.SECONDARY) {
				entry.set_text ("");
			}
		});
		content.add (entry);
		
		Gtk.Label label = new Gtk.Label ("All registered content types");
		label.xalign = 0;
		content.add (label);
		ScrolledWindow scroll = new ScrolledWindow (null, null);
		scroll.shadow_type = Gtk.ShadowType.OUT;
		content.pack_start (scroll, true, true, 0);

		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		Gtk.TreeModelFilter filter = new Gtk.TreeModelFilter (model, null);
		filter.set_visible_func (filter_tree);
		entry.changed.connect (()=>{filter.refilter();});

		view = new Gtk.IconView.with_model (filter);
		view.item_width = 380;
		view.item_orientation = 0;
		view.selection_mode = SelectionMode.MULTIPLE;
		view.set_tooltip_column (1);
		view.set_text_column (0);
		scroll.add (view);
		view.selection_changed.connect (()=>{
			string s = "";
			foreach (TreePath p in view.get_selected_items ()) {
				if (filter.get_iter (out iter, p)) {
					filter.get_value (iter, 0, out val);
					s += val.get_string () + " ";
				}
			}
			if (s.length > 0) s = s.substring (0, s.length - 1);
			mimes = s;
		});

		contents = GLib.ContentType.list_registered ();
		contents.sort (strcmp);
		foreach (string s in contents) {
			model.append (out iter);
			model.set (iter, 0, s, 1, GLib.ContentType.get_description (s));
		}

		show_all ();
	}

	private bool filter_tree (Gtk.TreeModel model, Gtk.TreeIter iter) {
		if (entry.text.length == 0) return true;
		string[] patterns = entry.text.up().split(" "); 
		GLib.Value val;
		model.get_value (iter, 0, out val);
		string mime = val.get_string ().up ();
		model.get_value (iter, 1, out val);
		mime += val.get_string ().up ();

		foreach (string s in patterns) {
			if (s.length > 0)
				if (mime.contains (s))
					return true;
		}
		return false;
	}

}

