# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'grape-middleware-logy'
  spec.version       = '1.0.0'
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Haidar Adi']
  spec.email         = ['pinulunghaidar@gmail.com']
  spec.summary       = %q{A logger for the Grape framework}
  spec.description   = %q{Logging middleware for the Grape framework, similar to what Rails offers}
  spec.homepage      = 'https://github.com/9edang/grape-middleware-logy'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").grep(%r{^lib/|gemspec})
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.post_install_message = %q{
  insert_after Grape::Middleware::Error, Grape::Middleware::Logy
  }

  spec.add_dependency 'grape', '>= 0.17'
  spec.add_development_dependency 'mime-types', '>= 2'
  spec.add_development_dependency 'rake', '>= 12.3.3'
end
