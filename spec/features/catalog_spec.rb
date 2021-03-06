require 'spec_helper'

describe 'catalog' do
  describe 'index' do
    before do
      visit root_path
    end
    context "when the browse items link is clicked" do
      before do
        click_link "Browse Items"
      end
      it "should go to the search page" do
        expect(page).to have_content("No entries found")
      end
    end
    context "when advanced search is clicked" do
      before do
        click_link "Advanced Search"
      end
      it "should go to the advanced search" do
        expect(page).to have_content("More Search Options")
      end
    end
  end
  describe 'search results' do
    let(:asset) { FactoryGirl.create(:document, :with_pdf_datastream, :description => 'Dogs', :title => title) }
    let(:title) { "Test Document" }

    context "when there is a collection" do
      before(:each) do
        FactoryGirl.create(:generic_collection)
      end
      it "should not show up in search results" do
        visit root_path(:search_field => "all_field")
        expect(page).not_to have_selector('.document')
      end
    end

    context "when there is a document" do
      let(:query) { "Document" }
      before do
        asset.create_derivatives
        asset.review

        visit root_path(:search_field => "all_field")
        fill_in "q", :with => query
        click_button "search"
      end

      after do
        begin
          FileUtils.rm_rf(Rails.root.join("media","test"))
        rescue
        end
      end

      context "result links to items" do
        it "should contain search term(s) in link anchor of title" do
          expect(page).to have_selector("h5.index_title a[href$='search/Document']")
        end
        it "should contain search term(s) in link anchor of thumbnail" do
          expect(page).to have_selector("div.thumbnail-container a[href$='search/Document']")
        end
        context "when query has quotes in it" do
          let(:query) { '"Document"' }
          it "should strip them in the anchor" do
            expect(page).to have_selector("h5.index_title a[href$='search/Document']")
          end
        end
      end

      context "with a fulltext search match" do
        let(:query) {"Dog"}
        it "should show Full Text field title" do
          expect(page).to have_content("Full Text")
        end
      end
      context "with no fulltext search match" do
        it "should not show 'Full Text' field title" do
          expect(page).not_to have_content("Full Text")
        end
        it "should show 'Description' field title" do
          expect(page).to have_content("Description")
        end
      end
    end


    context "when there is an asset with a thumbnails" do
      context "when the asset is an image" do
        it_should_behave_like "a thumbnail asset" do
          let(:asset) {FactoryGirl.create(:image, :with_tiff_datastream)}
        end
      end
      context "when the asset is a video" do
        it_should_behave_like "a thumbnail asset" do
          let(:asset) {FactoryGirl.create(:video, :with_video_datastream)}
        end
      end
      context "when the asset is a document" do
        it_should_behave_like "a thumbnail asset" do
          let(:asset) do
            document = Document.new
            file = File.open(File.join(fixture_path, 'fixture_pdf.pdf'), 'rb')
            document.add_file_datastream(file, :dsid => 'content')
            OregonDigital::FileDistributor.any_instance.stub(:base_path).and_return(Rails.root.join("media","test"))
            document.title = "Filler Title"
            document.review!
            document
          end 
        end
      end
    end

    context "when an asset has CV fields" do
      let(:asset) do
        asset = FactoryGirl.build(:generic_asset, lcsubject: RDF::URI.new("http://id.loc.gov/authorities/subjects/sh85050282"))
        asset.descMetadata.lcsubject.first.set_value(RDF::SKOS.prefLabel, "Test Facet")
        asset.descMetadata.lcsubject.first.persist!
        asset.review!
        asset
      end
      context "(when viewing the item page)" do
        before(:each) do
          visit catalog_path(:id => asset.pid)
        end

        it "should show links to the CV facets" do
          expect(page).to have_link("Test Facet")
        end
        context "(and you click a CV facet)" do
          before do
            click_link "Test Facet"
            expect(page).to have_content("You searched for")
          end
          it "should show the facet" do
            within("#content") do
              expect(page).to have_content("Topic")
              expect(page).to have_content("Test Facet")
            end
          end
        end
      end
      context "(and you click it as a facet)" do
        before do
          asset.review!
          visit root_path
          click_link "Test Facet"
          expect(page).to have_content("You searched for")
        end
        context "(and then check the search history)" do
          before do
            within("#header-navbar-fixed-top") do
              click_link "History"
            end
            expect(page).to have_content("Search History")
          end
          it "should show the facet label" do
            within("#content") do
              expect(page).to have_content("Topic")
              expect(page).to have_content("Test Facet")
            end
          end
          it "should not show the facet URI" do
            within("#content") do
              expect(page).not_to have_content(asset.resource.lcsubject.first.rdf_subject.to_s)
            end
          end
        end
      end
    end
  end

  context "when an asset has metadata" do
    let(:asset) do
      FactoryGirl.create(:generic_asset, :title => "bla")
    end
    context "(when requesting ntriples)" do
      before do
        visit catalog_path(:id => asset.pid, :format => :nt)
      end
      it "should show the ntriples" do
        expect(page.html).to include(asset.resource.dump(:ntriples))
      end
    end
  end

end
