require_relative 'config'
require 'csv'

module IcachingNuvi
  class Attributes
    def initialize
      @attrs = {}
      CSV.open(Config.attributes, headers: :first_row) { |csv|
        csv.each { |row|
          @attrs[row['ID'].to_i] = {
            no: row['NoText'],
            yes: row['YesText']
          }
        }
      }
    end

    attr_reader :attrs

    def [] id
      @attrs[id.to_i]
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  a = IcachingNuvi::Attributes.new
  p a.attrs
  p a[13]
end
