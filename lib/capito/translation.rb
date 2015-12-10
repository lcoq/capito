module Capito
  class Translation < ActiveRecord::Base
    self.abstract_class = true

    validates :locale, inclusion: { in: lambda { |t| Capito.available_locales } }

    attr_accessible :locale if defined? ProtectedAttributes

    def locale
      read_attribute(:locale).try(:to_sym)
    end

    private

    def destroy_model_without_translation
      model = translated_model
      if model && !model.destroyed? && !model.will_destroy? && (model.translations - [self]).empty?
        model.destroy
      end
    end
  end
end
