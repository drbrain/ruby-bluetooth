require 'bluetooth'

address = ARGV.shift || abort("#{$0} address # look up a device with scan.rb")

device = Bluetooth::Device.new address

puts device

