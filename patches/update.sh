#!/bin/bash

: ${UP_DRY:="0"}
: ${UP_BASE:="$(realpath $(dirname $0)/..)"}
: ${UP_LOG:="$UP_BASE/update.log"}
: ${UP_SET:="todo"}
: ${UP_PATH:="patches/$UP_SET"}



exit_usage() {
    
cat <<'EOF'

Usage: update.sh "command"

where "command"

-x: apply patch
-s: dry-mode, only check

EOF

exit 1

}

log() {
    local level="[$1]"
    shift
    echo "$(printf '%s %-7s\t' $(date -Im) $level) $*" | tee -a $UP_LOG
}

debug() { log 'debug' $@; }
info() { log 'INFO' $@; }
warn() { log 'WARN' $@; }
error() { log 'ERROR' $@; }
fatal() { log 'FATAL' $@; }
die() { fatal $@; exit 1; }

banner() {
cat <<EOF

update: $@

   $(date)

EOF
echo ".env."

set | grep ^UP | sort

echo ".apply."

grep -P '^\s+apply' $0

echo ".patches[$UP_SET]."

ls $UP_PATH

echo ".branch."

git --no-pager branch -vv

echo ".."
}




apply() {

    set -o pipefail
    
    N=$1
    F=$(find $UP_PATH -name "${N}*.diff" | head -n 1)
    if [ -z "$F" ]; then
        ls $UP_BASE/$UP_PATH
        die "cannot find patch for $N in $UP_BASE/$UP_PATH"
    fi

    debug "verify patch: $N -> $F, ..."

    # git apply --stat $F 2>&1 | tee -a $UP_LOG

    # rc=${PIPESTATUS[0]}

    # if [ ! $rc ]; then
    #     error "verify patch (stat) #ERR($rc)!: $N -> $F"
    #     die  "update failed!"
    # fi
        
    git apply --check $F 2>&1 | tee -a $UP_LOG

    rc=$?

    if [ $rc != 0 ]; then
        error "verify patch (check) #ERR($rc)!: $N -> $F"
        failed="$failed $N"
        exit_rc=1
    fi
    info "verify patch: $N -> $F, done."

    case "$rc.${UP_DRY}" in
        0.0)
        
    debug "applying patch: $N -> $F, ..."
    
    git am $F 2>&1 | tee -a $UP_LOG

    rc=$?
    
    if [ $rc != 0 ]; then
        error "apply patch (exec) #ERR($rc)!: $N -> $F"
        failed="$failed $N"
        exit_rc=1
    fi
        
    info "applying patch: $N -> $F, done"
    ;;
        *.*)
            warn "check failed, skip patch: $N -> $F"
            ;;
        *)
            warn "dry mode, skip patch: $N -> $F"
            ;;
    esac

    info "applying patch: $N -> $F, done."

    echo "--- $rc"
    #echo "--- rc:$rc  (exit_rc: $exit_rc -- failed: $failed)"

        
}

do_apply_all() {
    
    exit_rc=0
    failed=""
    
    #//////////////////////////////////////////////////////////
    
    ##
    # @see: https://st.suckless.org/patches/
    #

    apply st-newterm
    apply st-font2
    apply st-keyboard_select
    apply st-alpha
    apply st-scrollback-2
    apply st-scrollback-mouse
    apply st-ligatures-alpha-scrollback
    apply st-visualbell
    apply st-keyboard_select
    # apply st-invert
    apply st-w3m
    apply st-netwmicon
    apply st-colors-at-launch
    apply st-workingdir
    apply st-nordtheme
    apply st-xresources

    #//////////////////////////////////////////////////////////

    case "$exit_rc" in
        0) info "UPDATE all: SUCCESS." ;;
        *) fatal "Update all: FAILED! (rc:$exit_rc, failed:$failed )"
           exit $exit_rc
           ;;
    esac
}

main() {

    banner $@

    cd $UP_BASE
    
    case "$1" in
        -x)
            do_apply_all
            ;;
        
        -s)
            UP_DRY=1
            do_apply_all
            ;;
        *) exit_usage ;;
    esac
    
}

main $@

