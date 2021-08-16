require_relative './allocator'
require_relative './search_space'
require_relative './logger'

require 'erv'
require 'concurrent'

module BDMaaS
  module Optimizer
    class ChaosSearch

      include BDMaaS::Logging

      def initialize(simulation, sim_conf, opt_conf, component_placement)
        @sim                 = simulation
        @sim_conf            = sim_conf
        @opt_conf            = opt_conf
        @component_placement = component_placement
        @alpha_dist          = ERV::RandomVariable.new(distribution: :uniform, 
                                      args: { min_value: 0.01, max_value: 100.0 })
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
        # try different search strategies

        # allocate vm once, then modiify the allocation
        alpha         = @alpha_dist.sample
        vm_allocation = allocator.allocate(@component_placement, aggressiveness: alpha)

        results = Array.new(num_rounds) do
            # randomly sample search space for alpha parameter
            # SearchSpace.new(@opt_conf.dig(:local_search, :search_space)).sample
            begin
              fitness       = @sim.evaluate_allocation(vm_allocation)
            rescue => e
              $stderr.puts e.inspect
              $stderr.puts e.backtrace
              $stderr.flush
              exit
            end

            #puts "***Evaluation***"
            #puts fitness[:evaluation]
            #puts "***Evaluation***"
            total_failed = 0
            # I was trying to collect the stats here
            # analyze each workflow and check for failed requests
            # increase the number of VM
            # or migrate VM instances to mitigate injected chaos faults
            fitness[:stats].each do |w,v|
              v.each do |k, stat|
                failed = stat.failed
                total_failed += failed
                puts "Workflow: #{w}, CustomerID: #{k}, failed: #{failed}"
                # if consistent nunber of failed requests
                if failed > 1
                  # mitigate injected faults effects
                  vm_conf, index = vm_allocation.shuffle.each_with_index.min_by {|x, e| x[:vm_num]}
                  #puts "Index *** #{index} *** #{vm_conf}"
                  # increase the resource to prevent fault chaos
                  # here --- need to operate by selecting another data center
                  vm_conf[:vm_num] = vm_conf[:vm_num] + 2
                  vm_allocation[index] = vm_conf
                  # random allocation strategy to reduce faults
                  # --- random strategy

                  #size = @component_placement.length
                  #dc_service_vm = rand(size)
                  #@component_placement[dc_service_vm] += 2.0
                  # find closest data-center 
                  # and allocate more VMs
                  # here we need to keep working on this
                end
              end
            end

            puts "Total failed requests: #{total_failed}"

            { vm_allocation:       vm_allocation,
              fitness:             fitness[:evaluation],
              stats:               fitness[:stats],
              component_placement: @component_placement }
        end

        #promises.map(&:wait)
        # return best example
        results.max_by {|x| x[:fitness]}
      end
    end

  end
end
