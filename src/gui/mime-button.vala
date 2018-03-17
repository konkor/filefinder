/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * mime-button.vala
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

public class MimeButton : Gtk.MenuButton {
	private FilterMime mime;

	private Gtk.Popover pop;
	private Gtk.TreeView mime_group;
	private Gtk.ListStore mime_group_store;
	private Gtk.TreeView mime_type;
	private Gtk.ListStore mime_type_store;

	public MimeButton (FilterMime filter) {
		mime = filter;
		use_underline = true;
		label = mime.name;
		tooltip_text = "Any " + label;
		xalign = 0;

		build ();

		clicked.connect (()=>{
			int i = get_allocated_width() + 32;
			if (i < 480)
				pop.width_request = 480;
			else
				pop.width_request = i;
		});
	}

	private void build () {
		pop = new Gtk.Popover (this);
		pop.width_request = 512;
		pop.height_request = 320;
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
		pop.add (box);
		set_popover (pop);

		var scroll = new Gtk.ScrolledWindow (null, null);
		scroll.shadow_type = Gtk.ShadowType.OUT;
		scroll.halign = Gtk.Align.START;
		box.add (scroll);

		mime_group = new Gtk.TreeView ();
		mime_group_store = new Gtk.ListStore (1, typeof (string));
		mime_group.set_model (mime_group_store);
		mime_group.insert_column_with_attributes (-1, "Group", new Gtk.CellRendererText (), "text", 0, null);
		scroll.add (mime_group);
		Gtk.TreeIter it = {};
		foreach (MimeGroup s in Filefinder.preferences.mime_type_groups) {
			mime_group_store.append (out it);
			mime_group_store.set (it, 0, s.name, -1);
		}
		scroll.width_request = 200;

		scroll = new Gtk.ScrolledWindow (null, null);
		scroll.shadow_type = Gtk.ShadowType.OUT;
		scroll.expand = true;
		box.add (scroll);

		mime_type = new Gtk.TreeView ();
		mime_type.get_selection ().mode = Gtk.SelectionMode.MULTIPLE;
		mime_type_store = new Gtk.ListStore (1, typeof (string));
		mime_type.set_model (mime_type_store);
		mime_type.insert_column_with_attributes (-1, "MIME", new Gtk.CellRendererText (), "text", 0, null);
		scroll.add (mime_type);

		mime_group.get_selection ().changed.connect (()=>{
			Gtk.TreePath p;
			p = mime_group.get_selection ().get_selected_rows (null).nth_data (0);
			if (p == null) return;
			mime.clear ();
			mime_type_store.clear ();
			mime_type_store.append (out it);
			mime_type_store.set (it, 0, "Any", -1);
			mime.name = Filefinder.preferences.mime_type_groups[p.get_indices ()[0]].name;
			foreach (string s in Filefinder.preferences.mime_type_groups[p.get_indices ()[0]].mimes) {
				mime_type_store.append (out it);
				mime_type_store.set (it, 0, s, -1);
				mime.add (s);
			}
			set_mime_label (alloc);
		});
		mime_type.get_selection ().changed.connect (()=>{
			Gtk.TreePath p0;
			int tc = 0;
			string val, tt = "";
			mime.clear ();
			tooltip_text = tt;
			p0 = mime_group.get_selection ().get_selected_rows (null).nth_data (0);
			if (p0 == null) return;
			foreach (Gtk.TreePath p in mime_type.get_selection ().get_selected_rows (null)) {
				if (p.get_indices()[0] == 0) {
					foreach (string s in Filefinder.preferences.mime_type_groups[p0.get_indices ()[0]].mimes) {
						mime.add (s);
					}
					set_mime_label (alloc);
					tooltip_text = "Any Of The " + label;
					return;
				}
				if (mime_type.model.get_iter (out it, p)) {
					mime_type.model.get (it, 0, out val);
					mime.add (val);
					if (tc < 10) tt += val + "\n";
				}
				tc++;
			}
			if (mime.mime.length() != 1) {
				tt += "(Selected %u types)".printf (mime.mime.length());
			}
			tooltip_text = tt;
			set_mime_label (alloc);
		});
		box.show_all ();
		playout = (new Gtk.Label("")).get_layout ();
	}

	private int w = 0;
	private Gtk.Allocation alloc;

	public override void size_allocate (Gtk.Allocation allocation) {
		base.size_allocate (allocation);
		if (mime == null) return;
		alloc = allocation;
		if (w == allocation.width) return;
		w = allocation.width;
		set_mime_label (allocation);
	}

	private void set_mime_label (Gtk.Allocation allocation) {
		int j = 0;
		string[] mnames = {};
		string[] snames = mime.name.split (" ");
		string stypes = "";
		foreach (string s in mime.mime) {
			if (j != 0) stypes += " ";
			stypes += s;
			j++;
		}
		mnames += (mime.name + " (%s)".printf (stypes));
		mnames += (mime.name + " (Selected %u types)".printf (mime.mime.length()));
		mnames += (mime.name + " (%u types)".printf (mime.mime.length()));
		mnames += (mime.name + " (%u)".printf (mime.mime.length()));
		mnames += (mime.name);
		if (snames.length > 1) mnames += snames[0];
		if (mime.name.length > 6) mnames += (mime.name.substring (0, 3) + "...");
		mnames += "...";
		label = "";
		foreach (string s in mnames) {
			if (label_len (s) < w) {
				label = s;
				break;
			}
		}

#if HAVE_GTK320
		base.queue_allocate ();
#else
		base.size_allocate (allocation);
#endif
	}

	private Pango.Layout playout;
	private int label_len (string s) {
		int i = 2 * margin + 48, w, h;
		playout.set_font_description (get_style_context().get_font (Gtk.StateFlags.FOCUSED));
		playout.set_markup (s, -1);
		playout.get_pixel_size(out w, out h);
		return i + w;
	}
}

