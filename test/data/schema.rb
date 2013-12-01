ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :products, force: true do |t|
    t.string     :permalink
    t.boolean    :hidden
  end

  create_table :product_translations, force: true do |t|
    t.references :product
    t.string     :locale
    t.string     :title
  end

  create_table :product_variations, force: true do |t|
    t.string   :sku
  end

  create_table :product_variation_translations, force: true do |t|
    t.references :product_variation
    t.string     :locale
  end
end
