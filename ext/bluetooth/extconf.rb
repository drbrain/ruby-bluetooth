require 'mkmf'

dir_config 'bluetooth'

name = case RUBY_PLATFORM
       when /linux/ then
         abort 'could not find bluetooth library' unless
           have_library 'bluetooth'

         'linux'
       when /(win32|mingw32)/
         abort 'could not find Ws2bth.h' unless
           find_header('Ws2bth.h', 'c:\archiv~1\micros~2\include')

         'win32'
       when /darwin/ then
         $LDFLAGS << ' -framework IOBluetooth'
         'macosx'
       else
         abort "unknown platform #{RUBY_PLATFORM}"
       end

create_makefile 'bluetooth', name

if RUBY_PLATFORM =~ /darwin/ then
  open 'Makefile', 'a' do |io|
    io.write "\n.m.o:\n\t#{COMPILE_C}\n\n"
  end
end

