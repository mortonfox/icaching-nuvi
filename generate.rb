require_relative 'config'
require 'oga'

module IcachingNuvi
  class Generate
    # Maximum length of description, hints, and logs.
    TEXT_LIMIT = 16_500

    def initialize
    end

    def esc_html s
      x = Oga::XML::Text.new
      x.text = s
      x.to_xml
    end

    # Truncate a string to the specified length but clean up HTML entities at
    # the end of the string that may have gotten chopped up.
    def truncate s, len
      return s if s.size < len
      s = s[0, len]
      # Clean up the end of the string so we don't leave a piece of a HTML
      # entity behind when we truncate the string.
      s[0...-7] + s[-7..-1].delete('&')
    end

    DISCARD_WORDS = %w(this that the a an)

    def smart_name str, maxlen
      words = str.scan(/\w+/)

      # If the string begins with one of the words in DISCARD_WORDS, drop that word.
      words.shift if words.size > 1 && DISCARD_WORDS.include?(words.first.downcase)

      # Join words in camel case.
      squished = words.map(&:capitalize).join('')

      # If there is a number, try to keep the least significant digits of it.
      match = squished.match(/^(\D*)(\d+)(.*)$/)
      if match
        digit_length = [match[2].size, 3].min
        prefix = match[1][0, maxlen - digit_length]
        squished = prefix + match[2][[match[2].size - (maxlen - prefix.size), 0].max..-1] + match[3]
      end

      # Shorten string.
      squished[0, maxlen]
    end

    # Helper for strip_html.
    def strip_html_2 elem
      out = ''
      elem.each_node { |node|
        case node
        when Oga::XML::Element
          case node.name.downcase
          when 'br'
            out += '<br>'
          when 'p'
            # Need to do this recursively because we want to close the <p>
            # block properly.
            out += '<p>' + strip_html_2(node) + '</p>'
            throw :skip_children
          end
        when Oga::XML::Text
          out += node.text
        end
      }
      out
    end

    # Strip HTML tags except for <p> and <br>. This is for POILoader and the
    # Nuvi, which can't handle anything too complicated.
    def strip_html s
      elem = Oga.parse_html s
      strip_html_2 elem
    end

    LOG_TYPES = {
      'found it' => 'F',
      'webcam photo taken' => 'F',
      'attended' => 'F',
      'didn\'t find it' => 'N'
    }
    def conv_log_type log
      LOG_TYPES[log.downcase] || 'X'
    end

    # Summarize last 4 cache logs.
    def last4 cache
      4.times.zip(cache[:logs]) { |_, log|
        if log
          conv_log_type log[:type]
        else
          '-'
        end
      }.join
    end

    def conv_coord coord
      deg = coord.floor
      decim = (coord - deg) * 60.0
      format '%d %06.3f', deg, decim
    end

    # Convert latitude from decimal degrees to ddd mm.mmm
    def conv_latitude coord
      if coord < 0
        'S' + conv_coord(-coord)
      else
        'N' + conv_coord(coord)
      end
    end

    # Convert longitude from decimal degrees to ddd mm.mmm
    def conv_longitude coord
      if coord < 0
        'W' + conv_coord(-coord)
      else
        'E' + conv_coord(coord)
      end
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  # s = ARGV.join ' '
  # puts s
  puts IcachingNuvi::Generate.new.conv_latitude ARGV[0].to_f
  puts IcachingNuvi::Generate.new.conv_longitude ARGV[1].to_f
  # puts IcachingNuvi::Generate.new.strip_html s
  # puts IcachingNuvi::Generate.new.smart_name(s, 8)
  # puts IcachingNuvi::Generate.new.truncate(s, 8)
end
