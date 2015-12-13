require_relative 'config'

module IcachingNuvi
  class Generate
    # Maximum length of description, hints, and logs.
    TEXT_LIMIT = 16_500

    def initialize
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

    def smart_name str, maxlen
      words = str.scan(/\w+/)
      squished = words.map(&:capitalize).join('')
      match = squished.match(/^(\D*)(\d+)(.*)$/)
      if match
        digit_length = [match[2].size, 3].min
        prefix = match[1][0, maxlen - digit_length]
        squished = prefix + match[2][[match[2].size - (maxlen - prefix.size), 0].max..-1] + match[3]
      end
      squished[0, maxlen]
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  s = ARGV.join ' '
  puts s
  puts IcachingNuvi::Generate.new.smart_name(s, 8)
  puts IcachingNuvi::Generate.new.truncate(s, 8)
end
