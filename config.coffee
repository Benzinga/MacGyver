fs   = require 'fs'
path = require 'path'
_    = require 'underscore'

bowerPathMap = JSON.parse fs.readFileSync('bower-paths.json', 'utf8')
bowerPaths = _(for name, filename of bowerPathMap
  if /(\.js$)|(\.coffee$)|(\.css$)|(\.styl$)|(\.less$)/.exec filename
    filename
  else
    "#{filename}/#{path.basename filename}.js"
).flatten()

vendorPath = (filename) ->
  if filename.indexOf('vendor/') is 0
    if filename.indexOf('vendor/bower/') is 0
      filename in bowerPaths
    else
      filename.indexOf("brunch_JavaScriptCompiler_") < 0

  else
    false

beforePaths = _(bowerPaths).union([
    'app/main.coffee'
  ])

exports.config =
  # See http://brunch.readthedocs.org/en/latest/config.html for documentation.
  modules:
    wrapper: false
    definition: false

  paths:
    public: "example"
  files:
    javascripts:
      joinTo:
        'js/angular-util.js': /^app/
        'js/vendor.js': vendorPath
      order:
        # Files in `vendor` directories are compiled before other files
        # even if they aren't specified in order.before.
        before: beforePaths

    stylesheets:
      joinTo:
        'css/app.css': (filename) ->
          /^vendor\/bower\//.exec(filename)? or vendorPath filename

  server:
    port: 4545
    run: true

