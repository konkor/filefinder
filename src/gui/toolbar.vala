/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * toolbar.vala
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

public class Toolbar : Gtk.ScrolledWindow {
	public signal void clicked (int index);

	private Gtk.FlowBox fbox;

	public Toolbar () {
		vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
		hscrollbar_policy = Gtk.PolicyType.NEVER;
		shadow_type = Gtk.ShadowType.NONE;
		get_style_context ().add_class ("primary-toolbar");

		//rebuild ();
		show_all ();
	}

	public void rebuild () {
		if (Filefinder.preferences == null) return;
		if (Filefinder.preferences.plugins.length () == 0) return;
		if (fbox != null) fbox.destroy ();
		fbox = new Gtk.FlowBox ();
		fbox.margin = 0;
		fbox.selection_mode = Gtk.SelectionMode.NONE;
		fbox.valign = Gtk.Align.START;
		//fbox.homogeneous = true;
		add (fbox);
		Gtk.Menu? sm = null;
		List<ToolButton> gm = new List<ToolButton>();
		int gi, j;
		int id = 0, length = 0;
		foreach (Plugin p in Filefinder.preferences.plugins) {
			if (Filefinder.preferences.toolbar_groups) {
				if (p.group.length == 0) {
					sm = null;
				} else {
					j = 0; gi = -1;
					foreach (ToolButton m in gm) {
						if (m.group == p.group) gi = j;
						j++;
					}
					if (gi == -1) {
						var group = new Plugin (p.group, p.group, "", "", false);
						group.group = p.group;
						var item = new ToolButton (group, -1);
						gm.append (item);
						fbox.insert (item, -1);
						length++;
						sm = new Gtk.Menu ();
						item.submenu = sm;
					} else {
						sm = gm.nth_data (gi).submenu;
					}
				}
			}
			var tb = new ToolButton (p, id);
			if (sm == null) {
				fbox.insert (tb, -1);
				length++;
			} else {
				sm.add (tb);
				sm.show_all ();
			}
			id++;
		}
		if (length > 0) {
			fbox.max_children_per_line = length;
		show_all ();
		} else {
			hide ();
		}
	}

	public static string get_accelerator_label (uint accelerator_key,
												Gdk.ModifierType accelerator_mods) {
		string gstring = "", mod_separator = "+";
		bool seen_mod = false;
		unichar ch;

		if ((accelerator_mods & Gdk.ModifierType.SHIFT_MASK) != 0) {
			gstring += "Shift";
			seen_mod = true;
		}
		if ((accelerator_mods & Gdk.ModifierType.CONTROL_MASK) != 0) {
			if (seen_mod)
				gstring += mod_separator;
			gstring += "Ctrl";
			seen_mod = true;
		}
		if ((accelerator_mods & Gdk.ModifierType.MOD1_MASK) != 0) {
			if (seen_mod)
				gstring += mod_separator;
			gstring += "Alt";
			seen_mod = true;
		}
		if ((accelerator_mods & Gdk.ModifierType.MOD2_MASK) != 0) {
			if (seen_mod)
				gstring += mod_separator;
			gstring += "Mod2";
			seen_mod = true;
		}
		if ((accelerator_mods & Gdk.ModifierType.MOD3_MASK) != 0) {
			if (seen_mod)
				gstring += mod_separator;
			gstring += "Mod3";
			seen_mod = true;
		}
		if ((accelerator_mods & Gdk.ModifierType.MOD4_MASK) != 0) {
			if (seen_mod)
				gstring += mod_separator;
			gstring += "Mod4";
			seen_mod = true;
		}
		if ((accelerator_mods & Gdk.ModifierType.MOD5_MASK) != 0) {
			if (seen_mod)
				gstring += mod_separator;
			gstring += "Mod5";
			seen_mod = true;
		}
		if ((accelerator_mods & Gdk.ModifierType.SUPER_MASK) != 0) {
			if (seen_mod)
				gstring += mod_separator;
			gstring += "Super";
			seen_mod = true;
		}
		if ((accelerator_mods & Gdk.ModifierType.HYPER_MASK) != 0) {
			if (seen_mod)
				gstring += mod_separator;
			gstring += "Hyper";
			seen_mod = true;
		}
		if ((accelerator_mods & Gdk.ModifierType.META_MASK) != 0) {
			if (seen_mod)
				gstring += mod_separator;
			//g_string_append (gstring, C_("keyboard label", "Meta"));
			/* Command key symbol U+2318 PLACE OF INTEREST SIGN */
			gstring += "\xe2\x8c\x98";
			seen_mod = true;
		}
		ch = Gdk.keyval_to_unicode (accelerator_key);
		if ((ch != 0) && ch < 0x80 && (ch.isgraph () || ch == ' ')) {
			if (seen_mod)
				gstring += mod_separator;
			switch (ch) {
			case ' ':
				gstring += "Space";
				break;
			case '\\':
				gstring += "Backslash";
				break;
			default:
				gstring += ch.toupper ().to_string();
				break;
			}
		} else {
			string tmp = Gdk.keyval_name (Gdk.keyval_to_lower (accelerator_key));
			if (tmp != null) {
				if (seen_mod)
					gstring += mod_separator;
				if (tmp[0] != 0 && tmp[1] == 0) {
					gstring += tmp[0].to_string().up();
				} else {
					gstring += tmp;
					// translated char
					/*string str;
					str = dpgettext2 (GETTEXT_PACKAGE, "keyboard label", tmp);
					if (str == tmp)
						append_without_underscores (gstring, tmp);
					else
						g_string_append (gstring, str);*/
				}
			}
		}
		return gstring;
	}
}

