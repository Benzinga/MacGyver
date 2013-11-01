module.exports = (grunt) ->
  require('matchdep').filterDev('grunt-*').forEach grunt.loadNpmTasks
  grunt.loadTasks "misc/grunt"

  grunt.initConfig
    pkg:       grunt.file.readJSON "package.json"
    jqueryUI:  grunt.file.readJSON "vendor/bower/jquery.ui/package.json"
    buildConf: grunt.file.readJSON "build.json"

    #
    # Coffeescript section
    # Compile all coffeescripts to tmp/app before concatenating
    #
    coffee:
      options:
        bare: true
      appCoffee:
        expand: true
        cwd:    "src"
        src:    ["**/*.coffee"]
        dest:   "tmp/app/"
        ext:    ".js"

    #
    # Concat section
    # jqueryui    - compile required jquery ui files
    # appJs       - concat all the application code into MacGyver.js
    # deployAppJs - concat all app code for deployment
    # modulesJs   - modularized js
    # css         - compile all css
    #
    concat:
      jqueryui:
        options:
          process: (src, filepath) ->
            src.replace /@VERSION/g, grunt.config.get("jqueryUI").version
        dest: "tmp/jqueryui.js"
        src:  "<%= buildConf.jqueryui %>"

      appJs:
        dest: "example/js/<%= pkg.name %>.js"
        src: "<%= buildConf.example %>"

      deployAppJs:
        dest: "lib/<%= pkg.name.toLowerCase() %>.js"
        src: "<%= buildConf.full %>"

      modulesJs:
        options:
          banner:"""/**
                     * MacGyver v<%= pkg.version %>
                     * @link <%= pkg.homepage %>
                     * @license <%= pkg.license[0].type %>
                     */
                    (function(window, angular, undefined) {

                  """
          footer: "\n})(window, window.angular);"
        files: [
          {
            src:  "<%= buildConf.core %>"
            dest: "lib/<%= pkg.name.toLowerCase() %>-core.js"
          }
          {
            src:  "<%= buildConf.filters %>"
            dest: "lib/<%= pkg.name.toLowerCase() %>-filters.js"
          }
          {
            src:  "<%= buildConf.underscoreFilter %>"
            dest: "lib/<%= pkg.name.toLowerCase() %>-string-filter.js"
          }
          {
            src:  "<%= buildConf.table %>"
            dest: "lib/<%= pkg.name.toLowerCase() %>-table.js"
          }
          {
            src:  "<%= buildConf.datepicker %>"
            dest: "lib/<%= pkg.name.toLowerCase() %>-datepicker.js"
          }
          {
            src:  "<%= buildConf.fileupload %>"
            dest: "lib/<%= pkg.name.toLowerCase() %>-fileupload.js"
          }
        ]

      css:
        files: [
          {
            dest: "example/css/vendor.css"
            src:  ["tmp/vendor.css"]
          }
          {
            dest: "example/css/<%= pkg.name.toLowerCase() %>.css"
            src: "<%= buildConf.css.example %>"
          }
        ]

      moduleCss:
        files: [
          {
            dest: "build/bower-macgyver/<%= pkg.name.toLowerCase() %>.css"
            src: "<%= buildConf.css.example %>"
          }
          {
            dest: "build/bower-macgyver-core/<%= pkg.name.toLowerCase() %>-core.css"
            src: "<%= buildConf.css.core %>"
          }
          {
            dest: "build/bower-macgyver-datepicker/<%= pkg.name.toLowerCase() %>-datepicker.css"
            src: "<%= buildConf.css.datepicker %>"
          }
          {
            dest: "build/bower-macgyver-fileupload/<%= pkg.name.toLowerCase() %>-fileupload.css"
            src: "<%= buildConf.css.fileupload %>"
          }
          {
            dest: "build/bower-macgyver-table/<%= pkg.name.toLowerCase() %>-table.css"
            src: "<%= buildConf.css.table %>"
          }
        ]

    #
    # Stylus section
    # Adding nib to all stylus
    # Compile app css into tmp/app.css temporarily
    # Compile vendor stylus, e.g. example css into tmp/vendor.css
    #
    stylus:
      compile:
        options:
          paths:   ["example/css"]
          urlfunc: "url"
          import:  ["nib"]
        files: [
          expand:  true
          flatten: true
          src:     "src/css/*.styl"
          dest:    "tmp/css"
          ext:     ".css"
        ]
      vendor:
        options:
          use: ["nib"]
        files:
          "tmp/vendor.css": "vendor/vendor.styl"

    #
    # Jade section
    # Compile all template jade files into example folder
    #
    jade:
      files:
        expand: true
        cwd:    "src"
        src:    ["**/*.jade"]
        ext:    ".html"
        dest:   "example"

    #
    # Copy section
    # Currently used for copying images, MacGyver.js and MacGyver.css
    # when deploying code
    #
    copy:
      images:
        files: [
          expand:  true
          flatten: true
          src:     ["example/css/img/ui-*.png"]
          dest:    "lib/img/"
        ]

      public:
        files: [
          expand:  true
          flatten: true
          src:     [
            "example/css/<%= pkg.name.toLowerCase() %>.css"
          ]
          dest: "lib/"
        ]
      bower:
        files: [
          {
            src: "lib/<%= pkg.name.toLowerCase() %>.js"
            dest: "build/bower-macgyver/<%= pkg.name.toLowerCase() %>.js"
          }
          {
            src: "lib/<%= pkg.name.toLowerCase() %>-core.js"
            dest: "build/bower-macgyver-core/macgyver-core.js"
          }
          {
            src: "lib/<%= pkg.name.toLowerCase() %>-datepicker.js"
            dest: "build/bower-macgyver-datepicker/macgyver-datepicker.js"
          }
          {
            src: "lib/<%= pkg.name.toLowerCase() %>-fileupload.js"
            dest: "build/bower-macgyver-fileupload/macgyver-fileupload.js"
          }
          {
            src: "lib/<%= pkg.name.toLowerCase() %>-filters.js"
            dest: "build/bower-macgyver-filters/macgyver-filters.js"
          }
          {
            src: "lib/<%= pkg.name.toLowerCase() %>-table.js"
            dest: "build/bower-macgyver-table/macgyver-table.js"
          }
        ]

    #
    # Clean section
    # Clean up tmp folder used during compiling
    #
    clean: ["tmp"]

    uglify:
      options:
        report:           "min"
        preserveComments: false
      dist:
        files: [
          {
            src: "lib/<%= pkg.name.toLowerCase() %>.js"
            dest: "lib/<%= pkg.name.toLowerCase() %>.min.js"
          }
        ]
      bower:
        files: [
          {
            src: "lib/<%= pkg.name.toLowerCase() %>.js"
            dest: "build/bower-macgyver/macgyver.min.js"
          }
          {
            src: "lib/<%= pkg.name.toLowerCase() %>-core.js"
            dest: "build/bower-macgyver-core/macgyver-core.min.js"
          }
          {
            src: "lib/<%= pkg.name.toLowerCase() %>-datepicker.js"
            dest: "build/bower-macgyver-datepicker/macgyver-datepicker.min.js"
          }
          {
            src: "lib/<%= pkg.name.toLowerCase() %>-fileupload.js"
            dest: "build/bower-macgyver-fileupload/macgyver-fileupload.min.js"
          }
          {
            src: "lib/<%= pkg.name.toLowerCase() %>-filters.js"
            dest: "build/bower-macgyver-filters/macgyver-filters.min.js"
          }
          {
            src: "lib/<%= pkg.name.toLowerCase() %>-table.js"
            dest: "build/bower-macgyver-table/macgyver-table.min.js"
          }
        ]

    #
    # watch section
    # Watch all js, css and jade changes
    #
    watch:
      options:
        interrupt: true
      js:
        files: ["src/**/*.coffee", "src/*.coffee"]
        tasks: [
          "karma:unit:run"
          "coffee"
          "concat:jqueryui"
          "concat:appJs"
          "clean"
          "copy:public"
        ]
      test:
        files: ["test/**/*.spec.coffee"]
        tasks: ["karma:unit:run"]
      css:
        files: ["src/css/*.styl", "vendor/vendor.styl"]
        tasks: ["stylus", "concat:css", "clean"]
      jade:
        files: ["src/**/*.jade"]
        tasks: ["jade", "replace:docs"]

    #
    # karma section
    # Testing framework
    #
    karma:
      options:
        configFile: "test/karma.conf.js"
      unit:
        background: true
      travis:
        autoWatch: false
        singleRun: true
      build:
        options:
          files: [
            "../vendor/bower/jquery/jquery.js"
            "../vendor/bower/angular/angular.js"
            "template/*.html"
            "../lib/macgyver-*.js"
            "../vendor/bower/angular-mocks/angular-mocks.js"
            "../test/vendor/browserTrigger.js"
            "../test/unit/*.spec.coffee"
          ]
        autoWatch: false
        singleRun: true

    #
    # chalkboard section
    # Generating documentation from source code
    #
    chalkboard:
      docs:
        files: [
          expand:  true
          flatten: false
          cwd:     "src"
          src:     ["**/*.coffee"]
          dest:    "docs/"
          ext:     ".md"
        ]

    #
    # replace section
    # Replace placeholder with contents
    #
    replace:
      src:
        options:
          pattern: /templateUrl: "([^"]+)"/g
          replace: (match) ->
            filePath     = require("path").join "example/", match[1]
            compiledHtml = grunt.file.read filePath
            compiledHtml = compiledHtml.replace /"/g, "\\\""
            "template: \"#{compiledHtml}\""
        files: [
          expand:  true
          flatten: false
          src:     [
            "lib/*.js"
            "!lib/macgyver.min.js"
          ]
          ext: ".js"
        ]
      docs:
        options:
          pattern: /@@include\("([^"]+)"\)/g
          replace: (match) -> grunt.file.read match[1]
        files: [
          expand:  true
          flatten: false
          cwd:     "example"
          src:     "*.html"
          dest:    "example/"
        ]
      version:
        options:
          pattern: /@@version/g
          replace: "<%= pkg.version %>"
        files: [
          expand:  true
          flatten: false
          cwd:     "example"
          src:     "*.html"
          dest:    "example/"
        ]

    marked:
      docs:
        files:[
          expand:  true
          flatten: false
          cwd:     "docs"
          src:     "**/*.md"
          dest:    "docs/html"
          ext:     ".html"
        ]

    updatebuild:
      app:
        files: [
          expand:  true
          flatten: false
          cwd:     "build"
          src:     "**/bower.json"
          dest:    "build"
        ]

    "gh-pages":
      options:
        base:    "example"
        message: "docs update"
        push:    false
      src: ["**"]

  grunt.registerTask "prepare", "Prepare for deploying", ["bump", "changelog"]
  grunt.registerTask "concatDeploy", [
    "concat:jqueryui"
    "concat:appJs"
    "concat:deployAppJs"
    "concat:modulesJs"
    "concat:css"
  ]

  grunt.registerTask "deploy", "Build and copy to lib/", [
      "coffee"
      "stylus"
      "jade"
      "concatDeploy"
      "clean"
      "replace:src"
      "chalkboard"
      "marked"
      "replace:docs"
      "replace:version"
      "karma:build"
      "update:component"
      "copy:images"
      "copy:public"
      "uglify:dist"
      "tag"
    ]

  grunt.registerTask "compile", "Compile files", [
    "coffee"
    "stylus"
    "jade"
    "concat:jqueryui"
    "concat:appJs"
    "concat:css"
    "clean"
    "chalkboard"
    "marked"
    "replace:docs"
  ]

  grunt.registerTask "deploy-bower", "Updated all bower repositories", [
    "copy:bower"
    "uglify:bower"
    "stylus:compile"
    "concat:moduleCss"
    "clean"
    "updatebuild"
  ]

  grunt.registerTask "dev", "Watch src and run test server", [
    "compile"
    "karma:unit"
    "server"
    "watch"
  ]
