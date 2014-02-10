require 'rubygems'
require 'hoe'
#require 'rake/extensiontask'

hoe = Hoe.spec 'bluetooth' do
  developer 'Eric Hodel', 'drbrain@segment7.net'
  developer 'Jeremie Castagna', ''
  developer 'Esteve Fernandez', ''

  self.readme_file = 'README.rdoc'

  dependency 'rake-compiler', '~> 0.6', :development

  self.clean_globs = %w[
    ext/bluetooth/Makefile
    ext/bluetooth/mkmf.log
    ext/bluetooth/bluetooth.bundle
    ext/bluetooth/*.o
  ]

  self.spec_extras[:extensions] = 'ext/bluetooth/extconf.rb'
end

#Rake::ExtensionTask.new 'bluetooth' do |ext|
#  ext.source_pattern = '*/*.{c,cpp,h,m}'
#  ext.gem_spec = hoe.spec
#end
#
#task :test => :compile

