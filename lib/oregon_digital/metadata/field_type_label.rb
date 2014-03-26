class OregonDigital::Metadata::FieldTypeLabel
  # Returns the label for the given internal field name (the value in an
  # options dropdown, which is also the "type" on the ingest map)
  def self.for(field)
    I18n.t(field, :scope => [:oregondigital, :metadata], :default => field.to_s.humanize)
  end
end
