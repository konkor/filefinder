/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * input-dialog.vala
 * Copyright (C) 2016 konkor <kkorienkov <at> gmail.com>
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

public class InputDialog : Gtk.Dialog {

	public Gtk.Label label;
	public Gtk.Entry entry;

	public InputDialog (Gtk.Window? w = null) {
		set_transient_for (w);
		title = Text.app_name;
		add_button ("_Cancel", Gtk.ResponseType.CANCEL);
		add_button ("_OK", Gtk.ResponseType.ACCEPT);
		set_default_size (512, 140);
		Gtk.Box content = get_content_area () as Gtk.Box;
		content.border_width = 8;
		content.spacing = 6;

		label = new Gtk.Label (null);
		label.xalign = 0;
		content.add (label);

		entry = new Gtk.Entry ();
		entry.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear");
		entry.icon_press.connect ((pos, event) => {
			if (pos == Gtk.EntryIconPosition.SECONDARY) {
				entry.set_text ("");
			}
		});
		entry.key_press_event.connect ((event) => {
			if (event.keyval == Gdk.Key.Return) {
				response (Gtk.ResponseType.ACCEPT);
				return true;
			}
			return false;
		});
		content.add (entry);

		show_all ();
	}
}
