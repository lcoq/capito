require_relative '../test_helper'

describe 'Capito translation class' do
  let(:translated_model) { Product.new }
  subject { translated_model.translations.build(title: 'my title') }

  it 'has a translated model' do
    subject.translated_model.must_equal translated_model
  end

  it 'touch the translated model when updated' do
    translated_model.save!
    subject.locale = :en

    mock(translated_model).touch
    subject.save!
  end

  it 'alias the class name demodulized to the translated model' do
    subject.product.must_equal translated_model
  end

  it 'has accessors for locale' do
    subject.locale = :en
    subject.locale.must_equal :en
  end

  it 'locale is always a symbol' do
    subject.locale = 'en'
    subject.locale.must_equal :en
  end

  it 'mark accessible the locale' do
    subject.attributes = { locale: :en }
  end

  it 'has accessors for translated attributes' do
    subject.title = 'title'
    subject.title.must_equal 'title'
  end

  it 'mark accessible the translated attributes' do
    subject.attributes = { title: 'title' }
  end

  it 'is valid with a locale' do
    subject.locale = :en
    subject.valid?.must_equal true
  end

  it 'is invalid without locale' do
    subject.locale = nil
    subject.valid?.must_equal false
  end

  it 'is invalid with a locale not defined in the available locales' do
    subject.locale = :de
    subject.valid?.must_equal false
  end

  it 'is invalid with an existing locale' do
    translated_model.translations.build(locale: :en, title: 'English title').save!
    subject.locale = :en
    subject.valid?.must_equal false
  end

  it 'destroys the translated model when deleting its last translation' do
    subject.destroy
    assert_raises(ActiveRecord::RecordNotFound) { translated_model.reload }
  end

  it 'does not destroy the translated model with multiple translations when deleting one of its translations' do
    translated_model.save!
    translated_model.translations.build(locale: :fr, title: 'English title')
    subject.destroy
    translated_model.reload
  end
end
