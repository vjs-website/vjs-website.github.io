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
# Script @__AnyLabel__ from content/tutorials/basics.md 
#
#----------------------------------------------------------------------#  Start 1 of 16
echo "# @defineService (block #1 in __AnyLabel__) of content/tutorials/basics.md"

mkdir -p $V_TUT/src/fortune/ifc
 cat - <<EOF >$V_TUT/src/fortune/ifc/fortune.vdl
package ifc

type Fortune interface {
  // Returns a random fortune.
  Get() (wisdom string | error)
  // Adds a fortune to the set used by Get().
  Add(wisdom string) error
}
EOF
#----------------------------------------------------------------------#  End 1 of 16

#----------------------------------------------------------------------#  Start 2 of 16
echo "# @compileInterface (block #2 in __AnyLabel__) of content/tutorials/basics.md"

VDLROOT=$V23_RELEASE/src/v.io/v23/vdlroot \
    VDLPATH=$V_TUT/src \
    $V_BIN/vdl generate --lang go $V_TUT/src/fortune/ifc
go build fortune/ifc
#----------------------------------------------------------------------#  End 2 of 16

#----------------------------------------------------------------------#  Start 3 of 16
echo "# @serviceImpl (block #3 in __AnyLabel__) of content/tutorials/basics.md"

mkdir -p $V_TUT/src/fortune/service
 cat - <<EOF >$V_TUT/src/fortune/service/service.go
package service

import (
  "math/rand"
  "fortune/ifc"
  "sync"
  "v.io/v23/context"
  "v.io/v23/rpc"
)

type impl struct {
  wisdom []string      // All known fortunes.
  random *rand.Rand    // To pick a random index in 'wisdom'.
  mu     sync.RWMutex  // To safely enable concurrent use.
}

// Makes an implementation.
func Make() ifc.FortuneServerMethods {
  return &impl {
    wisdom: []string{
        "You will reach the heights of success.",
        "Conquer your fears or they will conquer you.",
        "Today is your lucky day!",
    },
    random: rand.New(rand.NewSource(99)),
  }
}

func (f *impl) Get(_ *context.T, _ rpc.ServerCall) (blah string, err error) {
  f.mu.RLock()
  defer f.mu.RUnlock()
  if len(f.wisdom) == 0 {
    return "[empty]", nil
  }
  return f.wisdom[f.random.Intn(len(f.wisdom))], nil
}

func (f *impl) Add(_ *context.T, _ rpc.ServerCall, blah string) error {
  f.mu.Lock()
  defer f.mu.Unlock()
  f.wisdom = append(f.wisdom, blah)
  return nil
}
EOF
go build fortune/service
#----------------------------------------------------------------------#  End 3 of 16

#----------------------------------------------------------------------#  Start 4 of 16
echo "# @authorizer (block #4 in __AnyLabel__) of content/tutorials/basics.md"

mkdir -p $V_TUT/src/fortune/server/util
 cat - <<EOF >$V_TUT/src/fortune/server/util/authorizer.go
package util

import (
  "v.io/v23/security"
)

// Returns Vanadium's default authorizer.
func MakeAuthorizer() security.Authorizer {
  return security.DefaultAuthorizer()
}
EOF
go build fortune/server/util
#----------------------------------------------------------------------#  End 4 of 16

#----------------------------------------------------------------------#  Start 5 of 16
echo "# @dispatcher (block #5 in __AnyLabel__) of content/tutorials/basics.md"

mkdir -p $V_TUT/src/fortune/server/util
 cat - <<EOF >$V_TUT/src/fortune/server/util/dispatcher.go
package util

import (
  "v.io/v23/rpc"
)

// Returns nil to trigger use of the default dispatcher.
func MakeDispatcher() (d rpc.Dispatcher) {
  return nil
}
EOF
go build fortune/server/util
#----------------------------------------------------------------------#  End 5 of 16

#----------------------------------------------------------------------#  Start 6 of 16
echo "# @intializer (block #6 in __AnyLabel__) of content/tutorials/basics.md"

mkdir -p $V_TUT/src/fortune/server/util
 cat - <<EOF >$V_TUT/src/fortune/server/util/initializer.go
package util

import (
  "flag"
  "fmt"
  "io/ioutil"
  "log"

  "v.io/v23/naming"
)

var (
  fileName = flag.String(
      "endpoint-file-name", "",
      "Write endpoint address to given file.")
)

func SaveEndpointToFile(e naming.Endpoint) {
  if *fileName == "" {
    return
  }
  contents := []byte(
      naming.JoinAddressName(e.String(), "") + "\n")
  if ioutil.WriteFile(*fileName, contents, 0644) != nil {
    log.Panic("Error writing ", *fileName)
  }
  fmt.Printf("Wrote endpoint name to %v.\n", *fileName)
}

EOF
go build fortune/server/util
#----------------------------------------------------------------------#  End 6 of 16

#----------------------------------------------------------------------#  Start 7 of 16
echo "# @server (block #7 in __AnyLabel__) of content/tutorials/basics.md"

mkdir -p $V_TUT/src/fortune/server
 cat - <<EOF >$V_TUT/src/fortune/server/main.go
package main

import (
  "flag"
  "fmt"
  "log"
  "fortune/ifc"
  "fortune/server/util"
  "fortune/service"

  "v.io/v23"
  "v.io/v23/rpc"
  "v.io/x/ref/lib/signals"
  _ "v.io/x/ref/runtime/factories/generic"
)

var (
  serviceName = flag.String(
      "service-name", "",
      "Name for service in default mount table.")
)

func main() {
  ctx, shutdown := v23.Init()
  defer shutdown()

  // Attach the 'fortune service' implementation
  // defined above to a queriable, textual description
  // of the implementation used for service discovery.
  fortune := ifc.FortuneServer(service.Make())

  // If the dispatcher isn't nil, it's presumed to have
  // obtained its authorizer from util.MakeAuthorizer().
  dispatcher := util.MakeDispatcher()

  // Start serving.
  var err error
  var server rpc.Server
  if dispatcher == nil {
    // Use the default dispatcher.
    _, server, err = v23.WithNewServer(
        ctx, *serviceName, fortune, util.MakeAuthorizer())
  } else {
    _, server, err = v23.WithNewDispatchingServer(
        ctx, *serviceName, dispatcher)
  }
  if err != nil {
    log.Panic("Error serving service: ", err)
  }
  endpoint := server.Status().Endpoints[0]
  util.SaveEndpointToFile(endpoint)
  fmt.Printf("Listening at: %v\n", endpoint)

  // Wait forever.
  <-signals.ShutdownOnSignals(ctx)
}
EOF
go install fortune/server
#----------------------------------------------------------------------#  End 7 of 16

#----------------------------------------------------------------------#  Start 8 of 16
echo "# @client (block #8 in __AnyLabel__) of content/tutorials/basics.md"

mkdir -p $V_TUT/src/fortune/client
 cat - <<EOF >$V_TUT/src/fortune/client/main.go
package main

import (
  "flag"
  "fmt"
  "time"

  "fortune/ifc"

  "v.io/v23"
  "v.io/v23/context"
  "v.io/x/lib/vlog"
  _ "v.io/x/ref/runtime/factories/generic"
)

var (
  server = flag.String(
      "server", "", "Name of the server to connect to")
  newFortune = flag.String(
      "add", "", "A new fortune to add to the server's set")
)

func main() {
  ctx, shutdown := v23.Init()
  defer shutdown()

  if *server == "" {
    vlog.Error("--server must be specified")
    return
  }
  f := ifc.FortuneClient(*server)
  ctx, cancel := context.WithTimeout(ctx, time.Minute)
  defer cancel()

  if *newFortune == "" { // --add flag not specified
    fortune, err := f.Get(ctx)
    if err != nil {
      vlog.Errorf("error getting fortune: %v", err)
      return
    }
    fmt.Println(fortune)
  } else {
    if err := f.Add(ctx, *newFortune); err != nil {
      vlog.Errorf("error adding fortune: %v", err)
      return
    }
  }
}
EOF
go install fortune/client
#----------------------------------------------------------------------#  End 8 of 16

#----------------------------------------------------------------------#  Start 9 of 16
echo "# @principalTutorial (block #9 in __AnyLabel__) of content/tutorials/basics.md"

$V_BIN/principal create \
    --overwrite $V_TUT/cred/basics tutorial
#----------------------------------------------------------------------#  End 9 of 16

#----------------------------------------------------------------------#  Start 10 of 16
echo "# @runServerAsPrincipal (block #10 in __AnyLabel__) of content/tutorials/basics.md"

kill_tut_process TUT_PID_SERVER
$V_TUT/bin/server \
    --v23.credentials $V_TUT/cred/basics \
    --endpoint-file-name $V_TUT/server.txt &
TUT_PID_SERVER=$!
sleep 2s # Added by mdrip
#----------------------------------------------------------------------#  End 10 of 16

#----------------------------------------------------------------------#  Start 11 of 16
echo "# @runClientAsPrincipal (block #11 in __AnyLabel__) of content/tutorials/basics.md"

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/basics \
    --server `cat $V_TUT/server.txt`
#----------------------------------------------------------------------#  End 11 of 16

#----------------------------------------------------------------------#  Start 12 of 16
echo "# @clientGet (block #12 in __AnyLabel__) of content/tutorials/basics.md"

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/basics \
    --server `cat $V_TUT/server.txt` \
    --add 'Fortune favors the bold.'
#----------------------------------------------------------------------#  End 12 of 16

#----------------------------------------------------------------------#  Start 13 of 16
echo "# @checkMethods (block #13 in __AnyLabel__) of content/tutorials/basics.md"

$V_BIN/vrpc --v23.credentials $V_TUT/cred/basics \
    call `cat $V_TUT/server.txt` Get
$V_BIN/vrpc --v23.credentials $V_TUT/cred/basics \
    call `cat $V_TUT/server.txt` Add \"More cowbell.\"
#----------------------------------------------------------------------#  End 13 of 16

#----------------------------------------------------------------------#  Start 14 of 16
echo "# @checkTheSignature (block #14 in __AnyLabel__) of content/tutorials/basics.md"

$V_BIN/vrpc --v23.credentials $V_TUT/cred/basics \
  signature `cat $V_TUT/server.txt`
#----------------------------------------------------------------------#  End 14 of 16

#----------------------------------------------------------------------#  Start 15 of 16
echo "# @checkMethods (block #15 in __AnyLabel__) of content/tutorials/basics.md"

$V_BIN/vrpc --v23.credentials $V_TUT/cred/basics \
  signature `cat $V_TUT/server.txt` Add
$V_BIN/vrpc --v23.credentials $V_TUT/cred/basics \
  signature `cat $V_TUT/server.txt` Get
#----------------------------------------------------------------------#  End 15 of 16

#----------------------------------------------------------------------#  Start 16 of 16
echo "# @killServer (block #16 in __AnyLabel__) of content/tutorials/basics.md"

kill_tut_process TUT_PID_SERVER
#----------------------------------------------------------------------#  End 16 of 16

#
# Script @__AnyLabel__ from content/tutorials/security/principals-and-blessings.md 
#
#----------------------------------------------------------------------#  Start 1 of 21
echo "# @makeAliceAndBob (block #1 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal create --overwrite $V_TUT/cred/alice alice
$V_BIN/principal create --overwrite $V_TUT/cred/bob bob
#----------------------------------------------------------------------#  End 1 of 21

#----------------------------------------------------------------------#  Start 2 of 21
echo "# @runServerAsAlice (block #2 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

kill_tut_process TUT_PID_SERVER
$V_TUT/bin/server \
    --v23.credentials $V_TUT/cred/alice \
    --endpoint-file-name $V_TUT/server.txt &
TUT_PID_SERVER=$!
sleep 2s # Added by mdrip
#----------------------------------------------------------------------#  End 2 of 21

#----------------------------------------------------------------------#  Start 3 of 21
echo "# @runClientAsAlice (block #3 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/alice \
    --server `cat $V_TUT/server.txt`
#----------------------------------------------------------------------#  End 3 of 21

#----------------------------------------------------------------------#  Start 4 of 21
echo "# @aliceBlessBobAsFriend (block #4 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal bless \
    --v23.credentials $V_TUT/cred/alice \
    --for=24h $V_TUT/cred/bob friend:bob | \
        $V_BIN/principal \
            --v23.credentials $V_TUT/cred/bob \
            set forpeer - alice
#----------------------------------------------------------------------#  End 4 of 21

#----------------------------------------------------------------------#  Start 5 of 21
echo "# @clientAsBob (block #5 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/bob \
    --server `cat $V_TUT/server.txt`
#----------------------------------------------------------------------#  End 5 of 21

#----------------------------------------------------------------------#  Start 6 of 21
echo "# @killServer (block #6 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

kill_tut_process TUT_PID_SERVER
#----------------------------------------------------------------------#  End 6 of 21

#----------------------------------------------------------------------#  Start 7 of 21
echo "# @principalAliceDump (block #7 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/alice \
    dump
#----------------------------------------------------------------------#  End 7 of 21

#----------------------------------------------------------------------#  Start 8 of 21
echo "# @principalAliceGetPublicKey (block #8 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/alice \
    get publickey --pretty
#----------------------------------------------------------------------#  End 8 of 21

#----------------------------------------------------------------------#  Start 9 of 21
echo "# @principalAliceGetDefault (block #9 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/alice \
    get default -names
#----------------------------------------------------------------------#  End 9 of 21

#----------------------------------------------------------------------#  Start 10 of 21
echo "# @principalAliceGetPeerMap (block #10 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/alice \
    get peermap
#----------------------------------------------------------------------#  End 10 of 21

#----------------------------------------------------------------------#  Start 11 of 21
echo "# @principalAliceGetRoots (block #11 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/alice \
    get recognizedroots
#----------------------------------------------------------------------#  End 11 of 21

#----------------------------------------------------------------------#  Start 12 of 21
echo "# @principalBobDump (block #12 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/bob \
    dump
#----------------------------------------------------------------------#  End 12 of 21

#----------------------------------------------------------------------#  Start 13 of 21
echo "# @comparePublicKeys (block #13 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

keyAlice=`$V_BIN/principal \
    --v23.credentials $V_TUT/cred/alice \
    get publickey --pretty`
keyBob=`$V_BIN/principal \
    --v23.credentials $V_TUT/cred/bob \
    get publickey --pretty`
echo -e "alice   $keyAlice\n  bob   $keyBob"
#----------------------------------------------------------------------#  End 13 of 21

#----------------------------------------------------------------------#  Start 14 of 21
echo "# @principalBobGetDefault (block #14 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/bob \
    get default -names
#----------------------------------------------------------------------#  End 14 of 21

#----------------------------------------------------------------------#  Start 15 of 21
echo "# @principalBobGetPeerMap (block #15 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/bob \
    get peermap
#----------------------------------------------------------------------#  End 15 of 21

#----------------------------------------------------------------------#  Start 16 of 21
echo "# @principalBobGetRoots (block #16 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/bob \
    get recognizedroots
#----------------------------------------------------------------------#  End 16 of 21

#----------------------------------------------------------------------#  Start 17 of 21
echo "# @principalBobDumpBlessings (block #17 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/bob \
    get forpeer alice | \
         $V_BIN/principal dumpblessings -
#----------------------------------------------------------------------#  End 17 of 21

#----------------------------------------------------------------------#  Start 18 of 21
echo "# @principalBobGetForPeerName (block #18 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/bob \
    get forpeer -names alice
#----------------------------------------------------------------------#  End 18 of 21

#----------------------------------------------------------------------#  Start 19 of 21
echo "# @principalBobGetForPeerRoots (block #19 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/bob \
    get forpeer -rootkey=alice:friend:bob alice
#----------------------------------------------------------------------#  End 19 of 21

#----------------------------------------------------------------------#  Start 20 of 21
echo "# @echoAlicesKey (block #20 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

echo $keyAlice
#----------------------------------------------------------------------#  End 20 of 21

#----------------------------------------------------------------------#  Start 21 of 21
echo "# @principalBobGetForPeerCaveats (block #21 in __AnyLabel__) of content/tutorials/security/principals-and-blessings.md"

$V_BIN/principal \
    --v23.credentials $V_TUT/cred/bob \
    get forpeer -caveats=alice:friend:bob alice
#----------------------------------------------------------------------#  End 21 of 21

#
# Script @__AnyLabel__ from content/tutorials/security/permissions-authorizer.md 
#
#----------------------------------------------------------------------#  Start 1 of 9
echo "# @fortuneInterfaceWithTags (block #1 in __AnyLabel__) of content/tutorials/security/permissions-authorizer.md"

 cat - <<EOF >$V_TUT/src/fortune/ifc/fortune.vdl
package ifc

type MyTag string
const (
  Reader = MyTag("R")
  Writer = MyTag("W")
)

type Fortune interface {
  // Returns a random fortune.
  Get() (Fortune string | error) {Reader}
  // Adds a fortune to the set used by Get().
  Add(Fortune string) error {Writer}
}
EOF

VDLROOT=$V23_RELEASE/src/v.io/v23/vdlroot \
    VDLPATH=$V_TUT/src \
    $V_BIN/vdl generate --lang go $V_TUT/src/fortune/ifc
go build fortune/ifc
#----------------------------------------------------------------------#  End 1 of 9

#----------------------------------------------------------------------#  Start 2 of 9
echo "# @permissionsAuthorizer (block #2 in __AnyLabel__) of content/tutorials/security/permissions-authorizer.md"

 cat - <<EOF >$V_TUT/src/fortune/server/util/authorizer.go
package util

import (
  "bytes"
  "flag"
  "fortune/ifc"
  "v.io/v23/security"
  "v.io/v23/security/access"
  "v.io/v23/vdl"
)

var (
	perms = flag.String("perms", "",
      "JSON-encoded access.Permissions.")
)

func MakeAuthorizer() (authorizer security.Authorizer) {
  aMap, _ := access.ReadPermissions(
      bytes.NewBufferString(*perms))
  typ := vdl.TypeOf(ifc.Reader)
  authorizer, _ = access.PermissionsAuthorizer(aMap, typ)
  return
}
EOF

go install fortune/server
#----------------------------------------------------------------------#  End 2 of 9

#----------------------------------------------------------------------#  Start 3 of 9
echo "# @startServerWithPerms (block #3 in __AnyLabel__) of content/tutorials/security/permissions-authorizer.md"

kill_tut_process TUT_PID_SERVER
$V_TUT/bin/server \
    --v23.credentials $V_TUT/cred/alice \
    --endpoint-file-name $V_TUT/server.txt \
    --perms '{"R": {"In": ["alice:family",
                           "alice:friend"]},
              "W": {"In": ["alice:family"]}}' &
TUT_PID_SERVER=$!
sleep 2s # Added by mdrip
#----------------------------------------------------------------------#  End 3 of 9

#----------------------------------------------------------------------#  Start 4 of 9
echo "# @bobCanRead (block #4 in __AnyLabel__) of content/tutorials/security/permissions-authorizer.md"

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/bob \
    --server `cat $V_TUT/server.txt`
#----------------------------------------------------------------------#  End 4 of 9

#----------------------------------------------------------------------#  Start 5 of 9
echo "# @bobCannotWrite (block #5 in __AnyLabel__) of content/tutorials/security/permissions-authorizer.md"

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/bob \
    --server `cat $V_TUT/server.txt` \
    --add 'Bob is awesome.'
#----------------------------------------------------------------------#  End 5 of 9

#----------------------------------------------------------------------#  Start 6 of 9
echo "# @createCarol (block #6 in __AnyLabel__) of content/tutorials/security/permissions-authorizer.md"

$V_BIN/principal create --overwrite $V_TUT/cred/carol carol
#----------------------------------------------------------------------#  End 6 of 9

#----------------------------------------------------------------------#  Start 7 of 9
echo "# @aliceBlessCarolAsSister (block #7 in __AnyLabel__) of content/tutorials/security/permissions-authorizer.md"

$V_BIN/principal bless \
    --v23.credentials $V_TUT/cred/alice \
    --for=24h $V_TUT/cred/carol family:sister | \
        $V_BIN/principal set \
            --v23.credentials $V_TUT/cred/carol \
            forpeer - alice
#----------------------------------------------------------------------#  End 7 of 9

#----------------------------------------------------------------------#  Start 8 of 9
echo "# @clientIsCarol (block #8 in __AnyLabel__) of content/tutorials/security/permissions-authorizer.md"

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/carol \
    --server `cat $V_TUT/server.txt`

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/carol \
    --server `cat $V_TUT/server.txt` \
    --add 'Eat kale.'
#----------------------------------------------------------------------#  End 8 of 9

#----------------------------------------------------------------------#  Start 9 of 9
echo "# @killServer (block #9 in __AnyLabel__) of content/tutorials/security/permissions-authorizer.md"

kill_tut_process TUT_PID_SERVER
#----------------------------------------------------------------------#  End 9 of 9

#
# Script @__AnyLabel__ from content/tutorials/security/custom-authorizer.md 
#
#----------------------------------------------------------------------#  Start 1 of 7
echo "# @authorizerWithFriendWindow (block #1 in __AnyLabel__) of content/tutorials/security/custom-authorizer.md"

 cat - <<EOF >$V_TUT/src/fortune/server/util/authorizer.go
package util

import (
  "flag"
  "fmt"
  "time"
  "v.io/v23/context"
  "v.io/v23/security"
)

var (
  openStart  = flag.Int(
    "start", 12, "Hour when friends may start access.")
  openLength = flag.Int(
    "length", 1, "Number of hours the window stays open.")
)

type policy struct{}

func (policy) Authorize(ctx *context.T, call security.Call) error {
  var (
    client, _  = security.RemoteBlessingNames(ctx, call)
    hour, _, _ = time.Now().Clock()
    friendsOk  = hour >= *openStart &&
                 hour < (*openStart + *openLength)

    // Patterns on the blessings of authorized folks.
    friends = security.BlessingPattern("alice:friend")
    family  = security.BlessingPattern("alice:family")
  )
  // The client may present multiple blessings, check if any
  // of them satisfy the policy.
  if family.MatchedBy(client...) {
      // family is always okay, so this request is authorized.
      return nil
  }
  if friends.MatchedBy(client...) {
    // Friends only allowed in a given time window.
    if friendsOk {
      return nil
    }
    return fmt.Errorf(
        "friends like %v not authorized at this hour (%d)",
        client, hour)
  }
  // Nobody else is authorized
  return fmt.Errorf("not friend nor family, not authorized")
}

func MakeAuthorizer() security.Authorizer {
  return policy{}
}
EOF
go install fortune/server
#----------------------------------------------------------------------#  End 1 of 7

#----------------------------------------------------------------------#  Start 2 of 7
echo "# @serverAsAliceWithFriendWindow (block #2 in __AnyLabel__) of content/tutorials/security/custom-authorizer.md"

kill_tut_process TUT_PID_SERVER
$V_TUT/bin/server \
    --v23.credentials $V_TUT/cred/alice \
    --endpoint-file-name $V_TUT/server.txt \
    --start `date +%k` &
TUT_PID_SERVER=$!
sleep 2s # Added by mdrip
#----------------------------------------------------------------------#  End 2 of 7

#----------------------------------------------------------------------#  Start 3 of 7
echo "# @clientAsBob (block #3 in __AnyLabel__) of content/tutorials/security/custom-authorizer.md"

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/bob \
    --server `cat $V_TUT/server.txt`
#----------------------------------------------------------------------#  End 3 of 7

#----------------------------------------------------------------------#  Start 4 of 7
echo "# @serverRejectingBob (block #4 in __AnyLabel__) of content/tutorials/security/custom-authorizer.md"

kill_tut_process TUT_PID_SERVER
$V_TUT/bin/server \
    --v23.credentials $V_TUT/cred/alice \
    --endpoint-file-name $V_TUT/server.txt \
    --start `expr \`date +%k\` + 3` &
TUT_PID_SERVER=$!
#----------------------------------------------------------------------#  End 4 of 7

#----------------------------------------------------------------------#  Start 5 of 7
echo "# @bobIsRejected (block #5 in __AnyLabel__) of content/tutorials/security/custom-authorizer.md"

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/bob \
    --server `cat $V_TUT/server.txt`
#----------------------------------------------------------------------#  End 5 of 7

#----------------------------------------------------------------------#  Start 6 of 7
echo "# @clientAsCarol (block #6 in __AnyLabel__) of content/tutorials/security/custom-authorizer.md"

$V_TUT/bin/client \
    --v23.credentials $V_TUT/cred/carol \
    --server `cat $V_TUT/server.txt`
#----------------------------------------------------------------------#  End 6 of 7

#----------------------------------------------------------------------#  Start 7 of 7
echo "# @killServer (block #7 in __AnyLabel__) of content/tutorials/security/custom-authorizer.md"

kill_tut_process TUT_PID_SERVER
#----------------------------------------------------------------------#  End 7 of 7

echo " "
echo "All done.  No errors."
