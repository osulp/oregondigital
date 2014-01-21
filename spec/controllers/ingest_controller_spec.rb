require 'spec_helper'

describe IngestController do
  describe "#index" do
    # Index doesn't do much yet, so this is just a quick smoke test to verify nothing crashes
    it "works" do
      get :index
    end
  end

  describe "#form" do
    before(:each) do
      # Create a local form and stub .new so we can make assertions on what the controller sees
      @form = Metadata::Ingest::Form.new
      Metadata::Ingest::Form.stub(:new => @form)

      # Hack groups to just two simple values
      Metadata::Ingest::Form.stub(:groups).and_return(["foo", "bar"])

      # Make sure we don't typo a method, since that's a false positive
      @build_foo = :build_foo
      @build_bar = :build_bar
    end

    it "should assign a form variable" do
      get :form
      expect(assigns(:form)).to be_kind_of(Metadata::Ingest::Form)
    end

    it "should build an empty association for each group" do
      expect(@form).to receive(@build_foo).once
      expect(@form).to receive(@build_bar).once
      get :form
    end

    it "shouldn't build empty associations for groups which have data" do
      # Add a single empty object to each group
      @form.build_foo
      @form.build_bar

      # Neither builder should be called
      expect(@form).not_to receive(@build_foo)
      expect(@form).not_to receive(@build_bar)
      get :form
    end
  end

  describe "#save" do
    before(:each) do
      # This is ugly but it mimics exactly what Rails params look like
      @attrs = {
        "titles_attributes" => {
          "0" => {"type" => "title", "value" => "test title", "_destroy" => "false"}
        },
        "subjects_attributes" => {
          "0" => {"type" => "subject", "value" => "foo", "_destroy" => "false"},
          "1" => {"type" => "subject", "value" => "bar", "_destroy" => "false"}
        }
      }
    end

    context "(when the form represents a new asset)" do
      before(:each) do
        # Stubbed asset to avoid AF hits, create expectations, etc
        @asset = GenericAsset.new
        @ds = @asset.descMetadata
        @asset.stub(:save)
        @asset.stub(:save!)
        GenericAsset.stub(:new => @asset)
      end

      it "should set single-value attributes to a scalar value" do
        expect(@ds).to receive(:title=).with("test title")
        post :save, :metadata_ingest_form => @attrs
      end

      it "should set multiple-value attributes to arrays" do
        expect(@ds).to receive(:subject=).with(["foo", "bar"])
        post :save, :metadata_ingest_form => @attrs
      end

      it "shouldn't set anything on empty attributes" do
        @attrs["titles_attributes"]["0"]["type"] = ""
        @attrs["titles_attributes"]["0"]["value"] = ""
        expect(@ds).not_to receive(:title=)
        post :save, :metadata_ingest_form => @attrs
      end

      it "should use the internal value if one is sent" do
        @attrs["titles_attributes"]["0"]["internal"] = "internal"
        expect(@ds).to receive(:title=).with("internal")
        post :save, :metadata_ingest_form => @attrs
      end

      it "should create a new asset" do
        expect(@asset).to receive(:save).once
        post :save, :metadata_ingest_form => @attrs
      end
    end
  end
end