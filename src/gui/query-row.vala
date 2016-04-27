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

	private Filter _filter;
	public Filter filter {
		get {
			return _filter;
		}
	}

	public types row_type {
		get {
			return (types)combo_type.active;
		}
		set {
			combo_type.active = value;
		}
	}
	public QueryRow () {
		GLib.Object (orientation:Gtk.Orientation.HORIZONTAL, spacing:6);
		this.margin = 2;
		this.get_style_context ().add_class ("search-bar");
		_filter = new Filter ();

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

	private FilterLocation location;
	public Gtk.FileChooserButton chooser;
	private Gtk.CheckButton chk_rec;

	public FilterFiles files;
	public Gtk.Button files_btn;

	private FilterMime mime;
	private Gtk.ComboBoxText mime_group;
	private Gtk.ComboBoxText mime_type;

	private FilterMask mask;
	private Gtk.Entry mask_entry;
	private Gtk.CheckButton mask_case;

	private FilterModified modified;
	private Gtk.Button mod_btn;

	private void create_type_widgets () {
		//TODO additional widgets by type
		if (hbox != null) hbox.destroy ();
		hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 4);
		pack_start (hbox, true, true, 0);

		switch (combo_type.active) {
			case types.LOCATION:
				location = new FilterLocation ();
				_filter.filter_value = location;
				location.folder = Environment.get_home_dir ();
				chooser = new Gtk.FileChooserButton ("Select folder",
		    	                                     Gtk.FileChooserAction.SELECT_FOLDER);
				chooser.set_current_folder (location.folder);
				hbox.pack_start (chooser, true, true, 0);
				chooser.file_set.connect (()=>{ 
					location.folder = chooser.tooltip_text = chooser.get_filename ();
				});

				chk_rec = new Gtk.CheckButton ();
				chk_rec.tooltip_text = "Recursively";
				chk_rec.active = true;
				hbox.add (chk_rec);
				chk_rec.toggled.connect (()=>{
					location.recursive = chk_rec.active;
				});
				break;
			case types.FILES:
				files = new FilterFiles ();
				_filter.filter_value = files;
				files_btn = new Gtk.Button.from_icon_name ("document-open-symbolic", Gtk.IconSize.BUTTON);
				files_btn.label = "NONE";
				files_btn.always_show_image = true;
				files_btn.xalign = 0;
				hbox.pack_start (files_btn, true, true, 0);
				files_btn.clicked.connect (()=>{
					Gtk.FileChooserDialog c = new Gtk.FileChooserDialog ("Select files",
																		Filefinder.window,
																		Gtk.FileChooserAction.OPEN,
																		"_Cancel",
																		Gtk.ResponseType.CANCEL,
																		"_Open",
																		Gtk.ResponseType.ACCEPT);
					c.select_multiple = true;
					if (c.run () == Gtk.ResponseType.ACCEPT) {
						SList<string> uris = c.get_filenames ();
						files.clear ();
						foreach (unowned string uri in uris) {
							files.add (uri);
						}
						files_btn.label = uris.nth(0).data;
						if (uris.length() > 1)
							files_btn.label += " ... (%u selected items)".printf (uris.length());
					}
					c.close ();
				});				
				break;
			case types.MIMETYPE:
				mime = new FilterMime ();
				_filter.filter_value = mime;
				mime_group = new Gtk.ComboBoxText ();
				foreach (MimeGroup s in mime_type_groups) {
					mime_group.append_text (s.name);
				}
				mime_group.active = 0;
				hbox.add (mime_group);
				mime_group.changed.connect (() => {
					mime.clear ();
					mime_type.remove_all ();
					mime_type.append_text ("Any");
					foreach (string s in mime_type_groups[mime_group.active].mimes) {
						mime_type.append_text (s);
						mime.add (s);
					}
					mime_type.active = 0;
				});

				mime_type = new Gtk.ComboBoxText ();
				mime_type.append_text ("Any");
				foreach (string s in mime_type_groups[0].mimes) {
					mime_type.append_text (s);
				}
				mime_type.active = 0;
				mime_type.changed.connect (() => {
					mime.clear ();
					if (mime_type.active == 0) {
						foreach (string s in mime_type_groups[mime_group.active].mimes) {
							mime.add (s);
						}
					} else {
						mime.add (mime_type.get_active_text ());
					}
				});
				hbox.pack_start (mime_type, true, true, 6);
				mime_type.expand = false;
				break;
			case types.FILEMASK:
				mask = new FilterMask ();
				_filter.filter_value = mask;
				mask_entry = new Gtk.Entry ();
				hbox.pack_start (mask_entry, true, true, 0);
				mask_entry.changed.connect (()=>{
					mask.mask = mask_entry.text;
				});

				mask_case = new Gtk.CheckButton ();
				mask_case.tooltip_text = "Case sensitive";
				hbox.add (mask_case);
				mask_case.toggled.connect (()=>{
					mask.case_sensetive = mask_case.active;
				});
				break;
			case types.MODIFIED:
				modified = new FilterModified ();
				_filter.filter_value = modified;
				Gtk.ComboBoxText mod_combo = new Gtk.ComboBoxText ();
				foreach (string s in date_operators) {
					mod_combo.append_text (s);
				}
				mod_combo.active = modified.operator;
				mod_combo.changed.connect (() => {
					modified.operator =(date_operator) mod_combo.active;
				});
				hbox.pack_start (mod_combo, false, false, 0);

				mod_btn = new Gtk.Button ();
				mod_btn.label = "%04d-%02d-%02d".printf (modified.date.get_year(),
				                                         modified.date.get_month(),
				                                         modified.date.get_day_of_month());
				hbox.pack_start (mod_btn, false, true, 6);
				mod_btn.clicked.connect (()=>{
					Gtk.Popover pop = new Gtk.Popover (mod_btn);
					Gtk.Calendar cal = new Gtk.Calendar ();
					cal.year = modified.date.get_year ();
					cal.month = modified.date.get_month ();
					cal.day = modified.date.get_day_of_month ();
					cal.day_selected.connect (()=>{
						modified.date = new DateTime.local (cal.year, cal.month, cal.day, 0, 0, 0);
						mod_btn.label = "%04d-%02d-%02d".printf (cal.year, cal.month, cal.day);
					});
					pop.add (cal);
					pop.show_all ();
				});

				break;
			default:
				_filter.filter_type = types.NONE;
				Gtk.Label label = new Gtk.Label ("none");
				hbox.add (label);
				break;
		}

		hbox.show_all ();
	 }


	 public MimeGroup[] mime_type_groups = {
	MimeGroup (){ name = "Text File",
	  mimes = { "text/plain"
	  }
	},
	MimeGroup (){ name = "Documents",
	  mimes = { "application/rtf",
	    "application/msword",
	    "application/vnd.sun.xml.writer",
	    "application/vnd.sun.xml.writer.global",
	    "application/vnd.sun.xml.writer.template",
	    "application/vnd.oasis.opendocument.text",
	    "application/vnd.oasis.opendocument.text-template",
	    "application/x-abiword",
	    "application/x-applix-word",
	    "application/x-mswrite",
	    "application/docbook+xml",
	    "application/x-kword",
	    "application/x-kword-crypt",
	    "application/x-lyx"
	  }
	},
	MimeGroup (){ name = "Music",
	  mimes = { "application/ogg",
	    "audio/x-vorbis+ogg",
	    "audio/ac3",
	    "audio/basic",
	    "audio/midi",
	    "audio/x-flac",
	    "audio/mp4",
	    "audio/mpeg",
	    "audio/x-mpeg",
	    "audio/x-ms-asx",
	    "audio/x-pn-realaudio"
	  }
	},
	MimeGroup (){ name = "Video",
	  mimes = { "video/mp4",
	    "video/3gpp",
	    "video/mpeg",
	    "video/quicktime",
	    "video/vivo",
	    "video/x-avi",
	    "video/x-mng",
	    "video/x-ms-asf",
	    "video/x-ms-wmv",
	    "video/x-msvideo",
	    "video/x-nsv",
	    "video/x-real-video"
	  }
	},
	MimeGroup (){ name = "Picture",
	  mimes = { "application/vnd.oasis.opendocument.image",
	    "application/x-krita",
	    "image/bmp",
	    "image/cgm",
	    "image/gif",
	    "image/jpeg",
	    "image/jpeg2000",
	    "image/png",
	    "image/svg+xml",
	    "image/tiff",
	    "image/x-compressed-xcf",
	    "image/x-pcx",
	    "image/x-photo-cd",
	    "image/x-psd",
	    "image/x-tga",
	    "image/x-xcf"
	  }
	},
	MimeGroup (){ name = "Illustration",
	  mimes = { "application/illustrator",
	    "application/vnd.corel-draw",
	    "application/vnd.stardivision.draw",
	    "application/vnd.oasis.opendocument.graphics",
	    "application/x-dia-diagram",
	    "application/x-karbon",
	    "application/x-killustrator",
	    "application/x-kivio",
	    "application/x-kontour",
	    "application/x-wpg"
	  }
	},
	MimeGroup (){ name = "Spreadsheet",
	  mimes = { "application/vnd.lotus-1-2-3",
	    "application/vnd.ms-excel",
	    "application/vnd.stardivision.calc",
	    "application/vnd.sun.xml.calc",
	    "application/vnd.oasis.opendocument.spreadsheet",
	    "application/x-applix-spreadsheet",
	    "application/x-gnumeric",
	    "application/x-kspread",
	    "application/x-kspread-crypt",
	    "application/x-quattropro",
	    "application/x-sc",
	    "application/x-siag"
	  }
	},
	MimeGroup (){ name = "Presentation",
	  mimes = { "application/vnd.ms-powerpoint",
	    "application/vnd.sun.xml.impress",
	    "application/vnd.oasis.opendocument.presentation",
	    "application/x-magicpoint",
	    "application/x-kpresenter"
	  }
	},
	MimeGroup (){ name = "PDF / PostScript",
	  mimes = { "application/pdf",
	    "application/postscript",
	    "application/x-dvi",
	    "image/x-eps"
	  }
	}
};

}

public struct MimeGroup {
	public string name;
	public string[] mimes;
} 



