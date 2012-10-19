# encoding: utf-8

module QuranVue

  class App < Sinatra::Base

    configure do
      mime_type :manifest, 'text/cache-manifest'
    end

    get '/app.manifest' do
      content_type :manifest
      puts "CACHE MANIFEST"
      puts "/assets/application.css"
      puts "/assets/application.js"
    end

  end

end
