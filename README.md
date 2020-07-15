# Data Variety, Come As You Are in Multi-model Data Warehouses

Multi-model DBMSs (MMDBMSs) have been recently introduced to store and seamlessly query heterogeneous data (structured, semi-structured, graph-based, etc.) in their native form, aimed at effectively preserving their variety. Unfortunately, when it comes to analyzing these data, traditional data warehouses (DWs) and OLAP systems fall short because they rely on relational DBMSs for storage and querying, thus constraining data variety into the rigidity of a structured, fixed schema. We investigate the performances of an MMDBMS when used to store multidimensional data for OLAP analyses. A multi-model DW would store each of its elements according to its native model; among the benefits we envision for this solution, that of bridging the architectural gap between data lakes and DWs, that of reducing the cost for ETL, and that of ensuring better flexibility, extensibility, and evolvability thanks to the combined use of structured and schemaless data.
    
To support our investigation we define a multidimensional schema for the UniBench benchmark dataset and an ad-hoc OLAP workload for it. Then we propose and compare three logical solutions implemented on the PostgreSQL multi-model DBMS: one that extends a star schema with JSON, XML, graph-based, and key-value data; one based on a classical (fully relational) star schema; and one where all data are kept in their native form (no relational data are introduced).

This repository provides all the details to reproduce our experimental evaluation by loading the dataset and running our workloads.

## Prerequisite

The implementation is based on [Agensgraph](https://bitnine.net/agensgraph/), i.e., an extension of PostgreSQL that adds support to graph storage. Please go to AgensGraph's website for install instructions. We recommend installing on Ubuntu or relying on [Docker](https://hub.docker.com/r/maxims/agens-graph-docker/dockerfile).

The database is based on [Unibench](https://github.com/HY-UDBMS/UniBench); more specifically, it is based on the version with scaling factor 30, which can be found [here](https://github.com/HY-UDBMS/Unibench/releases).

## Loading the data

Download the dump file of the database from [here](http://big.csr.unibo.it/downloads/m3d-dump) and use the ```pg_restore``` command to load it on AgensGraph.

## Workload queries

All queries are available in the ```workload``` folder.

## Authors

Sandro Bimonte [1], Enrico Gallinucci [2], Patrick Marcel [3], Stefano Rizzi [2]

[1]: INRAE - TSCF, University of Clermont Auvergne, Aubiere, France

[2]: DISI, University of Bologna, Italy

[3]: LIFAT Laboratory, University of Tours, France
