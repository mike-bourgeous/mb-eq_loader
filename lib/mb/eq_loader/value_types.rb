# This module provides code for converting decibels, Hertz, etc. into the
# integer values used by the Soundweb London hardware.  These conversions are
# based on the math in the documentation included with London Architect for
# this purpose.
module MB::EQLoader::ValueTypes
  module_function

  # Converts true/false to 1 or 0.
  def binary(value)
    !!value ? 1 : 0
  end
  alias boolean binary
  class << self
    alias boolean binary
  end

  # Converts delay time in seconds to Integer samples at 96kHz.
  def delay(seconds)
    (seconds * 96000).round
  end

  # Converts a mixer or gain object gain from decibels -80..10 to Integer.
  def gain(decibels)
    if decibels >= -10
      (decibels * 10000).round
    else
      (-Math.log10(-decibels / 10.0) * 200000 - 100000).round
    end
  end

  # Converts a value to a logarithmic scale used by some parameters.
  def log(value)
    (Math.log10(value) * 1000000).round
  end
  alias freq log

  # Converts a linear value to an Integer range used by some parameters.
  def scalar(value)
    (value * 10000).round
  end
end
