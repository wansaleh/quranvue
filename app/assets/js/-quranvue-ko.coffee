window.QuranVue ?= {}
window.QuranVue.JSON ?= {}

(($, bb, ko, kb, app) ->

  # ===================================================================================
  # private helper functions

  # returns a new kb.viewModel and wraps the @hash into a bare Backbone.Model
  # @return kb.ViewModel
  _viewModel = (hash) ->
    kb.viewModel new bb.Model(hash)

  # convert a collection (array) of hashes (from JSON) into Backbone.Collection
  # @param json   an array of hashes
  # @param model  is a function which returns a Backbone.Model instance
  # @return Backbone.Collection
  _collection = (json, model) ->
    new bb.Collection _.map(json, (element) -> new model(element))

  # return Backbone.Model previous sura's model
  _prevSura = (id) ->
    return false if !validSura(id - 1)
    app.Models.Sura(app.Data.Suras[--id - 1])

  # return Backbone.Model next sura's model
  _nextSura = (id) ->
    return false if !validSura(id + 1)
    app.Models.Sura(app.Data.Suras[--id + 1])

  # because app.Data.Suras has array indeces (n-1), it's confusing to use it.
  # so we find the one that hatch the real id.
  _suraWithId = (id) ->
    _.find app.Data.Suras, (sura) -> sura.id == id

  # ===================================================================================
  # public helper functions for use in views

  app.helpers = (->
    validSura: (id) ->
      return 1 <= id <= 114

    arabicNumber: (num) ->
      (new String(num)).arabicNumber()
  )()

  _.extend(window, app.helpers)


  # ===================================================================================
  # Models
  app.Models =

    # sura model
    Sura: (sura) ->
      new bb.Model
        id        : sura.id
        name      : sura.name
        tname     : sura.tname
        ename     : sura.ename
        ayas      : sura.ayas
        order     : sura.order
        type      : sura.type
        location  : if sura.type is 'Meccan' then 'Mecca' else 'Medina'
        permalink : "/sura/#{sura.id}"

    # SuraAdjacent (with adjacent suras references)
    SuraAdjacent: (sura) ->
      new bb.Model
        id        : sura.id
        name      : sura.name
        tname     : sura.tname
        ename     : sura.ename
        ayas      : sura.ayas
        order     : sura.order
        type      : sura.type
        location  : if sura.type is 'Meccan' then 'Mecca' else 'Medina'
        permalink : "/sura/#{sura.id}"
        prev      : if validSura(sura.id-1) then app.Models.Sura(_suraWithId(sura.id-1)) else false
        next      : if validSura(sura.id+1) then app.Models.Sura(_suraWithId(sura.id+1)) else false

    # aya model
    Aya: (aya) ->
      # sajda => 0=n/a 1=recommended 2=obligatory
      sajda = _.find app.Data.Sajdas, (s) ->
        s.sura is aya.sura_id and s.aya is aya.aya
      if sajda?
        sajda = switch sajda.hukm
          when 'recommended' then 1
          when 'obligatory'  then 2
      else
        sajda = 0

      # all first ayas in the database has "Bismillahirrahmanirrahim"
      # (39 utf-8 arabic characters) embeded. Remove it, unless for Al-Fatihah (sura_id=1)
      text = if aya.sura_id isnt 1 and aya.aya is 1 then aya.text.slice(39) else aya.text

      new bb.Model
        id          : aya.id
        sura_id     : aya.sura_id
        aya         : aya.aya
        text        : _.trim(text)
        translation : _.trim(aya.translation)
        sajda       : sajda
        img_src     : "/images/ayas/#{aya.sura_id}_#{aya.aya}.png"


  # ===================================================================================
  # ViewModels
  app.ViewModels =

    # SuraList
    SuraList: ->
      app.SuraCollection = _collection app.Data.Suras, app.Models.Sura
      ko.applyBindings _viewModel
        suras: app.SuraCollection

    # AyaList
    AyaList: ->
      app.SuraInfo = app.Models.SuraAdjacent _suraWithId(app.JSON.SuraId)
      app.AyaCollection = _collection app.JSON.Ayas, app.Models.Aya

      ko.applyBindings _viewModel
        sura: app.SuraInfo
        ayas: app.AyaCollection

      _.delay app.UIUpdater.run, 500


  # ===================================================================================
  # document ready
  $ ->
    return if !app.Data?

    if $('.sura-list').length
      app.ViewModels.SuraList()

    if $('.aya-list').length
      app.ViewModels.AyaList()

)(window.jQuery, window.Backbone, window.ko, window.kb, window.QuranVue)
