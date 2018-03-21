using Gtk;

public const uint IO_WAIT_MS = 1500;
public const uint EVENT_WAIT_MS = 100;
public const uint X_WAIT_MS = 200;

static int main (string[] args) {

	/*
	 * Unit tests allow you to test each component of an application
	 * in isolation which:
	 * - makes it easier to find bugs
	 * - makes it easier for someone else to understand how your code works
	 * - lets you refactor with confidence
	 * 
	* These unit tests use the GLib Test framework but you could always
	 * try out Valadate (http://github.com/chebizarro/valadate) which is
	 * an easier to use testing framework built on top of GLib Test.
	 * 
	 */

	Gtk.test_init (ref args);

	GLib.Test.add_func ("/Filefinder/new", () => {
	    string[] nargs = {"--debug"};
		var result = new Filefinder (nargs);

		assert(result is Filefinder);
	});

	GLib.Test.add_func ("/QueryEditor", () => {
	    var editor = new QueryEditor ();

	    //editor.show_all ();
	    //wait (X_WAIT_MS);

	    assert(editor is QueryEditor);

	    editor.add_filter (types.LOCATION);
	    editor.add_filter (types.TEXT);

	    var query = editor.query;
	    assert(query is Query);
	    assert(query.locations.length() == 1);

   	    assert(editor.rows.length() == 2);

	    editor.remove_rows ();

	    editor.add_filter (types.LOCATION);
	    editor.add_filter (types.LOCATION);
	    editor.add_filter (types.TEXT);
	    editor.add_filter (types.TEXT);

	    assert(editor.rows.length() == 4);
	    assert(query.locations.length() == 1);

   	    editor = null;
	});

	GLib.Test.add_func ("/FileFinderWindow", () => {
	    string[] nargs = {};
	    var ff = new Filefinder (nargs);
	    Timeout.add (5000, (SourceFunc) ff.quit);
	    ff.run (nargs);

	    wait (X_WAIT_MS);

	    var window = ff.window;
	    assert(window is FileFinderWindow);

	    window.move (100, 100);
	    window.set_size_request (400, 400);

	    wait (X_WAIT_MS);

	    assert(window.visible);

	    window = null;
	});

	return Test.run ();
}

void wait (uint milliseconds) {
	var main_loop = new MainLoop ();

	Gdk.threads_add_timeout (milliseconds, () => {
		main_loop.quit ();
		return false;
	});

	main_loop.run ();
}
