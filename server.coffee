
# TODO: Need better args parser.

# when command line arguments are passed into this, we ignore them
# when loading the config file.

# apf debug doesn't exist, or it's older than three days--rebuild it
# use this specific packed file
boot = ->
  configPath = path.resolve(__dirname, "./configs/", configName)
  plugins = require(configPath)
  
  # server plugins
  plugins.forEach (plugin) ->
    if plugin.packagePath and /\.\/cloud9.core$/.test(plugin.packagePath)
      plugin.debug = debug
      plugin.packed = packed
      plugin.packedName = packedName

  architect.createApp architect.resolveConfig(plugins, __dirname + "/plugins-server"), (err, app) ->
    if err
      console.error "While starting the '%s':", configPath
      throw err
    console.log "Started '%s'!", configPath

path = require("path")
architect = require("architect")
spawn = require("child_process").spawn
fs = require("fs")
configName = process.argv[2] or "default"
configName = "default"  if configName.indexOf("-") is 0
debug = false
packed = false
packedName = ""
p = 2

while p < process.argv.length
  if process.argv[p] is "-d"
    debug = true
    if not path.existsSync("plugins-client/lib.apf/www/apf-packaged/apf_debug.js") or (path.existsSync("plugins-client/lib.apf/www/apf-packaged/apf_debug.js")) and ((new Date() - fs.statSync("plugins-client/lib.apf/www/apf-packaged/apf_debug.js").mtime.valueOf()) / 86400000) >= 3
      console.log "Building apfdebug for first run..."
      buildDebug = spawn("npm", ["run-script", "build-debug"])
      buildDebug.stderr.setEncoding "utf8"
      buildDebug.stderr.on "data", (data) ->
        console.error data

      buildDebug.on "exit", (code) ->
        if code isnt 0
          console.error "build-debug process exited with code " + code
          process.exit code
        boot()

    else
      boot()
  else if process.argv[p] is "-P"
    packed = true
    if process.argv[p + 1] and process.argv[p + 1].indexOf("-") < 0
      packedName = process.argv[++p]
    else
      packedName = "c9os.min.js"
    configName = "packed"
    if not path.existsSync("plugins-client/lib.packed/www/" + packedName) and not path.existsSync("plugins-client/lib.packed/www/" + packedName + ".gz")
      console.log "Building packed file for first run...Please wait..."
      console.log "   |\\      _,,,---,,_\n" + "   /,`.-'`'    -.  ;-;;,_\n" + "   |,4-  ) )-,_..;\\ (  `'-'\n" + "   '---''(_/--'  `-'\\_)  Felix Lee"
      buildPackage = spawn("npm", ["run-script", "build-packed"])
      buildPackage.stderr.setEncoding "utf8"
      buildPackage.stderr.on "data", (data) ->
        console.error data

      buildPackage.on "exit", (code) ->
        if code isnt 0
          console.error "build-package process exited with code " + code
          process.exit code
        boot()

    else
      boot()
  p++
boot()  if debug is false and packed is false
