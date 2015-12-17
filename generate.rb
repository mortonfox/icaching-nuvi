require_relative 'config'
require_relative 'attributes'
require 'oga'

module IcachingNuvi
  class Generate
    # Maximum length of description, hints, and logs.
    TEXT_LIMIT = 16_500

    def initialize
      @attributes = Attributes.new
    end

    def escape_html s
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

    # Returns the date the cache was last found, if any.
    def last_found cache
      cache[:logs].each { |log|
        return log[:date] if conv_log_type(log[:type]) == 'F'
      }
      nil
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

    # Format cache attributes.
    def fmt_attrib cache
      cache[:attributes].map { |attr|
        attr_str = @attributes[attr[:attr]] || 'Unknown attr'
        ison_str = attr[:ison] ? 'Y' : 'N'
        "#{attr_str}=#{ison_str}"
      }.join(', ')
    end

    # Format cache logs.
    def fmt_logs cache
      cache[:logs].map { |log|
        "<font color=#0000FF>#{log[:type]} by #{log[:finder]} #{log[:date].strftime('%Y-%m-%d')}</font> - #{escape_html(strip_html(log[:text]))}<br><br>"
      }.join
    end

    # Generate GPX for an additional waypoint.
    def fmt_waypoint cache, wpt
      wptname = "#{wpt[:code]} - #{wpt[:symbol]}"
      ccomment = strip_html wpt[:comment]

      parentinfo = "#{cache[:code]} - #{smart_name(cache[:name], 8)}"

      childdesc = "This is a child waypoint for Cache <font color=#0000FF>#{parentinfo}</font><br><br>Type: #{wpt[:symbol]}<br>Comment: #{ccomment}"

      <<-STR
<wpt lat='#{wpt[:latitude]}' lon='#{wpt[:longitude]}'><ele>0.00</ele><time>#{wpt[:date].utc.strftime('%Y-%m-%dT%H:%M:%SZ')}</time>
<name>#{wptname}</name><cmt></cmt><desc>#{escape_html childdesc}</desc><link href="futurefeature.jpg"/>
<sym>Information</sym>
<extensions><gpxx:WaypointExtension>
<gpxx:DisplayMode>SymbolAndName</gpxx:DisplayMode>
<gpxx:Address><gpxx:PostalCode>Child of #{parentinfo}</gpxx:PostalCode></gpxx:Address>
</gpxx:WaypointExtension></extensions></wpt>
      STR
    end

    # Generate GPX for a geocache.
    def fmt_geocache cache
      wpt_name = "#{smart_name cache[:name]}/#{cache[:type][0,3]}/#{cache[:code]}"

      status = ''
      status_plain = ''

      unless cache[:available]
	status = '<font color=#FF0000>*** Temp Unavailable ***</font><br><br>'
	status_plain = '*** Temp Unavailable ***'
      end

      if cache[:archived]
	status = '<font color=#FF0000>*** Archived ***</font><br><br>'
	status_plain = '*** Archived ***'
      end

      name = escape_html cache[:name]
      owner_name = escape_html cache[:owner]

      info_line = "#{cache[:type][0,3]}/#{cache[:size][0,3]}/#{last4 cache}, (D:#{cache[:difficulty]}/T:#{cache[:terrain]})"

      last_found_date = last_found cache
      dates = "Pl:#{cache[:date_created].strftime('%Y-%m-%d')}, LF:#{last_found_date ? last_found_date.strftime('%Y-%m-%d') : 'N/A'}"

      coords = "#{conv_latitude cache[:latitude]} #{conv_longitude cache[:longitude]}"

      cache_info = <<-ENDS
<font color=#FF0000>#{name} by #{owner_name}</font><br>
<font color=#008000>#{info_line}</font><br>
<font color=#0000FF>#{dates}</font><br>
<font color=#FFA500>#{coords}</font><br><br>
      ENDS

      attr_str = fmt_attrib cache
      cache_info += "<font color=#00BFFF>**Attributes** #{attr_str}</font><br><br>" unless attr_str.empty?

      # This is some cache information in plain text that the Nuvi will
      # display before you touch the "More" button.
      plaincacheinfo = <<-ENDS
#{status_plain}
#{coords}
#{info_line}
#{name} by #{owner_name}
#{dates}
      ENDS

      all_desc = "#{strip_html cache[:short_desc]}<br>#{strip_html cache[:long_desc]}"

      hints = "<font color=#008000>Hint: #{strip_html cache[:hint]}</font><br>"

      logstr = fmt_logs cache

      comb_desc = status + cache_info + 'Description: ' + all_desc + '<br>'

      comb_desc = escape_html comb_desc
      hints = escape_html hints
      logstr = escape_html logstr

      final_str = if comb_desc.size + hints.size > TEXT_LIMIT
                    truncate(comb_desc, TEXT_LIMIT - hints.size - 10) + escape_html('<br>**DESCRIPTION CUT**<br>') + hints
                  else
                    truncate(comb_desc + hints + logstr, TEXT_LIMIT)
                  end

      <<-ENDS
<wpt lat='#{cache[:latitude]}' lon='#{cache[:longitude]}'><ele>0.00</ele><time>#{cache[:date_created].utc.strftime('%Y-%m-%dT%H:%M:%SZ')}</time>
<name>#{wpt_name}</name><cmt></cmt><desc>#{final_str}</desc>
<link href="futurefeature.jpg"/><sym>Information</sym>
<extensions><gpxx:WaypointExtension>
<gpxx:DisplayMode>SymbolAndName</gpxx:DisplayMode>
<gpxx:Address><gpxx:PostalCode>#{escape_html plaincacheinfo}</gpxx:PostalCode></gpxx:Address>
</gpxx:WaypointExtension></extensions></wpt>
      ENDS
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
