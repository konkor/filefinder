# ![](/data/icons/filefinder.png) File Finder
File  Finder  is  the advanced search tool with gtk3 user interface and
the integration with nautilus file explorer.  There is multiple  search
location  support  with  treading,  file  masking, MIME types, modified
dates, file sizes, text and binary patterns.  The search results can be
sorted  by  attributes  and  processed with common actions like opening
with a default application, containing folder, copy/move to  destination
folder or trashing selection.

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
* Customizable columns for file name, path, type, size, date, MIME...
* Sorting by any column.

### Custom MIME type's groups
* Creating in the preferences window.
* Creating/Inserting from the selection in context menu.

### Common actions for search results
* Opening with default application.
* Opening location of the selection.
* Copying/moving to destination location.
* Trashing selection.
* Summary properties.

### Advanced tools
* Finding of duplicates in the results.
* Copying to clipboard base or full file names.
* ...

### and more

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

### Source and packages
* [GitHub](https://github.com/konkor/filefinder.git)
* [Latest Debian/Ubuntu x64](https://www.dropbox.com/s/kep294nky3kzfdi/filefinder_latest.deb?dl=0)

## Screenshots

![](/data/screenshots/filefinder2.png?raw=true)
