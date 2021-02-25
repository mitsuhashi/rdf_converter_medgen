# RDF converter for MedGen

This script converts a MedGen CSV file into RDF turtle.

## Input files

MedGen source files are available at [here](https://ftp.ncbi.nlm.nih.gov/pub/medgen/csv/). 
medgen_pubmed_link.txt and MedGen_HPO_OMIM_Mapping.txt are available at [here](https://ftp.ncbi.nlm.nih.gov/pub/medgen/).
omim2gene_medgen file is available at [here](ftp://ftp.ncbi.nih.gov/gene/DATA/mim2gene_medgen).
Semantic Types Ontology is available at [here](https://bioportal.bioontology.org/ontologies/STY).

## Usage

    Usage: ruby convert_rdf_medgen.rb [options] <file>
       -p, --prefixes print prefixes
       -n, --names NAMES.csv to RDF
       -d, --mgdef convert MGDEF.csv to RDF
       -s, --mgsty   convert MGSTY.csv to RDF
       -c, --mgconso convert MGCONSO.csv to RDF
       -r, --mgrel   convert MGREL_1.csv and MGREL_2.csv to RDF
       -a, --mgsat   convert MGSAT_1.csv and MGSAT_2.csv to RDF
       -u, --pubmed  convert medgen_pubmed_lnk.txt to RDF
       -m, --omim    convert MedGen_HPO_OMIM_Mapping.txt to RDF
       -l, --sty     UMLS Semantic Type Ontology"
       -g, --gene    convert omim2gene_medgen to RDF"
       -h, --help print help\n"


    All options otherwise -p, -m, -l can be set exclusively. Only -p option can be used with other option. The -m and -l options must be specified in pairs.

    Example:
       ruby rdf_coverter_medgen -p -d MGDEF.csv > mgdef.ttl
       ruby rdf_converter_medgen -m MedGen_HPO_OMIM_Mapping.txt -l umls_semantictypes.ttl

