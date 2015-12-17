require_relative 'config'
require 'sqlite3'

module IcachingNuvi
  class Datastore
    # Sqlite3 seems to store timestamps as secs since 2001-01-01. So add the
    # following number of seconds to make it Unix time.
    SQLITE_EPOCH = 978_325_200
    def sqlite_to_time tm
      Time.at(tm + SQLITE_EPOCH)
    end

    def hash_auto_array
      Hash.new { |h, k| h[k] = [] }
    end

    def initialize
      @caches = {}
    end

    def read folder
      store_fname = File.join ENV['HOME'], Config.datastore
      SQLite3::Database.new(store_fname, results_as_hash: true) { |db|

        stmt = <<-ENDS
select * from ZATTRIBUTE
        ENDS

        attrtable = hash_auto_array
        db.query(stmt) { |result_set|
          result_set.each { |row|
            attrtable[row['ZRELTOCACHE']] << {
              attr: row['ZATTRIBUTETYPEID'],
              ison: row['ZISON'] != 0
            }
          }
        }

        stmt = <<-ENDS
select * from ZLOG
        ENDS

        logtable = hash_auto_array
        db.query(stmt) { |result_set|
          result_set.each { |row|
            logtable[row['ZRELTOCACHE']] << {
              date: sqlite_to_time(row['ZDATE']),
              finder: row['ZFINDER'],
              text: row['ZTEXT'],
              type: row['ZTYPE']
            }
          }
        }

        stmt = <<-ENDS
select * from ZWAYPOINT
        ENDS

        wpt_table = hash_auto_array
        db.query(stmt) { |result_set|
          result_set.each { |row|
            wpt_table[row['ZRELTOCACHE']] << {
              date: sqlite_to_time(row['ZTIME']),
              comment: row['ZCMT'],
              latitude: row['ZLAT'],
              longitude: row['ZLON'],
              code: row['ZCODE'],
              desc: row['ZDESC'],
              symbol: row['ZSYM']
            }
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
            cache_id = row['Z_PK']
            @caches[cache_id] = {
              archived: row['ZARCHIVED'] != 0,
              available: row['ZAVAILABLE'] != 0,
              date_created: sqlite_to_time(row['ZDATECREATED']),
              difficulty: row['ZDIFFICULTY'],
              terrain: row['ZTERRAIN'],
              latitude: row['ZLATITUDE'],
              longitude: row['ZLONGITUDE'],
              code: row['ZCODE'],
              size: row['ZCONTAINER'],
              name: row['ZNAME'],
              owner: row['ZOWNER'],
              desc: row['ZDESC'],
              hint: row['ZENCODEDHINTS'],
              short_desc: row['ZSHORTDESCRIPTION'],
              long_desc: row['ZLONGDESCRIPTION'],
              my_note: row['ZMYNOTE'],
              state: row['ZSTATE'],
              country: row['ZCOUNTRY'],
              type: row['ZTYPE'],
              attributes: attrtable[cache_id].sort_by { |v| v[:attr] },
              logs: logtable[cache_id].sort_by { |v| v[:date] }.reverse,
              waypoints: wpt_table[cache_id]
            }
          }
        }
      }
    end

    attr_reader :caches
  end
end

if __FILE__ == $PROGRAM_NAME
  require 'pp'
  ds = IcachingNuvi::Datastore.new
  ds.read 'lancaster'
  pp ds.caches
end
