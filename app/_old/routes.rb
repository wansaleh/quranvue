# encoding: utf-8
module QuranVue
  class App < Sinatra::Base

    # sura list
    get '/' do

      @title = "QuranVue"
      haml :index

    end

    # # single sura
    # get '/sura/:sura' do
    #   @sura_id = params[:sura].to_i
    #   @sura = QuranVue::DB[:suras].where(:id => @sura_id).first

    #   @ayas = fetchAyas(@sura_id)
    #   @json = {:sura_id => @sura_id, :ayas => @ayas}.to_json

    #   @title = "Sura #{@sura[:tname]}"
    #   @body = 'sura'
    #   haml :sura
    # end

    # single sura json
    get '/json/:sura' do
      content_type :json, :charset => 'utf-8'

      sura_id = params[:sura].to_i

      if sura_id < 1 || sura_id > 114
        return {:error => 'Invalid sura_id'}.to_json
      end

      # {:sura_id => sura_id, :ayas => fetchAyas(sura_id)}.to_json
      fetchAyas(sura_id).to_json
    end

    # not_found do
    #   redirect '/'
    # end

    private

    def fetchAyas(sura_id)
      ayas = QuranVue::DB[:ayas]
        .select(:ayas__id, :ayas__sura_id, :ayas__aya, :translations__text___translation)
        .join(:translations, :ayas__id => :translations__aya_id)
        .where(:ayas__sura_id => sura_id, :translations__language_id => 1)
        .all
        # .select(:ayas__id, :ayas__sura_id, :ayas__aya, :ayas__text___text, :translations__text___translation)

      ayas
    end

  end
end
