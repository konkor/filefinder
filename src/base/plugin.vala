/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * pluging.vala
 * Copyright (C) 2016 kapa <kkorienkov <at> gmail.com>
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

public class Plugin : GLib.Object {
	private string _uuid;
	public Plugin (string name, string desc, string plug_uri, string key, bool def) {
		_uuid = "";
		
		label = name;
		description = desc;
		hotkey = key;
		uri = plug_uri;
		default_action = def;

		if (key.length > 0) {
			_uuid = ((uint)this).to_string ();
			SimpleAction simple_action = new SimpleAction (_uuid, null);
			simple_action.activate.connect (hotkey_cb);
			Filefinder.self.add_action (simple_action);
			Filefinder.self.set_accels_for_action ("app." + _uuid, {hotkey});
		}
	}

	public string label {get;set;}

	public string description {get;set;}

	public string uri {get;set;}

	public bool default_action {get;set;}

	public bool sync {get;set;default=false;}

	public string hotkey {get;set;default="";}

	private void hotkey_cb (SimpleAction action, Variant? parameter) {
		if (Filefinder.window == null) return;
		try {
			Filefinder.window.result_view.launch (this);
		} catch (Error e) {
			Debug.error (label, e.message);
		}
	}

	protected override void dispose () {
		if (_uuid.length > 0)
			Filefinder.self.remove_action (_uuid);
		base.dispose ();
	}
}
