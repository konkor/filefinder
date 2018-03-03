# ![](/data/icons/filefinder.png) File Finder
**File Finder** is an advanced native graphical file search tool and an integration with Gnome Nautilus file explorer through the Nautilus Extension.
There is asynchronous threaded file search in multiple locations, a file masking, MIME types, modified dates, file sizes, text and binary patterns.
It means results appear before a search ends, you can cancel a searching anytime. File Finder can search in multiple locations like files, folders, mount points, disks at the same time. Search queries can contain multiple search filters and text patterns and process them all together.
The search results can be sorted by attributes and processed with common actions like opening with a default application, a containing folder, copy/move to a destination folder, trashing selection, and handled by internal plug-in's manager based on standard Shell Script.
It can be used for an automation on the search results.
Any shell script like bash, python, gjs can be converted to the File Finder Extension by adding the simple definitions in the scripts.

![](/data/screenshots/filefinder.png?raw=true)

## Features
### Supported filters
* Multi Locations with treading
* File Masks
* MIME Types
* Size of files
* Modified time
* Text search in various encodings
* Binary search for a value

### Nautilus extension

![](/data/screenshots/nautilus_menu.png?raw=true)

### Result table
* Customizable columns for file names, path, type, size, date, MIME...
* Sorting by any column.

### Custom MIME type's groups
* Creating in the preferences window.
* Creating/Inserting from the selection in the context menu.

### Common actions for search results
* Opening with the default application.
* Opening location of the selection.
* Copying/moving to a destination location.
* Trashing selection.
* Summary properties.

### Advanced tools
* Finding of duplicates in the results.
* Copying to clipboard base or full file names.

### Extensions in Shell-script format
* Easy format of the Extensions. At least just add one of the defined words (#PLUGNAME, #PLUGDESC, #PLUGKEYS, #PLUGARGS, #PLUGGROUP, #PLUGSYNC) to identify any shell script like an extension.
* Context menu for plugins.
* Plugin Toolbar with an ability to grouping extensions.
* Template of an extension to compressing selection with file-roller.

## Install
### Dependencies
* gtk+-3.0 >= 3.14
* vala (build only)
* autotools (build only)

### From source
```
git clone https://github.com/konkor/filefinder.git
cd filefinder
./autogen.sh
make
sudo make install
```
After `sudo make install` you could copy/move nautilus extension from _/usr/local/lib_ to _/usr/lib_ (for older Nautilus versions)
```
sudo cp /usr/local/lib/nautilus/extensions-3.0/* /usr/lib/nautilus/extensions-3.0/
```

To disable Nautilus extension pass `--without-nautilus-extension` to _autogen.sh_ or _configure_:
```
./configure --without-nautilus-extension
make
sudo make install
```

### Source and packages
* [GitHub](https://github.com/konkor/filefinder/archive/master.zip)
* [Latest Debian/Ubuntu x64](https://www.dropbox.com/s/6z3uq7sqn8runtx/filefinder_latest.deb?dl=1)

## Screenshots

![](/data/screenshots/filefinder2.png?raw=true)
