#!/usr/bin/env ruby

require 'optparse'

module MedGen

  Prefixes = {
    "rdf" => "<http://www.w3.org/1999/02/22-rdf-syntax-ns#>",
    "rdfs" => "<http://www.w3.org/2000/01/rdf-schema#>",
    "skos" => "<http://www.w3.org/2004/02/skos/core#>",
    "prov" => "<http://www.w3.org/ns/prov#>",
    "pav" => "<http://purl.org/pav/>",
    "medgen" => "<http://www.ncbi.nlm.nih.gov/medgen/>",
    "mo" => "<http://med2rdf/ontology/medgen#>",
    "ispref" => "<http://med2rdf/ontology/medgen/ispref#>",
    "sty" => "<http://purl.bioontology.org/ontology/STY/>",
    "omim" => "<http://identifiers.org/mim/>",
    "obo" => "<http://purl.obolibrary.org/obo/>",
    "mesh" => "<http://id.nlm.nih.gov/mesh/>",
    "ordo" => "<http://www.orpha.net/ORDO/>",
    "nci" => "<http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl#>",
    "dct" => "<http://purl.org/dc/terms/>",
    "pubmedid" => "<http://identifiers.org/pubmed/>",
    "pubmed" => "<http://rdf.ncbi.nlm.nih.gov/pubmed/>",
    "snomedct" => "<http://purl.bioontology.org/ontology/SNOMEDCT/>",
    "ncbigene" => "<http://identifiers.org/ncbigene/>",
    "bp_omim" => "<http://purl.bioontology.org/ontology/OMIM/>"
  }

  def prefixes
    Prefixes.each do |pfx, uri|
      print "@prefix #{pfx}: #{uri} .\n"
    end
    puts "\n"
  end

  module_function :prefixes

  class NAMES

    def self.rdf(file, prefixes = false)
      File.open(file) do |f|
        f.gets
        MedGen.prefixes if $prefixes
        while line = f.gets
          ary = parse(line)
          puts construct_turtle(*ary)
        end
      end
    end

    def self.parse(line)
      if /^(\S+),([^\".]+),(.+),(\w)[\r\n]*?$/ =~ line
        [$1, $2, $3, $4]
      elsif  /^(\S+),\"(.+)\",(.+),(\w)[\r\n]*?$/ =~ line
        [$1, $2, $3, $4]
      elsif /^(\S+),\"(.+)[\r\n]*?$/ =~ line
        [$1, $2, "Unknown", "Unknown"]
      elsif /^(\S+),(.+)[\r\n]*?$/ =~ line
        [$1, $2, "Unknown", "Unknown"]
      else
        raise "Parse error on NAMES.\n"
      end
    end

    def self.construct_turtle(cui, name, source, suppress)
      turtle_str = ""
      turtle_str = turtle_str +
        "medgen:#{cui}\n" +
        "  a mo:ConceptID ;\n" +
        "  dct:identifier \"#{cui}\" ;\n" +
        "  rdfs:label \"#{name.gsub('"','\"').gsub("\r","").gsub("\n","")}\" ;\n" +
        "  mo:name [\n" +
        "    rdfs:label \"#{name.gsub('"','\"').gsub("\r","").gsub("\n","")}\" ;\n" +
        "    dct:source mo:#{source.remove_space} ;\n" +
        "    mo:suppress mo:#{suppress}\n" +
        "  ] .\n" +
        "\n"
      turtle_str
    end

  end


  class MGDEF

    def self.rdf(file)
      File.open(file) do |f|
        f.gets
        MedGen.prefixes if $prefixes
        while line = f.gets
          ary = parse(line)
          puts construct_turtle(*ary) unless ary == "NA"
        end
      end
    end

    def self.parse(line)
      if /^(\w+),\"(.+)\",([\w\s]+?),(\w)[\r\n]+?$/ =~ line
#        STDERR.print "#{$3}\n"
        [$1, $2, $3, $4]
      elsif /^(\w+),(.+),([\w\s]+?),(\w)[\r\n]+?$/ =~ line
#        STDERR.print "#{$3}\n"
        [$1, $2, $3, $4]
      elsif /^(\w+),([.\\]+),([\w\s]+?),(\w)[\r\n]+?$/ =~ line
#        STDERR.print "#{$3}\n"
        [$1, $2, $3, $4]
      else
        begin
          raise "Parse error on MGDEF.\n"
        rescue
          return "NA"
        end
      end 
    end

    def self.construct_turtle(cui, c_def, source, suppress)
      turtle_str = ""
      turtle_str = turtle_str + 
        "medgen:#{cui}\n" +
        "  skos:definition \"#{c_def.gsub("\r"," ").gsub("\n","").gsub(/\\/,"\\\\\\\\").gsub('"','\"')}\" ;\n" +
        "  mo:mgdef [\n" +
        "    skos:definition \"#{c_def.gsub("\r"," ").gsub("\n","").gsub(/\\/,"\\\\\\\\").gsub('"','\"')}\" ;\n" +
        "    dct:source mo:#{source.remove_space} ;\n" +
        "    mo:suppress mo:#{suppress}\n" +
        "  ] .\n" +
        "\n"
      turtle_str
    end
  end

  class MGCONSO

    def self.rdf(file)
      hash = {}
      File.open(file) do |f|
        f.gets
        MedGen.prefixes if $prefixes
        while line = f.gets
          ary = parse(line)
          # ary[8] describes an abbreviation for the source of the term
          # (Defined in MedGen_Sources.txt)
          case ary[8]
          when "GTR"
            puts construct_turtle(*ary, :gtr)
          when "HPO"
            puts construct_turtle(*ary, :hpo)
          when "MSH"
            puts construct_turtle(*ary, :msh)
          when "OMIM"
            puts construct_turtle(*ary, :omim)
          when "ORDO"
            puts construct_turtle(*ary, :ordo)
          when "NCI"
            puts construct_turtle(*ary, :nci)
          when "SNOMEDCT_US"
            puts construct_turtle(*ary, :snomedct_us)
          when "MONDO"
            puts construct_turtle(*ary, :mondo)
          else
          end
        end
      end
    end

    def self.parse(line)
      if /^(\w+),(\w+),(\w+),(\w+),(\w+),(\S*),(\S*),(\S*),(\w+),(\w+),(.+?),\"(.+)\",(\w)[\r\n]*?$/ =~ line
        [$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13]
      elsif /^(\w+),(\w+),(\w+),(\w+),(\w+),(\S*),(\S*),(\S*),(\w+),(\w+),(.+?),\"(.+\",[\w\s]+?)[\r\n]+$/ =~ line
        [$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, "N"]
      elsif /^(\w+),(\w+),(\w+),(\w+),(\w+),(\S*),(\S*),(\S*),(\w+),(\w+),(.+),\"(.?)\",\w[\r\n]+$/ =~ line
        [$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, "N"]
      elsif /^(\w+),(\w+),(\w+),(\w+),(\w+),(\S*),(\S*),(\S*),(\w+),(\w+),(.?),\"\",\w[\r\n]+$/ =~ line
        [$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, "", "N"]
      elsif /^(\w+),(\w+),(\w+),(\w+),(\w+),(\S*),(\S*),(\S*),(\w+),(\w+),(.+?),(.+),\w[\r\n]+$/ =~ line
        [$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, "N"]
      else
        raise "Parse error on MGCONSO.\n"
      end
    end

    def self.construct_turtle(cui, ts, stt, ispref, aui, saui,
                              scui, sdui, sab, tty, code, str, suppress, flag)
      turtle_ary = ["medgen:#{cui}\n"]

      turtle_ary << 
        "  mo:mgconso [\n" <<
        "    rdfs:label \"#{str.gsub('"', '\"')}\" ;\n" <<
        "    mo:ts mo:#{ts} ;\n" <<
        "    mo:stt mo:#{stt} ;\n" <<
        "    mo:ispref ispref:#{ispref} ;\n" <<
        "    mo:aui \"#{aui}\" ;\n" <<
        "    dct:source mo:#{sab.remove_space} ;\n"
##        "    mo:suppress mo:#{suppress} ;\n"

      case flag
      when :hpo
        /HP\:(\d+)/ =~ sdui
        hp_id = $1
        turtle_ary << "    rdfs:seeAlso obo:HP_#{$1} ;\n"
      when :msh
        turtle_ary << "    rdfs:seeAlso mesh:#{sdui} ;\n"
      when :omim
        if /^\d+$/ =~ sdui
          turtle_ary << "    rdfs:seeAlso omim:#{sdui} ;\n"
        elsif /^(\d+)\.\d+$/ =~ sdui
          turtle_ary << "    rdfs:seeAlso omim:#{$1} ;\n"
        elsif /MTHU/ =~ sdui
          turtle_ary << "    rdfs:seeAlso bp_omim:#{sdui} ;\n"
        else
          STDERR.print "#{sdui} Unknown OMIM ID pattern.\n"
          exit
        end
      when :ordo
        turtle_ary << "    rdfs:seeAlso ordo:#{sdui} ;\n"
      when :nci
        turtle_ary << "    rdfs:seeAlso nci:#{scui} ;\n"
      when :snomedct_us
        turtle_ary << "    rdfs:seeAlso snomedct:#{scui} ;\n"
      when :mondo
        /MONDO\:(\d+)/ =~ sdui
        mondo_id = $1
        turtle_ary << "    rdfs:seeAlso obo:MONDO_#{$1} ;\n"
      when :other
      else
      end

      turtle_ary << 
        "    mo:suppress mo:#{suppress}\n" <<
        "  ] .\n" <<
        "\n"

      turtle_str = turtle_ary.join("")
    end
  end

  class MGSTY

    def self.rdf(file)
      File.open(file) do |f|
        f.gets
        MedGen.prefixes if $prefixes
        while line = f.gets
          ary = parse(line)
          puts construct_turtle(*ary)
        end
      end
    end

    def self.parse(line)
      if /^(\w+),(\w+),.+,(\w+)[\r\n]*?$/ =~ line
        [$1, $2, $13]
      else
        raise "Parse error on MGSTY.\n"
      end
    end

    def self.construct_turtle(cui, tui, atui)
      turtle_str = ""
      turtle_str = turtle_str +
        "medgen:#{cui}\n" +
        "  mo:sty sty:#{tui} .\n" +
        "\n"
      turtle_str
    end

  end

  class MGREL

    def self.rdf(file)
      File.open(file) do |f|
        f.gets
        MedGen.prefixes if $prefixes
        while line = f.gets
          ary = parse(line)
          puts construct_turtle(*ary)
        end
      end
    end

    def self.parse(line)
      if /^(\w+),(\w+),(\w+),(\w+),(\w+),(\w+),(\w*),(\w+),(\w+),(\w+),(\w)[\r\n]*?$/ =~ line
        [$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11]
      else
        raise "Parse error on MGREL.\n"
      end
    end

    def self.construct_turtle(cui1, aui1, stype1, rel, cui2, aui2, rela,
                              rui, sab, sl, suppress)
      turtle_str = 
        "[\n" +
        "  a mo:MGREL ;\n" +
        "  dct:identifier \"#{rui}\" ;\n" +
        "  mo:cui1 medgen:#{cui1} ;\n" +
        "  mo:aui1 \"#{aui1}\" ;\n" +
        "  mo:cui2 medgen:#{cui2} ;\n" +
        "  mo:aui2 \"#{aui2}\" ;\n"
      if rela == ""
        turtle_str = turtle_str +
          "  dct:source mo:#{sab} ;\n" +
          "  mo:suppress mo:#{suppress}\n" +
          "] .\n\n"
      else
        turtle_str = turtle_str + 
          "  mo:rela \"#{rela}\" ;\n" +
          "  dct:source mo:#{sab} ;\n" +
          "  mo:suppress mo:#{suppress}\n" +
          "] .\n\n"
      end
      turtle_str
    end

  end

  class MGSAT

    def self.rdf(file)
      File.open(file) do |f|
        f.gets
        MedGen.prefixes if $prefixes
        while line = f.gets
          ary = parse(line)
          puts construct_turtle(*ary)
        end
      end
    end

    def self.parse(line)
      if /^(\w+),(\w+),(\w+),([\.\:\w]*),(\w+),([\w\-\_]+),(\w+),\"(.*)\",(\w)[\r\n]*?$/ =~ line
        [$1, $2, $3, $4, $5, $6, $7, $8, $9]
      elsif /^(\w+),(\w+),(\w+),([\.\:\w]*),(\w+),([\w\-\_]+),(\w+),(.*),(\w)[\r\n]*?$/ =~ line
        [$1, $2, $3, $4, $5, $6, $7, $8, $9]
      else
        raise "Parse error on MGSAT.\n"
      end
    end

    def self.construct_turtle(cui, metaui, stype, code, atui, atn,
                              sab, atv, suppress)
      turtle_str = ""
      turtle_str = turtle_str +
        "medgen:#{cui}\n" +
        "  mo:mgsat [\n" +
        "    a mo:MGSAT ;\n" +
        "    dct:identifier \"#{atui}\" ;\n" +
        "    mo:metaui \"#{metaui}\" ;\n" +
        "    mo:stype \"#{stype}\" ;\n" +
        "    rdfs:label \"#{atn}\" ;\n" +
        "    rdf:value \"#{atv.gsub("\\","").gsub('"', '\"')}\" ;\n" +
        "    dct:source mo:#{sab} ;\n" +
        "    mo:suppress mo:#{suppress}\n" +
        "  ] .\n\n"
      turtle_str
    end

  end

#head -3 medgen_pubmed_lnk.txt
#
##UID|CUI|NAME|PMID|
#2|C0000039|1,2 Dipalmitoylphosphatidylcholine|1520723|
#2|C0000039|1,2 Dipalmitoylphosphatidylcholine|2157200|

  class MedGenPubMed

    def self.rdf(file)
      uid2pubmed = []
      File.open(file) do |f|
        f.gets # skip the header line
        MedGen.prefixes if $prefixes
        ary = parse(f.gets)
        uid2pubmed = [ary[0], ary[1], ary[2], [ary[3]]]
        while line = f.gets
          ary = parse(line)
          if uid2pubmed[0] != ary[0]
            puts construct_turtle(*uid2pubmed)
            uid2pubmed = [ary[0], ary[1], ary[2], [ary[3]]]
          else
            uid2pubmed[3] << ary[3]
          end
        end
      end
    end

    def self.parse(line)
      line_replaced = line.force_encoding('UTF-8').scrub('?')
      if /^(\d+)\|(\w+)\|(.+)\|(\d+)\|[\r\n]*?$/ =~ line_replaced
        [$1, $2, $3, $4]
      else
        raise "Parse error on medgen_pubmed_lnk.txt .\n"
      end
    end

    def self.construct_turtle(uid, cui, name, pmids)
      pmids.map!{|pmid| "pubmed:#{pmid}, pubmedid:#{pmid}"}
      turtle_ary = []
      turtle_str =
        "medgen:#{uid}\n" +
        "  rdfs:seeAlso medgen:#{cui} ;\n" +
        "  rdfs:label #{name.inspect} ;\n" +
        "  dct:references #{pmids.join(', ')} .\n\n"
    end
  end

  class MedGenOMIMHPOMapping

    def self.rdf(file, sty_file)
      sty_label2id = parse_umls_semantictype(sty_file)
      File.open(file) do |f|
        f.gets
        MedGen.prefixes if $prefixes
        while line = f.gets
          ary = parse(line)
          puts construct_turtle(*ary[0..9], sty_label2id)
        end
      end
    end

    def self.parse(line)
      ary = line.split("|", -1)
      if ary.size < 10
        STDERR.print "#{line}"
        raise "Parse error on MedGen_HPO_OMIM_Mapping.txt .\n"
      end
      ary
    end

    def self.parse_umls_semantictype(sty_file)
      sty_label2id = {}
      sty_id = ""
      sty_label = ""
      File.open(sty_file) do |f|
        while line = f.gets
          if /\/(\w+)\> a owl\:Class/ =~ line
            sty_id = $1
          elsif /skos\:prefLabel\s+\"(.+)\"\@en/ =~ line
            sty_label = $1
            sty_label2id[sty_label] = sty_id
          else
          end
        end
      end
      sty_label2id
    end

    def self.construct_turtle(omim_cui, mim_number, omim_name, relationship,
                              hpo_cui, hpo_id, hpo_name, medgen_name,
                              medgen_source, sty, sty_label2id)
      turtle_str = ""
      if relationship == ""
        turtle_str =
          "medgen:#{hpo_cui} mo:undefined_relationship medgen:#{omim_cui} .\n"
      else
        turtle_str =
          "medgen:#{hpo_cui} mo:#{relationship} medgen:#{omim_cui} .\n"
      end
      turtle_str = turtle_str +
        "[\n" +
        "  a rdf:Statement ;\n" +
        "  rdf:subject medgen:#{hpo_cui} ;\n"
      if relationship == ""
        turtle_str = turtle_str +
          "  rdf:predicate mo:undefined_relationship ;\n"
      else
        turtle_str = turtle_str +
          "  rdf:predicate mo:#{relationship} ;\n"
      end
      turtle_str = turtle_str +
        "  rdf:object medgen:#{omim_cui} ;\n" +
        "  dct:source mo:#{medgen_source} ;\n" +
        "  mo:sty sty:#{sty_label2id[sty]}\n" +
        "] .\n\n"

      turtle_str
    end
  end

  class MIM2GENE

    @@mim2type = {}

    def self.rdf(file)
      File.open(file) do |f|
        f.gets
        MedGen.prefixes if $prefixes
        while line = f.gets
          ary = parse(line)
          rdf_str = construct_turtle(*ary)
          puts rdf_str unless rdf_str == ""
        end
      end
      @@mim2type.each do |mim_number, mim_type|
        puts "omim:#{mim_number} mo:mim_type \"#{mim_type}\" . \n\n"
      end
    end

    def self.parse(line)
      ary = line.chomp.split("\t")
      if ary.size != 6
        STDERR.print "#{line}"
        raise "Parse error on mim2gene_medgen.\n"
      end
      ary
    end

    def self.construct_turtle(mim_number,
                              gene_id,
                              type,       # 'gene' or 'phenotype'
                              source,     # 'GeneMap', 'GeneReviews', 'GeneTests', 
                                          # 'NCBI curation', 'OMIM'
                              medgen_cui,
                              comment) 
      sources = ""
      if source == "-"
        sources = "-"
      else
        sources = source.strip.split("; ").map{|e| "\"#{e}\""}.join(", ")
      end

      turtle_str = ""
      if type == "phenotype"
        @@mim2type[mim_number] ||= "phenotype"
        unless gene_id == '-'
          turtle_str =
            # obo:RO_0003302 "causes or contributes to condition"
            "ncbigene:#{gene_id} obo:RO_0003302 medgen:#{medgen_cui} .\n" +
            "[\n" +
            "  rdf:subject ncbigene:#{gene_id} ;\n" +
            "  rdf:predicate obo:RO_0003302 ;\n" +
            "  rdf:object medgen:#{medgen_cui} ;\n" +
            "  dct:source #{sources} ;\n" +
            "  rdfs:comment \"#{comment}\" ;\n" +
            "  a rdf:Statement\n" +
            "] .\n\n"
        end
      elsif type == "gene"
        @@mim2type[mim_number] ||= "gene"
        unless gene_id == '-'
          turtle_str = 
            "ncbigene:#{gene_id} rdfs:seeAlso omim:#{mim_number} .\n\n"
        end
      end
      turtle_str
    end
  end
end


class String
  def to_snake
    self.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
  end

  def remove_space
    self.gsub(/\s([A-Za-z])/, '\1'.upcase)
  end
end

def help
  print "Usage: convert_rdf_medgen.rb [options] <file>\n"
  print "  -p, --prefixes print prefixes\n"
  print "  -n, --names    convert NAMES.csv to RDF\n"
  print "  -d, --mgdef    convert MGDEF.csv to RDF\n"
  print "  -s, --mgsty    convert MGSTY.csv to RDF\n"
  print "  -c, --mgconso  convert MGCONSO.csv to RDF\n"
  print "  -r, --mgrel    convert MGREL_1.csv and MGREL_2.csv to RDF\n"
  print "  -a, --mgsat    convert MGSAT_1.csv and MGSAT_2.csv to RDF\n"
  print "  -u, --pubmed   convert medgen_pubmed_lnk.txt to RDF\n"
  print "  -m, --omim     convert MedGen_HPO_OMIM_Mapping.txt to RDF\n"
  print "  -l, --sty      UMLS Semantic Type Ontology\n"
  print "  -g, --gene     convert omim2gene_medgen to RDF\n"
  print "  -h, --help     print help\n"
end

params = ARGV.getopts('ha:c:d:n:r:s:pu:m:l:g:', 'help', 'prefixes', 'names:', 'mgdef:', 'mgsty:', 'mgconso:', 'mgrel:', 'mgsat:', 'pubmed:', 'omim:', 'sty:', 'gene:')

if params["help"] || params["h"]
  help
  exit
end

$prefixes = true                           if params["prefixes"]
$prefixes = true                           if params["p"]
MedGen::MGDEF.rdf(params["mgdef"])         if params["mgdef"]
MedGen::MGDEF.rdf(params["d"])             if params["d"]
MedGen::NAMES.rdf(params["names"])         if params["names"]
MedGen::NAMES.rdf(params["n"])             if params["n"]
MedGen::MGSTY.rdf(params["mgsty"])         if params["mgsty"]
MedGen::MGSTY.rdf(params["s"])             if params["s"]
MedGen::MGCONSO.rdf(params["mgconso"])     if params["mgconso"]
MedGen::MGCONSO.rdf(params["c"])           if params["c"]
MedGen::MGREL.rdf(params["mgrel"])         if params["mgrel"]
MedGen::MGREL.rdf(params["r"])             if params["r"]
MedGen::MGSAT.rdf(params["mgsat"])         if params["mgsat"]
MedGen::MGSAT.rdf(params["a"])             if params["a"]
MedGen::MedGenPubMed.rdf(params["pubmed"]) if params["pubmed"]
MedGen::MedGenPubMed.rdf(params["u"])      if params["u"]
if params["m"] || params["omim"]
  if params["m"] && params["l"]
    MedGen::MedGenOMIMHPOMapping.rdf(params["m"], params["l"])
  elsif params["m"] && params["sty"]
    MedGen::MedGenOMIMHPOMapping.rdf(params["m"], params["sty"])
  elsif params["omim"] && params["l"]
    MedGen::MedGenOMIMHPOMapping.rdf(params["omim"], params["sty"])
  elsif params["omim"] && params["sty"]
    MedGen::MedGenOMIMHPOMapping.rdf(params["omim"], params["sty"])
  else
    help
    exit
  end
end
MedGen::MIM2GENE.rdf(params["gene"])       if params["gene"]
MedGen::MIM2GENE.rdf(params["g"])          if params["g"]
