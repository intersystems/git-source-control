module.exports = function(grunt) {
    grunt.initConfig({
        pkg: grunt.file.readJSON('package.json'),

        copy: {
            jquery: {
                expand: true,
                flatten: true,
                src: 'node_modules/jquery/dist/jquery.min.js',
                dest: 'dist/share/git-webui/webui/js/',
            },
            bootstrapjs: {
                expand: true,
                flatten: true,
                src: 'node_modules/bootstrap/dist/js/bootstrap.min.js',
                dest: 'dist/share/git-webui/webui/js/',
            },
            bootstrapcss: {
                expand: true,
                flatten: true,
                src: 'node_modules/bootstrap/dist/css/bootstrap.min.css',
                dest: 'dist/share/git-webui/webui/css/',
            },
            popperjs: {
                expand: true,
                flatten: true,
                src: 'node_modules/popper.js/dist/umd/popper.min.js',
                dest: 'dist/share/git-webui/webui/js/',
            },
            git_webui: {
                options: {
                    mode: true,
                },
                expand: true,
                cwd: 'src',
                src: ['share/**', '!**/less', '!**/*.less'],
                dest: 'dist',
            },
            release: {
                options: {
                    mode: true,
                },
                expand: true,
                cwd: 'dist',
                src: '**',
                dest: 'release',
            },
        },

        less: {
            files: {
                expand: true,
                cwd: 'src',
                src: 'share/git-webui/webui/css/*.less',
                dest: 'dist',
                ext: '.css',
            },
        },

        watch: {
            scripts: {
                files: ['src/share/**/*.js', 'src/share/**/*.html'],
                tasks: 'copy:git_webui'
            },
            css: {
                files: 'src/**/*.less',
                tasks: 'less',
            },
        },

        clean: ['dist'],
    });

    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-contrib-less');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-watch');

    grunt.registerTask('copytodist', ['copy:jquery', 'copy:bootstrapjs', 'copy:bootstrapcss', 'copy:popperjs', 'copy:git_webui']);
    grunt.registerTask('default', ['copytodist', 'less']);
    grunt.registerTask('release', ['default', 'copy:release']);
};
