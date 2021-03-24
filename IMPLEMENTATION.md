### Business rules

#### Environment
* Both behaviors of the script use the file `~/.config/user-dirs.dirs` to set some language-independent environment variables (for example, to get an independent system-language path to the Desktop), so some functions of this script will fail if this file does not exist. The variables declared in this file that are used in the customizer are `XDG_DESKTOP_DIR=/home/username/Desktop`, `XDG_PICTURES_DIR=/home/username/Images`, `XDG_TEMPLATES_DIR=/home/username/Templates`.
* Customizer must not rely ever on the working directory, that is why relative paths are completely avoided. In the same vein, files must not be downloaded in the working directory, they should be deleted in a controlled location. In most cases, this location is `USR_BIN_FOLDER`.

#### Structures
* The software that is manually installed is put under `USR_BIN_FOLDER`, which by default points to `~/.bin`. `~/.bin` is always **present**.
* Shell features are not installed directly into `~/.bashrc`, instead, there is always present the file `~/.bash_functions`, which is a file imported by `~/.bashrc`. In `~/.bash_functions`, you can write imports to individual scripts that provide a feature to the shell environment. Usually those scripts are stored under `~/.bin/bash_functions/`, which is a location always present. So the generic way to include new content to `~/.bashrc` is writing a script to `~/.bin/bash_functions` and including it in `~/.bash_functions/`.
* Soft links to include a program in the path are created under `~/.local/bin` which is a directory that is assured to be in the PATH 

#### Behaviour
* Each feature is expected to be executed with certain permissions (root / normal user). So the script will skip a feature that needs to be installed with different permissions from the ones that currently has.
* No unprotected `cd` commands. `cd` must be avoided and never change the working directory given from the outside, that is why they must be called from the inside of a subshell if present.

#### Syntax
* All variables must be expanded by using `${VAR_NAME}` (include the brackets) except for the special ones, like `$#`, `$@`, `$!`, `$?`, etc.
* All variables must be protected by using "" to avoid resplitting because of spaces, despite, customizer is not emphasized to work with spaces in its variables. Spaces are *evil* and are not considered.
* There is one blankline between functions in the same section. There is two blanklines between sections.

## Developed features
#### Aleix
- [x] Create argument (! or --not) for deselecting installed or uninstalled features.
- [x] -v --verbose Verbose mode (make the software not verbose by default)
- [x] Solve bug of `PATH` addition in shell features. (it works, but it appends the export many times)
- [x] To add more useful directory path variables in common_data.sh
- [x] Make sure USR_BIN_FOLDER is present in any user roll
- [x] Create file and directory structure to add features to `.bashrc` without actually writing anything on it by using the wrapper in `.bash_functions`
- [x] Name refactor of functions to make it coincide with what command is being thrown in order to determine if it is installed using which
- [x] try refactoring the point above by using type, which recognizes alias and functions too
- [x] Add aliases topycharm, clion, etc
- [x] Add argument to dummy commit
- [x] refactor installation bit to be installation order, which contains an integer that if it is greater than 0 means selected for install, and the integer determines the installation order
- [x] Installations must be done by argument order apparition (add another column to installation_data to sort an integer that determines the order)
- [x] declare variables like DESK, GIT, etc
- [x] Split multifeatures in one function into different functions
- [x] Create source in bashrc with file bash_functions.sh with all sources calls

#### Axel
- [x] Delete / rearrange arguments of one letter 
- [x] Refactor of data table in README.md
- [x] Youtube-dl

## Currently developing/refactoring features

## TO-DO
- [ ] Create high-level wrappers for a set of features, such as "minimal", "custom", "" etc.
- [ ] Desktop wallpapers
- [ ] Create escape function, which returns an escaped sequence of characters
- [ ] Refine extract function
- [ ] Standarize fromat of all launchers: Name, GenericName, Type, Comment, Categories=IDE;Programming;, Version, StartupWMClass, Icon, Exec, Terminal, StartupNotify, MimeType=x-scheme-handler/tg;, Encoding=UTF-8
- [ ] Create generic version for the function output_proxy_exec, to integrate with a bash feature to be installed
- [ ] Replicate most of the necessary structures and data to adapt `uninstall.sh` to the new specs
- [ ] Add special func in uninstall (--reset|-r) that uninstalls the file structures that the customizer creates (~/.bash_functions, ~/.bin, etc.) That cannot be removed directly using uninstall

## Coming features
- [ ] create a unique endpoint for all the code in customizer customizer.sh which accepts the arguments install uninstall for the recognized features and make the corresponding calls to sudo uninstall.sh ..., sudo install.sh ... And Install.sh ... 
- [ ] make `customizer.sh` 
- [ ] Automount available drives.*
- [ ] Create or integrate loc function bash feature which displays the lines of code of a script  
- [ ] Program function to unregister default opening applications on `uninstall.sh`
- [ ] nettools* 
- [ ] GnuCash, Rosegarden, Remmina, Freeciv, Shotwell, Handbrake, fslint, CMake, unrar, rar, evolution, guake, Brasero, Remastersys, UNetbootin, Blender3D, Skype, Ardour, Spotify, TeamViewer, Remmina, WireShark, PacketTracer, LMMS...
- [ ] LAMP stack web server, Wordpress
- [ ] Rsync, Axel, GNOME Tweak, Wine 5.0, Picasa, Synaptic, Bacula, Docker, kubernetes, Agave, apache2, Moodle, Oracle SQL Developer, Mdadm, PuTTY, MySQL Server instance, glpi*, FOG Server*, Proxmox*, Nessus*, PLEX Media Server
- [ ] nmap, gobuster, metasploit, Firewalld, sysmontask, sherlock, Hydra, Ghidra, THC Hydra, Zenmap, Snort, Hashcat, Pixiewps, Fern Wifi Cracker, gufw, WinFF, chkrootkit, rkhunter, Yersinia, Maltego, GNU MAC Changer, Burp Suite, BackTrack, John the Ripper, aircrack-ng
- [ ] SublimeText-Markdown, & other plugins for programs...
- [ ] Repair broken desktop icons (VLC...
- [ ] Fonts

## asjko
  #lsdisplay=$(ls -lhA | tr -s " ")
  #dudisplay=$(du -shxc .[!.]* * | sort -h | tr -s "\t" " ")
  #IFS=$'\n'
  #for linels in ${lsdisplay}; do
  #  if [[ $linels =~ ^d.* ]]; then
  #    foldername=$(echo $linels | cut -d " " -f9)
  #    for linedu in ${dudisplay}; do
  #      if [[ "$(echo ${linedu} | cut -d " " -f2)" = ${foldername} ]]; then
  #        # Replace $lsdisplay with values in folder size 
  #        break
  #      fi
  #    done
  #  fi
  #done

  #alias a="echo '---------------Alias----------------';alias"
  #alias c="clear"
  #alias h="history | grep $1"
  #du -shxc .[!.]* * | sort -h