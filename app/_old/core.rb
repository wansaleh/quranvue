# encoding: utf-8

require_relative 'helpers'

module QuranVue

  DB = Sequel.mysql2 'quran_sinatra', user: 'root', password: 'www', host: 'localhost'

  class Core < Sinatra::Base

    # core settings
    set :root,          File.expand_path('../../', __FILE__)
    set(:public_folder) { File.join(root, "static") }

    configure :development do
      register Sinatra::Reloader
    end

    # compass and sass options
    Compass.configuration do |config|
      config.project_path = root
      config.sass_dir = 'assets/css'
    end
    set :scss, Compass.sass_engine_options
    set :sass, Compass.sass_engine_options

    # haml options
    set :haml,
      :format       => :html5,
      :attr_wrapper => '"',
      :escape_attrs => false,
      :preserve     => ['textarea', 'pre', 'code']

    # asset pack
    register Sinatra::AssetPack
    assets do
      serve '/css',    :from => 'assets/css'
      serve '/js',     :from => 'assets/js'
      serve '/images', :from => 'assets/images'

      js :vendor, [
        '/js/vendor/jquery-1.8*.js',
        '/js/vendor/bootstrap.min.js',
        '/js/vendor/underscore.min.js',
        '/js/vendor/backbone.min.js',
        '/js/vendor/knockout.min.js',
        '/js/vendor/knockback-core.min.js',
        '/js/vendor/string.min.js',
        '/js/vendor/select2.js',
        # '/js/vendor/chosen.jquery.min.js',
      ]
      js :app, [
        '/js/quranvue*.js'
      ]

      css :app, [
        '/css/select2.css',
        '/css/quranvue.css'
      ]

      prebuild true
    end

    # include helpers
    helpers QuranVue::Helpers
    helpers Sinatra::ContentFor

  end

end

require_relative 'controllers'
