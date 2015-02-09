BINARY_REGEX = /([0,1]{8}[\.]?[0-1]{8}[\.]?[0-1]{8}[\.]?[0-1]{8})/
DOTTED_HEX_REGEX = /(0x[0-9a-fA-F]{2}\.0x[0-9a-fA-F]{2}\.0x[0-9a-fA-F]{2}\.0x[0-9a-fA-F]{2})/
DOTTED_OCTAL_REGEX = /([0-7]{4}\.[0-7]{4}\.[0-7]{4}\.[0-7]{4})/
DOTTED_DECIMAL_REGEX = /([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})/
HEX_REGEX = /(0x[0-9a-fA-F]{8})/
OCTAL_REGEX = /(0[0-7]+)/
DECIMAL_REGEX = /([0-9]+)/

filename = ARGV[0]

found_IPs = []

def most_frequent list
  list.group_by { |e| e }.values.max_by(&:size).first
end

def validate_IP ip
  octets = ip.split('.').map(&:to_i)

  return false if octets[0] == 0

  not octets.any? { |octet| octet > 255 }
end

def format_IP ip
  [24, 16, 8, 0].collect { |shift| (ip >> shift) & 255 }.join '.'
end

def find_binary_IPs text
  text.scan(BINARY_REGEX).flatten.collect { |match| format_IP(match.gsub('.', '').to_i(2)) }
end

def find_dotted_hex_IPs text
  text.scan(DOTTED_HEX_REGEX).flatten.collect { |match| format_IP(match.gsub('0x', '').gsub('.', '').to_i(16)) }
end

def find_dotted_octal_IPs text
  text.scan(DOTTED_OCTAL_REGEX).flatten.collect do |match|
    address = 0
    octet_index = 0

    match.split('.').each do |octet|
      address += octet.to_i(8) << (8 * (3 - octet_index))
      octet_index += 1
    end

    format_IP address
  end
end

def find_dotted_decimal_IPs text
  text.scan(DOTTED_DECIMAL_REGEX).flatten
end

def find_hex_IPs text
  text.scan(HEX_REGEX).flatten.collect { |match| match.sub('0x', '').to_i(16) }
end

def find_octal_IPs text
  text.scan(OCTAL_REGEX).flatten.collect { |match| format_IP(match.to_i(8)) }
end

def find_decimal_IPs text
  text.scan(DECIMAL_REGEX).flatten.collect { |match| format_IP(match.to_i) }
end

search_functions = [:find_binary_IPs,
                    :find_dotted_hex_IPs,
                    :find_dotted_octal_IPs,
                    :find_dotted_decimal_IPs,
                    :find_hex_IPs,
                    :find_octal_IPs,
                    :find_decimal_IPs]

File.open filename, 'r' do |file|
  for line in file
    for search in search_functions
      found_IPs += method(search).call line
    end
  end

  found_IPs.select! { |ip| validate_IP ip }
end

puts most_frequent(found_IPs)