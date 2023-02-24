require "rails_helper"

RSpec.describe "OccupationStandard", type: :request do
  describe "GET /index" do
    context "on admin subdomain", :admin do
      context "when admin user" do
        it "returns http success" do
          admin = create(:admin)
          create_pair(:occupation_standard)

          sign_in admin
          get occupation_standards_path

          expect(response).to be_successful
        end
      end

      context "when guest" do
        it "redirects to root path" do
          get occupation_standards_path

          expect(response).to redirect_to new_user_session_path
        end
      end
    end

    context "on non-admin subdomain" do
      it "has 404 response" do
        expect {
          get occupation_standards_path
        }.to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe "GET /show/:id" do
    context "on admin subdomain", :admin do
      context "when admin user" do
        it "returns http success" do
          admin = create(:admin)
          occupation_standard = create(:occupation_standard)

          sign_in admin
          get occupation_standard_path(occupation_standard)

          expect(response).to be_successful
        end
      end

      context "when guest" do
        it "redirects to root path" do
          occupation_standard = create(:occupation_standard)

          get occupation_standard_path(occupation_standard)

          expect(response).to redirect_to new_user_session_path
        end
      end
    end

    context "on non-admin subdomain" do
      it "has 404 response" do
        occupation_standard = create(:occupation_standard)

        expect {
          get occupation_standard_path(occupation_standard)
        }.to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe "GET /edit/:id" do
    context "on admin subdomain", :admin do
      context "when admin user" do
        it "returns http success" do
          admin = create(:admin)
          occupation_standard = create(:occupation_standard)

          sign_in admin
          get edit_occupation_standard_path(occupation_standard)

          expect(response).to be_successful
        end
      end

      context "when guest" do
        it "redirects to root path" do
          occupation_standard = create(:occupation_standard)

          get edit_occupation_standard_path(occupation_standard)

          expect(response).to redirect_to new_user_session_path
        end
      end
    end

    context "on non-admin subdomain" do
      it "has 404 response" do
        occupation_standard = create(:occupation_standard)

        expect {
          get edit_occupation_standard_path(occupation_standard)
        }.to raise_error(ActionController::RoutingError)
      end
    end
  end

  describe "PUT /update/:id" do
    context "on admin subdomain", :admin do
      context "when admin user" do
        context "with valid params" do
          it "updates record and redirects to show page" do
            admin = create(:admin)
            occupation_standard = create(:occupation_standard, occupation: nil)

            sign_in admin
            patch occupation_standard_path(occupation_standard),
              params: {
                occupation_standard: {
                  title: "New title",
                  onet_code: "123.45",
                  rapids_code: "98765",
                  status: "published"
                }
              }

            occupation_standard.reload
            expect(occupation_standard.title).to eq "New title"
            expect(occupation_standard.onet_code).to eq "123.45"
            expect(occupation_standard.rapids_code).to eq "98765"
            expect(occupation_standard).to be_published
            expect(response).to redirect_to occupation_standard_path(occupation_standard)
          end
        end

        context "with invalid params" do
          it "updates record and redirects to index" do
            admin = create(:admin)
            occupation_standard = create(:occupation_standard, occupation: nil)

            sign_in admin
            patch occupation_standard_path(occupation_standard),
              params: {
                occupation_standard: {
                  title: "",
                  onet_code: "123.45",
                  rapids_code: "98765",
                  status: "published"
                }
              }

            occupation_standard.reload
            expect(occupation_standard.title).to_not be_blank
            expect(occupation_standard.onet_code).to_not eq "123.45"
            expect(occupation_standard.rapids_code).to_not eq "98765"
            expect(occupation_standard).to be_importing
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end
    end
  end
end
