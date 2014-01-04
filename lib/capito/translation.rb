module Capito
  class Translation < ActiveRecord::Base
    self.abstract_class = true

    validates :locale, inclusion: { in: lambda { |t| Capito.available_locales } }

    def locale
      read_attribute(:locale).try(:to_sym)
    end
  end
end
