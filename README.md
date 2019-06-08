# RDF converter for MedGen

This script convert MedGen csv files into RDF turtle.

## Source files

MedGen source files are available at [here](ftp://ftp.ncbi.nlm.nih.gov/pub/medgen/csv/). medgen_pubmed_link.txt is available at [here](ftp://ftp.ncbi.nlm.nih.gov/pub/medgen/).

## Usage

    Usage: ruby convert_rdf_medgen.rb [options]
       -p, --prefixes print prefixes
       -n, --names NAMES.csv to RDF
       -d, --mgdef convert MGDEF.csv to RDF
       -s, --mgsty convert MGSTY.csv to RDF
       -c, --mgconso convert MGCONSO.csv to RDF
       -r, --mgrel convert MGREL_1.csv and MGREL_2.csv to RDF
       -a, --mgsat convert MGSAT_1.csv and MGSAT_2.csv to RDF
       -u, --pubmed convert medgen_pubmed_lnk.txt to RDF
       -h, --help print help

