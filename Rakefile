require 'rubygems'
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

desc 'Open an irb session preloaded with this library'
task :console do
  sh 'irb -I lib -r ./config/environment.rb'
end

namespace :assets do
  desc "Precompile the assets"
  task :precompile do
    require File.expand_path('../config/environment', __FILE__)
    App.compile_assets
  end

  desc "Clean out old assets"
  task :clean do
    system 'rm public/assets/*.css'
    system 'rm public/assets/*js'
  end

  desc "Cleans assets dir then precompiles latest assets"
  task precompile_for_deploy: [:clean, :precompile]
end
