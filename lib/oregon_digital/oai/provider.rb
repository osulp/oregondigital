class OregonDigital::OAI::Provider < ::OAI::Provider::Base
  repository_name APP_CONFIG['oai']['repository_name']
  repository_url APP_CONFIG['oai']['repository_url']
  record_prefix APP_CONFIG['oai']['record_prefix']
  admin_email APP_CONFIG['oai']['admin_email']
  sample_id APP_CONFIG['oai']['sample_id']
  source_model ::OregonDigital::OAI::Model::ActiveFedoraWrapper.new(::ActiveFedora::Base, :limit => 100)
  Base.register_format(OregonDigital::OAI::DublinCore.instance)
  Base.register_format(OregonDigital::OAI::QualifiedDublinCore.instance)

  OAI::Provider::Response::RecordResponse.class_eval do
    def identifier_for(record)
      setid = ""
      if !record.descMetadata.primarySet.empty?
        setid = record.descMetadata.primarySet.first.id.gsub("oregondigital:","")
      elsif !record.descMetadata.set.empty?
        setid = record.descMetadata.set.first.id.gsub("oregondigital:","")
      end
      "#{APP_CONFIG['oai']['record_prefix']}:#{setid}/#{record.id.gsub('oregondigital:','')}"
    end
  end

end
