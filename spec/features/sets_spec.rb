require 'spec_helper'

describe "SetsController /index" do
  let(:collection_pid) {'oregondigital:monkeys'}
  let(:collection) do
    g = GenericCollection.new(:pid => collection_pid)
    g.title = "Test Collection"
    g.save
    g
  end
  let(:item) do
    i = GenericAsset.new
    i.subject = "Test Facet"
    i.read_groups = ["public"]
    i.review!
    i
  end
  let(:item2) do
    i = GenericAsset.new
    i.subject = "Other Facet"
    i.read_groups = ["public"]
    i.review!
    i
  end
  before(:each) do
    collection
  end
  context "when there are sets" do
    before(:each) do
      visit sets_path
    end
    it "should show a list of all the collections" do
      expect(page).to have_content(collection.title)
    end
  end
  context "when there are facetable items" do
    before(:each) do
      item
      item2
      visit sets_path
    end
    it "should show the facets" do
      expect(page).to have_content("Test Facet")
      expect(page).to have_content("Other Facet")
    end
  end
  context "when requesting a specific collection" do
    before(:each) do
      item.collections << collection
      item.save
      item2
      visit sets_path(:set => collection)
    end
    context "that does have a set page" do
      let(:collection_pid) {'oregondigital:braceros'}
      it "should show the facets" do
        expect(page).to have_content("Test Facet")
      end
      it "should include the second half of the collection pid in the path" do
        expect(current_path).to eq "/sets/#{collection.pid.split(':').last}"
      end
      it "should show the collection landing page" do
        expect(page).to have_content("The Braceros Program")
      end
      it "should not show facets for items not in the collection" do
        expect(page).not_to have_content("Other Facet")
      end
    end
    context "that does not have a set page" do
      it "should show the generic collection landing page" do
        within("#main-container h2") do
          expect(page).to have_content("Test Collection")
        end
      end
    end
  end
end
