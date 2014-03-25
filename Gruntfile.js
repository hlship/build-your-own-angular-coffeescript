module.exports = function(grunt) {

  grunt.initConfig({

    clean: ["out"],

    coffee: {
      compile: {
        options: {
          bare: true,
          sourceMap: true
        },
        expand: true,
        flatten: true,
        cwd: "src",
        src: ["*.coffee"],
        dest: "out/prod",
        ext: ".js"
      },

      compileTest: {
        options: {
          bare: true,
          sourceMap: true
        },
        expand: true,
        flatten: true,
        cwd: "test",
        src: ["*.coffee"],
        dest: "out/test",
        ext: ".js"
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
    },
    watch: {
      all: {
        files: ["src/**/*.js", "src/**/*.coffee",
                "test/**/*.js", "test/**/*.coffee"],
        tasks: ["default"]
      }
    }
  });

  grunt.registerTask("default", ["coffee", "jasmine"]);

  grunt.loadNpmTasks("grunt-contrib-jasmine");
  grunt.loadNpmTasks('grunt-contrib-coffee');
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks("grunt-contrib-watch");
};