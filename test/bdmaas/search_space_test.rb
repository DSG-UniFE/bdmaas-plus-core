require 'test_helper'

require 'bdmaas/search_space'

CONFIG_EXAMPLE_1 = {
  'Web Server' => [
    { data_center: 1, min: 0, max:  100 },
    { data_center: 2, min: 0, max:  200 },
    { data_center: 3, min: 0, max:  300 },
    { data_center: 4, min: 0, max:  400 },
    { data_center: 5, min: 0, max:  500 },
  ],
  'App Server' => [
    { data_center: 1, min: 0, max:  600 },
    { data_center: 2, min: 0, max:  700 },
    { data_center: 3, min: 0, max:  800 },
    { data_center: 4, min: 0, max:  900 },
    { data_center: 5, min: 0, max: 1000 },
  ],
  'Financial Transaction Server' => [
    { data_center: 1, number: 1 },
    { data_center: 2, number: 0 },
    { data_center: 3, number: 0 },
    { data_center: 4, number: 0 },
    { data_center: 5, number: 0 },
  ],
}

DOMAIN_CONSTRAINTS_EXAMPLE_1 = {
  min: [   0,   0,   0,   0,   0,   0,   0,   0,   0,    0 ],
  max: [ 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000 ],
}

PARTIAL_ALLOCATION_EXAMPLE_1 = [ 2, 3, 4, 5, 6, 7, 8, 9, 10 ]
FULL_ALLOCATION_EXAMPLE_1    = [ 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 0, 0, 0, 0 ]


describe BDMaaS::SearchSpace do

  it 'should correctly process a basic config example' do 
    BDMaaS::SearchSpace.new(CONFIG_EXAMPLE_1)
  end

  describe 'example configuration 1' do

    it 'should correctly produce domain constraints' do
      ss = BDMaaS::SearchSpace.new(CONFIG_EXAMPLE_1)
      ss.domain_constraints.must_equal(DOMAIN_CONSTRAINTS_EXAMPLE_1)
    end

    it 'should correctly expand a partial (varying) allocation to a full one' do
      ss = BDMaaS::SearchSpace.new(CONFIG_EXAMPLE_1)
      ss.expand_partial_allocation(PARTIAL_ALLOCATION_EXAMPLE_1).must_equal(FULL_ALLOCATION_EXAMPLE_1)
    end

  end
end
