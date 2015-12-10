require_relative 'config'
require 'sqlite3'

module IcachingNuvi
  class Datastore
    def initialize folder
      @caches = {}

      store_fname = File.join ENV['HOME'], Config.datastore
      SQLite3::Database.new(store_fname, results_as_hash: true) { |db|

        stmt = <<-ENDS
select * from ZATTRIBUTE
        ENDS

        attrtable = Hash.new { |h, k| h[k] = [] }
        db.query(stmt) { |result_set|
          result_set.each { |row|
            attrtable[row['ZRELTOCACHE']] << { attr: row['ZATTRIBUTETYPEID'], ison: row['ZISON'] }
          }
        }

        stmt = <<-ENDS
select * from ZGEOCACHE
where Z_PK in (
  select Z_3RELTOCACHE from Z_2RELTOCACHE
  where Z_2RELTOFOLDER = (
    select Z_PK from ZFOLDER 
    where ZDISPLAYNAME = ?
  )
)
        ENDS

        db.query(stmt, [folder]) { |result_set|
          result_set.each { |row|
            @caches[row['Z_PK']] = {
              archived: row['ZARCHIVED'] != 0,
              available: row['ZAVAILABLE'] != 0,
              date_created: Time.at(row['ZDATECREATED'] + 978_325_200), # It was stored as secs since 2001-01-01.
              difficulty: row['ZDIFFICULTY'],
              terrain: row['ZTERRAIN'],
              latitude: row['ZLATITUDE'],
              longitude: row['ZLONGITUDE'],
              code: row['ZCODE'],
              size: row['ZCONTAINER'],
              name: row['ZNAME'],
              desc: row['ZDESC'],
              hint: row['ZENCODEDHINTS'],
              short_desc: row['ZSHORTDESCRIPTION'],
              long_desc: row['ZLONGDESCRIPTION'],
              my_note: row['ZMYNOTE'],
              state: row['ZSTATE'],
              country: row['ZCOUNTRY'],
              type: row['ZTYPE'],
              attributes: attrtable[row['Z_PK']].sort_by { |v| v[:attr] }
            }
            p row
            p @caches[row['Z_PK']]
          }
        }
      }
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  IcachingNuvi::Datastore.new 'lancaster'
end
