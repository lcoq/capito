class Product < ActiveRecord::Base
  belongs_to :category

  attr_accessible :permalink

  include Capito::Translatable
  translates :title
end
