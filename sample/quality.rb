require 'bluetooth'

address = ARGV.shift || abort("#{$0} address # look up a device with scan.rb")

device = Bluetooth::Device.new address

begin
  device.connect do
    loop do
      puts 'link quality: %3d RSSI: %4d dB' % [
        device._link_quality, device._rssi
      ]

      sleep 2
    end
  end
rescue Interrupt
  exit
rescue Bluetooth::OfflineError
  abort 'you need to enable bluetooth'
rescue Bluetooth::Error
  puts "#{$!} (#{$!.class})"
retry
end

