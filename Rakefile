require 'rubygems'
require 'hoe'

begin
  require 'rake/extensiontask'
rescue LoadError => e
  warn "\nmissing #{e.path} (for rake-compiler)" if e.respond_to? :path
  warn "run: rake newb\n\n"
end

HOE = Hoe.spec 'bluetooth' do
  developer 'Eric Hodel', 'drbrain@segment7.net'
  developer 'Jeremie Castagna', ''
  developer 'Esteve Fernandez', ''

  self.readme_file = 'README.rdoc'

  dependency 'rake-compiler', '~> 0.9', :development

  self.spec_extras[:extensions] = 'ext/bluetooth/extconf.rb'
end

if Rake.const_defined? :ExtensionTask then
  HOE.spec.files.delete_if { |file| file == '.gemtest' }

  Rake::ExtensionTask.new 'bluetooth', HOE.spec do |ext|
    ext.lib_dir = 'lib/bluetooth'
    ext.source_pattern = '**/*.{c,m,h,cpp}'
  end

  task test: :compile
end

