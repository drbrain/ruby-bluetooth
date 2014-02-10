require 'bluetooth'

address = ARGV.shift || abort("#{$0} address pin")

device = Bluetooth::Device.new address

device.pair_confirmation do |number|
  puts "The device should say %06d" % number
  true
end

paired = device.pair ? "paired" : "didn't pair"

puts paired

