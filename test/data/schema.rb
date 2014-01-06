ActiveRecord::Migration.verbose = false

ActiveRecord::Schema.define do
  create_table :categories, force: true do |t|
    t.string   :name
  end

  create_table :products, force: true do |t|
    t.references :category
    t.string     :permalink
    t.boolean    :hidden
  end

  create_table :product_translations, force: true do |t|
    t.references :product
    t.string     :locale
    t.string     :title
  end

  create_table :variations, force: true do |t|
    t.references :product
    t.string     :sku
  end

  create_table :variation_translations, force: true do |t|
    t.references :variation
    t.string     :locale
  end

  create_table :pages, force: true do |t|
    t.string :title
    t.boolean :hidden
  end

  create_table :page_translations, force: true do |t|
    t.references :page
    t.string     :locale
    t.string     :title
  end
end
