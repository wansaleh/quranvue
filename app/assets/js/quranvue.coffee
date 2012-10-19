window.QuranVue ?= {}
window.QV = QuranVue

((window, $, _, Backbone, ko, kb, app) ->
  'use strict'

  # ============================================================
  # Configuration
  app.config =
    url_prefix:       '#'
    permalink_format: ':sura_id'
    fetch_limit:      10

  # ===================================================================================
  # proxies
  config = app.config
  utils  = app.utils
  ui     = app.ui

  # ===================================================================================
  # Router
  class Router extends Backbone.Router
    routes:
      '': 'suraList'
      'old': 'suraListOld'
      ':sura_id': 'ayaList'
      ':sura_id/:aya_id': 'ayaList'
      '*notFound': 'notFound'

    suraList: ->
      app.ui.navbar 'home'
      app.settings.view 'sura_list'
      app.settings.sura_id null
      app.settings.aya_id  null

      new Views.SuraList

    suraListOld: ->
      app.ui.navbar 'old'
      app.settings.view 'sura_list_old'
      app.settings.sura_id null
      app.settings.aya_id  null
      app.settings.loaded true

    ayaList: (sura_id, aya_id) ->
      sura_id = new String(sura_id).toInt()
      aya_id  = new String(aya_id).toInt()

      if _.isNaN(sura_id) || !utils.validSura sura_id
        return @notFound()

      aya_id = if _.isNaN(aya_id) then null else aya_id

      app.ui.navbar()

      app.settings.view 'aya_list'
      app.settings.sura_id sura_id
      app.settings.aya_id  aya_id

      new Views.AyaList

    notFound: ->
      utils.navigate()
      ui.error('error', 'Route not found', 'Please use the links provided on the app.')


  # ===================================================================================
  # Models

  Models = app.Models = {}

  class Models.Sura extends Backbone.Model
    defaults:
      id    : ''
      name  : ''
      tname : ''
      ename : ''
      ayas  : ''
      order : ''
      rukus : ''
      type  : ''

  class Models.Aya extends Backbone.Model
    defaults:
      id          : ''
      sura_id     : ''
      aya         : ''
      text        : ''
      translation : ''


  # ===================================================================================
  # Collections

  Collections = app.Collections = {}

  class Collections.Suras extends Backbone.Collection
    model: Models.Sura
    comparator: (sura) -> sura.get('id')

  class Collections.Ayas extends Backbone.Collection
    model: Models.Aya
    url: '/ayas'
    comparator: (aya) -> aya.get('aya')


  # ===================================================================================
  # ViewModels

  ViewModels = app.ViewModels = {}

  ViewModels.Settings = ->
    @view    = ko.observable null
    @sura_id = ko.observable null
    @aya_id  = ko.observable null
    @loaded  = ko.observable false
    @

  ViewModels.Sura = (model, with_adjacents = false) ->
    @id    = kb.observable model, 'id'
    @name  = kb.observable model, 'name'
    @tname = kb.observable model, 'tname'
    @ename = kb.observable model, 'ename'
    @ayas  = kb.observable model, 'ayas'
    @order = kb.observable model, 'order'
    @rukus = kb.observable model, 'rukus'
    @type  = kb.observable model, 'type'

    @full_name     = ko.computed => "#{@id()} #{@tname()} #{@name()}"
    @full_name_2   = ko.computed => "<b>#{@id()}</b> #{@tname()} #{@name()}"
    @order_ordinal = ko.computed => new Number(@order()).toOrdinal()
    @location      = ko.computed => if @type() == 'Meccan' then 'Mecca' else 'Medina'
    @permalink     = ko.computed => utils.permalink @id()
    @id_prev       = ko.computed => if utils.validSura(@id() - 1) then @id() - 1 else false
    @id_next       = ko.computed => if utils.validSura(@id() + 1) then @id() + 1 else false

    if with_adjacents
      @prev = ko.computed => if @id_prev() then new ViewModels.Sura utils.suraById @id_prev() else false
      @next = ko.computed => if @id_next() then new ViewModels.Sura utils.suraById @id_next() else false
    @

  ViewModels.Aya = (model) ->
    @id          = kb.observable model, 'id'
    @sura_id     = kb.observable model, 'sura_id'
    @aya         = kb.observable model, 'aya'
    @text_orig   = kb.observable model, 'text'
    @trans_orig  = kb.observable model, 'translation'

    # aya identifier
    @aya_id      = ko.computed => "aya-#{@sura_id()}-#{@aya()}"
    @identifier  = ko.computed => "#{@sura_id()}<em>:</em>#{@aya()}"

    # all first ayas in the database has "Bismillahirrahmanirrahim"
    # (39 utf-8 arabic characters) embeded. Remove it, unless for Al-Fatihah (sura_id=1)
    @text = ko.computed => if @sura_id() != 1 and @aya() == 1 then @text_orig().slice(39) else @text_orig()

    # translation, update sujud instructions
    @translation = ko.computed =>
      @trans_orig().replace /(prostrat(e[ds]?|ion))/gi, '<u>$1</u>'

    # is aya is start of a juz?
    @juz = ko.computed =>
      app.Data.Juzs.some (s) => s.get('sura') == @sura_id() && s.get('aya') == @aya()

    # sajda => 0=n/a 1=recommended 2=obligatory
    @sajda = ko.computed =>
      sajda = app.Data.Sajdas.where sura: @sura_id(), aya: @aya()
      sajda = if !sajda.length then 0 else switch sajda[0].get('hukm')
        when 'recommended' then 1
        when 'obligatory'  then 2
      sajda

    @img_src    = ko.computed => "/images/ayas/#{@sura_id()}_#{@aya()}.png"
    @aya_arabic = ko.computed => new String(@aya()).arabicNumber()
    @

  # DEPRECATED: SuraList
  ViewModels.SuraList = ->
    @sort_attr = ko.observable 'id'
    @suras     = kb.collectionObservable app.Data.Suras,
      view_model: ViewModels.Sura
      sort_attribute: @sort_attr
    @sortSuras = =>
      @sort_attr(if @sort_attr() == 'id' then 'tname' else 'id')
    @

  # DEPRECATED: AyaList
  ViewModels.AyaList = ->
    @sura_info = new ViewModels.Sura(utils.suraById(app.settings.sura_id()), true)
    @ayas      = kb.collectionObservable(app.ayas, view_model: ViewModels.Aya)
    @


  # ===================================================================================
  # Views

  Views = app.Views = {}

  # ==================================================================
  app.renderedSuraList = null
  class Views.SuraList extends Backbone.View

    el: '.sura-list-wrapper'
    linkTpl: _.template "<a href='<%= permalink %>'><%= id %> <%= tname %></a>"
    rowTpl: _.template "<span class='slabtext'><%= links %></span>"
    linkJoin: " &middot; "

    initialize: ->
      @loading true

      # remove scoll events
      $(window).off 'scroll'

      # goto top
      $('body').scrollTo duration: 0

      # render list
      @render()

      utils.delay 400, =>
        app.settings.loaded true
        @loading false

    loading: (loading) ->
      return loading
      @$el[if loading then 'addClass' else 'removeClass']('loading')

    render: ->
      @slabText()

    slabText: ->
      if app.renderedSuraList?
        _.defer =>
          @$('.sura-list').html app.renderedSuraList

      else
        cut = 3
        start = 0; rows = []; cols = []

        app.Data.Suras.each (sura, i) =>
          cols.push @linkTpl
            permalink: utils.permalink sura.get('id')
            id: sura.get('id')
            tname: sura.get('tname')

          if i == start + cut - 1 || i == app.Data.Suras.length - 1
            rows.push @rowTpl(links: cols.join @linkJoin)

            cols = [] # reset column
            start = i + 1
            # cut = _.random(3, 5)

        @$('.sura-list').html rows.join ''

        utils.delay 100, =>
          @$('.sura-list').slabText()
          app.renderedSuraList = @$('.sura-list').html()


  # ==================================================================
  class Views.AyaList extends Backbone.View

    el: '.aya-list-wrapper'

    initialize: ->
      # sura/aya
      @sura_id   = app.settings.sura_id()
      @aya_id    = app.settings.aya_id()
      @sura_info = utils.suraById @sura_id

      # elements
      @$win = $(window)
      @$doc = $(document)
      @$select2 = @$('#sura-select')

      # remove scoll events
      @$win.off 'scroll'

      # goto top
      $('body').scrollTo duration: 0

      # bind events
      app.ayas.on 'all', =>
        app.settings.loaded true
        @loading false
        @loadingBar false

      # render everything
      @render()

    # ----------------------------------------------------------------
    # helper methods
    loading: (loading) ->
      if loading
        @$('.aya-list').stop().css opacity: 0
      else
        utils.delay 200, =>
          @$('.aya-list').stop().animate opacity: 1

      loading

    loadingBar: (loading) ->
      $loading = $('#loading')
      if loading
        $loading.addClass 'show'
      else
        utils.delay 500, ->
          $loading.removeClass 'show'

      loading

    # ----------------------------------------------------------------
    # main render
    render: ->
      @load()
      _(['lazyLoader', 'select2', 'fixedNav']).each (method) => @[method]()

    # ----------------------------------------------------------------
    # load ayas
    load: ->
      @loading true
      @loadingBar true

      app.ayas.fetch
        data:
          sura_id: @sura_id
          limit: if @aya_id? then Math.ceil(@aya_id/config.fetch_limit) * config.fetch_limit else config.fetch_limit

        success: =>
          _.defer =>
            @$('.translation').widowFix()

            # jump to aya, if defined
            if @aya_id? then utils.delay 500, =>
              @$("#aya-#{@sura_id}-#{@aya_id}").scrollTo
                duration: 500
                offset: -100
                callback: ->
                  $(this).expose()
                  utils.delay 4000, -> $.mask.close()

    # ----------------------------------------------------------------
    # Submodules renderer
    # ----------------------------------------------------------------
    # lazy loader
    lazyLoader: ->
      _lazyLoad = _.throttle (=>
        return if app.settings.view() != 'aya_list'

        if @$win.scrollTop() > @$doc.height() - @$win.height() * 2 && app.ayas.length > 0
          # get last loaded aya
          last_aya = app.ayas.last().get 'aya'
          if last_aya < @sura_info.get 'ayas'
            # get ayas
            @loadingBar true
            app.ayas.fetch
              data:
                sura_id: @sura_id
                limit: config.fetch_limit
                offset: last_aya
              add: true
              success: =>
                _.defer =>
                  @$('.translation').widowFix()
      ), 500

      @$win.on 'scroll', _lazyLoad

    # ----------------------------------------------------------------
    # jquery select2
    select2: ->
      _sura =
        id:     @sura_info.get 'id'
        text:   @sura_info.get 'tname'
        arabic: @sura_info.get 'name'

      init = =>
        suras = app.Data.Suras.map (sura) ->
          id:     sura.get 'id'
          text:   sura.get 'tname'
          arabic: sura.get 'name'

        @$select2.select2
          data: suras
          formatResult: (item) ->
            "<b>#{item.id}</b> · #{item.text}<span class='arabic' style='float:right;'>#{item.arabic}</span>"
          formatSelection: (item) ->
            "<b>#{item.id}</b> · #{item.text}"
          initSelection: (element, callback) ->
            callback [_sura]

        @$select2.on 'change', (e) ->
          utils.navigate utils.permalink(e.val)

      init(); @$select2.select2 'data', _sura

    # ----------------------------------------------------------------
    # fixed navigation & back to top
    fixedNav: ->
      $nav_affix = @$('.navigator-affix')
      $nav       = @$('.navigator-affix nav')
      $top       = $('#top-link')

      nav_els = $nav.children().not('input')
      nav_els.removeClass('first').removeClass('last')
      nav_els.first().addClass('first')
      nav_els.last().addClass('last')

      nav_affix_offset = $nav_affix.offset()

      $select2_container = $('.select2-container')
      $select2_drop = $('.select2-drop')
      select2_drop_top = $select2_drop.offset().top

      select2SetPosAbs = ->
        $select2_drop.css
          position: 'absolute'
          top: $select2_container.outerHeight() + $select2_container.offset().top

      select2SetPosFixed = ->
        $select2_drop.css
          position: 'fixed'
          top: 45

      @$win.on 'scroll', =>
        return if app.settings.view() != 'aya_list'

        if @$win.scrollTop() > nav_affix_offset.top
          $top.addClass 'active'
          $nav_affix.addClass 'fixed'
          select2SetPosFixed()
          @$select2.off 'open', select2SetPosAbs
          @$select2.on 'open', select2SetPosFixed

        else
          $top.removeClass 'active'
          $nav_affix.removeClass 'fixed'
          select2SetPosAbs()
          @$select2.on 'open', select2SetPosAbs
          @$select2.off 'open', select2SetPosFixed

      $('a.top', $top).click ->
        $('body').scrollTo duration: 1000
        false


  # ===================================================================================
  # document ready

  $ ->
    app.populateData()

    app.settings = new ViewModels.Settings
    app.ayas     = new Collections.Ayas

    app_view_model = ->
      @settings = app.settings

      @sura_list = ko.computed =>
        return false if @settings.view() != 'sura_list_old'
        new ViewModels.SuraList

      @sura_info = ko.computed =>
        return false if @settings.view() != 'aya_list'
        new ViewModels.Sura(utils.suraById(@settings.sura_id()), true)

      @ayas = ko.computed =>
        return false if @settings.view() != 'aya_list'
        kb.collectionObservable(app.ayas, view_model: ViewModels.Aya)

      @

    app.view_model = new app_view_model

    ko.applyBindings app.view_model, $('#quranvue')[0]

    app.router = new Router
    Backbone.history.start()

    window.testmodel = new Backbone.Model
      haha: 'test'
      hihi: 'test2'
      hoho:
        test: 'what?'


) window, window.jQuery, window._, window.Backbone, window.ko, window.kb, window.QuranVue
