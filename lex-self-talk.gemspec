# frozen_string_literal: true

require_relative 'lib/legion/extensions/self_talk/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-self-talk'
  spec.version       = Legion::Extensions::SelfTalk::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX SelfTalk'
  spec.description   = 'Inner dialogue system for brain-modeled agentic AI — structured internal conversation via multiple cognitive voices'
  spec.homepage      = 'https://github.com/LegionIO/lex-self-talk'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-self-talk'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-self-talk'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-self-talk'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-self-talk/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-self-talk.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
