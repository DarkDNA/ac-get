---
title: Custom Locations
groups: [ "docs" ]
---

To install program files to custom locations on the filesystem, you must first make a file in your root
The file must contain a lua table.

For example, say you want programs to go into /programs libraries into /apis configuration files under /config
and the ac-get state stuff under /ac-get

Then you just need To make a file in the root called `ac-get-dirs` **BEFORE YOU RUN THE INSTALLER**.

The file must contain the following for the above example.

	{
    	binaries = "/programs",
    	libraries = "/apis",
    	config = "/config",
    	startup = "/config/startup.d",
		docs = "/docs",
		state = "/ac-get",
		["repo-state"] = "/ac-get/repos"
	}

The following keys are available for you to override:

|    Name    |      Default      |                         Desc                         |
| ---------- | ----------------- | ---------------------------------------------------- |
| binaries   | /bin              | The location of "executable"s                        |
| libraries  | /lib              | The location of APIs and other libraries.            |
| config     | /cfg              | The location of config files for the packages.       |
| startup    | /cfg/startup.d    | A location for startup scripts to be placed.         |
| docs       | /docs             | A location for documentation to be placed.           |
| state      | /lib/ac-get/      | The location of the installed packages file.         |
| repo-state | /lib/ac-get/repos | The location of the repo index, and cached packages. |