# encoding: utf-8
require 'sequel'
require 'mysql2'
require 'pp'

DB = Sequel.mysql2 'quran_sinatra', user: 'root', password: 'www', host: 'localhost'

class Sura < Sequel::Model
  one_to_many :ayas
end

class Aya < Sequel::Model
  many_to_one :sura
  one_to_many :translations
end

class Language < Sequel::Model
  one_to_many :translations
end

class Translation < Sequel::Model
  many_to_one :aya
  many_to_one :language
end

class InfoHizb < Sequel::Model
  many_to_one :sura
end

class InfoJuz < Sequel::Model
  many_to_one :sura
end

class InfoManzil < Sequel::Model
  many_to_one :sura
end

class InfoRuku < Sequel::Model
  many_to_one :sura
end

class InfoSajda < Sequel::Model
  many_to_one :sura
end


aa = Aya
  .eager_graph(:translations)
  .where(:ayas__sura_id => 1, :language_id => 1)
  .limit(5)

# pp aa.sql

aa.each do |aya|
  pp aya
end
