module.exports = (grunt) ->

  grunt.initConfig
    clean: ["out"]

    coffee:
      compile:
        options:
          sourceMap: true
        expand: true
        flatten: true 
        cwd: "src"
        src: ["*.coffee"]
        dest: "out/prod"
        ext: ".js"

      compileTest:
        options:
          sourceMap: true
        expand: true
        flatten: true
        cwd: "test"
        src: ["*.coffee"]
        dest: "out/test"
        ext: ".js"

    testem:
      unit:
        options:
          framework: "jasmine2"
          launch_in_dev: ["PhantomJS"]
          before_tests: "grunt coffee"
          serve_files: [
            "out/**/*.js"
            "node_modules/lodash/lodash.js"
            "node_modules/jquery/dist/jquery.js"
          ]
          watch_files: [
            "src/**/*.coffee"
            "test/**/*.coffee"
          ]

    jasmine:
      unit:
        src: ["src/**/*.js", "out/prod/**/*.js"]
        options:
          specs: ["test/**/*.js", "out/test/**/*.js"]
          vendor: [
            "node_modules/lodash/lodash.js"
            "node_modules/jquery/dist.jquery.js"
          ]

  grunt.loadNpmTasks "grunt-contrib-#{name}" for name in ["jasmine", "coffee", "clean", "testem"]

  grunt.registerTask "default", ["testem:run:unit"]