require_relative './allocator'
require_relative './search_space'
require_relative './logger'

require 'erv'
require 'concurrent'

module BDMaaS
  module Optimizer
    class ChaosSearch

      include BDMaaS::Logging

      def initialize(simulation, sim_conf, opt_conf, component_placement, policy_type)
        @sim                 = simulation
        @sim_conf            = sim_conf
        @opt_conf            = opt_conf
        @component_placement = component_placement
        @alpha_dist          = ERV::RandomVariable.new(distribution: :uniform, 
                                      args: { min_value: 0.01, max_value: 100.0})
        @policy_type         = policy_type
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
            
            # there is some issue (I cannot make the case statement work properly)
            @policy_type = :migrate

            # then try to mitigate faults effects
            total_failed = 0
            case @policy_type
              
            # migrate VMs to another datacenter
            # activate VMs into another datacenter

            when :migrate
              puts "Selected correct policy"
              fitness[:failure_stats].each do |dc, vm_conf|
                vm_conf.each do |st, fn|
                  # st is service type
                  # fn is failure number
                  total_failed += fn 
                  # if we are experiencing failures
                  if fn > 1

                    #els = vm_allocation.each_with_index.select {|ae, i| ae[:dc_id] == dc && ae[:component_type] == st}
                    # verify what happens in the other DCs

                    alternative = vm_allocation.each_with_index.select {|ae, i| ae[:dc_id] != dc && ae[:component_type] == st}

                    # here some debug
                    puts "Alternative #{alternative}"
                    # we should verify the situation here
                    # let's try to pick up the element
                    al = alternative.sample
                    al_failures = fitness[:failure_stats][al[0][:dc_id]][:component_type]
                    
                    puts "al_failures #{al_failures}"

                    # increase the number of VM into another DC
                    if al_failures.nil? || al_failures < fn
                      al[0][:vm_num] += 2
                      # update the allocation here
                      vm_allocation[al[1]] = al[0]
                    end
                  end
                end
              end
              else
                puts "Default policy here (no migration)" 
                fitness[:failure_stats].each do |dc, vm_conf|
                  vm_conf.each do |st, fn|
                    total_failed += fn 
                    if fn > 1
                      els = vm_allocation.each_with_index.select {|ae, i| ae[:dc_id] == dc && ae[:component_type] == st}
                      # puts els
                      # pick a random size
                      el = els.sample
                      #puts "VM num: #{el[0][:vm_num]}"
                      # increase the number of VMs
                      el[0][:vm_num] += 2
                      # update the allocation here
                      vm_allocation[el[1]] = el[0]
                    end
                  end
                end


            end

            puts "Total failed requests: #{total_failed}"

            { vm_allocation:       vm_allocation,
              fitness:             fitness[:evaluation],
              stats:               fitness[:stats],
              total_failures:      total_failed,
              component_placement: @component_placement }
        end

        #promises.map(&:wait)
        # return best example
        results.min_by {|x| x[:total_failures]}
      end
    end

  end
end
