#!/bin/sh
# GitFoo - Script for Synchronizing Git Repositories from Remote Directory
#
# Bash script  which scans remote  host for git repositories  and clones
# respectively  fetches their content to a local directory.  The primary
# usage  is for  backup purposes.  On contrast  to other  aproaches e.g.
# rsync the backed up repositories stay intact in case of malformed data
# on the remote side.
#
# Invocation:
# ./gf_sync_remote_dir.sh -l <local backup root directory> \\
#                         -h <host to fetch from> \\
#                         -p [ssh port] <backup directories list>
#
# The use and distribution terms for this software are covered by
# the GNU General Public License.
# Refer to https://github.com/linneman/git-foo for further information.
#
# (C) 2015, Otto Linnemann


function syn_remote_dir() {
    #
    # helper function whicn synchronizes one target directory
    # invocation:
    # syn_remote_dir ${remote_ssh_host} ${remote_dir} ${local_root_dir}
    #

    local remote_ssh_server=$1
    local remote_root_folder=$2

    local remote_repo_search_cmd="cd $remote_root_folder ; find . -name \"*.git\" -type d -printf \"%P\n\""
    if $sync_bare_repos_only ; then
        remote_repo_search_cmd=$remote_repo_search_cmd" | grep -v \"\/.git$\""
    fi

    local repos=$(ssh -p $remote_ssh_port $remote_ssh_server -C $remote_repo_search_cmd)

    for fq in $repos ; do
        cd $local_root_dir

        p=$(dirname $fq)
        r=$(basename $fq)

        echo "Synchronize repository $fq ..."

        if [ $r == ".git" ] ; then
            # splitt off last slash for path of non-bare repos
            fq=$p
            p="./"$p ; p=${p%/*}
            is_bare=false
        else
            is_bare=true
        fi

        if [ -d "$fq" ]; then
            # repository exists, just fetch
            cd "$local_root_dir/$fq"
            if $is_bare ; then
                local fetch_cmd="git remote update"
            else
                local fetch_cmd="git fetch origin --tags"
            fi
            echo "cd $local_root_dir/$fq ; $fetch_cmd"
            eval $fetch_cmd
        else
            # repository does not exist yet, so clone it
            if [ ! -d $fq ] ; then
                mkdir -p "$local_root_dir/$p"
            fi
            cd "$local_root_dir/$p"

            if $is_bare ; then
                local clone_cmd="git clone --mirror ssh://$remote_ssh_server:$remote_ssh_port/$remote_root_folder/$fq"
            else
                local clone_cmd="git clone ssh://$remote_ssh_server:$remote_ssh_port/$remote_root_folder/$fq"
            fi

            echo $clone_cmd
            eval $clone_cmd
        fi

	if [ $? -ne 0 ]; then
	    errors=$(expr $errors + 1)
	fi

        echo

    done

} # end function syn_remote_dir


function print_help() {
    echo "GitFoo - Script for Synchronizing Git Repositories from Remote Directory"
    echo
    echo "Bash script  which scans remote  host for git repositories  and clones"
    echo "respectively  fetches their content to a local directory.  The primary"
    echo "usage  is for  backup purposes.  On contrast  to other  aproaches e.g."
    echo "rsync the backed up repositories stay intact in case of malformed data"
    echo "on the remote side."
    echo
    echo "Invocation:"
    echo "./gf_sync_remote_dir.sh -l <local backup root directory> \\"
    echo "                        -h <host to fetch from> \\"
    echo "                        -p [ssh port] <backup directories list>"
    echo
    echo "The use and distribution terms for this software are covered by"
    echo "the GNU General Public License."
    echo "Refer to https://github.com/linneman/git-foo for further information."
    echo
    echo "(C) 2015, Otto Linnemann"
} # end function print_help



#
# default arguments
#
sync_bare_repos_only=false
remote_ssh_host=""
remote_ssh_port=22
remote_dirs=""
local_root_dir=""

errors=0


#
# main function, according to:
#
# http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ $# > 0 ]]
do
    key="$1"

    case $key in
        -l|--local-dir)
            local_root_dir="$2"
            shift # past argument
            ;;
        -h|--host)
            remote_ssh_host="$2"
            shift # past argument
            ;;
        -p|--port)
            remote_ssh_port="$2"
            shift # past argument
            ;;
        -b|--bare-repos-only)
            sync_bare_repos_only="$2"
            shift # past argument
            ;;
        --help)
            print_help
            exit -1
            ;;
        *)
            break;
            # remote directories to be synchronized
            ;;
    esac
    shift # past argument or value
done
remote_dirs=$*

#
# check whether all required arguments are defined
#
if [ "x$remote_ssh_host" == "x" ] ; then
    print_help
    echo
    echo "Remote host not specified error!"
    exit -1
fi

if [ "x$remote_dirs" == "x" ] ; then
    print_help
    echo
    echo "Remote directory(ies) not specified error!"
    exit -1
fi

if [ "x$local_root_dir" == "x" ] ; then
    print_help
    echo
    echo "Local target directory not specified error!"
    exit -1
fi

echo "=============================================================================="
echo "start synchronizing on $(date) with the following options:"
echo "from remote_ssh_host         = ${remote_ssh_host}"
echo "     remote_ssh_port         = ${remote_ssh_port}"
echo "     remote_directories      = ${remote_dirs}"
echo "     sync_bare_repos_only    = ${sync_bare_repos_only}"
echo "to   local_root_dir          = ${local_root_dir}"
echo

# chreate local target directory if it does not exist yet
if [ ! -d "$local_root_dir" ]; then
    mkdir $local_root_dir
fi

# loop over all remote directories and synchronize them
for remote_dir in $remote_dirs ; do
    echo "Synchronizing remote directory: $remote_dir ..."
    echo
    syn_remote_dir ${remote_ssh_host} ${remote_dir} ${local_root_dir}
done

# print number of total errors
echo "overall number of errors:"$errors
exit $errors
