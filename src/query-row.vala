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

public class QueryRow : Gtk.Box {
	public signal void closed (QueryRow row);
	public signal void changed_type (QueryRow row);

	private Gtk.ComboBoxText combo_type;
	private Gtk.Box hbox;

	public QueryRow () {
		GLib.Object (orientation:Gtk.Orientation.HORIZONTAL, spacing:6);
		this.margin = 2;
		this.get_style_context ().add_class ("search-bar");
		
		combo_type = new Gtk.ComboBoxText ();
		foreach (string s in type_names) {
			combo_type.append_text (s.up ());
		}
		combo_type.active = 0;
		add (combo_type);
		combo_type.changed.connect (() => {
			changed_type (this);
			create_type_widgets ();
		});

		create_type_widgets ();

		Gtk.Button btn  = new Gtk.Button.from_icon_name ("window-close-symbolic",
		                                                 Gtk.IconSize.BUTTON);
		btn.get_style_context ().add_class (Gtk.STYLE_CLASS_ACCELERATOR);
		btn.tooltip_text = "Remove this criterion from the search";
		pack_end (btn, false, false, 0);
		btn.clicked.connect ( () => {
			closed (this);
		});

		show_all ();
	}

	 private void create_type_widgets () {
		//TODO additional widgets by type
		if (hbox != null) hbox.destroy ();
		hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
		pack_start (hbox, true, true, 0);

		switch (combo_type.active) {
			case types.LOCATION:
				Gtk.FileChooserButton chooser;
				chooser = new Gtk.FileChooserButton ("Select folder",
		    	                                     Gtk.FileChooserAction.SELECT_FOLDER);
				chooser.set_current_folder (Environment.get_home_dir ());
				hbox.pack_start (chooser, true, true, 0);
				chooser.file_set.connect (()=>{ chooser.tooltip_text = chooser.get_filename ();});

				Gtk.CheckButton chk = new Gtk.CheckButton ();
				chk.tooltip_text = "Recursively";
				chk.active = true;
				hbox.add (chk);
				break;
			default:
				Gtk.Label label = new Gtk.Label ("test");
				hbox.add (label);

				break;
		}

		hbox.show_all ();
	 }

	

}

public static const string[] type_names = {
	"Location",
	"File Mask",
	"Mimetype",
	"Text",
	"Binary",
	"Modified"
};

