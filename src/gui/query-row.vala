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

	public FilterLocation location;
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

	private FilterText text;
	private Gtk.Entry text_entry;
	private Gtk.CheckButton text_case;

	private FilterBin bin;
	private Gtk.Entry bin_entry;

	private FilterSize size;

	private void create_type_widgets () {
		int i = 0;
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
					mime.add (s);
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
			case types.SIZE:
				size = new FilterSize ();
				_filter.filter_value = size;
				Gtk.ComboBoxText size_combo = new Gtk.ComboBoxText ();
				foreach (string s in date_operators) {
					size_combo.append_text (s);
				}
				size_combo.active = size.operator;
				size_combo.changed.connect (() => {
					size.operator =(date_operator) size_combo.active;
				});
				hbox.pack_start (size_combo, false, false, 0);

				Gtk.SpinButton size_btn = new Gtk.SpinButton.with_range (0, uint64.MAX, 1024);
				hbox.pack_start (size_btn, true, true, 0);

				Gtk.ComboBoxText w_combo = new Gtk.ComboBoxText ();
				foreach (string s in new string[] {"Bytes", "KiB", "MiB", "GiB"}) {
					w_combo.append_text (s);
				}
				w_combo.active = 0;
				hbox.pack_start (w_combo, false, false, 0);
				w_combo.changed.connect (() => {
					size.size = (uint64) size_btn.get_value () *
										size.WEIGHT[w_combo.active];
				});

				size_btn.value_changed.connect (()=>{
					size.size = (uint64) size_btn.get_value () *
										size.WEIGHT[w_combo.active];
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
					cal.month = modified.date.get_month () - 1;
					cal.day = modified.date.get_day_of_month ();
					cal.day_selected.connect (()=>{
						modified.date = new DateTime.local (cal.year, cal.month+1, cal.day, 0, 0, 0);
						mod_btn.label = "%04d-%02d-%02d".printf (cal.year, cal.month+1, cal.day);
					});
					pop.add (cal);
					pop.show_all ();
				});
				break;
			case types.TEXT:
				text = new FilterText ();
				_filter.filter_value = text;
				text_entry = new Gtk.Entry ();
				hbox.pack_start (text_entry, true, true, 0);
				text_entry.changed.connect (()=>{
					text.text = text_entry.text;
				});

				Gtk.ComboBoxText text_combo = new Gtk.ComboBoxText ();
				i = 0;
				foreach (string s in Text.encodings) {
					text_combo.append_text (s);
					if (s == "UTF-8")
						text_combo.active = i;
					i++;
				}
				text_combo.changed.connect (() => {
					text.encoding = text_combo.get_active_text ();
				});
				text_combo.wrap_width = 4;
				hbox.pack_start (text_combo, false, false, 0);

				text_case = new Gtk.CheckButton ();
				text_case.tooltip_text = "Case sensitive";
				hbox.add (text_case);
				text_case.toggled.connect (()=>{
					text.case_sensetive = text_case.active;
				});
				break;
			case types.BINARY:
				bin = new FilterBin ();
				_filter.filter_value = bin;
				hbox.pack_start (new Gtk.Label("0x"), false, false, 0);
				bin_entry = new Gtk.Entry ();
				hbox.pack_start (bin_entry, true, true, 0);
				bin_entry.changed.connect (()=>{
					bin_entry.text = check_hex (bin_entry.text);
					bin.bin = bin_entry.text;
				});
				bin_entry.focus_out_event.connect (()=>{
					if (bin_entry.text.length % 2 == 1)
						bin_entry.text = "0" + bin_entry.text;
					return false;
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

	private string check_hex (string txt) {
		string res = "";
		if (txt == null) return res;
		if (txt.length == 0) return res;
		string symb = "0123456789ABCDEF";
		unichar c = 0;
		int index = 0;
		for (int i = 0; txt.get_next_char (ref index, out c); i++) {
			if (symb.index_of (c.to_string ().up ()) == -1) {
				return res;
			}
			res += c.to_string ().up ();
		}
		return res;
	}

	public MimeGroup[] mime_type_groups = {
	MimeGroup (){ name = "Text File",
	mimes = { "text/plain",
		"text/x-authors",
		"text/x-changelog",
		"text/x-chdr",
		"text/x-copying",
		"text/x-csrc",
		"text/x-gettext-translation",
		"text/x-install",
		"text/x-log",
		"text/x-makefile",
		"text/x-markdown",
		"text/x-matlab",
		"text/x-microdvd",
		"text/x-tex",
		"text/x-vala"
	}
	},
	MimeGroup (){ name = "Archive",
	mimes = { "application/x-compressed-tar",
		"application/x-xz-compressed-tar"
	}
	},
	MimeGroup (){ name = "Temporary",
	mimes = { "application/x-trash"
	}
	},
	MimeGroup (){ name = "Development",
	mimes = { "application/x-anjuta",
		"application/x-desktop",
		"application/x-archive",
		"application/x-executable",
		"application/x-sharedlib",
		"application/x-shared-library-la",
		"application/x-gettext-translation",
		"application/x-glade",
		"application/x-gtk-builder",
		"application/x-m4",
		"application/xml",
		"application/x-object",
		"application/x-shellscript",
		"application/x-sqlite3",
		"text/x-authors",
		"text/x-changelog",
		"text/x-chdr",
		"text/x-copying",
		"text/x-csrc",
		"text/x-gettext-translation",
		"text/x-install",
		"text/x-log",
		"text/x-makefile",
		"text/x-markdown",
		"text/x-matlab",
		"text/x-microdvd",
		"text/x-tex",
		"text/x-vala"
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
		"application/x-lyx",
		"application/xml"
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
		"audio/x-pn-realaudio",
		"audio/x-mpegurl"
	}
	},
	MimeGroup (){ name = "Video",
	mimes = { "video/mp4",
		"video/3gpp",
		"video/mpeg",
		"video/quicktime",
		"video/vivo",
		"video/x-avi",
		"video/x-matroska",
		"video/x-mng",
		"video/x-ms-asf",
		"video/x-ms-wmv",
		"video/x-msvideo",
		"video/x-nsv",
		"video/x-real-video"
	}
	},
	MimeGroup (){ name = "Subtitles",
	mimes = { "application/x-subrip",
		"text/x-ssa",
		"text/x-microdvd"
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
	MimeGroup (){ name = "Raw Image",
	mimes = { "image/x-canon-cr2",
		"image/x-panasonic-raw2"
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
