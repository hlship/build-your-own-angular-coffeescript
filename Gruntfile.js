module.exports = function(grunt) {

  grunt.initConfig({

    coffee: {
      compile: {
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
      all: ["src/**/*.js", "test/**/*.js"],
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

  grunt.loadNpmTasks("grunt-contrib-jshint");
  grunt.loadNpmTasks("grunt-contrib-jasmine");
  grunt.loadNpmTasks('grunt-contrib-coffee');
};