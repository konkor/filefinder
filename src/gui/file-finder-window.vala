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
using Gdk;

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
	private Gtk.MenuButton button_plus;
	private Gtk.MenuButton button_menu;
	private Gtk.Menu mmenu;
	private Gtk.Paned paned;
	private Gtk.ScrolledWindow scrolledwindow1;
	private Gtk.ScrolledWindow scrolledwindow;
	private Gtk.AccelGroup accel_group;
	public Gtk.Spinner spinner;

	private Gtk.Box empty_box;
	private Gtk.Box toolbar_bottom;
	private FilterBar filterbar;

	private QueryEditor editor;
	public ResultsView result_view;
	public Gtk.CheckMenuItem cmi;

	protected void build () {
		set_position (Gtk.WindowPosition.CENTER);
		//set_border_width (4);

		accel_group = new AccelGroup ();
		this.add_accel_group (accel_group);

		hb = new Gtk.HeaderBar ();
		hb.title = Text.app_name;
		hb.set_show_close_button (true);
		set_titlebar (hb);

		mmenu = new Gtk.Menu ();
		MenuItemIndex mii = new MenuItemIndex (0, "Toggle Panel");
		mii.tooltip_text = "Toggle Visiblity Of The Filter Panel";
		mii.set_accel ("<Ctrl>n");
		mmenu.add (mii);
		mii.activate.connect (()=>{
			toggle_paned ();
		});
		cmi = new Gtk.CheckMenuItem.with_label ("Autohide Panel");
		cmi.tooltip_text = "Autohide The Filter Panel On Results";
		cmi.active = Filefinder.preferences.check_autohide;
		mmenu.add (cmi);
		cmi.toggled.connect (()=>{
			Filefinder.preferences.set_autohide (cmi.active);
		});
		mmenu.add (new Gtk.SeparatorMenuItem ());
		var rmi = new Gtk.RadioMenuItem.with_label (null, "Split Vertical");
		unowned SList<Gtk.RadioMenuItem> rgroup = rmi.get_group ();
		rmi.set_active (Filefinder.preferences.split_verticaly);
		mmenu.add (rmi);
		rmi.toggled.connect (()=>{
			Filefinder.preferences.split_verticaly = !rmi.active;
		});
		rmi = new Gtk.RadioMenuItem.with_label (rgroup, "Split Horizontal");
		rmi.set_active (!Filefinder.preferences.split_verticaly);
		mmenu.add (rmi);
		mmenu.add (new Gtk.SeparatorMenuItem ());
		Gtk.MenuItem mi = new Gtk.MenuItem.with_label ("Preferences");
		mmenu.add (mi);
		mi.activate.connect (()=>{
			Filefinder.preferences.show_window ();
		});
		mmenu.add (new Gtk.SeparatorMenuItem ());
		mi = new Gtk.MenuItem.with_label ("About");
		mmenu.add (mi);
		mi.activate.connect (()=>{
			Filefinder.about ();
		});
		mmenu.show_all ();

		Gtk.Image image = new Gtk.Image.from_icon_name ("open-menu-symbolic",
														Gtk.IconSize.SMALL_TOOLBAR);
		button_menu = new MenuButton ();
		button_menu.use_underline = true;
		button_menu.tooltip_text = "Options";
		button_menu.image = image;
		button_menu.menu_model = (mmenu as MenuModel);
		button_menu.set_popup (mmenu);
		hb.pack_end (button_menu);

		button_go = new Gtk.ToggleButton ( );
		button_go.use_underline = true;
		button_go.can_default = true;
		this.set_default (button_go);
		button_go.label = "Search";
		button_go.tooltip_text = "Start Search <Control+Return>";
		button_go.get_style_context ().add_class ("suggested-action");
		hb.pack_end (button_go);
		button_go.add_accelerator ("clicked", accel_group,
									Gdk.keyval_from_name("Return"),
									Gdk.ModifierType.CONTROL_MASK,
									AccelFlags.VISIBLE);

		spinner = new Gtk.Spinner ();
		hb.pack_end (spinner);

		Gtk.Menu menu = new Gtk.Menu ();
		for (int i = 0; i < types.NONE; i++) {
			mii = new MenuItemIndex (i, type_names[i]);
			mii.activate.connect ((o)=>{
				add_filter ((types)(o as MenuItemIndex).id);
			});
			menu.add (mii);
		}
		menu.show_all ();
		image = new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
		button_plus = new MenuButton ();
		button_plus.use_underline = true;
		button_plus.tooltip_text = "Add Filter <Insert>";
		button_plus.image = image;
		button_plus.menu_model = (menu as MenuModel);
		button_plus.set_popup (menu);
		hb.pack_start (button_plus);

		vbox1 = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		add (vbox1);

		infoBox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		vbox1.pack_start (infoBox, false, true, 0);
		filterbar = new FilterBar ();
		//vbox1.pack_start (filterbar, false, true, 0);

		empty_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 40);
		empty_box.margin = 80;
		image = new Gtk.Image.from_icon_name ("folder-documents-symbolic", Gtk.IconSize.DIALOG);
		empty_box.pack_start (image, true, true, 0);
		//var label = new Label("<b>No search results.</b>");
		//label.use_markup = true;
		//empty_box.pack_start (label, true, true, 0);

		paned = new Gtk.Paned (Filefinder.preferences.split_orientation);
		paned.can_focus = true;
		if (Filefinder.preferences.split_orientation == Gtk.Orientation.VERTICAL)
			paned.position = 1;// paned.min_position;
		else
			paned.position = 480;
		vbox1.add (paned);

		toolbar_bottom = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		vbox1.add (toolbar_bottom);

		scrolledwindow1 = new Gtk.ScrolledWindow (null, null);
		scrolledwindow1.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		scrolledwindow1.shadow_type = Gtk.ShadowType.NONE;
		scrolledwindow1.get_style_context ().add_class ("search-bar");
		paned.pack1 (scrolledwindow1, false, true);

		editor = new QueryEditor ();
		editor.expand = true;
		scrolledwindow1.add (editor);
		editor.search.connect (()=>{button_go.clicked ();});

		vbox1 = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		paned.pack2 (vbox1, true, false);
		vbox1.pack_start (empty_box, true, true, 0);
		scrolledwindow = new Gtk.ScrolledWindow (null, null);
		scrolledwindow.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		scrolledwindow.shadow_type = Gtk.ShadowType.OUT;
		//paned.pack2 (scrolledwindow, true, false);
		vbox1.pack_start (scrolledwindow, true, true, 0);

		result_view = new ResultsView ();
		scrolledwindow.add (result_view);

		set_default_size (Filefinder.preferences.rect.width, Filefinder.preferences.rect.height);
		if (Filefinder.preferences.is_maximized)
			maximize ();
		if (Filefinder.preferences.first_run) {
			show_info (Text.first_run);
			Filefinder.preferences.first_run = false;
		}
	}

	private void initialize () {
		button_go.clicked.connect (on_go_clicked);
		result_view.changed_selection.connect (()=>{set_subtitle ();});
		size_allocate.connect (()=>{
			Filefinder.preferences.save_geometry ();
		});
		window_state_event.connect (()=>{
			Filefinder.preferences.save_geometry ();
			return false;
			
		});
		realize.connect (()=>{
			editor.changed_rows.connect (()=>{check_paned_position ();});
			check_paned_position ();
		});
		paned.position = _paned_pos = Filefinder.preferences.paned_pos;

		Gtk.drag_dest_set (this, DestDefaults.ALL, target_list, Gdk.DragAction.COPY);
		this.drag_data_received.connect(this.on_drag_data_received);
	}

	public void post_init () {
		show_box = false;
		show_box = true;
		if (Filefinder.uris.length () == 0) {
			add_filter (types.LOCATION);
			add_filter (types.TEXT);
		}
	}

	public bool show_box {
		get {return empty_box.visible;}
		set {
			if (empty_box.visible != value) {
				empty_box.visible = value;
				scrolledwindow.visible = !empty_box.visible;
			}
		}
	}

	private int _paned_pos = 0;
	public void toggle_paned () {
		if (paned.visible) {
			if ((paned.position < 4) && (paned.position < _paned_pos)) {
				paned.position = _paned_pos;
			} else {
				_paned_pos = paned.position;
				paned.position = 0;
				Filefinder.preferences.paned_pos = _paned_pos;
			}
		}
	}

	public void off_paned (bool off = true) {
		if (off) {
			if (paned.position > 0) {
				_paned_pos = paned.position;
				Filefinder.preferences.paned_pos = _paned_pos;
			}
			paned.position = 0;
		} else {
			paned.position = _paned_pos;
		}
	}

	private void check_paned_position () {
		int h1, h2;
		if (Filefinder.preferences.split_orientation == Gtk.Orientation.VERTICAL) {
			if (editor.rows.length () == 0) {
				paned.position = 1;
			} else {
				editor.get_preferred_height_for_width (editor.get_allocated_width(), out h1, out h2);
				if (h2 < 400) paned.position = h2 + 6;
				if (editor.rows.length() == 1) paned.position += 6;
			}
		} else {
			if (paned.position < 400)
				paned.position = 400;
		}
	}

	public void add_filter (types filter_type = types.LOCATION) {
		paned.visible = true;
		editor.add_filter (filter_type);
	}

	public void add_locations (List<string> uris) {
		File file;
		if (editor.query == null) return;
		editor.remove_rows (types.LOCATION);
		foreach (string s in uris) {
			file = File.new_for_path (s);
			paned.visible = true;
			if (file.query_file_type (FileQueryInfoFlags.NONE) == FileType.DIRECTORY) {
				editor.add_folder (s);
			} else {
				editor.add_file (s);
			}
		}
		Filefinder.uris = new List<string>();
		if (editor.text_filters_count == 0) {
			add_filter (types.TEXT);
		}
	}


	private void on_drag_data_received (Widget widget, DragContext context,
										int x, int y,
										SelectionData selection_data,
										uint target_type, uint time) {
		File file;
		if (editor.query == null) return;
		foreach (string uri in selection_data.get_uris ()){
			file = File.new_for_uri (uri);
			paned.visible = true;
			Debug.info ("DnD", uri);
			if (file.query_file_type (FileQueryInfoFlags.NONE) == FileType.DIRECTORY) {
				if (!editor.location_exist (file)) editor.add_folder (file.get_path());
			} else {
				if (!editor.location_exist (file)) editor.add_file (file.get_path());
			}
		}
		Gtk.drag_finish (context, true, false, time);
	}

	private void on_go_clicked () {
		if (button_go.active) {
			spinner.start ();
			button_go.label = "Stop";
			go_clicked (query);
			if (Filefinder.preferences.check_autohide)
				off_paned ();
			//result_view.disconnect_model ();
		} else {
			button_go.label = "Search";
			canceled ();
			spinner.stop ();
			//result_view.connect_model ();
		}
	}

	public void set_subtitle () {
		if (Filefinder.service == null) {
			hb.subtitle = "";
			return;
		}
		if (Filefinder.service.results_all == null) {
			hb.subtitle = "";
			return;
		}
		int n = result_view.model.iter_n_children (null);
		if (n > 0) {
			show_box = false;
			if (result_view.results_selection.position == 0)
				hb.subtitle = "(%d items in %s)".printf (n,
					result_view.get_bin_size (Filefinder.service.results_all.size));
			else
				hb.subtitle = "(selected %jd items in %s of the %d items in %s)".printf (
					result_view.results_selection.position,
					result_view.get_bin_size (result_view.results_selection.size),
					n, result_view.get_bin_size (Filefinder.service.results_all.size));
		} else {
			show_box = true;
			hb.subtitle = "(No items found)";
			if (Filefinder.preferences.check_autohide)
				off_paned (false);
		}
	}

	public void split_orientation (Gtk.Orientation orientation) {
		paned.orientation = orientation;
		check_paned_position ();
	}

	public void set_column_visiblity (int column, bool visible) {
		result_view.get_column (column).visible = visible;
	}

	public void set_max_filters (int count) {
		editor.max_children_per_line = count;
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
			info_timeout_id = 0;
		});
		if (info_timeout_id > 0) {
			GLib.Source.remove (info_timeout_id);
		}
		info_timeout_id = GLib.Timeout.add (10000, on_info_timeout);
		return -1;
	}

	private bool on_info_timeout () {
		if (infoBar != null)
			infoBar.destroy ();
		info_timeout_id = 0;
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

	private Toolbar? toolbar = null;
	public void enable_toolbar () {
		if (!Filefinder.preferences.show_toolbar) return;
		disable_toolbar ();
		toolbar = new Toolbar ();
		toolbar_bottom.pack_start (toolbar, true, false, 0);
		refresh_toolbar ();
	}

	public void disable_toolbar () {
		if (toolbar == null) return;
		toolbar.destroy ();
		toolbar = null;
	}

	public void refresh_toolbar () {
		if (toolbar == null) return;
		toolbar.rebuild ();
	}
}

const TargetEntry[] target_list = {
	{"text/uri-list", 0, 0}
};
