window.QuranVue ?= {}

((window, $, app) ->

  # ============================================================
  # ui helper methods
  app.ui =

    # active navbar
    navbar: (name = '-none-') ->
      $(".navbar .nav li").removeClass 'active'
      $(".navbar .nav li.nav-#{name}").addClass 'active'

    # error message
    error: (type = 'alert', title = 'Alert!', message = 'Oh snap!', wait = 2500) ->
      $error_container = $('#error')
      $error = $('.alert', $error_container)
      $error_content = $('.alert-content', $error)
      $error_close = $('.close', $error)

      $error.removeClass('error').removeClass('success').removeClass('info').addClass("alert-#{type}")
      $error_content.html "<h4>#{title}</h4>#{message}"

      $error_close.click ->
        $error_container.removeClass 'show'
        false

      $error_container.addClass 'show'
      _.delay (-> $error_container.removeClass 'show'), wait

      false

  # debug
  window.e = app.ui.error
  window.o = app.ui.overlay

) window, window.jQuery, window.QuranVue
