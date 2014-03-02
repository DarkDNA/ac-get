---
title: Installer Manifests
v_added: 10
groups: [ "docs" ]
---

# What are these? #	

Install manifests are a series of commands for ac-get to run. They are in the same format as the details.pkg file in a repo. There are currently only three directives available, listed below. They can be chain-loaded, allowing you to compartamentalise your manifests for your repos. The manifests do *not* have to be inside a repository's folder structure, but they *may* be.

# Directives?! #

| Directive | Description |
|-----------|-------------|
| Add-Repo | Adds the given repository url to the ac-get state, if not already added. |
| Install | Installs the given package. Note this will fail if the repository you're trying to add it from hasn't been added yet. |
| Run-Manifest | Chain-loads the given manifest URL. |