/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * tool-button.vala
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

public class ToolButton : Gtk.MenuItem {
	private List<string> labels;
	private string description;
	private string hotkey;
	//private string icon;

	public int id;
	public string group {get;set;default="";}

	public ToolButton (Plugin plug, int index = 0) {
		labels = new List<string>();
		id = index;
		use_underline = true;
		label = "";
		labels.append (plug.label);
		description = plug.description;
		if (plug.hotkey.length > 0) {
			set_accel (plug.hotkey);
			description += " <" + hotkey + ">";
		}
		group = plug.group;

		int i, word_index;
		string s;
		if (plug.label.length > 3) {
			string[] words = plug.label.split (" ");
			for (i = words.length - 1; i > 0; i--) {
				s = "";
				word_index = 0;
				while (word_index < i) {
					s += words[word_index++] + " ";
				}
				if (s.length > 0) s = s.substring (0, s.length - 1);
				labels.append (s);
			}
			labels.append ("...");
			labels.append (plug.label.substring (0, 1));
		}
		labels.sort (labelcmp);
		//icon_widget = new Gtk.Image.from_file (plug.icon);

		playout = (new Gtk.Label("")).get_layout ();

		if ((group.length == 0) || (id == -1) || !Filefinder.preferences.toolbar_groups) {
			get_style_context ().add_class ("button");
			get_style_context ().add_class ("dim-label");
			enter_notify_event.connect (on_enter);
			leave_notify_event.connect (on_leave);
		}
		
		button_press_event.connect ((event)=>{
			if (id > -1) {
				try {
				print ("'%s'\n", label);
				if (Filefinder.window == null) return false;
				var p = (Filefinder.preferences.plugins.nth_data (id) as Plugin);
				if (p == null) return false;
				Filefinder.window.result_view.launch (p);
				} catch (Error e) {
					Debug.error (label, e.message);
				}
			} else {
				Gtk.MenuPositionFunc func = menu_position_up_down_func;
				submenu.popup (null, null, func, event.button, event.time);
			}
			return false;
		});
		show_all ();
	}

	public void set_accel (string hot_key) {
		uint key;
		Gdk.ModifierType mods;
		if (hot_key.length == 0) return;
		Gtk.accelerator_parse (hot_key, out key, out mods);
		if (Filefinder.preferences.toolbar_shotcuts) {
			var child = get_child ();
			(child as Gtk.AccelLabel).set_accel (key, mods);
		}
		hotkey = Toolbar.get_accelerator_label (key, mods);
	}

	CompareFunc<string> labelcmp = (a, b) => {
		if (a.length > b.length) 
			return -1;
		else if (a.length < b.length)
			return 1;
		return 0;
	};

	private bool on_enter (Gdk.EventCrossing evnt) {
		get_style_context ().remove_class ("dim-label");
		return false;
	}

	private bool on_leave (Gdk.EventCrossing evnt) {
		get_style_context ().add_class ("dim-label");
		return false;
	}

	private int w = 0;
	//private Gtk.Allocation alloc;

	public override void size_allocate (Gtk.Allocation allocation) {
		base.size_allocate (allocation);
		if (labels.length () == 0) return;
		//alloc = allocation;
		if (w == allocation.width) return;
		w = allocation.width;
		set_mime_label (allocation);
	}

	private void set_mime_label (Gtk.Allocation allocation) {
		label = "";
		foreach (string s in labels) {
			if (label_len (s) < w) {
				label = s;
				break;
			}
		}
		tooltip_text = description;
		base.size_allocate (allocation);
	}

	private Pango.Layout playout;
	private int label_len (string s) {
		int i = 2 * margin + 32, w, h;
		playout.set_font_description (get_style_context().get_font (Gtk.StateFlags.FOCUSED));
		playout.set_markup (s, -1);
		playout.get_pixel_size (out w, out h);
		return i + w;
	}

	private bool _up = true;
	private void menu_position_up_down_func (Gtk.Menu menu, ref int x, ref int y, out bool push_in) {
		Gtk.Allocation menu_allocation, allocation, arrow_allocation;
		Gdk.Screen screen = menu.get_screen ();
		Gdk.Window window = this.get_window ();
		int monitor_num = screen.get_monitor_at_window (window);
		if (monitor_num < 0)
			monitor_num = 0;
		Gdk.Rectangle monitor = screen.get_monitor_workarea (monitor_num);
		this.get_allocation (out allocation);
		this.get_allocation (out arrow_allocation);
		menu.get_allocation (out menu_allocation);

		window.get_origin (out x, out y);
		x += allocation.x;
		y += allocation.y;

		if (_up && (y - menu_allocation.height >= monitor.y)) {
			y -= menu_allocation.height;
		} else {
			if ((y + arrow_allocation.height + menu_allocation.height) <= monitor.y + monitor.height)
				y += arrow_allocation.height;
			else if ((y - menu_allocation.height) >= monitor.y)
				y -= menu_allocation.height;
			else if (monitor.y + monitor.height - (y + arrow_allocation.height) > y)
				y += arrow_allocation.height;
			else
				y -= menu_allocation.height;
		}

		if (allocation.width > menu_allocation.width)
			menu.width_request = allocation.width;
		push_in = false;
	}
}

