window.QuranVue ?= {}

# ============================================================
# Data cleanups

((window, _, Backbone, app) ->

  app.populateData = ->

    app.Markings =
      Pause: ["\u06D6", "\u06D7", "\u06D8", "\u06D9", "\u06DA", "\u06DB"]
      Vowel: ["\u064B", "\u064C", "\u064D", "\u064E", "\u064F", "\u0650", "\u0651",
              "\u0652", "\u0653", "\u0654", "\u0655", "\u0656", "\u0657", "\u0658",
              "\u0659", "\u065A", "\u065B", "\u065C", "\u065D", "\u065E"]
      Sajda:  "\u06E9"

    # cleanup vendor file quran-data.js
    # make all data as Backbone.Model
    if window.QuranData?
      app.Data = {}

      mapping =
        Sura:        {name: 'Suras',   keys: ['start', 'ayas', 'order', 'rukus', 'name', 'tname', 'ename', 'type']}
        Juz:         {name: 'Juzs',    keys: ['sura', 'aya']}
        HizbQaurter: {name: 'Hizbs',   keys: ['sura', 'aya']}
        Manzil:      {name: 'Manzils', keys: ['sura', 'aya']}
        Ruku:        {name: 'Rukus',   keys: ['sura', 'aya']}
        Page:        {name: 'Pages',   keys: ['sura', 'aya']}
        Sajda:       {name: 'Sajdas',  keys: ['sura', 'aya', 'hukm']}

      for infoName, infoVal of mapping
        # remove first element (empty element)
        infoContent = _.rest window.QuranData[infoName]

        if _.any(['Juzs', 'Hizbs', 'Manzils', 'Rukus', 'Pages', 'Suras'], (n) -> n == infoVal.name)
          # remove last element
          infoContent = _.initial infoContent

        if infoVal.name == 'Suras'
          # special for Suras
          app.Data[infoVal.name] = new app.Collections.Suras
          model = app.Models.Sura
        else
          # generic for others
          app.Data[infoVal.name] = new Backbone.Collection
          model = Backbone.Model

        i = 0
        for val in infoContent
          data = {}
          data['id'] = i + 1
          for key, j in infoVal.keys
            data[key] = val[j]

          app.Data[infoVal.name].add new model(data)
          i++

      window.QuranData = null
      delete window.QuranData

)(window, window._, window.Backbone, window.QuranVue)
