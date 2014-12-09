require 'spec_helper'

describe CatalogController do
  describe 'GET show' do
    let(:core_asset) { FactoryGirl.build(:generic_asset) }
    let(:asset) { core_asset }
    let(:soft_destroyed) do
      core_asset.soft_destroy
      core_asset
    end
    let(:document) { asset.to_solr }
    let(:user) {}
    let(:fake_document) do
      {
        "responseHeader" =>
        {"status" => 0,
         "QTime" => 0,
         "params" => {}
        },
        "response" => {
          "numFound" => 1,
          "start" => 0,
          "docs" => [document]
        }
      }
    end
    let(:stubbed_solr_response) do
      [fake_document, SolrDocument.new(document, fake_document)]
    end
    let(:stubbed_permissions_doc) do
      Hydra::PermissionsSolrDocument.new(document, fake_document)
    end

    before do
      sign_in(user) if user
      asset.stub(:pid).and_return("oregondigital:bla")
      controller.stub(:get_solr_response_for_doc_id).and_return(stubbed_solr_response)
      Ability.any_instance.stub(:permissions_doc).and_return(stubbed_permissions_doc)
      get :show, :id => asset.pid
    end

    context "when an admin" do
      let(:user) { FactoryGirl.create(:admin) }
      context "when the asset is soft destroyed" do
        let(:asset) { soft_destroyed }
        it "should be found" do
          expect(response).to be_success
        end
      end
    end
    context "when a user" do
      context "when the asset is built" do
        it "should be a success" do
          expect(response).to be_success
        end
      end
      context "when the asset is soft destroyed" do
        let(:asset) { soft_destroyed }
        it "should be not found" do
          expect(response.code).to eq "302"
          expect(flash[:alert]).to include "do not have sufficient"
        end
      end
    end
  end
end
