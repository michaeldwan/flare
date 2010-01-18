# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{flare}
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Michael Dwan"]
  s.date = %q{2010-01-18}
  s.description = %q{This needs to get updated}
  s.email = %q{mpdwan@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "flare.gemspec",
     "lib/flare.rb",
     "lib/flare/active_record.rb",
     "lib/flare/collection.rb",
     "lib/flare/configuration.rb",
     "lib/flare/index_builder.rb",
     "lib/flare/session.rb",
     "lib/flare/tasks.rb",
     "test/helper.rb",
     "test/test_flare.rb"
  ]
  s.homepage = %q{http://github.com/michaeldwan/flare}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{This needs to get updated}
  s.test_files = [
    "test/helper.rb",
     "test/test_flare.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rsolr>, [">= 0.9.6"])
      s.add_runtime_dependency(%q<escape>, [">= 0.0.4"])
      s.add_development_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    else
      s.add_dependency(%q<rsolr>, [">= 0.9.6"])
      s.add_dependency(%q<escape>, [">= 0.0.4"])
      s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
    end
  else
    s.add_dependency(%q<rsolr>, [">= 0.9.6"])
    s.add_dependency(%q<escape>, [">= 0.0.4"])
    s.add_dependency(%q<thoughtbot-shoulda>, [">= 0"])
  end
end

