#
# Script @__AnyLabel__ from content/tutorials/setup.md 
#
#----------------------------------------------------------------------#  Start 1 of 1
echo "# @envVars (block #1 in __AnyLabel__) of content/tutorials/setup.md"

# If JIRI_ROOT or V23_RELEASE are not defined, set them to the default values
# from the installation instructions and hope for the best.

[ -z "$JIRI_ROOT" ] && export JIRI_ROOT=${HOME}/v23_root
[ -z "$V23_RELEASE" ] && export V23_RELEASE=${JIRI_ROOT}/release/go

# All files created by the tutorial will be placed in $V_TUT. It is a disposable
# workspace, easy to recreate.
export V_TUT=${V_TUT-$HOME/v23_tutorial}

# V_BIN is a convenience for running Vanadium binaries. It avoids the need to
# modify your PATH or to be 'in' a particular directory when doing the
# tutorials.
export V_BIN=${V23_RELEASE}/bin

# For the shell doing the tutorials, GOPATH must include both Vanadium and the
# code created as a result of doing the tutorials. To avoid trouble with
# accumulation, $GOPATH is intentionally omitted from the right hand side (any
# existing value is ignored).
if [ -z "$V23_GOPATH" ]; then
  export V23_GOPATH=`${JIRI_ROOT}/devtools/bin/jiri go env GOPATH`
fi
export GOPATH=$V_TUT:${V23_GOPATH}

# HISTCONTROL set as follows excludes long file creation commands used in
# tutorials from your shell history.
HISTCONTROL=ignorespace

# A convenience for killing tutorial processes
function kill_tut_process() {
  eval local pid=\$$1
  if [ -n "$pid" ]; then
    kill $pid || true
    wait $pid || true
    eval unset $1
  fi
}
#----------------------------------------------------------------------#  End 1 of 1

#
# Script @__AnyLabel__ from content/tutorials/checkup.md 
#
#----------------------------------------------------------------------#  Start 1 of 1
echo "# @checkTutorialAssets (block #1 in __AnyLabel__) of content/tutorials/checkup.md"

function bad_vanadium() {
  echo '
  Per https://vanadium.github.io/installation/, either

    export JIRI_ROOT={your installation directory}

  or do a fresh install.';
  exit 1;
}

[ -z "$V23_RELEASE" ] && { echo 'The environment variable V23_RELEASE is not defined.'; bad_vanadium; }

[ -x "$V23_RELEASE/bin/principal" ] || { echo 'The file $V23_RELEASE/bin/principal does not exist or is not executable.'; bad_vanadium; }
#----------------------------------------------------------------------#  End 1 of 1

echo " "
echo "All done.  No errors."
