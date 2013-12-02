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
end
