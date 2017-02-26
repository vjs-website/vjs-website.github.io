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

#
# Script @__AnyLabel__ from content/tutorials/wipe-slate.md 
#
#----------------------------------------------------------------------#  Start 1 of 1
echo "# @deleteTutdirContent (block #1 in __AnyLabel__) of content/tutorials/wipe-slate.md"

if [ -z "${V_TUT}" ]; then
  echo "V_TUT not defined, nothing to do."
else
  if [ -d "${V_TUT}" ]; then
    /bin/rm -rf $V_TUT/*
    echo "Removed contents of $V_TUT"
  else
    echo "Not a directory: V_TUT=\"$V_TUT\""
  fi
fi
#----------------------------------------------------------------------#  End 1 of 1

#
# Script @__AnyLabel__ from content/tutorials/hello-world.md 
#
#----------------------------------------------------------------------#  Start 1 of 12
echo "# @displayVTut (block #1 in __AnyLabel__) of content/tutorials/hello-world.md"

echo $V_TUT
#----------------------------------------------------------------------#  End 1 of 12

#----------------------------------------------------------------------#  Start 2 of 12
echo "# @defineService (block #2 in __AnyLabel__) of content/tutorials/hello-world.md"

mkdir -p $V_TUT/src/hello/ifc
 cat - <<EOF >$V_TUT/src/hello/ifc/hello.vdl
package ifc

type Hello interface {
  // Returns a greeting.
  Get() (greeting string | error)
}
EOF
#----------------------------------------------------------------------#  End 2 of 12

#----------------------------------------------------------------------#  Start 3 of 12
echo "# @compileInterface (block #3 in __AnyLabel__) of content/tutorials/hello-world.md"

VDLROOT=$V23_RELEASE/src/v.io/v23/vdlroot \
    VDLPATH=$V_TUT/src \
    $V_BIN/vdl generate --lang go $V_TUT/src/hello/ifc
#----------------------------------------------------------------------#  End 3 of 12

#----------------------------------------------------------------------#  Start 4 of 12
echo "# @compileInterface (block #4 in __AnyLabel__) of content/tutorials/hello-world.md"

ls $V_TUT/src/hello/ifc
#----------------------------------------------------------------------#  End 4 of 12

#----------------------------------------------------------------------#  Start 5 of 12
echo "# @serviceImpl (block #5 in __AnyLabel__) of content/tutorials/hello-world.md"

mkdir -p $V_TUT/src/hello/service
 cat - <<EOF >$V_TUT/src/hello/service/service.go
package service

import (
  "hello/ifc"
  "v.io/v23/context"
  "v.io/v23/rpc"
)

type impl struct {
}

func Make() ifc.HelloServerMethods {
  return &impl {}
}

func (f *impl) Get(_ *context.T, _ rpc.ServerCall) (
    greeting string, err error) {
  return "Hello World!", nil
}
EOF
#----------------------------------------------------------------------#  End 5 of 12

#----------------------------------------------------------------------#  Start 6 of 12
echo "# @server (block #6 in __AnyLabel__) of content/tutorials/hello-world.md"

mkdir -p $V_TUT/src/hello/server
 cat - <<EOF >$V_TUT/src/hello/server/main.go
package main

import (
  "log"
  "hello/ifc"
  "hello/service"
  "v.io/v23"
  "v.io/x/ref/lib/signals"
  _ "v.io/x/ref/runtime/factories/generic"
)

func main() {
  ctx, shutdown := v23.Init()
  defer shutdown()
  _, _, err := v23.WithNewServer(ctx, "", ifc.HelloServer(service.Make()), nil)
  if err != nil {
    log.Panic("Error listening: ", err)
  }
  <-signals.ShutdownOnSignals(ctx)  // Wait forever.
}
EOF
go install hello/server
#----------------------------------------------------------------------#  End 6 of 12

#----------------------------------------------------------------------#  Start 7 of 12
echo "# @checkTheBinary (block #7 in __AnyLabel__) of content/tutorials/hello-world.md"

ls $V_TUT/bin
#----------------------------------------------------------------------#  End 7 of 12

#----------------------------------------------------------------------#  Start 8 of 12
echo "# @client (block #8 in __AnyLabel__) of content/tutorials/hello-world.md"

mkdir -p $V_TUT/src/hello/client
 cat - <<EOF >$V_TUT/src/hello/client/main.go
package main

import (
  "flag"
  "fmt"
  "time"
  "hello/ifc"
  "v.io/v23"
  "v.io/v23/context"
  _ "v.io/x/ref/runtime/factories/generic"
)

var (
  server = flag.String(
      "server", "", "Name of the server to connect to")
)

func main() {
  ctx, shutdown := v23.Init()
  defer shutdown()
  f := ifc.HelloClient(*server)
  ctx, cancel := context.WithTimeout(ctx, time.Minute)
  defer cancel()
  hello, _ := f.Get(ctx)
  fmt.Println(hello)
}
EOF
go install hello/client
#----------------------------------------------------------------------#  End 8 of 12

#----------------------------------------------------------------------#  Start 9 of 12
echo "# @principalTutorial (block #9 in __AnyLabel__) of content/tutorials/hello-world.md"

$V_BIN/principal create \
    --overwrite $V_TUT/cred/basics tutorial
#----------------------------------------------------------------------#  End 9 of 12

#----------------------------------------------------------------------#  Start 10 of 12
echo "# @runServerAsPrincipal (block #10 in __AnyLabel__) of content/tutorials/hello-world.md"

PORT_HELLO=23000  # Pick an unused port.
kill_tut_process TUT_PID_SERVER
$V_TUT/bin/server \
    --v23.credentials $V_TUT/cred/basics \
    --v23.tcp.address :$PORT_HELLO &
TUT_PID_SERVER=$!
sleep 2s # Added by mdrip
#----------------------------------------------------------------------#  End 10 of 12

#----------------------------------------------------------------------#  Start 11 of 12
echo "# @runClientAsPrincipal (block #11 in __AnyLabel__) of content/tutorials/hello-world.md"

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/basics \
    --server /localhost:$PORT_HELLO
#----------------------------------------------------------------------#  End 11 of 12

#----------------------------------------------------------------------#  Start 12 of 12
echo "# @killServer (block #12 in __AnyLabel__) of content/tutorials/hello-world.md"

kill_tut_process TUT_PID_SERVER
#----------------------------------------------------------------------#  End 12 of 12

echo " "
echo "All done.  No errors."
