# Capito [![Build Status](https://travis-ci.org/lcoq/capito.png?branch=master)](https://travis-ci.org/lcoq/capito)

Capito is a Globalize alternative for model translations to ActiveRecord models.

## Why ?

Globalize does not handle correctly translation errors with several translations at the same time. 
Capito is designed to be used on an API more than a simple website.

## Installation

Simply put this in your Gemfile:

```ruby
gem 'capito'
```

## Usage

### Models

The translated attributes can be defined easily in the model directly. E.g.

```ruby
class Product < ActiveRecord::Base
  translates :title, :description
end
```

You can also define validations to the translations by passing a block to `#translate` method. 
The block will be evaluated by the translation class. E.g.

```ruby
class Product < ActiveRecord::Base
  translates :title, :description do
    validates :title, presence: true, uniqueness: true
  end
end
```

The attributes will be translated per locale:

```ruby
Capito.locale = :en
product.title # => Toy
 
Capito.locale = :fr
product.title # => Jouet
```

For a quicker access to an attribute in a given locale, you can do as follow:

```ruby
product.title(:en) # => Toy
product.title(:fr) # => Jouet
 
Capito.with_locale(:en) { product.title = 'Toy new version' }
Capito.with_locale(:fr) { product.title = 'Jouet nouvelle version' }
```


### Creating translation tables

Translation tables are not automatically handled yet. You have to write them manually. Given the `Product` model above, the migration should look like this:

```ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.timestamps
    end
    create_table :product_translations do |t|
      t.references :product
      t.string :locale
      t.string :title
      t.string :description
    end
    add_index :product_translations, :product_id
  end
end
```

### Managing translations

You can manage several translations for a model at the same time:

```ruby
product.update_attributes(translations_attributes: [ 
  { locale: :en, title: 'Toy', description: 'A funny toy' }, 
  { locale: :fr, title: 'Jouet', description: 'Un jouet sympa' }
])
```

Notice that you'll never have to pass the `id` and the `_destroy` in the attributes, Capito will manage them for you.
It implies that translations that are not present in the attributes you pass to `Product#update_attributes` will be destroyed.

If you want to update only one translation, you might want to update the model translated attributes, like this :
(you can omit the `Capito#with_locale` if you want to update the model in the default locale)

```ruby
Capito.with_locale(:en) do
  product.update_attributes(title: 'Toy new version', description: 'A really funny toy')
end
```
