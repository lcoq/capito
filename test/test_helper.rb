require 'pry'

require 'bundler/setup'
Bundler.require(:test)

require 'capito'

require 'logger'
log = '/tmp/capito_test.log'
FileUtils.touch(log) unless File.exists?(log)

ActiveRecord::Base.logger = Logger.new(log)
ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

require 'database_cleaner'
DatabaseCleaner.strategy = :truncation

require_relative 'data/schema'
require_relative 'data/models'

require 'minitest/autorun'
require 'minitest/spec'

MiniTest::Spec.class_eval do
  def setup
    DatabaseCleaner.start

    Capito.locale = :en
    Capito.available_locales = [ :en, :fr ]
  end

  def teardown
    DatabaseCleaner.clean
  end
end
