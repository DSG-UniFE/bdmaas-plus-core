require_relative './support/dsl_helper'

module BDMaaS

  module Configurable
    dsl_accessor :local_search,
                 :solver
  end

  class Configuration
    include Configurable

    attr_accessor :filename

    def initialize(filename)
      @filename = filename
    end

    def validate
      # do nothing
    end

    def self.load_from_file(filename)
      # allow filename, string, and IO objects as input
      raise ArgumentError, "File #{filename} does not exist!" unless File.exists?(filename)

      # create configuration object
      conf = Configuration.new(filename)

      # take the file content and pass it to instance_eval
      conf.instance_eval(File.new(filename, 'r').read)

      # validate and finalize configuration
      conf.validate

      # return new object
      conf
    end

  end
end
