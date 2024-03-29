# encoding: utf-8

module QuranVue

  class App < Sinatra::Base

    @assets = assets = Sprockets::Environment.new(root_path) do |env|
      env.logger = Logger.new(STDOUT)
    end

    %w[app lib vendor].each do |path|
      %w[fonts images js css].each do |asset_path|
        assets.append_path(File.join(root_path, path, 'assets', asset_path))
      end
    end

    module AssetHelpers
      def asset_path(name)
        "/assets/#{@assets.find_asset(name).digest_path}"
      end
    end

    assets.context_class.instance_eval do
      include AssetHelpers
    end

    helpers AssetHelpers

    get '/assets/*' do
      new_env = env.clone
      new_env["PATH_INFO"].gsub!("/assets", "")

      assets.call(new_env)
    end

  end

end
