# encoding: utf-8

class QuranVue < Sinatra::Base
  helpers do
    include Sinatra::ContentFor

    def partial(page, variables = {})
      haml page, { layout: false }, variables
    end

    def prev_sura(current_sura_id)
      prev_id = current_sura_id - 1
      return nil if prev_id < 1

      QuranVue::DB[:suras].where(id: prev_id).first
    end

    def next_sura(current_sura_id)
      next_id = current_sura_id + 1
      return nil if next_id > 114

      QuranVue::DB[:suras].where(id: next_id).first
    end

    def arabic_number(number)
      number.to_s.tr("0123456789","٠١٢٣٤٥٦٧٨٩")
    end

    def body_class
      @body || 'index'
    end
  end
end
