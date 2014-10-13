RDF_VOCABS = {
  :dcmitype             =>  { :prefix => 'http://purl.org/dc/dcmitype/', :source => 'http://dublincore.org/2012/06/14/dctype.rdf' },
  :marcrel              =>  { :prefix => 'http://id.loc.gov/vocabulary/relators/', :source => 'http://id.loc.gov/vocabulary/relators.nt' },
  :dwc                  =>  { :prefix => 'http://rs.tdwg.org/dwc/terms/', :strict => false },
  :iso_639_1            =>  { :prefix => 'http://id.loc.gov/vocabulary/iso639-1/', :source => 'http://id.loc.gov/vocabulary/iso639-1.nt'},
  :iso_639_2            =>  { :prefix => 'http://id.loc.gov/vocabulary/iso639-2/', :source => 'http://id.loc.gov/vocabulary/iso639-2.nt'},
  :marc_lang            =>  { :prefix => 'http://id.loc.gov/vocabulary/languages/', :source => 'http://id.loc.gov/vocabulary/languages.nt'},
  :premis               =>  { :prefix => 'http://www.loc.gov/premis/rdf/v1#', :source => 'http://www.loc.gov/premis/rdf/v1.nt' },
  :geonames             =>  { :prefix => 'http://sws.geonames.org/', :strict => false, :fetch => false },
  :lcsh                 =>  { :prefix => 'http://id.loc.gov/authorities/subjects/', :strict => false, :fetch => false },
  :lcnames              =>  { :prefix => 'http://id.loc.gov/authorities/names/', :strict => false, :fetch => false },
  :tgm                  =>  { :prefix => 'http://id.loc.gov/vocabulary/graphicMaterials', :strict => false, :fetch => false },
  :afs_ethn             =>  { :prefix => 'http://id.loc.gov/vocabulary/ethnographicTerms', :strict => false, :fetch => false },
  :lc_orgs              =>  { :prefix => 'http://id.loc.gov/vocabulary/organizations', :strict => false, :fetch => false },
  :aat                  =>  { :prefix => 'http://vocab.getty.edu/aat/', :strict => false, :fetch => false },
  :getty_tgn            =>  { :prefix => 'http://vocab.getty.edu/tgn/', :strict => false, :fetch => false },
  :cclicenses           =>  { :prefix => 'http://creativecommons.org/licenses/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/cclicenses/cclicenses.nt'},
  :ccpublic             =>  { :prefix => 'http://creativecommons.org/publicdomain/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/cclicenses/cclicenses.nt'},
  :uonames              =>  { :prefix => 'http://opaquenamespace.org/ns/uo-names/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/uo/names.jsonld'},
  :rights               =>  { :prefix => 'http://opaquenamespace.org/rights/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/rights.jsonld', :strict => true },
  :eurights             =>  { :prefix => 'http://www.europeana.eu/rights/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/eurights/rightsstatements.nt', :strict => true },
  :mimetype             =>  { :prefix => 'http://purl.org/NET/mediatypes/', :source => 'http://mediatypes.appspot.com/dump.rdf' },
  :oregondigital        =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/opaquenamespace.jsonld', :strict => true },
  :oregon_universities  =>  { :prefix => 'http://dbpedia.org/resource/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/oregon_universities.jsonld', :strict => true },
  :set                  =>  { :prefix => 'http://oregondigital.org/resource/', :strict => false },
  :holding              =>  { :prefix => 'http://purl.org/ontology/holding#' },
  :creator              =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/creator.jsonld', :strict => true },
  :culture              =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/culture.jsonld', :strict => true },
  :localcoll            =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/localCollectionName.jsonld', :strict => true },
  :institutions         =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/oregondigital_orgs.jsonld', :strict => true },
  :people               =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/people.jsonld', :strict => true },
  :repository           =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/repository.jsonld', :strict => true },
  :sciclass             =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/scientific_class.jsonld', :strict => true },
  :scicommon            =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/scientific_commonNames.jsonld', :strict => true },
  :scigenus             =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/scientific_genus.jsonld', :strict => true },
  :sciphylum            =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.githubusercontent.com/OregonDigital/opaque_ns/master/scientific_phylum.jsonld', :strict => true },
  :styleperiod          =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/stylePeriod.jsonld', :strict => true },
  :subject              =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/subject.jsonld', :strict => true },
  :technique            =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/technique.jsonld', :strict => true },
  :worktype             =>  { :prefix => 'http://opaquenamespace.org/ns/', :source => 'https://raw.github.com/OregonDigital/opaque_ns/master/workType.jsonld', :strict => true },
  :ubio                 =>  { :prefix => 'http://identifiers.org/ubio.namebank/', :strict => false, :fetch => false },
  :itis                 =>  { :prefix => 'http://www.itis.gov/ITISWebService/', :strict => false, :fetch => false },
  :bm                   =>  { :prefix => 'http://collection.britishmuseum.org/', :strict => false, :fetch => false }
}
