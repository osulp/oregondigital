module OregonDigital::RDF
  module DeepIndex
    def solrize
      return super if node?
      return [rdf_subject.to_s] if rdf_label.first.to_s.blank? || rdf_label.first.to_s == rdf_subject.to_s
      [rdf_subject.to_s, {:label => "#{rdf_label.first.to_s}$#{rdf_subject.to_s}"}]
    end
  end
end
