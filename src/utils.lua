local class = require "middleclass"
local bin = require "plc52.bin"

-- provides file-like read
local Reader = class("Reader")

function Reader:initialize(payload)
  self.payload = payload
  self.offset = 0
end

function Reader:read(how_many)
  local result = self.payload:sub(self.offset + 1, self.offset + how_many)
  self.offset = self.offset + how_many

  return result
end

function Reader:is_finished()
  return self.payload:len() <= self.offset
end

function encode_signature_der(packed_r, packed_s)
  local packed_integers = {packed_r, packed_s}
  local packed_encoded_integers = {}
  for _, integer in pairs(packed_integers) do
    local first_byte = tonumber(bin.stohex(integer:sub(1, 1)), 16)
    -- If the first bit is 0
    if first_byte == bit32.band(first_byte, tonumber("01111111", 2)) then
      table.insert(packed_encoded_integers, "\x02\x20" .. integer)
    else
      table.insert(packed_encoded_integers, "\x02\x21\x00" .. integer)
    end
  end

  local result_integer_part = table.concat(packed_encoded_integers)
  local result_length = bin.hextos(string.format("%02x", #result_integer_part))
  local result_seq = "\x30" .. result_length .. result_integer_part
  return result_seq
end

function convert_signature_der(packed_signature)
  local packed_r = packed_signature:sub(1, 32)
  local packed_s = packed_signature:sub(33, 64)

  return encode_signature_der(packed_r, packed_s)
end

return {
  Reader = Reader,
  encode_signature_der = encode_signature_der,
  convert_signature_der = convert_signature_der
}
