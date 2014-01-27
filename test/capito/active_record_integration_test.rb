require_relative '../test_helper'

describe 'ActiveRecord integration' do

  describe 'on Product' do
    subject { Product }

    describe 'finders' do
      it 'find by untranslated attributes' do
        object = subject.new.tap { |m| m.hidden = true; m.save! }
        subject.find_by(hidden: true).must_equal object
      end

      it 'find by translated attributes' do
        object = subject.new.tap { |m| m.title = 'foo'; m.save! }
        subject.find_by(title: 'foo').must_equal object
      end

      it 'find object and load all translations' do
        product = subject.new
        Capito.with_locale(:en) { product.title = 'my title' }
        Capito.with_locale(:fr) { product.title = 'mon titre' }
        product.save!
        found = Capito.with_locale(:fr) do
          Product.find_by(title: 'my title')
        end
        found.must_equal product
        found.translations.size.must_equal 2
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

      it 'searches with both attributes' do
        object = subject.new.tap { |p| p.title = 'test'; p.hidden = true; p.save! }
        subject.where(title: 'test', hidden: true).first.must_equal object
      end

      it 'searches with not attributes' do
        object = subject.new.tap { |p| p.title = 'foo'; p.hidden = true; p.save! }
        subject.where.not(title: 'test').first.must_equal object
      end
    end
  end

  describe 'on Page' do
    subject { Page }

    it 'can build a page' do
      subject.find_or_create_by(title: 'test', hidden: true).title.must_equal 'test'
    end
  end
end
