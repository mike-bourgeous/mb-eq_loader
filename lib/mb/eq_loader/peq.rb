module MB
  module EQLoader
    # Represents a single parametric EQ object within a Soundweb London DSP,
    # providing methods to set the EQ type, frequency, etc. for any EQ band.
    class PEQ
      # State variable ID offsets
      SVID = {
        bypass: 0,
        frequency: 1,
        boost: 2,
        width: 3,
        type: 4,
        slope: 6,
        bypass_all: 512,
      }.freeze

      # Values for the filter type parameter
      TYPES = {
        bell: 0,
        peak: 0,
        low_shelf: 1,
        high_shelf: 2,
      }.freeze

      # Values for the slope parameter
      SLOPES = {
        6 => 0,
        9 => 1,
        12 => 2,
        15 => 3,
      }.freeze

      # Creates a PEQ object with the given 16-bit +:node+ ID and 24-bit
      # +:object+ ID.  The +:io+ may be an object that responds to :write,
      # allowing this class to send messages over TCP or Serial.
      def initialize(node:, object:, io: nil)
        @node = node
        @vd = 0x03
        @object = object
        @io = io
      end

      # Sets the global bypass toggle for the entire PEQ.
      def set_bypass_all(value)
        set(band: nil, param: :bypass_all, value: value)
      end

      # Sets the bypass toggle (true for bypass, false for enable) for the
      # given +band+ (1-indexed).
      def set_bypass(band, value)
        set(band:, param: :bypass, value:)
      end

      # Sets the frequency in Hz for the given band (1-indexed).
      def set_frequency(band, freq_hz)
        set(band:, param: :frequency, value: freq_hz)
      end

      # Sets the gain in dB for the given band (1-indexed).
      def set_gain(band, gain_db)
        set(band:, param: :boost, value: gain_db)
      end
      alias set_boost set_gain

      # Sets the bandwidth in octaves (0.01..4) for the given band (1-indexed).
      def set_width(band, width_oct)
        set(band:, param: :width, value: width_oct)
      end
      alias set_bandwidth set_width

      # +type_id+ values (or send :bell, :low_shelf, or :high_shelf):
      #   0 - peak/bell
      #   1 - low shelf
      #   2 - high shelf
      def set_type(band, type_id)
        type_id = TYPES.fetch(type_id) if type_id.is_a?(Symbol)
        set(band:, param: :type, value: type_id)
      end

      # +slope_id+ values (or send 6, 9, 12, or 15):
      #   0 - 6dB/Oct
      #   1 - 9dB/Oct
      #   2 - 12dB/Oct
      #   3 - 15dB/Oct
      def set_slope(band, slope_id)
        slope_id = SLOPES.fetch(slope_id) if slope_id >= 6
        set(band:, param: :slope, value: slope_id)
      end

      # Sets all of the parameters on an EQ band.
      def set_band(band:, bypass:, frequency:, gain:, width:, type:, slope:)
        [
          set_bypass(band, bypass),
          set_type(band, type),
          set_frequency(band, frequency),
          set_gain(band, gain),
          set_width(band, width),
          set_slope(band, slope),
        ]
      end

      private

      # Sends a message for the given band and parameter to the IO object given
      # to the constructor.
      def set(band:, param:, value:)
        create_set(band:, param:, value:).tap { |msg|
          @io&.write(msg)
        }
      end

      # Generates a wire-ready message String to set the given parameter to the
      # given value on the given band (1-indexed).
      def create_set(band:, param:, value:)
        case param
        when :bypass_all
          DIProtocol.set_sv(node: @node, vd: @vd, object: @object, sv: SVID[param], value: ValueTypes.binary(value))

        else
          DIProtocol.set_sv(node: @node, vd: @vd, object: @object, sv: sv_id(band:, param:), value: convert_value(param:, value:))
        end
      end

      # Calculates the final state variable ID for the given +:band+ and
      # +:param+ (one of the entries in the SVID Hash).
      def sv_id(band:, param:)
        SVID[param] + (band - 1) * 16
      end

      # Converts the value range from natural float/integer to the
      # device-specific range for that parameter.
      def convert_value(param:, value:)
        case param
        when :bypass
          ValueTypes.binary(value)

        when :frequency
          ValueTypes.log(value)

        when :boost, :width
          ValueTypes.scalar(value)

        when :type, :slope
          value.to_i

        else
          raise "Invalid parameter #{param.inspect}"
        end
      end
    end
  end
end
