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

public class Service : GLib.Object {
	private signal void finished_thread ();
	public signal void finished_search ();

	private List<string> files;
	public List<Result> results;
	private Query query;
	private bool threading;
	private const int MAX_THREAD = 4;
	private int thread_count;

	public Service () {
		threading = Thread.supported ();
		threading = false;

		this.finished_thread.connect (()=>{
			this.thread_count--;
		});
	}

	private void init () {
		thread_count = 0;
		results = new List<Result> ();
		files = new List<string> ();
	}

	public void start (Query q) {
		if (q == null) return;
		this.query = q;
		init ();
		if (threading) {
			get_files_thread ();
		} else {
			get_files ();
		}
	}

	private void get_files () {
		foreach (FilterLocation p in query.locations) {
			list_dir (p.folder, p.recursive);
		}

		finished_search ();
	}

	async void list_dir(string path, bool recursive) {
		var dir = File.new_for_path (path);
		if (!dir.query_exists ()) return;
	    try {
		    var e = yield dir.enumerate_children_async(
    		    FileAttribute.STANDARD_NAME, 0, Priority.DEFAULT, null);
    		while (true) {
        		var _files = yield e.next_files_async(
            		 10, Priority.DEFAULT, null);
        		if (_files == null) {
            		break;
        		}
        		foreach (FileInfo info in _files) {
					if (recursive) {
						if (info.get_file_type () == FileType.DIRECTORY) {
							list_dir (path + Path.DIR_SEPARATOR_S + info.get_name (), recursive);
						}
					}
            		print("%s\n", info.get_name ());
        		}
    		}
		} catch (Error err) {
    		Debug.error (this.get_type().to_string(), err.message);
		}
	}

	private void get_files_thread () {
		foreach (FilterLocation p in query.locations) {
			
		}
	}

	private void on_found_file (string filename) {
		//add file
	}

	private void on_found_result (Result result) {
		//add result
	}
}

