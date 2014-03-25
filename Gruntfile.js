module.exports = function(grunt) {

  grunt.initConfig({

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
        src: "src/**/*.js",
        options: {
          specs: ["test/**/*.js"]
        }
      }
    }
  });

  grunt.loadNpmTasks("grunt-contrib-jshint");
  grunt.loadNpmTasks("grunt-contrib-jasmine");
};