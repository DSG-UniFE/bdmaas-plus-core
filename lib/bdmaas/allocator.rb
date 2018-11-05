require_relative './logger'

module BDMaaS
  module Optimizer

    class Allocator
      include BDMaaS::Logging

      def initialize(sim_conf, opt_conf)
        @data_center_conf = sim_conf.data_centers
        @component_conf   = sim_conf.service_component_types

        # find out how many components do not have constraints
        @unconstrained_components = @component_conf.count do |(k,v)|
          !v.has_key? :deployment_constraints
        end

        # the default allocation strategy is exponential
        allocation_strategy = opt_conf[:local_search].fetch(:strategy, :exponential)

        case allocation_strategy
        when :random
          @strategy = RandomAllocationStrategy
        when :exponential
          @strategy = ExponentialAllocationStrategy
        else
          raise ArgumentError, 'Invalid strategy #{allocation_strategy}!'
        end
      end

      # TODO: consider implementing VM allocation feasibility check
      def allocate(component_placement, opts = {})

        # check input array size
        unless component_placement.size == @data_center_conf.size * @unconstrained_components
          raise ArgumentError, 'Invalid size of component_placement array!'
        end

        # prepare amended version of component placement array, including hard constaints
        component_placement_amended = []
        component_placement
          .each_slice(@unconstrained_components)
          .zip(@data_center_conf.keys) do |components_wo_constraints,dc_id|
          i = 0
          component_placement_amended += @component_conf.map do |c_id,cc|
            if cc.has_key? :deployment_constraints
              if cc.dig(:deployment_constraints, :data_center) == dc_id
                logger.debug "Adding 1 component of type #{c_id} in data center #{dc_id}"
                # TODO: might have more than 1 component here
                1
              else
                0
              end
            else
              res = components_wo_constraints[i]
              i += 1
              res
            end
          end
        end

        # check input array size
        unless component_placement_amended.size == @data_center_conf.size * @component_conf.size
          raise 'Invalid size of component_placement_amended array!'
        end

        # allocation information
        allocation = []

        component_placement_amended
          .each_slice(@component_conf.size)
          .zip(@data_center_conf.keys) do |components_to_allocate_in_dc,dc_id|
          # logger.info "Trying to allocate components #{components_to_allocate_in_dc.inspect} in data center #{dc_id}"

          # perform the actual allocation
          dc_alloc = @strategy.allocate_one(dc_id, @component_conf, components_to_allocate_in_dc, opts)

          # update allocation information
          allocation.concat(dc_alloc)
        end

        # everything went ok, return the allocation information
        allocation
      end

    end


    class RandomAllocationStrategy
      def self.allocate_one(dc_id, component_types, components_to_allocate, opts = {})
        raise 'Not implemented yet!'
      end
    end

    # IMPORTANT: we assume that VM types are ordered from the smallest VM size to the largest one!!!
    class ExponentialAllocationStrategy
      include BDMaaS::Logging

      DEFAULT_ALPHA = 0.5

      def self.allocate_one(dc_id, component_types, components_to_allocate, opts = {})
        # get alpha exponent
        alpha = opts.fetch(:alpha, DEFAULT_ALPHA)

        # result
        allocation = []

        raise "Inconsistent input" unless component_types.size == components_to_allocate.size

        components_to_allocate.each.zip(component_types) do |n,(ct_name,ct)|
          # skip if we don't have any component of this type
          if n == 0
            logger.debug "No VMs allocated for data center #{dc_id} and service component #{ct_name}."
            next
          end

          # get allowed VM types
          # NOTE: we also perform a conversion to an array in case we have a single element
          allowed_vm_types = [*ct[:allowed_vm_types]]

          if allowed_vm_types.size == 1
            # if we have only one type of allowed VM size, the allocation is easy
            allocation << {
              dc_id:          dc_id,
              vm_num:         n,
              vm_size:        allowed_vm_types.first,
              component_type: ct_name,
            }
          else
            # get distribution shape
            shape = (0...allowed_vm_types.size).each_with_object([]) {|i,a| a << alpha ** i }
            s = shape.inject(0) {|s,x| s+= x }
            shape.reverse!.map! {|x| (x * n / s).round }

            # fix distribution shape if needed
            delta = n - shape.inject(0) {|s,x| s+= x }
            if delta > 0
              # we need to allocate delta VMs
              shape[-1] += delta
            elsif delta < 0
              # we need to remove |delta| VMs, starting from the smallest ones
              j = 0
              while delta != 0
                if shape[j] > delta.abs
                  shape[j] -= delta.abs
                  delta = 0
                else
                  delta += shape[j]
                  shape[j] = 0
                  j += 1
                end
              end
            end

            # consistence check
            allocated_vms = shape.inject(0) {|s,vm_num| s += vm_num }
            raise 'Inconsistent number of VMs allocated!' unless allocated_vms == n

            shape.each_with_index do |num,i|
              if num != 0
                allocation << {
                  dc_id:          dc_id,
                  vm_num:         num,
                  vm_size:        allowed_vm_types[i],
                  component_type: ct_name,
                }
              end
            end
          end
        end
        # logger.warn "Allocation for data center #{dc_id}: #{allocation.inspect}"

        allocation
      end
    end

    # For more sophisticated VM allocation strategies, we might want to consider
    # algorithms designed for constraint programming. More specifically, the well
    # known generalized assignment problem presents some interesting analogies
    # with our VM allocation problem:
    #
    # http://en.wikipedia.org/wiki/Generalized_assignment_problem
    # http://www.or.deis.unibo.it/kp/Chapter7.pdf
  end

end
