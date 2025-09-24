require 'logger'

module Cantaloupe
  class Delegates
    NASA_KAGUYA_S3 = {
      'kaguya-band1' => 'https://nasa-lunar-data.s3.us-west-2.amazonaws.com/kaguya/mi/global_mosaic_60m/Kaguya_MI_Band1_60m.tif',
      'kaguya-band2' => 'https://nasa-lunar-data.s3.us-west-2.amazonaws.com/kaguya/mi/global_mosaic_60m/Kaguya_MI_Band2_60m.tif'
    }.freeze

    def initialize(context = {})
      @context = context
      @logger = Logger.new($stdout)
    end

    # Map the short IIIF identifier to the absolute URL in the NASA S3 bucket.
    def source_resource_identifier
      identifier = @context['identifier']
      resolved = NASA_KAGUYA_S3[identifier]

      unless resolved
        @logger.warn("No mapping found for identifier '#{identifier}'")
      end

      resolved
    end
  end
end

