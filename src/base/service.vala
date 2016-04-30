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
    uint process_result_idle = 0;

    HardLink[] hardlinks;
    GenericSet<File> excluded_locations;

    bool successful = false;
	AsyncQueue<ResultsArray> results_queue;
	Service? self;
	Cancellable cancellable;
	Error? scan_error;

	private List<string> files;
	public List<Result> results;
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
				typeof (uint64),  // OFFSET/ROW
                typeof (string),  // NAME
                typeof (uint64),  // SIZE
                typeof (uint64),  // TIME_MODIFIED
                typeof (int),     // ELEMENTS
                typeof (State),   // STATE
                typeof (Error)    // ERROR (if STATE is ERROR)
            });
		this.finished_thread.connect (()=>{
			this.thread_count--;
		});
	}

	private void init () {
		thread_count = 0;
		results = new List<Result> ();
		files = new List<string> ();

		excluded_locations = Filefinder.get_excluded_locations ();
        if (query.exclude_mounts) {
            foreach (unowned UnixMountEntry mount in UnixMountEntry.get (null)) {
                excluded_locations.add (File.new_for_path (mount.get_mount_path ()));
            }
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
		if (threading) {
			get_files_thread ();
		} else {
			get_files ();
		}
	}

	private void get_files () {
		Debug.info ("started search", "");
		uint64 c = 0;
		foreach (FilterLocation p in query.locations) {
			list_dir (p.folder, p.recursive,ref c);
		}
		//Debug.info ("finished search", "");
		DateTime de = new DateTime.now_local();
		Debug.info ("search", "duration %ju counted %ju".printf (de.difference(d), c));
		finished_search ();
	}

	Results? list_dir (string path, bool recursive,ref uint64 c) {
		bool last = true;
		var results = new Results ();
		var dir = File.new_for_path (path);
		if (!dir.query_exists ()) return null;
		if (dir in excluded_locations) {
			return null;
		}
	    try {
			if (dir.query_file_type (FileQueryInfoFlags.NONE) == FileType.REGULAR) {
				if (apply_masks (dir.query_info ("*", 0))) {
					on_found_file (dir.query_info ("*", 0));
				}
				return null;
			}
		    var e = dir.enumerate_children (ATTRIBUTES,
		                                    FileQueryInfoFlags.NONE,
		                                    cancellable);
			FileInfo info;
			while ((info = e.next_file (cancellable)) != null) {
				switch (info.get_file_type ()) {
					case FileType.DIRECTORY:
						if (recursive) {
							list_dir (path + Path.DIR_SEPARATOR_S + info.get_name (),
							          recursive,ref c);
							last = false;
						}
						break;
					case FileType.REGULAR:
						if (apply_masks (info)) {
							on_found_file (info);
						}
						break;
					default:
						break;
				}
				c++;
			}
		} catch (Error err) {
    		Debug.error ("list_dir", err.message + " " + path);
			//results.error = err;
		}
		/*if (last) {
			DateTime de = new DateTime.now_local();
			Debug.info ("search", "duration %ju counted %ju".printf (de.difference(d), c));
		}*/
		return results;
	}

	private bool apply_masks (FileInfo info) {
		bool flag = true;
		string fname = info.get_name ();
		string fmask;
		int64 fsize = info.get_size ();
		DateTime d;
		int64 t = (int64) info.get_modification_time ().tv_sec;

		//Maybe we want to find directories too...
		//if (info.get_file_type () == FileType.REGULAR) {
		foreach (FilterSize f in query.sizes) {
			switch (f.operator) {
				case date_operator.NOT_EQUAL:
					if (fsize != f.size) {
						flag = true;
					} else {
						return false;
					}
					break;
				case date_operator.EQUAL:
					if (fsize == f.size) {
						flag = true;
					} else {
						return false;
					}
					break;
				case date_operator.LESS:
					if (fsize < f.size) {
						flag = true;
					} else {
						return false;
					}
					break;
				case date_operator.MORE:
					if (fsize > f.size) {
						flag = true;
					} else {
						return false;
					}
					break;
				case date_operator.LESS_EQUAL:
					if (fsize <= f.size) {
						flag = true;
					} else {
						return false;
					}
					break;
				case date_operator.MORE_EQUAL:
					if (fsize >= f.size) {
						flag = true;
					} else {
						return false;
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
						return false;
					}
					break;
				case date_operator.EQUAL:
					d = f.date.add_full (0,0,0,23,59,59.999999);
					if ((t >= f.date.to_unix()) && (t <= d.to_unix())) {
						flag = true;
					} else {
						return false;
					}
					break;
				case date_operator.LESS:
					if (t < f.date.to_unix()) {
						flag = true;
					} else {
						return false;
					}
					break;
				case date_operator.MORE:
					d = f.date.add_full (0,0,1,0,0,0);
					if (t >= d.to_unix()) {
						flag = true;
					} else {
						return false;
					}
					break;
				case date_operator.LESS_EQUAL:
					d = f.date.add_full (0,0,1,0,0,0);
					if (t <= d.to_unix()) {
						flag = true;
					} else {
						return false;
					}
					break;
				case date_operator.MORE_EQUAL:
					if (t >= f.date.to_unix()) {
						flag = true;
					} else {
						return false;
					}
					break;
			}
		}

		string fmime = info.get_content_type ();
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
				return false;
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
		return flag;
	}

	private void get_files_thread () {
		foreach (FilterLocation p in query.locations) {
			
		}
	}

	private void on_found_file (FileInfo info) {
		Debug.info ("on_found_file", "Found '%s'".printf (info.get_name ()));
	}

	private void on_found_result (Result result) {
		//add result
	}

	[Compact]
    class ResultsArray {
        internal Results[] results;
    }

    [Compact]
    class Results {
        internal unowned Results? parent;
        internal string display_name;
        internal string parse_name;

        // written in the worker thread before dispatch
        // read from the main thread only after dispatch
        internal uint64 size;
        internal uint64 alloc_size;
        internal uint64 time_modified;
        internal int elements;
        internal double percent;
        internal int max_depth;
        internal Error? error;
        internal bool child_error;

        // accessed only by the main thread
        internal Gtk.TreeIter iter;
        internal bool iter_is_set;
    }
}

public enum Columns {
	ROW,
	DISPLAY_NAME,
	SIZE,
	TIME_MODIFIED,
	ELEMENTS,
	STATE,
	ERROR,
	COLUMNS
}

public enum State {
	SCANNING,
	CANCELLED,
	NEED_ROW,
	ERROR,
	CHILD_ERROR,
	DONE
}