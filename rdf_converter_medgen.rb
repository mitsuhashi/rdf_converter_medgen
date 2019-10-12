#!/usr/bin/env ruby

require 'optparse'

module MedGen

  Prefixes = {
    "rdf" => "<http://www.w3.org/1999/02/22-rdf-syntax-ns#>",
    "rdfs" => "<http://www.w3.org/2000/01/rdf-schema#>",
    "skos" => "<http://www.w3.org/2004/02/skos/core#>",
    "prov" => "<http://www.w3.org/ns/prov#>",
    "pav" => "<http://purl.org/pav/>",
    "medgen" => "<https://www.ncbi.nlm.nih.gov/medgen/>",
    "mo" => "<http://med2rdf/ontology/medgen#>",
    "ispref" => "<http://med2rdf/ontology/medgen/ispref#>",
    "sty" => "<http://purl.bioontology.org/ontology/STY/>",
    "omim" => "<http://purl.bioontology.org/ontology/OMIM/>",
    "obo" => "<http://purl.obolibrary.org/obo/>",
    "mesh" => "<http://id.nlm.nih.gov/mesh/>",
    "ordo" => "<http://www.orpha.net/ORDO/>",
    "nci" => "<http://ncicb.nci.nih.gov/xml/owl/EVS/Thesaurus.owl#>",
    "dct" => "<http://purl.org/dc/terms/>",
    "pubmedid" => "<http://identifiers.org/pubmed/>",
    "pubmed" => "<http://rdf.ncbi.nlm.nih.gov/pubmed/>"
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
      if  /^(\S+),\"(.+)\",(.+),(\w)[\r\n]*?$/ =~ line
        [$1, $2, $3, $4]
      elsif /^(\S+),\"(.+)[\r\n]*?$/ =~ line
        [$1, $2, "Unknown", "Unknown"]
      elsif /^(\S+),(.+)[\r\n]*?$/ =~ line
        [$1, $2, "Unknown", "Unknown"]
      else
        raise "Parse error on NAMES.\n"
      end
    end

    def self.construct_turtle(cui, name, source, supress)
      turtle_str = ""
      turtle_str = turtle_str +
        "medgen:#{cui}\n" +
        "  a mo:ConceptID ;\n" +
        "  dct:identifier \"#{cui}\" ;\n" +
        "  rdfs:label \"#{name.gsub('"','\"').gsub("\r","").gsub("\n","")}\" ;\n" +
        "  mo:name [\n" +
        "    rdfs:label \"#{name.gsub('"','\"').gsub("\r","").gsub("\n","")}\" ;\n" +
        "    dct:source mo:#{source.remove_space} ;\n" +
        "    mo:supress mo:#{supress}\n" +
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
          puts construct_turtle(*ary)
        end
      end
    end

    def self.parse(line)
      if /^(\w+),\"(.+)\",(.+?),(\w)[\r\n]+?$/ =~ line
        [$1, $2, $3, $4]
      else
        raise "Parse error on MGDEF.\n"
      end 
    end

    def self.construct_turtle(cui, c_def, source, supress)
      turtle_str = ""
      turtle_str = turtle_str + 
        "medgen:#{cui}\n" +
        "  skos:definition \"#{c_def.gsub("\r"," ").gsub("\n","").gsub(/\\/,"\\\\\\\\").gsub('"','\"')}\" ;\n" +
        "  mo:mgdef [\n" +
        "    skos:definition \"#{c_def.gsub("\r"," ").gsub("\n","").gsub(/\\/,"\\\\\\\\").gsub('"','\"')}\" ;\n" +
        "    dct:source mo:#{source.remove_space} ;\n" +
        "    mo:supress mo:#{supress}\n" +
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
          hash[ary[0]] = {} unless hash.key?(ary[0])
          if hash[ary[0]].key?(ary[8])
            puts construct_turtle(*ary, :other)
          else
            hash[ary[0]][ary[8]] = {}
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
            else
            end
          end
        end
      end
    end

    def self.parse(line)
      if /^(\w+),(\w+),(\w+),(\w+),(\w+),(\S*),(\S*),(\S*),(\w+),(\w+),(.+?),\"(.+)\",(\w)[\r\n]*?$/ =~ line
        [$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13]
      elsif /^(\w+),(\w+),(\w+),(\w+),(\w+),(\S*),(\S*),(\S*),(\w+),(\w+),(.+?),\"(.+\",[\w\s]+?)[\r\n]+$/ =~ line
        [$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, "N"]
      else
        raise "Parse error on MGCONSO.\n"
      end
    end

    def self.construct_turtle(cui, ts, stt, ispref, aui, saui,
                              scui, sdui, sab, tty, code, str, supress, flag)
      turtle_ary = ["medgen:#{cui}\n"]
      case flag
      when :hpo
        turtle_ary << "  rdfs:seeAlso obo:#{cui} ;\n"
      when :msh
        turtle_ary << "  rdfs:seeAlso mesh:#{sdui} ;\n"
      when :omim
        turtle_ary << "  rdfs:seeAlso omim:#{sdui} ;\n"
      when :ordo
        turtle_ary << "  rdfs:seeAlso ordo:#{sdui} ;\n"
      when :nci
        turtle_ary << "  rdfs:seeAlso nci:#{scui} ;\n"
      when :snomedct_us
      when :other
      else
      end

      turtle_ary << 
        "  mo:mgconso [\n" <<
        "    rdfs:label \"#{str.gsub('"', '\"')}\" ;\n" <<
        "    mo:ts mo:#{ts} ;\n" <<
        "    mo:stt mo:#{stt} ;\n" <<
        "    mo:ispref ispref:#{ispref} ;\n" <<
        "    mo:aui \"#{aui}\" ;\n" <<
        "    dct:source mo:#{sab.remove_space} ;\n" <<
        "    mo:supress mo:#{supress}\n" <<
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
                              rui, sab, sl, supress)
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
          "  mo:supress mo:#{supress}\n" +
          "] .\n\n"
      else
        turtle_str = turtle_str + 
          "  mo:rela \"#{rela}\" ;\n" +
          "  dct:source mo:#{sab} ;\n" +
          "  mo:supress mo:#{supress}\n" +
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
      if /^(\w+),(\w+),(\w+),([\:\w]*),(\w+),([\w\-\_]+),(\w+),\"(.*)\",(\w)[\r\n]*?$/ =~ line
        [$1, $2, $3, $4, $5, $6, $7, $8, $9]
      else
        raise "Parse error on MGSAT.\n"
      end
    end

    def self.construct_turtle(cui, metaui, stype, code, atui, atn,
                              sab, atv, supress)
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
        "    mo:supress mo:#{supress}\n" +
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
      if /^(\d+)\|(\w+)\|(.+)\|(\d+)\|[\r\n]*?$/ =~ line
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
  print "  -h, --help     print help\n"
end

params = ARGV.getopts('ha:c:d:n:r:s:pu:', 'help', 'prefixes', 'names:', 'mgdef:', 'mgsty:', 'mgconso:', 'mgrel:', 'mgsat:', 'pubmed:')

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
