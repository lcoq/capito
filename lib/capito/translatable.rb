module Capito
  module Translatable
    extend ActiveSupport::Concern

    # Remark: This method mark for destruction all the translations that are not present in the passed argument
    def translations_attributes=(translations_attributes)
      translations_to_destroy = translations.to_a

      translations_attributes.each do |translation_attributes|
        locale = HashWithIndifferentAccess.new(translation_attributes)[:locale]
        translation = translation!(locale)
        translation.attributes = translation_attributes
        translations_to_destroy.delete translation
      end

      translations_to_destroy.each { |t| t.mark_for_destruction }
    end

    def translated_locales
      translations.pluck(:locale).map(&:to_sym).to_set
    end

    def translation!(locale = Capito.locale)
      translation(locale) || translations.build(locale: locale)
    end

    def translation(locale = Capito.locale)
      locale = locale.try(:to_sym)
      translations.detect { |t| t.locale == locale }
    end

    module ClassMethods
      def with_translations(*locales)
        locale_field_name = [ translation_class.table_name, 'locale' ].join('.')
        scoped.includes(:translations).where(locale_field_name => locales)
      end

      def translated_locales
        locale_field_name = [ translation_class.table_name, 'locale' ].join('.')
        scoped.joins(:translations).select("DISTINCT #{locale_field_name}").map { |t| t.locale.to_sym }.to_set
      end

      def translations_table_name
        translation_class.table_name
      end

      def translates(*attr_names, &block)
        translation_class.attr_accessible *attr_names

        has_many :translations, {
          class_name: translation_class.name,
          foreign_key: translation_foreign_key,
          inverse_of: :translated_model,
          autosave: true,
          dependent: :destroy
        }

        cattr_accessor :translated_attribute_names
        self.translated_attribute_names = attr_names.to_set

        attr_names.each do |attr_name|
          getter = attr_name.to_sym
          setter = "#{attr_name}=".to_sym
          define_method(setter) { |value| translation!(Capito.locale).send setter, value }
          define_method(getter) { |locale = Capito.locale| translation(locale).send(getter) if translation(locale) }
        end

        translation_class.class_eval(&block) if block_given?
      end

      def translation_class
        @translation_class ||= define_translation_class
      end

      private

      def translation_foreign_key
        table_name.singularize.foreign_key
      end

      def define_translation_class
        klass = self.const_get(:Translation) rescue nil
        if klass.nil?
          klass = self.const_set(:Translation, Class.new(Capito::Translation))
        end
        klass.belongs_to :translated_model, class_name: name, foreign_key: translation_foreign_key, inverse_of: :translations
        klass.validates :locale, presence: true, uniqueness: { scope: translation_foreign_key }
        klass
      end
    end

  end
end
