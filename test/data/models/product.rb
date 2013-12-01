class Product < ActiveRecord::Base
  belongs_to :category

  include Capito::Translatable
  translates :title
end
