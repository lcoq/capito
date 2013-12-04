class Product < ActiveRecord::Base
  belongs_to :category
  has_many :variations

  attr_accessible :permalink

  include Capito::Translatable
  translates :title, autobuild: false do
    delegate :permalink, to: :product, prefix: true
  end
end
