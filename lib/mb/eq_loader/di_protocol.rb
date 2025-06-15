# This module implements message packing for the Soundweb London
# direct-inject protocol as documented in the help file shipped with London
# Architect.
#
# The Rubyisms used here are super inefficient compared to a straightforward
# C implementation, but they make the code much simpler.
module MB::EQLoader::DIProtocol
  module_function

  # Valid message IDs
  MESSAGE_IDS = {
    0x88 => :set,
    0x89 => :subscribe,
    0x8a => :unsubscribe,
    0x8b => :recall_venue_preset,
    0x8c => :recall_parameter_preset,
    0x8d => :set_percent,
    0x8e => :subscribe_percent,
    0x8f => :unsubscribe_percent,
    0x90 => :bump_percent,
  }.freeze
  MESSAGE_ID_LOOKUP = MESSAGE_IDS.invert.freeze

  # Message IDs that load presets and use a shorter payload
  PRESET_IDS = [0x8b, 0x8c].freeze

  # Returns a wire-ready message to set the value of a state variable.
  def set_sv(node:, vd:, object:, sv:, value:)
    serialize_message(
      assemble_payload(
        id: MESSAGE_ID_LOOKUP[:set],
        address: pack_address(node:, vd:, object:),
        sv:,
        value:
      )
    )
  end

  # Creates a raw message payload with the message type :+id+.  Address and SV
  # (state variable) are required unless the +:id+ is a preset recalling
  # message type.  Pass the returned string into #serialize_message.
  def assemble_payload(id:, address: nil, sv: nil, value:)
    raise "Invalid message ID #{id}" unless MESSAGE_IDS.include?(id)
    raise 'Address is required' unless address || PRESET_IDS.include?(id)
    raise 'SV ID is required' unless sv || PRESET_IDS.include?(id)

    id = [id].pack('C')
    address = [address].pack('Q>')[-6..]
    sv = [sv].pack('S>')
    value = [value].pack('L>')

    "#{id}#{address}#{sv}#{value}"
  end

  # Combines 16-bit node ID, 8-bit virtual device ID, and 24-bit object ID
  # into a single integer.  E.g. pack_address(node: 0x1234, vd: 0x56, object:
  # 0x789abc) will return 0x123456789abc.
  def pack_address(node:, vd:, object:)
    ((node & 0xffff) << 32) | ((vd & 0xff) << 24) | (object & 0xffffff)
  end

  # Computes the message checksum, escapes special values less than 0x80 with
  # 0x1b, (val|0x80), then adds the STX/ETX characters to the start and end.
  def serialize_message(raw_payload)
    checksum = [raw_payload.bytes.reduce(&:^)].pack('C')
    checksum_payload = "#{raw_payload}#{checksum}"
    escaped_payload = checksum_payload.gsub(/[\x02\x03\x06\x15\x1b]/) { |c| [0x1b, c.bytes[0] | 0x80].pack('C*') }

    "\x02#{escaped_payload}\x03"
  end
end
