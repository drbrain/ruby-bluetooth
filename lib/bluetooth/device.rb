##
# A bluetooth device

class Bluetooth::Device

  ##
  # The address of this device in XX-XX-XX-XX-XX-XX format

  attr_accessor :address

  ##
  # Sets the name of this device

  attr_writer :name

  ##
  # Creates a new Device with an +address+ and an optional +name+

  def initialize address, name = nil
    @address = address
    @name = name

    @pair_error = nil
    @pair_confirmation_callback = nil
  end

  ##
  # The bytes of this address

  def address_bytes
    @address.split('-').map { |c| c.to_i(16) }.pack 'C*'
  end

  ##
  # Returns the link quality for the device.

  def link_quality
    connect do
      _link_quality
    end
  end

  ##
  # The name of this Device.  It will be automatically looked up if not
  # already known.

  def name
    return @name if @name

    @name = request_name

    return '(unknown)' unless @name

    @name
  end

  ##
  # Called during pairing if user confirmation is required with a number
  # to match with the device.  Return true if the number matches.

  def pair_confirmation &block
    @pair_confirmation_callback = block
  end

  ##
  # Returns the RSSI for the device

  def rssi
    connect do
      _rssi
    end
  end

  def to_s # :nodoc:
    "#{name} at #{address}"
  end

end

