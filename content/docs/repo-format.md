---
title: Repository Format
---

# Overview #
Since some people learn by example better than RTFMing, I've made an example repository available [here](/example-repo.zip)

# Repository Format #

Repositories are formatted as plain-text files located in any http-accessible location.

They consist of two files.

## packages.list ##

The packages.list file contains a newline-seperated list of packages. The packages are formatted like so:

    foo::foo-version::foo-short-description
    lib-bar::lib-bar-version::bar-short-description

for example, look at [The base repo's source](/repo/packages.list)

## desc.txt ##

This is the second required file for a repository. It contains a human-readable description of
the repository, in plain-text format. This is currently not shown to the user at any point, but it is
still a requirement for future expansion.

# Package Format #

Packages reside under the repository's directory, for the above example of packages.list, the tree would
look like this:

  * foo/
    * details.pkg
    * history.txt
    * bin/
      * foo.lua
  * lib-bar/
    * details.pkg
    * lib/
      * bar.lua
  * packages.list
  * desc.txt

## history.txt ##

history.txt is a purely human-consumed file for package update history, it works by pulling down this file, from the
`ac-get history <package>` command. It's not in any particular format, and will be printed with a textutils.pagedPrint() call.

## details.pkg ##

The details.pkg contains the meta-information of a package, as well as the directives for ac-get to install it, the directives are listed below.

In our example repository, we'd have this for the foo/details.pkg:

    Name: Foo Program
    Description: Foo Program that Foos Fooseballs
    Executable: foo

and lib-bar would have

    Name: Bar Library
    Description: Serves cookies to all who ask.
    Library: bar

The following directives are supported and parsed:

| Name | Type | Desc |
|------|------|------|
| Description |  Human-Readable string |  The description of the package. |
| Library | File Spec | A library contained in the package. the file that it referenced must be under the lib/ subdirectory and have a `.lua` extension. |
| Executable | File Name | A program contained in the package. The file that it references must be under the bin/ sub-directory of the package's directory. and have a `.lua` extension. |
| Config | File Spec | A config file in the package. The file that it references must be under the cfg/ sub-directory of the package directory. |
| Startup | File Name | A startup script to run on system boot. Must be in the startup/ subdirectory, and have the extension `.lua`|
| Documentation | File Name | A file for documentation. Must be in the package's docs/ sub-directory and must have the extension `.txt` |
| Dependency | Package Name | Tells ac-get that you need this package to function. Specify multiple times to require multiple things. |

The following are under consideration for addition, and there's no harm in using them now.

| Name | Type | Desc |
|------|------|------|
| Author | HR-String | The author of the package. |
| Name | HR-String | A human-readable version of the package name |

### Script Directives ###
Script Directives are run at specific steps in the package's life-cycle. In order to do things that normally the install/remove/upgrade cycle can't. The ac-get package itself uses this for installing the startup script launcher. These are to be placed in the details.pkg alondside the above directives. The scripts themselves all go inside their respective directive names in the `steps` sub-directory,  with the `-` replaced with a `_` and the name made all-lowercase. For instance, a Pre-Install directive's script would go under `steps/pre_install/foo-script.lua`.

Examples of these can be seen in the `overly-attached-pkg` package in the above example repo download.

| Name |Args | Desc |
|------|-----|------|
| Pre-Install | None | Runs before installing the package from a non-upgrading state. |
| Post-Install | None | Runs after installing the package. |
| Pre-Upgrade | Installed Version, New Version | Runs before upgrading the package. |
| Post-Upgrade | Installed Version, New Version | Runs after upgrading the package. |
| Pre-Remove | None | Runs before removing the package. |
| Post-Remove | None | Runs after removing the package. |


### File Spec ###

The File Spec type is a simple format.

If you want the file to go somewhere other than the file's immediate name, then you can do this:

`foo => foo-program`

the foo.lua must still reside in the bin/ sub-directory, but it will be saved as foo-progam on the filesystem ( under the user's binary directory )

If you omit the => then it will be saved as it's file name.

Additionally, for libraries and configs, you can do directories by ending the string with a `/`.
