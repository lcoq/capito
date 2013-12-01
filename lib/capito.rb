require 'active_record'

module Capito
  autoload :Translatable, 'capito/translatable'
  autoload :Translation, 'capito/translation'

  class << self
    def locale
      @locale || I18n.locale
    end

    def locale=(locale)
      @locale = locale
    end

    def available_locales
      @available_locales || I18n.available_locales
    end

    def available_locales=(available_locales)
      @available_locales = available_locales
    end

    def with_locale(locale, &block)
      previous_locale = self.locale
      begin
        self.locale = locale
        result = yield(locale)
      ensure
        self.locale = previous_locale
      end
      result
    end
  end
end
