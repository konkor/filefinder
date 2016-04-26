class FilefinderMenuProvider : Nautilus.MenuProvider, Object {
    public virtual List<Nautilus.MenuItem>? get_file_items(
            Gtk.Widget window, List<Nautilus.FileInfo> files) {
        //var gfiles = new List<File>();
	string cmds = "filefinder";
        int i = 0;
        foreach (var file in files) {
            //if (file.is_directory()) return null;
            //gfiles.append(file.get_location());
            cmds += " \"" + file.get_location().get_path () + "\"";
            i++;
        }

        var list = new List<Nautilus.MenuItem>();
        var item = new Nautilus.MenuItem ("filefinder", "Advanced Search %d Items...".printf (i),
            "");
        item.activate.connect(() => {
            //GLib.DesktopAppInfo info = new GLib.DesktopAppInfo("srtmerge.desktop");
            AppInfo appinfo = AppInfo.create_from_commandline (cmds, null, AppInfoCreateFlags.NONE);
            try {
                //info.launch (gfiles, null);
                appinfo.launch (null, null);
            } catch (Error e) {
                new Gtk.MessageDialog(null, 0, Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.CLOSE, "Failed to launch: %s",
                    e.message).show();
            }
        });
        list.append(item);
        return list;
    }

    public virtual List<Nautilus.MenuItem>? get_background_items(
            Gtk.Widget window, Nautilus.FileInfo current_folder) {
        
        string cmds = "filefinder \"" + current_folder.get_location().get_path () + "\"";
        var list = new List<Nautilus.MenuItem>();
        var item = new Nautilus.MenuItem("filefinder_cur", "Advanced Search...",
            "");
        item.activate.connect(() => {
            AppInfo appinfo = AppInfo.create_from_commandline (cmds, null, AppInfoCreateFlags.NONE);
            try {
                appinfo.launch (null, null);
            } catch (Error e) {
                new Gtk.MessageDialog(null, 0, Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.CLOSE, "Failed to launch: %s",
                    e.message).show();
            }
        });
        list.append(item);
        return list;
    }
}


[ModuleInit]
public void nautilus_module_initialize(TypeModule module) {
    typeof(FilefinderMenuProvider);
}

public void nautilus_module_shutdown() {;}

public void nautilus_module_list_types(out Type[] types) {
    types = {typeof(FilefinderMenuProvider)};
}
