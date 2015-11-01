# Git-Foo - Scripts for Managing Git Repositories

This repository collects utilities I wrote for working with Git and Android Repo.

## gf\_sync\_remote\_dir - Synchronizing Git Repositories from Remote Directory

Bash script  which scans remote  host for git repositories  and clones
respectively  fetches their content to a local directory.  The primary
usage  is for  backup purposes.  On contrast  to other  aproaches e.g.
rsync the backed up repositories stay intact in case of malformed data
on the remote side.

Invocation:

    ./gf_sync_remote_dir.ssh -l <local backup root directory> \\
                             -h <host to fetch from> \\
                             -p [ssh port] <backup directories list>

## Licence
This software stands under the terms of the
[GNU General Public Licence](http://www.gnu.org/licenses/gpl.html).

Copyright © 2015 Otto Linnemann
