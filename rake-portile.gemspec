Gem::Specification.new do |spec|
  spec.name          = "rake-portile"
  spec.version       = '0.0.0'
  spec.authors       = ["Kasumi Hanazuki"]
  spec.email         = ["kasumi@rollingapple.net"]

  spec.summary       = %q{Rake::Portile}
  spec.description   = %q{Rake tasks for building libraries}
  spec.homepage      = "https://github.com/hanazuki/rake-portile"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'rake'
  spec.add_dependency 'mini_portile2'
end
