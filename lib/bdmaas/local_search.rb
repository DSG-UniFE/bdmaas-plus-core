require_relative './allocator'
require_relative './search_space'
require_relative './logger'

require 'erv'

module BDMaaS
  module Optimizer
    class LocalSearch

      include BDMaaS::Logging

      def initialize(simulation, sim_conf, opt_conf, component_placement)
        @sim                 = simulation
        @sim_conf            = sim_conf
        @opt_conf            = opt_conf
        @component_placement = component_placement
        @alpha_dist          = ERV::RandomVariable.new(distribution: :uniform, args: { min_value: 0.01, max_value: 100.0 })
      end

      def run

        begin
          allocator = Allocator.new(@sim_conf, @opt_conf)
        rescue => e
          $stderr.puts e.inspect
          $stderr.puts e.backtrace
          $stderr.flush
          exit
        end

        num_rounds = @opt_conf.dig(:local_search, :rounds).to_i

        # this implements a random search
        results = Array.new(num_rounds) do
          # randomly sample search space for alpha parameter
          alpha         = @alpha_dist.sample
          # SearchSpace.new(@opt_conf.dig(:local_search, :search_space)).sample
          begin
            vm_allocation = allocator.allocate(@component_placement, aggressiveness: alpha)
            fitness       = @sim.evaluate_allocation(vm_allocation)
          rescue => e
            $stderr.puts e.inspect
            $stderr.puts e.backtrace
            $stderr.flush
            exit
          end

          { vm_allocation:       vm_allocation,
            fitness:             fitness,
            component_placement: @component_placement }
        end

        # return best example
        results.max_by {|x| x[:fitness] }
      end
    end

  end
end
