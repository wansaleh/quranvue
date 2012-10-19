# encoding: utf-8
require 'bundler'
Bundler.require

ROOT_DIR = File.expand_path(File.dirname(__FILE__))
Encoding.default_external = 'utf-8' if defined?(::Encoding)

def root_path(*args)
  File.join(ROOT_DIR, *args)
end

Dir[root_path('app/core_ext/*.rb')].each do |file|
  require file
end

class QuranVue < Sinatra::Base

  # ======================================================================
  # Sequel DB connection

  DB = Sequel.mysql2 'quran_sinatra', user: 'root', password: 'www', host: 'localhost'

  # ======================================================================
  # Settings

  set :root,          ROOT_DIR
  set :public_folder, root_path('app/static')
  set :views,         root_path('app/views')
  # set :environment,   :production

  configure :development do
    use Rack::LiveReload
    register Sinatra::Reloader
  end

  # compass and sass options
  Compass.add_project_configuration(root_path('config.rb'))
  set :scss, Compass.sass_engine_options
  set :sass, Compass.sass_engine_options

  # haml options
  set :haml,
    :format       => :html5,
    :attr_wrapper => '"',
    :escape_attrs => false,
    :preserve     => ['textarea', 'pre', 'code']

  # ======================================================================
  # Sinatra Backbone by ricostacruz

  register Sinatra::JstPages
  serve_jst '/js/jst.js'

  # ======================================================================
  # Sinatra AssetPack by ricostacruz

  register Sinatra::AssetPack
  assets do
    serve '/css',    :from => 'app/assets/css'
    serve '/js',     :from => 'app/assets/js'
    serve '/images', :from => 'app/assets/images'

    js :modernizr, [
      '/js/vendor/modernizr*.js',
    ]
    js :quranvue, [
      '/js/vendor/jquery-1.8.2.min.js',
      '/js/vendor/lodash.min.js',
      '/js/vendor/backbone.js',
      '/js/vendor/knockout.min.js',
      '/js/vendor/knockback-core.min.js',
      '/js/vendor/select2.min.js',
      '/js/vendor/bootstrap/bootstrap-tooltip.js',
      '/js/vendor/jquery.slabtext.min.js',
      '/js/vendor/jquery.widowFix.min.js',
      '/js/vendor/jquery.tools.min.js',
      '/js/vendor/jade.min.js',
      '/js/jst.js',
      '/js/qurandata.min.js',
      '/js/quranvue*.js'
    ]

    css :quranvue, [
      '/css/quranvue.css'
    ]

    js_compression :yui
    prebuild true
  end

  # ======================================================================
  # Helpers

  helpers do
    include Sinatra::ContentFor

    def partial(page, variables = {})
      haml page, { layout: false }, variables
    end

    def prev_sura(current_sura_id)
      prev_id = current_sura_id - 1
      return nil if prev_id < 1

      DB[:suras].where(id: prev_id).first
    end

    def next_sura(current_sura_id)
      next_id = current_sura_id + 1
      return nil if next_id > 114

      DB[:suras].where(id: next_id).first
    end

    def arabic_number(number)
      number.to_s.tr("0123456789","٠١٢٣٤٥٦٧٨٩")
    end

    def body_class
      @body || 'index'
    end

    def cache_bust
      "?#{rand(1e5..1e6)}"
    end
  end

  # ======================================================================
  # Route definitions

  LIMIT = 20

  # sura list
  get '/' do
    @title = "QuranVue"
    haml :index
  end

  # redirect normal permalink to hash permalink
  get '/sura/:sura/?' do
    sura_id = params[:sura].to_i
    redirect "/#/sura/#{sura_id}"
  end

  # single sura json
  get '/ayas' do
    redirect '/' if params[:sura_id].blank?

    sura_id  = params[:sura_id].to_i
    limit    = params[:limit].blank? ? LIMIT : params[:limit].to_i
    offset   = params[:offset].blank? ? 0 : params[:offset].to_i

    limit    = [limit, 0].max
    offset   = [offset, 0].max

    content_type :json, :charset => 'utf-8'

    json = ''

    if sura_id < 1 || sura_id > 114
      json = {:error => 'Invalid sura_id'}.to_json
    else
      json = fetchAyas(sura_id, limit, offset).to_json
    end

    json = "#{params[:callback]}(#{json})" if !params[:callback].blank?

    json
  end

  def fetchAyas(sura_id, limit = 10, offset = 0)
      # .select(:ayas__id, :ayas__sura_id, :ayas__aya, :translations__text___translation)
    ayas = DB[:ayas]
      .select(:ayas__id, :ayas__sura_id, :ayas__aya, :ayas__text___text, :translations__text___translation)
      .join(:translations, :ayas__id => :translations__aya_id)
      .where(:ayas__sura_id => sura_id, :translations__language_id => 1)
      .limit(limit, offset)
      .all

    ayas
  end

end
