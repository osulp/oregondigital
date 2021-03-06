module OregonDigital::ControlledVocabularies
  class Ethnog < ActiveFedora::Rdf::Resource
    include OregonDigital::RDF::Controlled

    use_vocabulary :afs_ethn

    class QaLcEth < Qa::Authorities::Loc
      include OregonDigital::Qa::Caching
      def search(q, sub_authority=nil)
        super(q, 'ethnog')
      end

      def loc_response_to_qa(data)
        response = super(data)
        for link in data.links
          response["id"] = link[1] if link[0].nil?
        end
        return response
      end
    end

    @qa_interface = QaLcEth.new
  end
end
