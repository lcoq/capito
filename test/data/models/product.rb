class Product < ActiveRecord::Base
  belongs_to :category
  has_many :variations

  include Capito::Translatable
  translates :title, autobuild: false do
    delegate :permalink, to: :product, prefix: true
    validates :title, presence: true
  end
end
