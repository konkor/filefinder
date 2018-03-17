/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * filter-bar.vala
 * Copyright (C) 2018 konkor <kapa76@gmail.com>
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

public class FilterBar : Gtk.ScrolledWindow {

	private Filter _filter;
	public Filter filter {
		get {
			return _filter;
		}
	}

	public FilterBar () {
		vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		hscrollbar_policy = Gtk.PolicyType.NEVER;
		shadow_type = Gtk.ShadowType.NONE;
		_filter = new Filter ();
		margin = 6;
		//get_style_context ().add_class ("primary-toolbar");

		build ();
		//show_all ();
	}

	private void build () {
		Gtk.Box box;
		//Gtk.Label label;
		FilterButton btn;

		box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
		add (box);
		/*label = new Gtk.Label ("<b>+</b>");
		label.set_use_markup (true);
		box.add (label);*/
		for (int i = 0; i < types.NONE; i++) {
			btn = new FilterButton (type_names[i], i);
			btn.tooltip_text = "Add " + type_tooltips[i];
			btn.clicked.connect ((o)=>{
				if (Filefinder.window == null) return;
				Filefinder.window.add_filter ((types)(o as FilterButton).id);
			});
			box.add (btn);
		}
	}
}

public class FilterButton : Gtk.Button {
	private int _id = -1;

	public FilterButton (string text = "", int id = -1) {
		margin = 4;
		label = text;
		_id = id;
	}

	public int id {
		get {
			return _id;
		}
	}

}
