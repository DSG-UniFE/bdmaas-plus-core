module BDMaaS
  class SearchSpace
    attr_reader :domain_constraints

    def initialize(constraints)
      @constraint_config = constraints
      @components        = constraints.size
      @data_centers      = constraints.first[1].size

      # sanitize constraint configuration:
      @constraint_config.each_with_index do |(k,v),i|
        # 1) make sure the constraint information for each software component
        # (i.e., the value arrays) is sorted by data center ID
        v.sort_by! {|x| x[:data_center] }

        # 2) make sure we have the same number of constraints for each software
        # component (should correspond to number of data centers)
        if v.size != @data_centers
          raise "Constraints for software component #{k} have a wrong number of entries! " +
                "(Expected #{@data_centers}, found #{v.size}.)"
        end

        # 3) make sure we don't have duplicate entries
        v.each_cons(2) do |x|
          raise "Multiple constraints for component #{k} and data center #{x[:data_center]}!" if x[0] == x[1]
        end

        # 4) for each data center specific constraint, make sure we have either
        # a 'number' or both a 'min' and a 'max' attribute
        v.each do |x|
          if !( x.has_key? :number and !x.has_key? :max and !x.has_key? :min) and
             !(!x.has_key? :number and  x.has_key? :max and  x.has_key? :min)
            raise "Wrong constraint for component #{k} and data center #{x[:data_center]}! " +
                  "Need to have either a 'number' or both a 'min' and a 'max' attribute!"
          end
        end
      end

      # the extension_pattern instance variable holds the rules to transform
      # (extend) a partial software component allocation into a full one
      @extension_pattern = []

      # the domain constraint instance variable holds the constraints in the
      # search space domain, to be passed to the optimizer
      @domain_constraints = {
        min: [], max: []
      }

      idx = 0
      @constraint_config.each do |k,v|
        v.each do |x|
          if x.has_key? :number
            # save extension pattern
            @extension_pattern << { idx: idx, number: x[:number] }
          else
            # save domain constraint
            @domain_constraints[:min] << x[:min]
            @domain_constraints[:max] << x[:max]
          end
          idx += 1
        end
      end
    end

    # WARNING! for performance sake, this method makes an inline modification
    # of partial_allocation
    def expand_partial_allocation(partial_allocation)
      @extension_pattern.each do |rule|
        partial_allocation.insert(rule[:idx]-1, rule[:number])
      end
      partial_allocation
    end
  end
end
