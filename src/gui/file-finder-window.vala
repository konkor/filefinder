/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * file-finder-window.vala
 * Copyright (C) 2016 see AUTHORS <>
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

public class FileFinderWindow : Gtk.ApplicationWindow {
	public signal void go_clicked (Query q);
	public signal void canceled ();

	public FileFinderWindow (Gtk.Application app) {
        GLib.Object (application: app);
		build ();
        initialize ();
	}

    private Gtk.Box vbox1;
    private Gtk.InfoBar infoBar;
	private Gtk.Box infoBox;
    private Gtk.HeaderBar hb;
    private Gtk.ToggleButton button_go;
	private Gtk.Button button_plus;
	private Gtk.Paned paned;
	private Gtk.AccelGroup accel_group;

	private Gtk.Box empty_box;

	private QueryEditor editor;
	public ResultsView result_view;
    
    protected void build () {
        set_position (Gtk.WindowPosition.CENTER);
        //set_border_width (4);

		accel_group = new AccelGroup ();
		this.add_accel_group (accel_group);
		
        hb = new Gtk.HeaderBar ();
		//hb.has_subtitle = false;
		hb.title = Text.app_name;
        hb.set_show_close_button (true);
        set_titlebar (hb);

		button_go = new Gtk.ToggleButton ( );
        button_go.use_underline = true;
        button_go.can_default = true;
        this.set_default (button_go);
        button_go.label = "Search";
        button_go.tooltip_text = "Start Search";
		button_go.get_style_context ().add_class ("suggested-action");
        hb.pack_end (button_go);

		button_plus = new Button.from_icon_name ("list-add-symbolic", IconSize.BUTTON);
		button_plus.use_underline = true;
		button_plus.tooltip_text = "Add Query";
		button_plus.add_accelerator ("clicked", accel_group,
		                               Gdk.keyval_from_name("Insert"), 0,
		                               AccelFlags.VISIBLE);
		hb.pack_start (button_plus);

        vbox1 = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        add (vbox1);

        infoBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		vbox1.pack_start (infoBox, false, true, 0);

		empty_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 40);
		empty_box.margin = 80;
		vbox1.pack_start (empty_box, true, true, 0);

		Gtk.Image image = new Gtk.Image.from_icon_name ("folder-documents-symbolic", Gtk.IconSize.DIALOG);
        empty_box.add (image);
		empty_box.add (new Label("No search results."));

        paned = new Gtk.Paned (Filefinder.preferences.split_orientation);
		paned.events |= Gdk.EventMask.VISIBILITY_NOTIFY_MASK;
		paned.can_focus = true;
		if (Filefinder.preferences.split_orientation == Gtk.Orientation.VERTICAL)
			paned.position = paned.min_position;
		else
			paned.position = 480;
		vbox1.add (paned);

		Gtk.ScrolledWindow scrolledwindow = new Gtk.ScrolledWindow (null, null);
		scrolledwindow.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		scrolledwindow.shadow_type = Gtk.ShadowType.OUT;
		paned.pack1 (scrolledwindow, false, true);

		editor = new QueryEditor ();
		editor.expand = true;
		scrolledwindow.add (editor);
		button_plus.clicked.connect ( ()=>{
			paned.visible = true;
			if (paned.position < 200) {
				paned.position += 24;
			}
			editor.add_row (new QueryRow ());
		});

		scrolledwindow = new Gtk.ScrolledWindow (null, null);
		scrolledwindow.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		scrolledwindow.shadow_type = Gtk.ShadowType.OUT;
		paned.pack2 (scrolledwindow, true, false);

		result_view = new ResultsView ();
		scrolledwindow.add (result_view);
		
		set_default_size (800, 512);
    }

    private void initialize () {
        button_go.clicked.connect (on_go_clicked);
        paned.visibility_notify_event.connect (()=>{
			empty_box.visible = !paned.visible;
			return false;
		});
		//GLib.Timeout.add (2000, refresh_ui);
	}

	public void post_init () {
		paned.visible = false;
	}

	public void add_locations (List<string> uris) {
		File file;
		foreach (string s in uris) {
			file = File.new_for_path (s);
			paned.visible = true;
			if (file.query_file_type (FileQueryInfoFlags.NONE) == FileType.DIRECTORY) {
				editor.add_folder (s);
			} else {
				editor.add_file (s);
			}
			if (paned.position < 200) {
				paned.position += 24;
			}
		}
	}

    private void on_go_clicked () {
		if (button_go.active) {
			button_go.label = "Stop";
			go_clicked (query);
			//result_view.disconnect_model ();
		} else {
			button_go.label = "Search";
			canceled ();
			//result_view.connect_model ();
		}
    }

	public void set_subtitle () {
		int n = result_view.model.iter_n_children (null);
		if (n > -1)
			hb.subtitle = "(%d items)".printf (n);
		else
			hb.subtitle = "";
		//if ((n%1000) == 0) while (Gtk.events_pending ()) Gtk.main_iteration ();
	}

	public void split_orientation (Gtk.Orientation orientation) {
		paned.orientation = orientation;
	}

	public void set_column_visiblity (int column, bool visible) {
		result_view.get_column (column).visible = visible;
	}

	private uint info_timeout_id = 0;
    public int show_message (string text, MessageType type = MessageType.INFO) {
        if (infoBar != null) infoBar.destroy ();
        if (type == Gtk.MessageType.QUESTION) {
            infoBar = new InfoBar.with_buttons ("gtk-yes", Gtk.ResponseType.YES,
                                                "gtk-cancel", Gtk.ResponseType.CANCEL);
        } else {
            infoBar = new InfoBar.with_buttons ("gtk-close", Gtk.ResponseType.CLOSE);
            infoBar.set_default_response (Gtk.ResponseType.OK);
        }
        infoBar.set_message_type (type);
        Gtk.Container content = infoBar.get_content_area ();
        switch (type) {
            case Gtk.MessageType.QUESTION:
                content.add (new Gtk.Image.from_icon_name ("gtk-dialog-question", Gtk.IconSize.DIALOG));
                break;
            case Gtk.MessageType.INFO:
                content.add (new Gtk.Image.from_icon_name ("gtk-dialog-info", Gtk.IconSize.DIALOG));
                break;
            case Gtk.MessageType.ERROR:
                content.add (new Gtk.Image.from_icon_name ("gtk-dialog-error", Gtk.IconSize.DIALOG));
                break;
            case Gtk.MessageType.WARNING:
                content.add (new Gtk.Image.from_icon_name ("gtk-dialog-warning", Gtk.IconSize.DIALOG));
                break;
        }
        content.add (new Gtk.Label (text));
        infoBar.show_all ();
        infoBox.add (infoBar);
        infoBar.response.connect (() => {
			infoBar.destroy ();
			//hide();
		});
		if (info_timeout_id > 0) {
			GLib.Source.remove (info_timeout_id);
		}
		info_timeout_id = GLib.Timeout.add (5000, on_info_timeout);
        return -1;
    }

    private bool on_info_timeout () {
        if (infoBar != null)
            infoBar.destroy ();
        return false;
    }

    public int show_warning (string text = "") {
        return show_message (text, MessageType.WARNING);
    }

    public int show_info (string text = "") {
        return show_message (text, MessageType.INFO);
    }

    public int show_error (string text = "") {
        return show_message (text, MessageType.ERROR);
    }

	public Query query {
		get {
			return editor.query;
		}
	}

	public void show_results () {
		Debug.info (this.name, "show_results () reached");
		//result_view.connect_model ();
		set_subtitle ();
		button_go.active = false;
		while (Gtk.events_pending ())
			Gtk.main_iteration ();
	}

	/*private bool refresh_ui () {
		while (Gtk.events_pending ())
			Gtk.main_iteration ();
		return true;
	}*/
}

