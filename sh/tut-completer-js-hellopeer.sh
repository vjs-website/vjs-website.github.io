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
# Script @__AnyLabel__ from content/tutorials/javascript/hellopeer.md 
#
#----------------------------------------------------------------------#  Start 1 of 11
echo "# @createProjectDir (block #1 in __AnyLabel__) of content/tutorials/javascript/hellopeer.md"

export V_TUT=${V_TUT-$HOME/v23_tutorial}
mkdir -p $V_TUT
#----------------------------------------------------------------------#  End 1 of 11

#----------------------------------------------------------------------#  Start 2 of 11
echo "# @removeThisBlockBeforeRelease (block #2 in __AnyLabel__) of content/tutorials/javascript/hellopeer.md"

cd $V_TUT
echo "{}" > $V_TUT/package.json
npm install git+https://vanadium.googlesource.com/release.js.core
npm install browserify node-static
#----------------------------------------------------------------------#  End 2 of 11

#----------------------------------------------------------------------#  Start 3 of 11
echo "# @helloPeerJS (block #3 in __AnyLabel__) of content/tutorials/javascript/hellopeer.md"

mkdir -p $V_TUT/src/hello
cat - <<EOF >$V_TUT/src/hello/peer.js
var vanadium = require('vanadium');

// Define HelloService and the hello() method.
function HelloService() {}

HelloService.prototype.hello = function(ctx, serverCall, greeting) {
  displayHello(greeting);
};

// Initialize Vanadium runtime.
vanadium.init(function(err, runtime) {
  if (err) {
    showStatus('Initialization error: ' + err);
    return;
  }
  showStatus('Initialized');
  runtime.on('crash', function(err) {
    showStatus('The runtime has crashed unexpectedly and the page must be reloaded.');
  });

  setupServer(runtime);
  setupClient(runtime);
});

// Setup the server.
function setupServer(runtime) {
  // Create a server and serve the HelloService.
  var serviceName = getLocalPeerName(runtime.accountName);
  runtime.newServer(serviceName, new HelloService(), function(err) {
    if (err) {
      showServerStatus('Failed to serve ' + serviceName + ': ' + err);
      return;
    }
    showServerStatus('Serving');
    // HelloService is now served.
  });
}

// Setup the client.
function setupClient(runtime) {
  // Create a client and bind to the service.
  var client = runtime.getClient();
  var ctx = runtime.getContext();

  var serviceName = getRemotePeerName(runtime.accountName);
  showClientStatus('Binding');
  client.bindTo(ctx, serviceName, function(err, helloService) {
    if (err) {
      showClientStatus('Failed to bind to ' + serviceName + ': ' + err);
      return;
    }
    showClientStatus('Ready');

    registerButtonHandler(function(greeting) {
      showClientStatus('Calling');
      // Call hello() on the service.
      helloService.hello(ctx, greeting, function(err) {
        if (err) {
          showClientStatus('Error invoking hello(): ' + err);
          return;
        }
        showClientStatus('Ready');
      });
    });
  });
}

// Get the local and remote names.
function getLocalPeerName(accountName) {
  var homeDir = accountName.replace(/^dev.v.io:u:/, 'users/').replace(vanadium.security.ChainSeparator.val, '/');
  var hash = window.location.hash;
  return homeDir + '/tutorial/hello' + hash;
}
function getRemotePeerName(accountName) {
  var localPeer = getLocalPeerName(accountName);
  var splitPeer = localPeer.split('#');
  if (splitPeer[1] == 'A') {
    splitPeer[1] = 'B';
  } else {
    splitPeer[1] = 'A';
  }
  return splitPeer.join('#');
}

// Manipulate the html page.
function displayHello(greeting) {
  var li = document.createElement('li');
  li.textContent = greeting;
  document.getElementById('receivedhellos').appendChild(li);
}
function registerButtonHandler(fn) {
  document.getElementById('hellobutton').addEventListener('click', function() {
    var greeting = document.getElementById('hellotext').value;
    fn(greeting);
  });
}
function showClientStatus(text) {
  document.getElementById('clientstatus').textContent = text;
}
function showServerStatus(text) {
  document.getElementById('serverstatus').textContent = text;
}
function showStatus(text) {
  showClientStatus(text);
  showServerStatus(text);
}
EOF
#----------------------------------------------------------------------#  End 3 of 11

#----------------------------------------------------------------------#  Start 4 of 11
echo "# @browserifyServer (block #4 in __AnyLabel__) of content/tutorials/javascript/hellopeer.md"

mkdir -p $V_TUT/browser
NODE_PATH=$V_TUT $V_TUT/node_modules/.bin/browserify \
  $V_TUT/src/hello/peer.js -o $V_TUT/browser/hello-peer.js
#----------------------------------------------------------------------#  End 4 of 11

#----------------------------------------------------------------------#  Start 5 of 11
echo "# @helloPeerHTML (block #5 in __AnyLabel__) of content/tutorials/javascript/hellopeer.md"

cat - <<EOF >$V_TUT/browser/peer.html
 <!DOCTYPE html>
 <html>
 <head>
   <title>Hello Peer</title>
 </head>
 <body>
   <div>
     <div style="float:left;"><input id="hellotext" value="Hello World"></input><button id="hellobutton">Send</button></div>
     <div style="float:right; white-space:nowrap">
     <div>Client Status: <span id="clientstatus">Initializing</span></div>
     <div>Server Status: <span id="serverstatus">Initializing</span></div>
     </div>
   </div>
   <div style="clear:both;">
     Received Greetings:
     <ol id="receivedhellos"></ol>
   </div>
   <script src="hello-peer.js"></script>
 </body>
 </html>
EOF
#----------------------------------------------------------------------#  End 5 of 11

#----------------------------------------------------------------------#  Start 6 of 11
echo "# @helloMainHTML (block #6 in __AnyLabel__) of content/tutorials/javascript/hellopeer.md"

cat - <<EOF >$V_TUT/hello.html
 <!DOCTYPE html>
 <html>
 <head>
   <title>Hello Peers</title>
 </head>
 <body style="background: #000000;">
   <div style="position:fixed;top:0px;left:0px;bottom:0px;width:48%; background: #ffffff;">
     <iframe id="frameA" src="browser/peer.html#A" style="width:100%; height:100%;" frameBorder="0"></iframe>
   </div>
   <div style="position:fixed;top:0px;right:0px;bottom:0px;width:48%; background: #ffffff;">
     <iframe id="frameB" src="browser/peer.html#B" style="width:100%; height:100%;" frameBorder="0"></iframe>
   </div>
 </body>
 </html>

EOF
#----------------------------------------------------------------------#  End 6 of 11

#----------------------------------------------------------------------#  Start 7 of 11
echo "# @serveHello (block #7 in __AnyLabel__) of content/tutorials/javascript/hellopeer.md"

$V_TUT/node_modules/.bin/static $V_TUT -p 8989 > /dev/null &
TUT_PID_HTTPD=$!
sleep 2s # Added by mdrip
#----------------------------------------------------------------------#  End 7 of 11

#----------------------------------------------------------------------#  Start 8 of 11
echo "# @curlHello (block #8 in __AnyLabel__) of content/tutorials/javascript/hellopeer.md"

curl -f http://127.0.0.1:8989/hello.html > /dev/null
#----------------------------------------------------------------------#  End 8 of 11

#----------------------------------------------------------------------#  Start 9 of 11
echo "# @mavenEnv (block #9 in __AnyLabel__) of content/tutorials/javascript/hellopeer.md"

# Set WORKSPACE, if not chosen.
[ -z "$WORKSPACE" ] && export WORKSPACE=${JIRI_ROOT}/www

# Check that the environment variables exist.
echo ${CHROME_WEBDRIVER?} > /dev/null
echo ${GOOGLE_BOT_USERNAME?} > /dev/null
echo ${GOOGLE_BOT_PASSWORD?} > /dev/null
#----------------------------------------------------------------------#  End 9 of 11

#----------------------------------------------------------------------#  Start 10 of 11
echo "# @mavenTest (block #10 in __AnyLabel__) of content/tutorials/javascript/hellopeer.md"

# Run the maven test.
TMPDIR=/tmp xvfb-run -s '-ac -screen 0 1024x768x24' \
  mvn test \
  -f=$JIRI_ROOT/website/test/ui/pom.xml \
  -Dtest=HelloPeerUITest \
  -DchromeDriverBin=$CHROME_WEBDRIVER \
  -DhtmlReportsRelativePath=htmlReports \
  -DgoogleBotUsername=$GOOGLE_BOT_USERNAME \
  -DgoogleBotPassword=$GOOGLE_BOT_PASSWORD
#----------------------------------------------------------------------#  End 10 of 11

#----------------------------------------------------------------------#  Start 11 of 11
echo "# @cleanupHTTPD (block #11 in __AnyLabel__) of content/tutorials/javascript/hellopeer.md"

kill $TUT_PID_HTTPD
#----------------------------------------------------------------------#  End 11 of 11

echo " "
echo "All done.  No errors."
