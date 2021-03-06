rTorrent-PS
===========

Extended `rTorrent` distribution with UI enhancements, colorization, and some added features.

![Extended Canvas Screenshot](https://raw.githubusercontent.com/pyroscope/rtorrent-ps/master/images/rT-PS-094-2014-05-24-shadow.png)

`rTorrent-PS` is *not* the same as the `PyroScope`
[command line utilities](https://code.google.com/p/pyroscope/wiki/CommandLineTools),
and doesn't depend on them; the same is true the other way 'round.
It's just that both unsurprisingly have synergies if used together,
and some features *do* only work when both are present.


## Feature Overview

`rTorrent-PS` is a `rTorrent` distribution in form of a set of patches
that improves the user experience and stability of official `rTorrent` releases.

The main changes are these:

  * self-contained install into any location of your choosing, including your home directory, offering the ability to run several versions at once (in different client instances).
  * rpath-linked to the major dependencies, so you can upgrade those independently from your OS distribution's versions.
  * extended command set:
    * sort views by more than one value, and set the sort direction for each of these.
    * bind keys in the root display to any command, e.g. change the built-in views.
  * interface additions:
    * easily customizable colors.
    * collapsed 1-line item display.
    * network bandwidth graph.
    * displaying the tracker domain for each item.
    * some more minor modifications to the download list view.

To get those, you just need to either follow the build instructions, or download and install a package from Bintray — assuming one is available for your platform.


For more details, see the [wiki page at Google code](https://code.google.com/p/pyroscope/wiki/RtorrentExtended).


## Installation

### General

See the [instructions on Google code](https://code.google.com/p/pyroscope/wiki/DebianInstallFromSource#rTorrent_installation), for either package based installation, or building from source.

### Packages

* The build script is able to build a DEB package (living in `/opt/rtorrent`), pre-built ones for some Debian and Ubuntu versions can be found on [Bintray](https://bintray.com/pyroscope/rtorrent-ps).
* There is an AUR package [rtorrent-pyro-git](https://aur.archlinux.org/packages/rtorrent-pyro-git/) for Arch Linux.


## References

  * https://github.com/rakshasa/rtorrent
  * http://wiki.rtorrent.org/
