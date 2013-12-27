Gem::Specification.new do |s|
  s.name          = 'capito'
  s.version       = '0.0.2'

  s.authors       = [ 'Louis Coquio' ]
  s.email         = [ 'louis.coquio@gmail.com' ]
  s.homepage      = 'http://github.com/lcoq/capito'
  s.description   = 'ActiveRecord model translations'
  s.summary       = s.description
  s.license       = 'MIT'

  s.files         = Dir['README.md', 'LICENSE.txt', 'lib/**/*', 'test/**/*']

  s.require_paths = ["lib"]

  s.add_dependency 'activerecord', '~> 3.2.12'
  s.add_dependency 'activemodel', '~> 3.2.12'

  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'pry'
end
