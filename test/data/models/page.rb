class Page < ActiveRecord::Base
  include Capito::Translatable
  translates :title
end
