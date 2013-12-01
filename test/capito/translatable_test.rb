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
      subject.save!
      translation = subject.translations.create(locale: Capito.locale, title: 'my title')
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
    end

    describe '#translates' do
      it 'accepts a block which is evaluated by the translation class' do
        subject.translates { def bar; 'bar'; end }
        subject.new.translations.build.bar.must_equal 'bar'
      end
    end

    it 'translations table name is the translation class table name' do
      subject.translations_table_name.must_equal subject.translation_class.table_name
    end
  end
end
