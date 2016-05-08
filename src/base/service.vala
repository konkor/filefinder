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

public class Service : Gtk.TreeStore {
	private signal void finished_thread ();
	public signal void finished_search ();

	static const string ATTRIBUTES =
        FileAttribute.STANDARD_NAME + "," +
        FileAttribute.STANDARD_DISPLAY_NAME + "," +
        FileAttribute.STANDARD_TYPE + "," +
        FileAttribute.STANDARD_SIZE +  "," +
		FileAttribute.STANDARD_CONTENT_TYPE +  "," +
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

	public Service () {
		threading = Thread.supported ();
		threading = false;
		cancellable = new Cancellable();
		scan_error = null;
		set_column_types (new Type[] {
			typeof (string), // NAME
			typeof (uint64), // SIZE
			typeof (int),    // TYPE
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
			if (this.thread_count < 1)
				finished_search ();
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

			process_result_idle = Timeout.add (200, () => {
				bool res = process_results();
				if (!res) {
					process_result_idle = 0;
				}
				return res;
			});
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
			foreach (unowned Results results in results_array.results) {
				//print ("%s %ju\n", results.display_name, results.size);
				i++;
				ensure_iter_exists (results);

				set (results.iter,
					Columns.SIZE,       results.size);

				if (results.error != null) {
					if (results.error is IOError.CANCELLED) {
						scan_error = results.error;
						finished_thread ();
						if (this.thread_count == 0) {
							return false;
						}
					} else if (scan_error != null) {
						scan_error = results.error;
					}
				}

				if (results_array.first && (results_array.results.length == i)) {
					finished_thread ();
					if (this.thread_count == 0) {
						successful = true;
						return false;
					}
				}
			}
		}
		return this.self != null;
	}

	void ensure_iter_exists (Results results) {
		if (results.iter_is_set) {
			return;
		}

		append (out results.iter, null);
		set (results.iter,
			Columns.DISPLAY_NAME, results.display_name,
			Columns.TIME_MODIFIED,results.time_modified,
			Columns.PATH,results.path,
			Columns.POSITION,results.position,
		    Columns.TYPE,results.type,
		    Columns.MIME,results.mime,
		    Columns.POSITION,results.position,
		    Columns.ROW,results.row);
		results.iter_is_set = true;
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

	/*private void get_files () {
		Debug.info ("started search", "");
		uint64 c = 0;
		foreach (FilterLocation p in query.locations) {
			list_dir (p);
		}
		//Debug.info ("finished search", "");
		DateTime de = new DateTime.now_local();
		Debug.info ("search", "duration %ju counted %ju".printf (de.difference(d), c));
		finished_search ();
	}*/

	void list_dir (FilterLocation loc, bool first = true) {
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
			if (info.get_file_type () == FileType.REGULAR) {
				Results res = apply_masks (info, dir.get_path ());
				if (res != null) {
					//on_found_file (info);
					results_array.results += (owned) res;
					results_queue.push ((owned) results_array);
					return;
				} else {
					return;
				}
			} else if (!info.get_attribute_boolean (FileAttribute.ACCESS_CAN_READ)){
				return;
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
						// check if we've already encountered this node
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
							//on_found_file (info);
							res.path = loc.folder;
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
		/*if (last) {
			DateTime de = new DateTime.now_local();
			Debug.info ("search", "duration %ju counted %ju".printf (de.difference(d), c));
		}*/
		results_array.first = first;
		results_queue.push ((owned) results_array);
		return;
	}

	private Results? apply_masks (FileInfo info, string? path) {
		bool flag = true;
		string fname = info.get_display_name ();
		string fmask;
		int64 fsize = info.get_size ();
		string fmime = info.get_content_type ();
		DateTime d;
		int64 t = (int64) info.get_modification_time ().tv_sec;
		//info.get_attribute_uint64 (FileAttribute.TIME_MODIFIED);
		Results? results = null;
		if (!query.apply_masks) {
			results = new Results ();
			results.display_name = fname;
			results.time_modified = info.get_attribute_uint64 (FileAttribute.TIME_MODIFIED);
			results.size = fsize;
			results.mime = fmime;
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
			results = get_text_pos (info, path);
			if (results == null) {
				return null;
			} else {
				flag = true;
			}
		}

		if (results == null)
			results = new Results ();
		results.display_name = info.get_display_name ();
		//results.parse_name = info.get_parse_name ();
		results.time_modified = info.get_attribute_uint64 (FileAttribute.TIME_MODIFIED);
		results.size = fsize;
		results.mime = fmime;
		results.type = info.get_file_type();

		return results;
	}

	Results? get_text_pos (FileInfo info, string? path) {
		Results? res = null;
		if ((path == null) || (info == null))
			return res;
		File file = File.new_for_path (GLib.Path.build_filename (path, info.get_name ()));

		if (!file.query_exists ()) {
			return res;
		}

		try {
			string contents, s, mask;
			size_t length;
			int pos = 0;
			if (FileUtils.get_contents (GLib.Path.build_filename (path, info.get_name ()),
			                  out contents, out length)) {
				/*if (line.length >= 4096) {
					return null;
				}*/
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
							res.row = convert_to (line, f.encoding);;
							return res;
						}
					}
					pos++;
				}
				/*foreach (FilterText f in query.texts) {
					if (f.text.length > contents.length)
						return null;
					if (!f.case_sensetive) {
						s = contents.up ();
						mask = f.text.up ();
					} else {
						s = contents;
						mask = f.text;
					}
					s = convert_to (s, f.encoding);
					if (s.contains (mask)) {
						res = new Results ();
						pos = s.index_of (mask);
						res.position = pos;
						//res.row = s.substring (pos, s.index_of ("\0", pos));
						return res;
					}
				}*/
			}
			/*DataInputStream dis = new DataInputStream (file.read ());
			string line, s, enc, mask;
			int64 pos = 0;
			while ((line = dis.read_line (null)) != null) {
				if (line.length >= 4096) {
					return null;
				}
				foreach (FilterText f in query.texts) {
					if (!f.case_sensetive) {
						s = line.up ();
						mask = f.text.up ();
					} else {
						s = line;
						mask = f.text;
					}
					//enc = convert_to (s, f.encoding);
					if (s.contains (mask)) {
						res = new Results ();
						res.position = pos;
						res.row = line;
						return res;
					}
				}
				pos++;
			}*/
		} catch (Error err) {
			return null;
		}
		return res;
	}

	public string convert_to (string str, string enc) throws ConvertError {
        string s = str;
        if (enc.length == 0) return s;
        if (enc != "UTF-8") {
            try {
                s = convert (s, -1, enc, "UTF-8");
            } catch (ConvertError err) {
				throw new ConvertError.FAILED ("Converting error");
            }
        } else {
            return s;
        }
        return s;
    }

	[Compact]
    class ResultsArray {
		internal bool first = false;
        internal Results[] results;
    }

    [Compact]
    class Results {
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