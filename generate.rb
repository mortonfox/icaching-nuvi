require_relative 'config'

module IcachingNuvi
  class Generate
    def initialize
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
end
