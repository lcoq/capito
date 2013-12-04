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
        locales = translated_locales.to_a if locales.empty?
        locale_field_name = [ translation_class.table_name, 'locale' ].join('.')
        scoped.includes(:translations).where(locale_field_name => locales)
      end

      def translated_locales
        locale_field_name = [ translation_class.table_name, 'locale' ].join('.')
        scoped.joins(:translations).select("DISTINCT #{locale_field_name}").map { |t| t.locale.to_sym }.to_set
      end

      def translated_column_name(name)
        [ translations_table_name, name ].join('.')
      end

      def translations_table_name
        translation_class.table_name
      end

      def translates(*attr_names, &block)
        attr_accessible :translations_attributes
        attr_accessible :translations_attributes, *attr_names
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

      def respond_to_missing?(method_id, include_private = false)
        supported_on_missing?(method_id) || super
      end

      private

      def supported_on_missing?(method)
        match = defined?(::ActiveRecord::DynamicFinderMatch) && ::ActiveRecord::DynamicFinderMatch.match(method)
        return false unless match

        attribute_names = match.attribute_names.map(&:to_sym)
        translated_attributes = attribute_names & translated_attribute_names.to_a
        return false if translated_attributes.empty?

        untranslated_attributes = attribute_names - translated_attributes
        return false if untranslated_attributes.any? { |attribute| !respond_to?("scoped_by_#{attribute}".to_sym) }

        return [ match, attribute_names, translated_attributes, untranslated_attributes ]
      end

      def method_missing(method, *args, &block)
        match, attribute_names, translated_attributes, untranslated_attributes = supported_on_missing?(method)
        return super unless match

        scope = scoped.includes(:translations)

        translated_attributes.each do |attribute|
          value = args[attribute_names.index(attribute)]
          scope = scope.where(translated_column_name(attribute) => value)
        end

        untranslated_attributes.each do |attribute|
          value = args[attribute_names.index(attribute)]
          scope = scope.send("scoped_by_#{attribute}".to_sym, value)
        end

        if match.instantiator?
          scoped.send :find_or_instantiator_by_attributes, match, attribute_names, *args, &block
        else
          scope.send(match.finder)
        end
      end

      def translation_foreign_key
        table_name.singularize.foreign_key
      end

      def define_translation_class
        klass = self.const_get(:Translation) rescue nil
        if klass.nil?
          klass = self.const_set(:Translation, Class.new(Capito::Translation))
        end
        klass.belongs_to :translated_model, class_name: name, foreign_key: translation_foreign_key, inverse_of: :translations

        translated_model_alias = self.to_s.demodulize.underscore
        klass.class_eval %Q{ def #{translated_model_alias}; self.translated_model; end }

        klass.validates :locale, presence: true, uniqueness: { scope: translation_foreign_key }
        klass
      end
    end

  end
end
