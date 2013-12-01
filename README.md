# Capito

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
The block will be evaluated in the translation class. E.g.

```ruby
class Product < ActiveRecord::Base
  translates :title, :description do
    validates :title, presence: true, uniqueness: true
  end
end
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
    end
    add_index :product_translations, :product_id
  end
end
```
