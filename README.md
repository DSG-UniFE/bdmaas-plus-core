# BDMaaS+ Engine

BDMaaS+ (Business Driven Management as a Service Plus) is a management
framework to optimize the component placement of large scale IT services in
hybrid Cloud environments. This repository contains the main (engine) component
of the framework.


## Recommended Installation

As BDMaaS+ was developed in Ruby and leverages several other components, you
will need both a working Ruby interpreter and the bundler dependency management
tool. We recommend to use JRuby to best take advantage of the parallelism
offered by your CPU.

Once you have Ruby and bundler setup, you can install BDMaaS+ by cloning the
git repository:

    git clone https://github.com/DSG-UniFE/bdmaas-plus-core.git

and then install the dependencies using bundler:

    cd bdmaas-plus-core
    bundle install --path=vendor/bundle

(the --path parameter is not really needed but we still highly recommend it in
order to keep your BDMaaS+ installation isolated and self contained and to
avoid polluting your gem repository).


## Usage

To run BDMaaS+ simply digit:

    bundle exec ./bin/bdmaas-plus configuration_file

The examples directory contains an example configuration file.


## References

BDMaaS+ was used in the following research papers:

1.  L. Foschini, M. Tortonesi, "Adaptive and Business-driven Service Placement
    in Federated Cloud Computing Environments", in Proceedings of the 8th
    IFIP/IEEE International Workshop on Business-driven IT Management (BDIM 2013),
    27 May 2013, Ghent, Belgium.

2.  G. Grabarnik, L. Shwartz, M. Tortonesi, "Business-Driven Optimization of
    Component Placement for Complex Services in Federated Clouds", in
    Proceedings of the 14th IEEE/IFIP Network Operations and Management Symposium
    (NOMS 2014) - Miniconference track, 5-9 May 2014, Krakow, Poland.

3.  M. Tortonesi, L. Foschini, "Business-driven Service Placement for Highly
    Dynamic and Distributed Cloud Systems", IEEE Transactions on Cloud
    Computing, (in print).

4.  W. Cerroni et al., "Service Placement for Hybrid Clouds Environments based
    on Realistic Network Measurements", in Proceedings of 14th International
    Conference on Network and Service Management (CNSM 2018) - Miniconference
    track, 5-9 November 2018, Rome, Italy.

Please, consider citing some of these papers if you find BDMaaS+ useful for
your research.
