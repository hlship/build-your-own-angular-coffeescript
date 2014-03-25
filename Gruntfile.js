module.exports = function(grunt) {

  grunt.initConfig({

    clean: ["out"],
    
    coffee: {
      compile: {
        sourceMap: true,
        expand: true,
        flatten: true,
        cwd: "src",
        src: ["*.coffee"],
        dest: "out/prod",
        ext: ".js"
      },

      compileTest: {
        expand: true,
        flatten: true,
        cwd: "test",
        src: ["*.coffee"],
        dest: "out/test",
        ext: ".js"
      }
    },

    jshint: {
      // CoffeeScript should always generate lint-free JS, but why not check?
      all: ["src/**/*.js", "test/**/*.js", "out/**/*.js"],
      options: {
        globals: {
          _ : false,
          $ : false,
          jasmine: false,
          describe: false,
          it: false,
          expect: false,
          beforeEach: false
        },
        browser: true,
        devel: true
      }
    },
    jasmine: {
      unit: {
        src: ["src/**/*.js", "out/prod/**/*.js"],
        options: {
          specs: ["test/**/*.js", "out/test/**/*.js"],
          vendor: [
            "node_modules/lodash/lodash.js",
            "node_modules/jquery/dist/jquery.js"
          ]
        }
      }
    }
  });

  grunt.registerTask("default", ["coffee", "jshint", "jasmine"]);

  grunt.loadNpmTasks("grunt-contrib-jshint");
  grunt.loadNpmTasks("grunt-contrib-jasmine");
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-clean');
};