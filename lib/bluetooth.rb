module Bluetooth

  VERSION = '1.0'

  ERRORS = {}

  class Error < RuntimeError
    def self.raise status
      err = Bluetooth::ERRORS[status]
      super(*err) if err

      super self, "unknown error (#{status})"
    end
  end

  autoload :Device, 'bluetooth/device'

end

require 'bluetooth/bluetooth'

