require 'active_record'

module Capito
  autoload :Translatable, 'capito/translatable'
  autoload :Translation, 'capito/translation'

  class << self
    def locale
      read_locale || I18n.locale
    end

    def locale=(locale)
      set_locale locale
    end

    def available_locales
      @available_locales || I18n.available_locales
    end

    def available_locales=(available_locales)
      @available_locales = available_locales
    end

    def with_locale(locale, &block)
      previous_locale = read_locale
      begin
        set_locale locale
        result = yield(locale)
      ensure
        set_locale previous_locale
      end
      result
    end

    protected

    def read_locale
      Thread.current[:capito_locale]
    end

    def set_locale(locale)
      Thread.current[:capito_locale] = locale.try(:to_sym)
    end
  end
end
