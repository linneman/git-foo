#!/bin/sh
# diff tool for two manifest files
#
# INVOCATION:
#
# diff-manifests old-manifest-file new-manifest-file
#
# needs to be invoked from project root directory
#
# DEPENDENCIES: Linux package xmlstarlet
#
# @peiker/ol
#   based on https://groups.google.com/forum/#!topic/repo-discuss/tOXveIgbavo

old_manifest=.repo/manifests/$1
new_manifest=.repo/manifests/$2

# [ -z "$3" ] && diff_cmd="git --no-pager log --pretty=oneline --abbrev-commit"
[ -z "$3" ] && diff_cmd="git --no-pager log --cherry"

xmlstarlet sel -t -m "//project" -v "@name" -o " " -v "@path" -o " " -v "@revision" -n $old_manifest |
while read name path old_rev; do
    if [[ -z  $name  ]]; then
       continue
    fi
    new_rev=$(xmlstarlet sel -t -m "//project[@path='$path']" -v "@revision" $new_manifest)
    dir=$PWD
    cd $path
    echo "##################################################################################"
    echo "Project ${name}"
    $diff_cmd $old_rev...$new_rev | while read line; do
        echo $line
    done
    cd $dir
done
