using Gtk;

static int main (string[] args) {

	/*
	 * Unit tests allow you to test each component of an application
	 * in isolation which:
	 * - makes it easier to find bugs
	 * - makes it easier for someone else to understand how your code works
	 * - lets you refactor with confidence
	 * 
	 * To run the unit tests simply type:
	 * make check
	 * 
	 * This will produce 3 files in the src directory:
	 * - test-suite.log
	 * - tests_srtmerge.log
	 * - tests_srtmerge.trs
	 * These will give any information on any tests that fail
	 * 
	 * To debug, you can run the unit test program in gdb or nemiver
	 * eg: nemiver tests_srtmerge &
	 * 
	 * These unit tests use the GLib Test framework but you could always
	 * try out Valadate (http://github.com/chebizarro/valadate) which is
	 * an easier to use testing framework built on top of GLib Test.
	 * 
	 */

	//Gtk.test_init (ref args);
	Test.init (ref args);
	Gtk.init (ref args);

	/*
	 * This unit test enabled me to find the error you were experiencing
	 * on program startup in just a few seconds:
	 * Gtk-CRITICAL **: gtk_entry_set_text: assertion 'GTK_IS_ENTRY (entry)'
	 */
	GLib.Test.add_func ("/Filefinder/new", () => {
	    string[] nargs = {};
		var result = new Filefinder (nargs);

		assert(result is Filefinder);
		
		nargs = {"--debug", "."};
		result = new Filefinder (nargs);

		assert(result is Filefinder);
	});

	return Test.run ();
}
