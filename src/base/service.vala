/* -*- Mode: vala; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * service.vala
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

public class Service : Gtk.ListStore {
	private signal void finished_thread ();
	public signal void finished_search ();

	static const string ATTRIBUTES = "standard," +
		FileAttribute.TIME_MODIFIED + "," +
		FileAttribute.UNIX_NLINK + "," +
		FileAttribute.UNIX_INODE + "," +
		FileAttribute.UNIX_DEVICE + "," +
		FileAttribute.ACCESS_CAN_READ;

	struct HardLink {
		uint64 inode;
		uint32 device;

		public HardLink (FileInfo info) {
			this.inode = info.get_attribute_uint64 (FileAttribute.UNIX_INODE);
			this.device = info.get_attribute_uint32 (FileAttribute.UNIX_DEVICE);
		}
	}

	Thread<void*>? thread = null;
	List<Thread<void*>> thread_list;
	uint process_result_idle = 0;

	private int mutex { get; set; }
	HardLink[] hardlinks;
	GenericSet<File> excluded_locations;

	bool successful = false;
	AsyncQueue<ResultsArray> results_queue;
	Service? self;
	Cancellable cancellable;
	Error? scan_error;

	private Query query;
	private bool threading;
	private const int MAX_THREAD = 4;
	private int thread_count;
	private DateTime d;
	
	public Results results_all;

	public Service () {
		threading = Thread.supported ();
		threading = false;
		cancellable = new Cancellable();
		scan_error = null;
		set_column_types (new Type[] {
			typeof (string), // NAME
			typeof (uint64), // SIZE
			typeof (int),	// TYPE
			typeof (uint64), // TIME_MODIFIED
			typeof (string), // PERMISSIONS
			typeof (string), // MIME
			typeof (string), // PATH
			typeof (int64),  // OFFSET/ROW
			typeof (string)  // ROW
		});
		this.finished_thread.connect (()=>{
			this.thread_count--;
			print ("thread_count %d\n", thread_count);
			if (this.thread_count < 1) {
				finished_search ();
			}
		});
	}

	private void init () {
		base.clear ();
		thread_count = 0;
		thread_list = new List<Thread<void*>>();
		results_queue = new AsyncQueue<ResultsArray> ();

		excluded_locations = Filefinder.get_excluded_locations ();
		assert_null (Filefinder.preferences);
		if (Filefinder.preferences.check_mounts) {
			foreach (unowned UnixMountEntry mount in UnixMountEntry.get (null)) {
				excluded_locations.add (File.new_for_path (mount.get_mount_path ()));
			}
		}
		foreach (string mount in Filefinder.preferences.get_user_excluded ()) {
			excluded_locations.add (File.new_for_path (mount));
		}
		foreach (FilterLocation f in query.locations) {
			excluded_locations.remove (File.new_for_path (f.folder));
		}
		
		results_all = new Results ();
		results_all.position = 0;
	}

	public void start (Query q) {
		if (q == null) return;
		this.query = q;
		init ();
		d = new DateTime.now_local();
		scan (true);
	}

	public void scan (bool force) {
		if (force) {
			successful = false;
		}
		if (!successful) {
			cancel_and_reset ();
			// the thread owns a reference on the Scanner object
			this.self = this;

			foreach (FilterLocation p in query.locations) {
				thread = new Thread<void*> ("scanner" + thread_count.to_string (),
											scan_in_thread);
				thread_list.append (thread);
				thread_count++;
				Thread.usleep (200000);
			}

			foreach (string s in query.files) {
				get_file (s);
			}

			process_result_idle = Timeout.add (200, () => {
				bool res = process_results();
				if (!res) {
					process_result_idle = 0;
				}
				return res;
			});

			if (thread_count == 0)
				finished_search ();
		} else {
			finished_search ();
		}
	}

	void* scan_in_thread () {
		Debug.info ("scaner", "thread %d".printf (this.thread_count));
		list_dir (query.locations.nth_data (this.thread_count-1));
		this.self = null;
		return null;
	}

	bool process_results () {
		uint i;
		while (true) {
			var results_array = results_queue.try_pop ();

			if (results_array == null) {
				break;
			}

			i = 0;
			//print ("count %u\n", results_array.results.length);
			//base_array.results += unowned results_array.results;
			foreach (unowned Results results in results_array.results) {
				//print ("%s %ju\n", results.display_name, results.size);
				i++;
				ensure_iter_exists (results);

				//set (results.iter, Columns.SIZE, results.size);
				/*Results res = new Results ();
				res.display_name = results.display_name;
				res.time_modified = results.time_modified;
				res.size = results.size;
				res.mime = results.mime;
				res.type = results.type;
				base_array.results += (owned) res;*/

				if (results.error != null) {
					if (results.error is IOError.CANCELLED) {
						scan_error = results.error;
						finished_thread ();
						if (this.thread_count < 1) {
							return false;
						}
					} else if (scan_error != null) {
						scan_error = results.error;
					}
				}


			}
			if (results_array.first) {
				finished_thread ();
				if (this.thread_count < 1) {
					successful = true;
					return false;
				}
			}
		}
		return this.self != null;
	}

	void ensure_iter_exists (Results results) {
		if (results.iter_is_set) {
			return;
		}
		insert_after (out results.iter, null);
		set (results.iter,
			Columns.DISPLAY_NAME, results.display_name,
			Columns.SIZE, results.size,
			Columns.TIME_MODIFIED,results.time_modified,
			Columns.PATH,results.path,
			Columns.POSITION,results.position,
			Columns.TYPE,results.type,
			Columns.MIME,results.mime,
			Columns.POSITION,results.position,
			Columns.ROW,results.row);
		results.iter_is_set = true;

		if (results_all.position == 0) {
			results_all.display_name = results.display_name;
			results_all.time_modified = results.time_modified;
			results_all.size = results.size;
			results_all.mime = results.mime;
			results_all.type = results.type;
			results_all.path = results.path;
			results_all.position = 1;
		} else {
			if (results_all.display_name != results.display_name)
				results_all.display_name = "--";
			if (results_all.path != results.path)
				results_all.path = "--";
			if (results_all.type != results.type)
				results_all.type = 0;
			if (results_all.mime != results.mime)
				results_all.mime = "--";
			if (results_all.time_modified != results.time_modified)
				results_all.time_modified = 0;
			results_all.size += results.size;
			results_all.position++;
		}
	}

	public void cancel () {
		if (!successful) {
			cancel_and_reset ();
		}
	}

	private void cancel_and_reset () {
		cancellable.cancel ();


		foreach (Thread<void*> p in thread_list)
		if (p != null) {
			p.join ();
			p = null;
		}
		thread_list = null;

		if (process_result_idle != 0) {
			GLib.Source.remove (process_result_idle);
			process_result_idle = 0;
		}
		// Drain the async queue
		var tmp = results_queue.try_pop ();
		while (tmp != null) {
			tmp = results_queue.try_pop ();
		}

		hardlinks = null;

		//base.clear ();

		cancellable.reset ();
		scan_error = null;
	}

	private void get_file (string path) {
		FileInfo info;
		File dir = File.new_for_path (path);
		if (!dir.query_exists ()) return;
		try {
			info = dir.query_info ("*", 0);
			if (info.get_is_symlink ()) {
				dir = File.new_for_path (Posix.realpath (path));
				info = dir.query_info ("*", 0);
			}
			if (dir in excluded_locations) {
				return;
			}
			if (!info.get_attribute_boolean (FileAttribute.ACCESS_CAN_READ)){
				return;
			}
			if (info.get_file_type () == FileType.REGULAR) {
				Results res = apply_masks (info, dir.get_path ().substring (0, dir.get_path ().last_index_of ("/")));
				if (res != null) {
					ensure_iter_exists (res);
				}
			}
		} catch (Error err) {
			Debug.error ("get_file", err.message + " " + path);
		} 
	}

	private void list_dir (FilterLocation loc, bool first = true) {
		FileInfo info;
		var results_array = new ResultsArray ();
		var dir = File.new_for_path (loc.folder);
		if (!dir.query_exists ()) return;
		try {
			info = dir.query_info ("*", 0);
			if (info.get_is_symlink ()) {
				loc.folder = Posix.realpath (loc.folder);
				dir = File.new_for_path (loc.folder);
				info = dir.query_info ("*", 0);
			}
			if (dir in excluded_locations) {
				return;
			}
			if (!info.get_attribute_boolean (FileAttribute.ACCESS_CAN_READ)){
				return;
			}
			if (info.get_file_type () == FileType.REGULAR) {
				Results res = apply_masks (info, dir.get_path ());
				if (res != null) {
					results_array.results += (owned) res;
					results_queue.push ((owned) results_array);
					return;
				} else {
					return;
				}
			}
			var e = dir.enumerate_children (ATTRIBUTES,
											Filefinder.preferences.follow_links,
											cancellable);
			while ((info = e.next_file (cancellable)) != null) {
				if (Filefinder.preferences.check_hidden) {
					if (info.get_name ().has_prefix ("."))
						continue;
				}
				if (Filefinder.preferences.check_backup) {
					if (info.get_is_backup ())
						continue;
				}
				if (info.has_attribute (FileAttribute.UNIX_NLINK)) {
					if (info.get_attribute_uint32 (FileAttribute.UNIX_NLINK) > 1) {
						var hl = HardLink (info);
						lock (mutex) {
							if (hl in hardlinks) {
								continue;
							}
							hardlinks += hl;
						}
					}
				}
				switch (info.get_file_type ()) {
					case FileType.DIRECTORY:
						if (loc.recursive) {
							var l = new FilterLocation ();
							l.folder = GLib.Path.build_filename (loc.folder, info.get_name ());
							l.recursive = true;
							list_dir (l, false);
						}
						break;
					case FileType.REGULAR:
						Results res = apply_masks (info, loc.folder);
						if (res != null) {
							results_array.results += (owned) res;
						}
						break;
					default:
						break;
				}
			}
		} catch (Error err) {
			Debug.error ("list_dir", err.message + " " + loc.folder);
			//results.error = err;
		}
		results_array.first = first;
		results_queue.push ((owned) results_array);
		return;
	}

	private Results? apply_masks (FileInfo info, string path) {
		bool flag = true;
		string fname = info.get_display_name ();
		string fmask;
		int64 fsize = info.get_size ();
		string fmime = info.get_content_type ();
		DateTime d;
		int64 t = (int64) info.get_modification_time ().tv_sec;
		Results? results = null;
		if (!query.apply_masks) {
			results = new Results ();
			results.display_name = info.get_name ();
			results.path = path;
			results.time_modified = info.get_attribute_uint64 (FileAttribute.TIME_MODIFIED);
			results.size = fsize;
			results.mime = fmime;
			if (info.get_is_symlink())
				results.type = (FileType) 3;
			else
				results.type = info.get_file_type();
			return results;
		}
		//Maybe we want to find directories too...
		//if (info.get_file_type () == FileType.REGULAR) {
		foreach (FilterSize f in query.sizes) {
			switch (f.operator) {
				case date_operator.NOT_EQUAL:
					if (fsize != f.size) {
						flag = true;
					} else {
						return null;
					}
					break;
				case date_operator.EQUAL:
					if (fsize == f.size) {
						flag = true;
					} else {
						return null;
					}
					break;
				case date_operator.LESS:
					if (fsize < f.size) {
						flag = true;
					} else {
						return null;
					}
					break;
				case date_operator.MORE:
					if (fsize > f.size) {
						flag = true;
					} else {
						return null;
					}
					break;
				case date_operator.LESS_EQUAL:
					if (fsize <= f.size) {
						flag = true;
					} else {
						return null;
					}
					break;
				case date_operator.MORE_EQUAL:
					if (fsize >= f.size) {
						flag = true;
					} else {
						return null;
					}
					break;
			}
		}

		foreach (FilterModified f in query.modifieds) {
			switch (f.operator) {
				case date_operator.NOT_EQUAL:
					d = f.date.add_full (0,0,0,23,59,59.999999);
					if ((t < f.date.to_unix()) || (t > d.to_unix())) {
						flag = true;
					} else {
						return null;
					}
					break;
				case date_operator.EQUAL:
					d = f.date.add_full (0,0,0,23,59,59.999999);
					if ((t >= f.date.to_unix()) && (t <= d.to_unix())) {
						flag = true;
					} else {
						return null;
					}
					break;
				case date_operator.LESS:
					if (t < f.date.to_unix()) {
						flag = true;
					} else {
						return null;
					}
					break;
				case date_operator.MORE:
					d = f.date.add_full (0,0,1,0,0,0);
					if (t >= d.to_unix()) {
						flag = true;
					} else {
						return null;
					}
					break;
				case date_operator.LESS_EQUAL:
					d = f.date.add_full (0,0,1,0,0,0);
					if (t <= d.to_unix()) {
						flag = true;
					} else {
						return null;
					}
					break;
				case date_operator.MORE_EQUAL:
					if (t >= f.date.to_unix()) {
						flag = true;
					} else {
						return null;
					}
					break;
			}
		}

		bool mflag = false;
		if (query.mimes.length () > 0) {
			//print ("%s - %s\n", info.get_content_type (), fname);
			foreach (string s in query.mimes) {
				if (s == fmime) {
					mflag = true;
					break;
				}
			}
			if (!mflag) {
				return null;
			}
		}

		foreach (FilterMask f in query.masks) {
			fmask = f.mask;
			if (!f.case_sensetive) {
				fname = fname.up ();
				fmask = fmask.up ();
			}
			if (fname.contains (fmask) == false){
				flag = false;
			} else {
				flag = true;
				break;
			}
		}

		if (!flag) return null;

		if (query.texts.length () > 0) {
			flag = false;
			results = get_text_result (info, path);
			if (results == null) {
				return null;
			} else {
				flag = true;
			}
		}

		if (results == null) {
			if (query.bins.length () > 0) {
				flag = false;
				results = get_bin_result (info, path);
				if (results == null) {
					return null;
				} else {
					flag = true;
				}
			}
		}

		if (results == null)
			results = new Results ();
		results.display_name = info.get_name ();//.get_display_name ();
		results.path = path;
		//results.parse_name = info.get_parse_name ();
		results.time_modified = info.get_attribute_uint64 (FileAttribute.TIME_MODIFIED);
		results.size = fsize;
		results.mime = fmime;
		if (info.get_is_symlink())
			results.type = (FileType) 3;
		else
			results.type = info.get_file_type();

		return results;
	}

	Results? get_text_result (FileInfo info, string? path) {
		Results? res = null;
		if ((path == null) || (info == null)) return res;
		File file = File.new_for_path (GLib.Path.build_filename (path, info.get_name ()));
		if (!file.query_exists ()) return res;
		uint64[] rows = {};
		Tokens[] tokens = {};
		foreach (FilterText f in query.texts) {
			if (f.text.length == 0) continue;
			Tokens t = new Tokens ();
			t.sensetive = f.case_sensetive;
			t.encoding = f.encoding;
			if (!f.is_utf8) {
				try {
					t.data = convert_to (f.text, f.encoding).data;
					t.data_up = convert_to (f.text.up(), f.encoding).data;
					t.data_down = convert_to (f.text.down (), f.encoding).data;
				} catch (ConvertError err) {
					Debug.error ("get_text_result", err.message);
					continue;
				}
			} else {
				t.data = f.text.data;
				t.data_up = f.text.up ().data;
				t.data_down = f.text.down ().data;
			}
			tokens += (owned) t;
		}
		if (tokens.length == 0) return res;

		uint8[] buffer = new uint8[8192];
		ssize_t	 count = 8192;
		bool sensetive;
		uint64 ind = 0, row_start, row_end;
		uint8[] row;
		string s;
		try {
			FileInputStream ios = file.read ();
			DataInputStream dis = new DataInputStream (ios);
			do {
				count = dis.read (buffer, cancellable);
				for (uint64 i = 0; i < count; i++) {
					foreach (unowned Tokens t in tokens) {
						if (buffer[i] == 10)
							rows += (ind + i + 1);
						if (t.sensetive)
							sensetive = t.data[t.cursor] == buffer[i];
						else
							sensetive = (t.data_up[t.cursor] == buffer[i]) ||
										(t.data_down[t.cursor] == buffer[i]);
						if (sensetive)
							t.cursor++;
						else
							t.cursor = 0;
						if (t.cursor == t.data.length) {
							//we have found token
							res = new Results ();
							res.position = rows.length + 1;
							row_end = i + 1;
							if (rows.length == 0) {
								row_start = 0;
							} else {
								if (rows[rows.length-1] < ind) {
									row_start = 0;
								} else {
									row_start = rows[rows.length-1] - ind;
								}
							}
							if ((row_end - row_start) < 100) {
								uint64 j = 0;
								for (j = 0; j < 100; j++) {
									if ((i + j) < count) {
										if (buffer[i + j] == 10) break;
									} else {
										break;
									}
								}
								row_end += j - 1;
							}
							row = buffer[row_start:row_end];
							row += 0;
							s = (string) row;
							try {
								s = convert_to (s, "UTF-8", t.encoding);
							} catch (ConvertError e) {
								Debug.error ("convert_to", e.message);
							}
							unichar c = 0;
							int char_ind = 0;
							res.row = "";
							for (int cnt = 0; s.get_next_char (ref char_ind, out c); cnt++) {
								if (c.isprint ()) res.row += c.to_string ();
							}
							return res;
						}
					}
				}
				ind += count;
			} while (count == 8192);
		} catch (Error err) {
			return null;
		}
		return res;
	}

	Results? get_bin_result (FileInfo info, string? path) {
		Results? res = null;
		if ((path == null) || (info == null)) return res;
		File file = File.new_for_path (GLib.Path.build_filename (path, info.get_name ()));
		if (!file.query_exists ()) return res;
		Tokens[] tokens = {};
		foreach (FilterBin f in query.bins) {
			if (f.bin.length == 0) continue;
			Tokens t = new Tokens ();
			var data = f.bin.data;
			for (int i = 0; i < data.length; i+=2) {
				char c = (char) data[i];
				int val1 = c.xdigit_value() << 4;
				c = (char) data[i+1];
				val1+= c.xdigit_value();
				t.data += (uint8) val1;
			}
			tokens += (owned) t;
		}
		if (tokens.length == 0) return res;

		uint8[] buffer = new uint8[65536];
		ssize_t	 count = 65536;
		uint64 ind = 0;
		try {
			FileInputStream ios = file.read ();
			DataInputStream dis = new DataInputStream (ios);
			do {
				count = dis.read (buffer, cancellable);
				for (uint64 i = 0; i < count; i++) {
					foreach (unowned Tokens t in tokens) {
						if (t.data[t.cursor] == buffer[i])
							t.cursor++;
						else
							t.cursor = 0;
						if (t.cursor == t.data.length) {
							//we have found token
							res = new Results ();
							res.position = (int64) (ind + i);
							var sb = new StringBuilder();
							foreach (uint8 u in t.data) {
								var str = "%02x".printf (u);
								sb.append (str);
							}
							res.row = (string) sb.data;
							res.row = "0x" + res.row.up();
							return res;
						}
					}
				}
				ind += count;
			} while (count == 65536);
		} catch (Error err) {
			return null;
		}
		return res;
	}

	//this method is longer it's need to load whole file in memory before search
	Results? get_text_pos (FileInfo info, string? path) {
		Results? res = null;
		if ((path == null) || (info == null)) return res;
		File file = File.new_for_path (GLib.Path.build_filename (path, info.get_name ()));
		if (!file.query_exists ()) {return res;}
		try {
			string contents, s, mask;
			size_t length;
			int pos = 1;
			if (FileUtils.get_contents (GLib.Path.build_filename (path, info.get_name ()),
							  out contents, out length)) {
				foreach (string line in contents.split_set ("\n")) {
					foreach (FilterText f in query.texts) {
						if (f.text.length > contents.length)
							return null;
						if (!f.case_sensetive) {
							s = line.up ();
							mask = f.text.up ();
						} else {
							s = line;
							mask = f.text;
						}
						s = convert_to (s, f.encoding);
						if (s.contains (mask)) {
							res = new Results ();
							res.position = pos;
							res.row = convert_to (line, f.encoding);
							return res;
						}
					}
					pos++;
				}
			}
		} catch (Error err) {
			return null;
		}
		return res;
	}

	public string convert_to (string str, string enc, string enc_from = "UTF-8") throws ConvertError {
		string s = str;
		if (enc.length == 0) return s;
		if (enc != enc_from) {
			try {
				s = convert (s, -1, enc, enc_from);
			} catch (ConvertError err) {
				throw new ConvertError.FAILED ("Converting error");
			}
		} else {
			return s;
		}
		return s;
	}

	[Compact]
	class Tokens {
		internal uint64 cursor = 0;
		internal bool sensetive;
		internal string encoding;
		internal uint8[] data;
		internal uint8[] data_up;
		internal uint8[] data_down;
	}

	[Compact]
	class ResultsArray {
		internal bool first = false;
		internal Results[] results;
	}

	[Compact]
	public class Results {
		internal int64 position = -1;
		internal string display_name;
		internal uint64 size;
		internal FileType type;
		internal uint64 time_modified;
		//internal string permission;
		internal string mime;
		internal string path;
		internal string row;

		internal Error? error;

		internal Gtk.TreeIter iter;
		internal bool iter_is_set;
	}
}

public enum State {
	SCANNING,
	CANCELLED,
	NEED_ROW,
	ERROR,
	CHILD_ERROR,
	DONE
}
