window.QuranVue ?= {}

((window, _, Backbone, app) ->

  # ============================================================
  # Utility methods
  app.utils =

    # return Backbone.Model the model of the sura with the id @id
    suraById: (id) ->
      app.Data.Suras.get(if _.isString id then id.toInt() else id)

    # check the validity of the sura_id
    validSura: (sura_id) ->
      1 <= sura_id <= 114

    # proxy for Backbone.Router.navigate
    navigate: (fragment = '', trigger = true, replace = false) ->
      # remove prefix
      fragment = fragment.replace app.config.url_prefix, ''
      # call navigate
      app.router.navigate fragment, { trigger: trigger, replace: replace }

    # proxy for Backbone.Router.navigate
    redirect: (url = '') ->
      window.location.replace url

    # get sura permalink
    permalink: (sura_id, add_prefix = true) ->
      url_prefix = if add_prefix then app.config.url_prefix else ''
      url_prefix + app.config.permalink_format.replace ':sura_id', sura_id

    # proxy function for _.delay
    # reverse the params
    delay: (wait, func) ->
      _.delay func, wait


  # debug
  window.n = app.utils.navigate

) window, window._, window.Backbone, window.QuranVue


# ============================================================
# jQuery simple plugins

(($) ->
  $.fn.scrollTo = (options = {}) ->
    options = _.defaults options, { duration: 1000, callback: $.noop, offset: 0 }
    $('body').animate
      scrollTop: $(this).offset().top + options.offset,
      options.duration,
      options.callback.bind this
    this
) window.jQuery


# ===================================================================================
# backbone extensions

((_, Backbone) ->
  Backbone.Model::get = (key) ->
    _.reduce key.split("."), ((attr, key) ->
      return attr.attributes[key] if attr instanceof Backbone.Model
      attr[key]
    ), @attributes
) window._, window.Backbone


# ===================================================================================
# knockout extensions

((ko) ->
  ko.bindingHandlers.block =
    update: (element, value_accessor) ->
      element.style.display = if ko.utils.unwrapObservable value_accessor() then 'block' else 'none'
) window.ko


# ============================================================
# Javascript extensions

String::unicode = ->
  output = ''
  for i in [0..@length]
    uni = @charCodeAt(i).toString(16).toUpperCase()

    while uni.length < 4
      uni = '0' + uni

    uni = '\\u' + uni
    output += uni

  return output

String::arabicNumber = ->
  arabic = ["\u0660", "\u0661", "\u0662", "\u0663", "\u0664", "\u0665", "\u0666", "\u0667", "\u0668", "\u0669"]
  return @replace /[0-9]/g, (w) ->
    return arabic[+w]

String::toInt = ->
  parseInt this, 10

Number::toOrdinal = ->
  n = @ % 100;
  suffix = ['th', 'st', 'nd', 'rd', 'th']
  ord = if n < 21 then (if n < 4 then suffix[n] else suffix[0]) else (if n % 10 > 4 then suffix[0] else suffix[n % 10])
  @ + ord

Number::toInt = ->
  parseInt this, 10

# ============================================================
# alias for console.log
window.log = -> console.log.apply console, arguments
