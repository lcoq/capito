require_relative 'test_helper'

describe Capito do
  subject { Capito }

  describe 'locale' do
    it 'is the I18n locale by default' do
      subject.locale = nil
      subject.locale.must_equal I18n.locale
    end

    it 'can be set' do
      subject.locale = :en
      subject.locale.must_equal :en
    end
  end

  describe 'available locales' do
    it 'is the I18n available locales by default' do
      subject.available_locales = nil
      subject.available_locales.must_equal I18n.available_locales
    end

    it 'can be set' do
      subject.available_locales = [ :en, :fr ]
      subject.available_locales.must_equal [ :en, :fr ]
    end
  end

  describe 'with locale' do
    it 'yields in the locale specified' do
      subject.with_locale(:fr) { Capito.locale }.must_equal :fr
      subject.with_locale(:en) { Capito.locale }.must_equal :en
    end
  end
end
