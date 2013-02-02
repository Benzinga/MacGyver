fs            = require "fs"
path          = require "path"
child_process = require "child_process"
bower         = require "bower"
wrench        = require "wrench"

testacularPath = "./node_modules/.bin/testacular"
brunchPath     = "./node_modules/brunch/bin/brunch"
examplePath    = "example/"
finalBuildPath = "lib/"
componentFile  = "component.json"

spawn = (command, args = [], callback = ->) ->
  ps = child_process.spawn command, args

  addLogging = (obj) ->
    obj.setEncoding "utf8"
    obj.on "data", (data) -> console.log data

  addLogging ps.stdout
  addLogging ps.stderr

  ps.on "exit", callback

updateBowerPaths = ->
  bower.commands.list(paths: true).on "data", (files) ->
    fs.writeFile "bower-paths.json", JSON.stringify(files), "utf8"

copyImagesDirectory = ->
  fromDir = path.join examplePath, "css/images"
  toDir   = path.join finalBuildPath, "images"
  wrench.copyDirSyncRecursive fromDir, toDir

task "update:paths", "Update bower paths file", -> updateBowerPaths()

task "test", "Run tests with testacular", ->
  spawn testacularPath, ["start", "test/testacular.conf.js"]

task "build:images", "Copy images to build directory", -> copyImagesDirectory()

task "build", "Build the latest MacGyver", ->
  spawn brunchPath, ["build"], ->

    # Copy macgyver js to lib
    # Replace templateUrl with actual html
    fromFile         = path.join examplePath, "js/macgyver.js"
    writeFile        = path.join finalBuildPath, "macgyver.js"
    templateUrlRegex = /templateUrl: "([^"]+)"/g

    fs.readFile fromFile, "utf8", (err, data) ->
      throw err if err?

      updatedCode = data

      while match = templateUrlRegex.exec data
        toReplace    = match[0]
        filePath     = path.join examplePath, match[1]
        compiledHtml = fs.readFileSync filePath, "utf8"
        compiledHtml = compiledHtml.replace /"/g, "\\\""
        updatedCode  = updatedCode.replace toReplace, "template: \"#{compiledHtml}\""

      fs.writeFile writeFile, updatedCode, "utf8", (err, data) ->
        console.log "MacGyver built successfully"

    # Copy macgyver css
    fromCssFile  = path.join examplePath, "css/app.css"
    writeCssFile = path.join finalBuildPath, "macgyver.css"
    fs.createReadStream(fromCssFile).pipe fs.createWriteStream(writeCssFile)

    copyImagesDirectory()

    # Read all files in build folder and add to component.json
    fileList = wrench.readdirSyncRecursive finalBuildPath
    fs.readFile componentFile, "utf8", (err, data) ->
      throw err if err?

      newArray = JSON.stringify fileList
      data     = data.replace /"main": \[[^\]]+]/, "\"main\": #{newArray}"

      fs.writeFile componentFile, data, "utf8", (err, data) ->
        console.log "Updated component.json"

  # Generate documentation from source code
