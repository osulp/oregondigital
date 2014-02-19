class TemplatesController < FormControllerBase
  def index
    @templates = Template.all
  end

  def new
    @form.add_blank_groups
  end

  def create
    validate_and_save("Created Template", :new)
  end

  private

  # Overrides base behavior to handle the magic template varible (name) which
  # goes directly onto the template object, not the form object
  def setup_resources
    if params[:metadata_ingest_form]
      template_name = params[:metadata_ingest_form].delete(:template_name)
    end

    super

    @form.asset.name = template_name if template_name
  end

  # Chooses the ingest map to be used for grouping form elements and
  # translating data.  This is hard-coded for now, but may eventually use
  # things like user groups or collection info or who knows what.
  def ingest_map
    return INGEST_MAP
  end

  # Asset class used to instantiate a new object or load an existing one
  def asset_class
    return Template
  end
end
