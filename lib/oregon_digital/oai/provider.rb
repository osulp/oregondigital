class OregonDigital::OAI::Provider < ::OAI::Provider::Base
  repository_name APP_CONFIG['oai']['repository_name']
  repository_url APP_CONFIG['oai']['repository_url']
  record_prefix APP_CONFIG['oai']['record_prefix']
  admin_email APP_CONFIG['oai']['admin_email']
  sample_id APP_CONFIG['oai']['sample_id']
<<<<<<< HEAD
  source_model ::OregonDigital::OAI::Model::ActiveFedoraWrapper.new(::ActiveFedora::Base, :limit => 10)
=======
  source_model ::OregonDigital::OAI::Model::ActiveFedoraWrapper.new(::ActiveFedora::Base, :limit => 5)
>>>>>>> 15ccd09f812c452e9576dd4c90e8abf0916d8d50

  Base.register_format(OregonDigital::OAI::DublinCore.instance)
end
