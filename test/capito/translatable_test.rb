require_relative '../test_helper'

describe Capito::Translatable do
  subject { Product.new }

  it 'translations are empty for a new record' do
    Product.new.translations.must_be_empty
  end

  it 'has many translations' do
    subject.translations.build
    subject.translations.size.must_equal 1
  end

  it 'has accessors for the translated attributes' do
    subject.title = 'foo'
    subject.title.must_equal 'foo'
  end

  it 'translated locales are the persisted locales for this translated model' do
    subject.save!
    subject.translations.create(locale: Capito.locale, title: 'my title')
    subject.translations.build(locale: :fr)
    subject.translated_locales.must_equal [Capito.locale].to_set
  end

  describe 'translated attribute getter' do
    it 'returns the value in the current locale' do
      subject.translations.build(locale: Capito.locale, title: 'foo')
      subject.title.must_equal 'foo'
    end

    it 'returns the value in the locale specified' do
      subject.translations.build(locale: :fr, title: 'foo')
      subject.title(:fr).must_equal 'foo'
    end

    it 'returns nil when the translation does not exist' do
      subject.title(:de).must_be_nil
    end

    it 'does not build translation with the locale specified' do
      subject.title(:de)
      subject.translations.select { |t| t.locale == :en }.must_be_empty
    end
  end

  describe 'translated attribute setter' do
    it 'builds a translation in the current locale and set the attribute' do
      subject.title = 'foo'
      translation = subject.translations.detect { |t| t.locale == Capito.locale }
      translation.wont_be_nil
      translation.title.must_equal 'foo'
    end

    it 'updates a translation attribute in the current locale' do
      translation = subject.translations.build(locale: Capito.locale)
      subject.title = 'foo'
      translation.title.must_equal 'foo'
    end
  end

  describe '#translations_attributes=' do
    it 'is accessible' do
      subject.attributes = { translations_attributes: [] }
    end

    it 'accepts new translations' do
      subject.translations_attributes = [ { locale: 'en', title: 'my title' } ]
      subject.save!
      subject.reload
      subject.translations.count.must_equal 1
      subject.translations.first.title.must_equal 'my title'
    end

    it 'accepts existing translations' do
      subject.save!
      subject.translations.create(locale: :en, title: 'my title')

      subject.translations_attributes = [ { locale: 'en', title: 'my new title' } ]
      subject.save!
      subject.reload
      subject.translations.count.must_equal 1
      subject.translations.first.title.must_equal 'my new title'
    end

    it 'mark for destruction the translations not present in the attributes specified' do
      subject.save!
      translation = subject.translations.create(locale: :en, title: 'my title')
      subject.translations_attributes = [ { locale: 'fr', title: 'mon titre'} ]
      translation.marked_for_destruction?.must_equal true
      translation.destroyed?.must_equal false
    end

    it 'destroys the translations not present in the attributes specified on save' do
      subject.save!
      translation = subject.translations.create(locale: :en, title: 'my title')
      subject.translations_attributes = [ { locale: 'fr', title: 'mon titre'} ]
      subject.save!
      translation.destroyed?.must_equal true
    end
  end

  describe 'save' do
    it 'save the new translations' do
      translation = subject.translations.build(locale: Capito.locale, title: 'my title')
      subject.save!
      translation.persisted?.must_equal true
    end

    it 'updates the existing translations' do
      translation = subject.translation!
      translation.title = 'my title'
      subject.save!

      subject.title = 'my new title'
      subject.save!
      translation.title.must_equal 'my new title'
      translation.changed?.must_equal false
    end
  end

  describe 'destroy' do
    it 'destroys its translations' do
      subject.save!
      fr = subject.translations.create(locale: :fr, title: 'mon titre')
      en = subject.translations.create(locale: :en, title: 'my title')
      subject.destroy
      subject.translations.all? { |t| t.destroyed? }.must_equal true
    end
  end

  describe 'destroy_translation' do
    it 'destroys the translation' do
      subject.save!
      subject.translations.create(locale: :fr, title: 'mon titre')
      subject.translations.create(locale: :en, title: 'my title')
      subject.save!
      subject.translation(:fr).destroyed?.must_equal false
      subject.destroy_translation(:fr)
      subject.translation(:fr).destroyed?.must_equal true
    end
  end

  describe '#translation' do
    it 'returns the translation for the locale specified' do
      translation = subject.translations.build(locale: :en)
      subject.translation(:en).must_equal translation
    end

    it 'returns the translation for the current locale' do
      translation = subject.translations.build(locale: Capito.locale)
      subject.translation.must_equal translation
    end

    it 'accepts both string and symbol' do
      translation = subject.translations.build(locale: 'en')
      subject.translation(:en).must_equal translation
      subject.translation('en').must_equal translation
    end
  end

  describe '#translation!' do
    it 'returns the translation for the locale specified' do
      translation = subject.translations.build(locale: :en)
      subject.translation(:en).must_equal translation
    end

    it 'builds the translation when it does not exist' do
      translation = subject.translation!(:en)
      translation.locale.must_equal :en
    end

    it 'uses the current locale by default' do
      subject.translation!.locale.must_equal Capito.locale
    end
  end

  describe 'errors_hash' do
    it 'contains the translation errors' do
      subject.translations.build(locale: :fr)
      subject.valid?.must_equal false

      hash = subject.errors_hash
      hash[:translations].size.must_equal 1

      errors = hash[:translations].first
      errors[:locale].must_equal :fr
      errors[:title].must_equal ["can't be blank"]
    end

    it 'contains only errored translations' do
      subject.translation!(:en).title = 'foo'
      subject.translations.build(locale: :fr)
      subject.valid?.must_equal false

      hash = subject.errors_hash
      hash[:translations].size.must_equal 1
    end

    it 'contains the translation errors even when the locale is not set' do
      subject.translations.build
      subject.valid?.must_equal false

      hash = subject.errors_hash
      hash[:translations].size.must_equal 1

      errors = hash[:translations].first
      errors[:locale].to_set.must_equal ["is not included in the list", "can't be blank"].to_set
      errors[:title].must_equal ["can't be blank"]
    end
  end

  describe 'class methods' do
    subject { Product }

    it 'has a translation class nested in the model class' do
      subject.const_defined?(:Translation).must_equal true
    end

    it 'has translated attribute names' do
      subject.translated_attribute_names.must_equal [:title].to_set
    end

    it 'translated locales are all the locale available for the model class' do
      Capito.with_locale(:en) { subject.new.tap { |m| m.title = 'foo'; m.save! } }
      Capito.with_locale(:fr) { subject.new.tap { |m| m.title = 'bar'; m.save! } }
      subject.translated_locales.must_equal [ :en, :fr ].to_set
    end

    describe '#with_translations' do
      it 'returns the models that are translated in the locale specified' do
        en = Capito.with_locale(:en) { subject.new.tap { |m| m.title = 'foo'; m.save! } }
        fr = Capito.with_locale(:fr) { subject.new.tap { |m| m.title = 'bar'; m.save! } }

        result = subject.with_translations(:fr)
        result.must_include fr
        result.wont_include en
      end

      it 'returns all models that have a translation' do
        en = Capito.with_locale(:en) { subject.new.tap { |m| m.title = 'foo'; m.save! } }
        fr = Capito.with_locale(:fr) { subject.new.tap { |m| m.title = 'bar'; m.save! } }

        untranslated = subject.new.tap { |m| m.save! }
        untranslated.translations.destroy_all

        result = subject.with_translations
        result.must_include en
        result.must_include fr
        result.wont_include untranslated
      end
    end

    describe '#translates' do
      it 'accepts a block which is evaluated by the translation class' do
        model = subject.new(permalink: 'permalink')
        translation = model.translations.build
        translation.respond_to?(:product_permalink).must_equal true
        translation.product_permalink.must_equal 'permalink'
      end

      it 'accepts false for :autobuild option' do
        model = subject.new
        model.translation.must_be_nil
        model.valid?
        model.translation.must_be_nil
      end

      it 'autobuilds by default' do
        model = Variation.new
        model.translation.must_be_nil
        model.valid?
        model.translation.wont_be_nil
      end
    end

    it 'translations table name is the translation class table name' do
      subject.translations_table_name.must_equal 'product_translations'
    end

    it 'translated column name is the column name prefixed with the translation class table name' do
      subject.translated_column_name(:title).must_equal 'product_translations.title'
    end

    describe 'finders' do
      it 'find by untranslated attributes' do
        object = subject.new.tap { |m| m.hidden = true; m.save! }
        subject.find_by(hidden: true).must_equal object
      end

      it 'find by translated attributes' do
        object = subject.new.tap { |m| m.title = 'foo'; m.save! }
        subject.find_by(title: 'foo').must_equal object
      end

      describe 'instantiators' do
        it 'find' do
          object = subject.new.tap { |m| m.title = 'foo'; m.save! }
          subject.find_or_initialize_by(title: 'foo').must_equal object
          subject.find_or_create_by(title: 'foo').must_equal object
        end

        it 'instantiate' do
          result = subject.find_or_initialize_by(title: 'foo', permalink: 'permalink')
          result.persisted?.must_equal false
          result.title.must_equal 'foo'
          result.permalink.must_equal 'permalink'
        end

        it 'create' do
          result = subject.find_or_create_by(title: 'foo', permalink: 'permalink')
          result.persisted?.must_equal true
          result.title.must_equal 'foo'
          result.permalink.must_equal 'permalink'
        end

        it 'keeps the scope' do
          category = Category.new.tap { |c| c.save! }
          category.products.find_or_initialize_by(title: 'foo').category.must_equal category
        end
      end
    end

    describe 'where' do
      it 'searches with untranslated attributes' do
        object = subject.new.tap { |m| m.hidden = true; m.save! }
        subject.where(hidden: true).first.must_equal object
      end

      it 'searches with translated attributes' do
        object = subject.new.tap { |m| m.title = 'foo'; m.save! }
        subject.where(title: 'foo').first.must_equal object
      end
    end
  end
end
