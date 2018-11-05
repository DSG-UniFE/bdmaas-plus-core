require 'bdmaas'


LOCAL_SEARCH_CHARACTERIZATION = <<END
local_search \
  strategy: :exponential,
  rounds: 8,
  search_space: { from: 0.01, to: 100.0 }
# search_space: BDMaaS::SearchSpace.new(from: 0.01, to: 100.0)
END


SOLVER_CHARACTERIZATION = <<END
solver \
  population_size: 48,
  genotype_space_type: :integer,
  mutation_probability: 0.05, # average mutation will be of 19 units
  recombination_probability: 0.25,
  exit_condition: lambda { |gen, best| gen >= 20 }, # exit after 20 generations
  genotype_space_conf: {
    dimensions: 6,
    recombination_type: :intermediate,
    # we estimate that about 300 VMs will be required
    random_func: lambda { Array.new(6) { 1 + rand(99) } }
  }
END


# this is the whole reference configuration
# (useful for spec'ing configuration.rb)
REFERENCE_CONFIGURATION =
  LOCAL_SEARCH_CHARACTERIZATION +
  SOLVER_CHARACTERIZATION


evaluator = Object.new
evaluator.extend BDMaaS::Configurable
evaluator.instance_eval(REFERENCE_CONFIGURATION)

# these are preprocessed portions of the reference configuration
# (useful for spec'ing everything else)
LOCAL_SEARCH            = evaluator.local_search
SOLVER                  = evaluator.solver


def with_reference_config(opts={})
  begin
    # create temporary file with reference configuration
    tf = Tempfile.open('REFERENCE_CONFIGURATION')
    tf.write(REFERENCE_CONFIGURATION)
    tf.close

    # create a configuration object from the reference configuration file
    conf = BDMaaS::Configuration.load_from_file(tf.path)

    # apply any change from the opts parameter and validate the modified configuration
    opts.each do |k,v|
      conf.send(k, v)
    end
    conf.validate

    # pass the configuration object to the block
    yield conf
  ensure
    # delete temporary file
    tf.delete
  end
end
