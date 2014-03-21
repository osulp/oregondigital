require 'spec_helper'

describe GenericAsset do
  it_behaves_like 'a baggable item'
  it_behaves_like 'a collectible item'

  subject(:generic_asset) { FactoryGirl.build(:generic_asset) }

  it 'should initialize' do
    expect { generic_asset }.not_to raise_error
  end

  describe '.save' do
    context 'when content has not been assigned' do
      it 'should not try to create derivatives' do
        generic_asset.should_not_receive(:create_derivatives)
        generic_asset.save
      end
    end
    context 'when content has been assigned' do
      before(:each) do
        file = File.open(File.join(fixture_path, 'fixture_image.jpg'), 'rb')
        generic_asset.add_file_datastream(file, :dsid => 'content')
        expect(generic_asset.content).not_to be_blank
      end
      it 'should try to create derivatives' do
        GenericAsset.any_instance.should_receive(:create_derivatives)
        generic_asset.save
      end
    end
    context "when content is returned to nil" do
      before(:each) do
        file = File.open(File.join(fixture_path, 'fixture_image.jpg'), 'rb')
        generic_asset.add_file_datastream(file, :dsid => 'content')
        generic_asset.save
        g = GenericAsset.find(generic_asset.pid)
        generic_asset.content.content = nil
      end
      it "should not try to create derivatives" do
        GenericAsset.any_instance.should_not_receive(:create_derivatives)
        generic_asset.save
      end
    end
  end

  describe '#set' do
    context "when it has an assigned set" do
      let(:collection) {FactoryGirl.create(:generic_collection)}
      let(:assigned_object) {collection}
      before(:each) do
        subject.set = assigned_object
      end

      context "by assigning it a collection object" do
        it "should return the set" do
          expect(subject.set).to eq [collection]
        end
        it "should return the set (after reload)" do
          subject.save
          subject.reload
          expect(subject.set).to eq [collection]
        end
        it "should index the rdf label" do
          expect(subject.to_solr[Solrizer.solr_name("desc_metadata__set_label", :facetable)]).to eq ["#{collection.resource.rdf_label.first}$#{collection.resource.rdf_subject.to_s}"]
        end
        it "should update the RDF label when the set is updated" do
          subject.save
          expect(subject.class.where(Solrizer.solr_name("desc_metadata__set_label", :facetable) => "#{collection.title}$#{collection.resource.rdf_subject.to_s}").length).to eq 1
          #collection.reload
          collection.title = "AnotherTitle"
          collection.save
          expect(subject.class.where(Solrizer.solr_name("desc_metadata__set_label", :facetable) => "#{collection.title}$#{collection.resource.rdf_subject.to_s}").length).to eq 1
        end
      end

      context "by assigning it a URI" do
        let(:assigned_object) {collection.resource.rdf_subject}
        it "should return the set (after reload)" do
          subject.save
          subject.reload
          expect(subject.set).to eq [collection]
        end
      end
    end
  end

  describe "fetching data" do
    let(:subject_1) {RDF::URI.new("http://id.loc.gov/authorities/subjects/sh85050282")}
    subject(:generic_asset) do
      g = FactoryGirl.build(:generic_asset)
      g.descMetadata.subject = subject_1
      g.save
      g
    end
    it "should fetch on save" do
      subject.reload
      expect(subject.descMetadata.subject.first.rdf_label.first).to eq "Food industry and trade"
    end
    context "when a new object asset has a subject that is fetched" do
      let(:asset_2) {
        g = FactoryGirl.build(:generic_asset)
        g.descMetadata.subject = subject_1
        g
      }
      before(:each) do
        # Stop auto reload
        GenericAsset.any_instance.stub(:queue_fetch).and_return(true)
        subject
        expect(GenericAsset.where("desc_metadata__subject_label_sim" => "Food industry and trade#{subject_1.to_s}").length).to eq 0
        asset_2.descMetadata.fetch_external
      end
      it "should set that object's label" do
        expect(asset_2.descMetadata.subject.first.rdf_label.first).to eq "Food industry and trade"
      end
      it "should fix the label on other objects" do
        subject.reload
        expect(subject.descMetadata.subject.first.rdf_label.first).to eq "Food industry and trade"
      end
      it "should not call fetch again when run again within 7 days" do
        expect(asset_2.descMetadata.subject.first).not_to receive(:fetch)
        asset_2.descMetadata.fetch_external
      end
      it "should persist the label to solr for other objects" do
        expect(GenericAsset.where("desc_metadata__subject_label_sim" => "Food industry and trade$#{subject_1.to_s}").length).to eq 1
      end
    end
  end

  describe 'indexing of deep nodes' do
    context 'when the object has a deep node with an rdf_subject' do
      let(:subject_1) {RDF::URI.new("http://id.loc.gov/authorities/subjects/sh85050282")}
      let(:subject_2) {RDF::URI.new("http://id.loc.gov/authorities/subjects/sh85123395")}
      subject(:generic_asset) do
        g = FactoryGirl.build(:generic_asset)
        g.descMetadata.subject = subject_1
        g.descMetadata.subject.first.set_value(RDF::SKOS.prefLabel, "Test Subject")
        g.descMetadata.subject.first.persist!
        g.descMetadata.subject << subject_2
        g.descMetadata.subject.last.set_value(RDF::SKOS.prefLabel, "Dogs")
        g.descMetadata.subject.first.persist!
        g
      end
      it "should index it" do
        name = subject.solr_name('desc_metadata__subject_label',:facetable)
        expect(subject.to_solr).to include name
        expect(subject.to_solr[name]).to eq ["Test Subject$#{subject_1.to_s}", "Dogs$#{subject_2.to_s}"]
      end
    end
  end

  describe 'pid assignment' do
    context 'before the object is saved' do
      it 'should be nil' do
        expect(generic_asset.pid).to be_nil
      end
    end
    context 'when a new object is saved' do
      context "when it doesn't have a pid" do
        before(:each) do
          OregonDigital::IdService.should_receive(:mint).and_call_original
          generic_asset.save
        end
        it 'should no longer be nil' do
          expect(generic_asset.pid).not_to be_nil
        end
        it 'should be a valid NOID' do
          expect(OregonDigital::IdService.valid?(generic_asset.pid)).to eq true
        end
      end
      context 'but it already has a pid' do
        subject(:generic_asset) { FactoryGirl.create(:generic_asset, :has_pid, pid: "changeme:monkeys") }
        it 'should not override the pid' do
          expect(generic_asset.pid).to eq 'changeme:monkeys'
          expect(generic_asset).to be_persisted
        end
      end
    end
  end
end
