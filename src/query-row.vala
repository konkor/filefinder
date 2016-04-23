/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * query-row.vala
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

public class QueryRow : Gtk.Toolbar {
	public signal void closed (QueryRow row);

	public Gtk.Box hbox;
	public Gtk.Label label;

	public QueryRow () {
		this.get_style_context ().add_class ("search-bar");

		Gtk.ToolItem item = new Gtk.ToolItem ();
		item.expand = true;
		insert (item, -1);

		hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		item.add (hbox);

		create_type_widgets ();

		Gtk.Button btn  = new Gtk.Button.from_icon_name ("window-close-symbolic",
		                                                 Gtk.IconSize.MENU);
		btn.get_style_context ().add_class (Gtk.STYLE_CLASS_RAISED);
		btn.tooltip_text = "Remove this criterion from the search";
		hbox.pack_end (btn, false, false, 0);
		btn.clicked.connect ( () => {
			closed (this);
		});

		show_all ();
	}

	 private void create_type_widgets () {
		//TODO additional widgets by type
		label = new Gtk.Label ("test");
		hbox.pack_start (label, true, true, 2);
	 }

}

