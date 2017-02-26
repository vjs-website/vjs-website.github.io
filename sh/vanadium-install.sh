#
# Script @__AnyLabel__ from content/installation/step-by-step.md 
#
#----------------------------------------------------------------------#  Start 1 of 8
echo "# @checkForBash (block #1 in __AnyLabel__) of content/installation/step-by-step.md"

set | grep BASH > /dev/null || echo "Vanadium installation requires Bash."
#----------------------------------------------------------------------#  End 1 of 8

#----------------------------------------------------------------------#  Start 2 of 8
echo "# @define_JIRI_ROOT (block #2 in __AnyLabel__) of content/installation/step-by-step.md"

# Edit to taste.
export JIRI_ROOT=${HOME}/v23_root
#----------------------------------------------------------------------#  End 2 of 8

#----------------------------------------------------------------------#  Start 3 of 8
echo "# @define_V23_RELEASE (block #3 in __AnyLabel__) of content/installation/step-by-step.md"

# Needed for tutorials only.
export V23_RELEASE=${JIRI_ROOT}/release/go
#----------------------------------------------------------------------#  End 3 of 8

 bash -euo pipefail <<'HANDLED_SCRIPT'
function handledTrouble() {
  echo " "
  echo "Unable to continue!"
  exit 1
}
trap handledTrouble INT TERM
#
# Script @__AnyLabel__ from content/installation/step-by-step.md 
#
#----------------------------------------------------------------------#  Start 1 of 8
echo "# @checkForBash (block #1 in __AnyLabel__) of content/installation/step-by-step.md"

set | grep BASH > /dev/null || echo "Vanadium installation requires Bash."
#----------------------------------------------------------------------#  End 1 of 8

#----------------------------------------------------------------------#  Start 2 of 8
echo "# @define_JIRI_ROOT (block #2 in __AnyLabel__) of content/installation/step-by-step.md"

# Edit to taste.
export JIRI_ROOT=${HOME}/v23_root
#----------------------------------------------------------------------#  End 2 of 8

#----------------------------------------------------------------------#  Start 3 of 8
echo "# @define_V23_RELEASE (block #3 in __AnyLabel__) of content/installation/step-by-step.md"

# Needed for tutorials only.
export V23_RELEASE=${JIRI_ROOT}/release/go
#----------------------------------------------------------------------#  End 3 of 8

#----------------------------------------------------------------------#  Start 4 of 8
echo "# @define_rmrf_JIRI_ROOT (block #4 in __AnyLabel__) of content/installation/step-by-step.md"

# WARNING: Make sure you're not deleting something important.
rm -rf $JIRI_ROOT
#----------------------------------------------------------------------#  End 4 of 8

#----------------------------------------------------------------------#  Start 5 of 8
echo "# @runBootstrapScript (block #5 in __AnyLabel__) of content/installation/step-by-step.md"

# This can take several minutes.
curl -f https://vanadium.github.io/bootstrap.sh | bash
#----------------------------------------------------------------------#  End 5 of 8

#----------------------------------------------------------------------#  Start 6 of 8
echo "# @addDevtoolsToPath (block #6 in __AnyLabel__) of content/installation/step-by-step.md"

export PATH=$JIRI_ROOT/.jiri_root/scripts:$PATH
#----------------------------------------------------------------------#  End 6 of 8

#----------------------------------------------------------------------#  Start 7 of 8
echo "# @installBaseProfile (block #7 in __AnyLabel__) of content/installation/step-by-step.md"

jiri v23-profile install base
#----------------------------------------------------------------------#  End 7 of 8

#----------------------------------------------------------------------#  Start 8 of 8
echo "# @installVanadiumBinaries (block #8 in __AnyLabel__) of content/installation/step-by-step.md"

# Install specific tools needed for the tutorials.
jiri go install v.io/x/ref/cmd/... v.io/x/ref/services/agent/... v.io/x/ref/services/mounttable/...
#----------------------------------------------------------------------#  End 8 of 8

echo " "
echo "All done.  No errors."
HANDLED_SCRIPT
