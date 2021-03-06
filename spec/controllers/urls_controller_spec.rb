require "rails_helper"

RSpec.describe UrlsController, type: :controller do
  let(:url) { create(:url) }

  describe "before actions" do
    it { should use_before_action(:set_url) }
    it { should use_before_action(:redirect_to_dashboard) }
    it { should use_before_action(:redirect_to_root) }
  end

  describe "#homepage" do
    before(:each) { get :homepage }

    it "renders the :homepage view" do
      expect(response).to render_template "homepage"
    end

    it "populates the recently added links" do
      expect(assigns(:recently_added_links)).to eq([url])
    end

    it "populates the popular links" do
      @first_url = create(:url, visits_count: 3)
      @second_url = create(:url, visits_count: 4)
      expect(assigns(:popular_links)).to eq([@second_url, @first_url])
    end
  end

  describe "#details" do
    before(:each) do
      session[:user_id] = create(:user).id
      get :details, id: url.id
    end

    it "renders the :details view" do
      expect(response).to render_template "details"
    end

    it "assigns the requested url to @url" do
      expect(assigns(:url)).to eq(url)
    end
  end

  describe "#dashboard" do
    before(:each) do
      session[:user_id] = create(:user).id
      get :dashboard
    end

    it "renders the :dashboard view" do
      expect(response).to render_template :dashboard
    end
  end

  describe "#edit" do
    before(:each) do
      session[:user_id] = create(:user).id
      get :edit, id: url.id
    end

    it "renders the :edit view" do
      expect(response).to render_template "edit"
    end
  end

  describe "#create" do
    context "with valid details" do
      it "creates a new url" do
        expect do
          post :create, url: {
            long_url: "https://andela.com",
            short_url: "andela"
          }
        end
          .to change(Url, :count).by(1)
      end
    end

    context "with invalid details" do
      it "does not create a new url" do
        expect do
          post :create, url: {
            long_url: "invalid_url",
            short_url: "url.short_url"
          }
        end
          .to_not change { Url.count }
      end
    end
  end

  describe "#update" do
    context "with valid details" do
      it "updates the url" do
        put :update, id: url, url: {
          long_url: "https://andela.com/apply"
        }
        url.reload
        expect(url.long_url).to eq("https://andela.com/apply")
        expect(response).to redirect_to details_path
      end
    end

    context "with invalid details" do
      it "re-renders the :edit view" do
        put :update, id: url, url: {
          long_url: "invalid_url"
        }
        expect(url.long_url).to_not eq("invalid_url")
        expect(response).to render_template "edit"
      end
    end
  end

  describe "#redirect_url" do
    context "when url does not exist" do
      it "redirects to the :deleted view" do
        get :redirect_url,
        short_url: "invalid"
        expect(response).to redirect_to :deleted
      end
    end

    context "when url is inactive" do
      it "redirects to the :inactive view" do
        url.update(status: false)
        get :redirect_url,
        short_url: url.short_url

        expect(response).to redirect_to :inactive
      end
    end

    context "when url is active" do
      before(:each) do 
        get :redirect_url,
        short_url: url.short_url
      end

      it "redirects to the long_url" do
        expect(response).to redirect_to url.long_url
      end

      it "increments the url's click_count" do
        expect(Visit.count).to eq(1)
      end
    end
  end

  describe "#deleted" do
    it "renders the :deleted view" do
      get :deleted
      expect(response).to render_template "deleted"
    end
  end

  describe "#inactive" do
    it "renders the :inactive view" do
      get :inactive
      expect(response).to render_template "inactive"
    end
  end

  describe "#destroy" do
    it "deletes the url" do
      delete :destroy, id: url
      expect(Url.all).to_not include(url)
    end
  end
end
