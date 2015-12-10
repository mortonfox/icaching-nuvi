module IcachingNuvi
  class Config
    @attributes = '/Applications/iCaching.app/Contents/Resources/Attributes.csv'
    @datastore = 'Library/Containers/com.teamGiants.iCaching/Data/Library/Application Support/iCaching/storedata'

    class << self
      attr_accessor :attributes, :datastore
    end
  end
end
