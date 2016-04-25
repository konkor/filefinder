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

	public FileFinderWindow (Gtk.Application app) {
        GLib.Object (application: app);
		build ();
        initialize ();
	}

    private Gtk.Box vbox1;
    private Gtk.InfoBar infoBar;
	private Gtk.Box infoBox;
    private Gtk.HeaderBar hb;
    private Gtk.Button button_go;
	private Gtk.Button button_plus;
	//private Gtk.Entry search_entry;
	private Gtk.Paned paned;

	private QueryEditor editor;
    
    protected void build () {
        set_position (Gtk.WindowPosition.CENTER);
        //set_border_width (4);
        hb = new Gtk.HeaderBar ();
		hb.has_subtitle = false;
		hb.title = Environment.get_home_dir ();
        hb.set_show_close_button (true);
        set_titlebar (hb);

		/*Gtk.FileChooserButton chooser = new Gtk.FileChooserButton ("Select folder",
		                                                           Gtk.FileChooserAction.SELECT_FOLDER);
		chooser.set_current_folder (Environment.get_home_dir ());
		hb.pack_start (chooser);
		chooser.file_set.connect (()=>{ hb.title = chooser.get_filename ();});
		*/
		/*search_entry = new Gtk.Entry ();
		search_entry.halign = Gtk.Align.FILL;
		search_entry.expand = true;
		hb.set_custom_title (search_entry);*/

        button_go = new Gtk.Button ( );
        button_go.use_underline = true;
        button_go.can_default = true;
        this.set_default (button_go);
        button_go.label = "Search";
        button_go.tooltip_text = "Start Search";
        //Gtk.Image image = new Gtk.Image.from_stock (Gtk.Stock.EXECUTE, Gtk.IconSize.BUTTON);
        //button_go.add (image);
		button_go.get_style_context ().add_class ("suggested-action");
        hb.pack_end (button_go);

		button_plus = new Button.from_icon_name ("list-add-symbolic", IconSize.BUTTON);
		button_plus.use_underline = true;
		button_plus.tooltip_text = "Add Query";
		hb.pack_start (button_plus);

        vbox1 = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        add (vbox1);

        infoBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		vbox1.pack_start (infoBox,false,true,0);

        paned = new Gtk.Paned (Gtk.Orientation.VERTICAL);
		paned.can_focus = true;
		paned.position = 32;
		vbox1.add (paned);

		Gtk.ScrolledWindow scrolledwindow = new Gtk.ScrolledWindow (null, null);
		//scrolledwindow.can_focus = true;
		scrolledwindow.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		scrolledwindow.shadow_type = Gtk.ShadowType.OUT;
		paned.pack1 (scrolledwindow, false, false);

		editor = new QueryEditor ();
		editor.expand = true;
		scrolledwindow.add (editor);
		button_plus.clicked.connect ( ()=>{
			paned.
				visible = true;
			if (paned.position < 200) {
				paned.position += 24;
			}
			editor.add_row (new QueryRow ());
		});

		scrolledwindow = new Gtk.ScrolledWindow (null, null);
		//scrolledwindow.can_focus = true;
		scrolledwindow.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		scrolledwindow.shadow_type = Gtk.ShadowType.OUT;
		paned.pack2 (scrolledwindow, false, false);
		
        set_default_size (640, 480);
    }

    private void initialize () {
        button_go.clicked.connect (on_go_clicked);
        
	}

	public void post_init () {
		paned.visible = false;
	}
	 
    private void on_go_clicked () {
        go_clicked (query);
    }

    public int show_message (string text, MessageType type = MessageType.INFO) {
        if (infoBar != null) infoBar.destroy ();
        if (type == Gtk.MessageType.QUESTION) {
            infoBar = new InfoBar.with_buttons (Gtk.Stock.YES, Gtk.ResponseType.YES,
                                                Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL);
        } else {
            infoBar = new InfoBar.with_buttons ("gtk-close", Gtk.ResponseType.CLOSE);
            infoBar.set_default_response (Gtk.ResponseType.OK);
        }
        infoBar.set_message_type (type);
        Gtk.Container content = infoBar.get_content_area ();
        switch (type) {
            case Gtk.MessageType.QUESTION:
                content.add (new Gtk.Image.from_stock ("gtk-dialog-question", Gtk.IconSize.DIALOG));
                break;
            case Gtk.MessageType.INFO:
                content.add (new Gtk.Image.from_stock ("gtk-dialog-info", Gtk.IconSize.DIALOG));
                break;
            case Gtk.MessageType.ERROR:
                content.add (new Gtk.Image.from_stock ("gtk-dialog-error", Gtk.IconSize.DIALOG));
                break;
            case Gtk.MessageType.WARNING:
                content.add (new Gtk.Image.from_stock ("gtk-dialog-warning", Gtk.IconSize.DIALOG));
                break;
        }
        content.add (new Gtk.Label (text));
        infoBar.show_all ();
        infoBox.add (infoBar);
        infoBar.response.connect (() => {
			infoBar.destroy ();
			//hide();
		});
        GLib.Timeout.add (5000, on_info_timeout);
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
}

