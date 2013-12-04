class Variation < ActiveRecord::Base
  belongs_to :product

  include Capito::Translatable
  translates
end
