require "bundler/gem_tasks"
require "rake/testtask"
require 'appraisal'

Rake::TestTask.new(:test) do |t, args|
  t.libs << "test"
  t.libs << "lib"
  file_list = FileList["test/**/*_test.rb"]

  file_list.exclude(/integration+/) unless ENV["APPRAISAL_INITIALIZED"]
  t.test_files = file_list
end

task :default => :test
