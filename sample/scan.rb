require 'bluetooth'

devices = Bluetooth.scan

devices.each do |device|
  puts device
end

