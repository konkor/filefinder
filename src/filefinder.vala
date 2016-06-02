/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * main.c
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

using GLib;
using Gtk;

public class Filefinder : Gtk.Application
{
	public static bool debugging;
	public static FileFinderWindow window;
	public static Preferences preferences;
	public static Service service;
	public static Filefinder self;
	public static List<string> uris;

	private const GLib.ActionEntry[] action_entries = {
		{"preferences", preferences_cb},
		{"about", about_cb},
		{"quit", quit_cb},
		{"add_location", add_location_cb},
		{"toggle_paned", toggle_paned_cb}
	};

	public Filefinder (string[] args)
	{
		Object (application_id: "org.konkor.filefinder",
				flags: ApplicationFlags.HANDLES_OPEN);
		uris = new List<string>();
		int i, count = args.length;
		for (i = 1; i < count; i++) {
			switch (args[i]) {
				case "--help":
				case "--version":
				case "--license":
				case "--debug":
					break;
				default:
					if (exist (args[i]))
						uris.append (args[i]);
					break;
			}
		}
		self = this;
	}

	protected override void startup () {
		base.startup ();
		add_action_entries (action_entries, this);
		GLib.Menu section = new GLib.Menu ();
		section.append_item (new GLib.MenuItem ("Preferences", "app.preferences"));
		section.append_item (new GLib.MenuItem ("About", "app.about"));
		section.append_item (new GLib.MenuItem ("Quit", "app.quit"));
		GLib.Menu menu = new GLib.Menu ();
		menu.append_section (null, section);
		this.set_app_menu ((GLib.MenuModel) menu);

		set_accels_for_action ("app.quit", {"<Primary>q"});
		set_accels_for_action ("app.add_location", {"Insert"});
		set_accels_for_action ("app.toggle_paned", {"<Primary>n"});

		Environment.set_application_name (Text.app_name);

		preferences = new Preferences ();
		service = new Service ();

		window = new FileFinderWindow (this);
		window.show_all ();
		window.post_init ();
		window.go_clicked.connect ((q)=>{
			Debug.info ("loc count", "%u".printf (q.locations.length ()));
			Debug.info ("file count", "%u".printf (q.files.length ()));
			Debug.info ("mask count", "%u".printf (q.masks.length ()));
			Debug.info ("mime count", "%u".printf (q.mimes.length ()));
			Debug.info ("mod count", "%u".printf (q.modifieds.length ()));
			Debug.info ("text count", "%u".printf (q.texts.length ()));
			Debug.info ("bin count", "%u".printf (q.bins.length ()));
			Debug.info ("size count", "%u".printf (q.sizes.length ()));
			service = new Service ();
			window.result_view.connect_model ();
			service.finished_search.connect (()=>{
				window.show_results ();
			});
			service.row_changed.connect(()=>{window.set_subtitle ();});
			window.canceled.connect (()=>{
				service.cancel ();
			});
			service.start (q);
		});
		//window.add_locations (uris);
		open.connect (()=>{window.add_locations (uris);});
		preferences.load_plugs ();
	}

	protected override void activate () {
		window.present ();
	}

	private void quit_cb () {
		exit ();
	}

	public static void exit () {
		window.destroy ();
	}

	private void preferences_cb () {
		preferences.show_window ();
	}

	private void add_location_cb () {
		window.add_filter ();
	}

	private void toggle_paned_cb () {
		if (window == null) return;
		window.toggle_paned ();
	}

	protected override void shutdown() {
		preferences.save ();
		base.shutdown();
	}

	private void about_cb () {
		about ();
	}

	public static void about () {
		string[] authors = {
		  "Kostiantyn Korienkov",
		  null
		};
		Gtk.show_about_dialog (window,
							"name", Text.app_name,
							"copyright", Text.app_copyright,
							"license-type", Gtk.License.GPL_3_0,
							"authors", authors,
							"website", Text.app_website,
							"website-label", Text.app_name,
							"version", Text.app_version,
							"logo_icon_name", "filefinder",
							null);
	}

	public static bool exist (string filepath) {
		GLib.File file = File.new_for_path (filepath.strip ());
		return file.query_exists ();
	}

	public static GenericSet<File>   get_excluded_locations () {
		var excluded_locations = new GenericSet<File> (File.hash, File.equal);
		excluded_locations.add (File.new_for_path ("/dev"));
		excluded_locations.add (File.new_for_path ("/proc"));
		excluded_locations.add (File.new_for_path ("/sys"));
		excluded_locations.add (File.new_for_path ("/selinux"));

		var home = File.new_for_path (Environment.get_home_dir ());
		excluded_locations.add (home.get_child (".gvfs"));

		/*var root = File.new_for_path ("/");
		foreach (var uri in prefs_settings.get_value ("excluded-uris")) {
			var file = File.new_for_uri ((string) uri);
			if (!file.equal (root)) {
				excluded_locations.add (file);
			}
		}*/

		return excluded_locations;
	}
}
