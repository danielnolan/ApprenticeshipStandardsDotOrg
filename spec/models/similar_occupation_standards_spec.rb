require "rails_helper"

RSpec.describe SimilarOccupationStandards do
  describe ".similar_to", :elasticsearch do
    it "returns records similar to the provided, sorted by similarity score" do
      create(:occupation_standard, title: "Mechanic")
      medical_assistant_standard = create(:occupation_standard, title: "Medical Assistant")
      create(:occupation_standard, title: "Medical Assistant II")
      create(:occupation_standard, title: "Admin Assistant")
      create(:occupation_standard, title: "Medical Assistant")

      OccupationStandard.import(refresh: true)

      similars_to_medical_assistant = SimilarOccupationStandards.similar_to(medical_assistant_standard)

      expect(similars_to_medical_assistant.pluck(:title)).to eq ["Medical Assistant", "Medical Assistant II", "Admin Assistant"]
    end

    it "returns records similar to the provided, including associations, sorted by similarity score" do
      medical_assistant_standard = create(:occupation_standard, title: "Medical Assistant")
      nurse_stantard = create(:occupation_standard, title: "Nurse")

      create(:work_process, title: "Patient Interaction", occupation_standard: medical_assistant_standard)
      create(:work_process, title: "Patient Interaction", occupation_standard: nurse_stantard)

      OccupationStandard.import(refresh: true)
      sleep 2

      similars_to_medical_assistant = SimilarOccupationStandards.similar_to(medical_assistant_standard)

      expect(similars_to_medical_assistant.pluck(:title)).to eq ["Nurse"]
    end
  end
end
