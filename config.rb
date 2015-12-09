module IcachingNuvi
  class Config
    @resource_path = '/Applications/iCaching.app/Contents/Resources'
    @datastore = 'Library/Containers/com.teamGiants.iCaching/Data/Library/Application Support/iCaching/storedata'

    class << self
      attr_accessor :resource_path, :datastore
    end
  end
end
