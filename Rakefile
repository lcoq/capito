require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests'
task default: :test

desc 'Run all tests'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Bump gem version'
task :bump_version, :version do |t, args|
  gemspec_path = 'capito.gemspec'
  new_gemspec = File.open(gemspec_path) do |f|
    content = f.read
    version = content.match(/version\s*=\s*[\'|\"](.*)[\'|\"]/)[1]
    content.sub version, args.version
  end
  IO.write gemspec_path, new_gemspec

  changelog_path = 'CHANGELOG.md'
  new_changelog = File.open(changelog_path) do |f|
    content = f.read
    content.match(/(\#{3}\s*\w+(\s+))/)
    unreleased = $1
    spaces = $2

    date = Time.now.strftime('%B %-d, %Y')
    released = "### Capito #{args.version} (#{date})"
    content.sub unreleased, "#{unreleased}#{released}#{spaces}"
  end
  IO.write changelog_path, new_changelog

  system 'git diff'
  puts "Do you wants to commit this changes ? (Y/n)"
  if STDIN.gets.chomp =~ /y/i
    tag_version = "v#{args.version}"
    `git add .`
    `git commit -m "Bump version #{tag_version}"`
    `git tag #{tag_version} HEAD`
    puts "Bump version finished"
  else
    puts "Bump version cancelled"
  end
end
