require "rails_helper"

RSpec.describe ImportOccupationStandardDetails do
  describe "#call" do
    it "returns an occupation standards record" do
      create(:registration_agency, for_state_abbreviation: "CA", agency_type: :oa)
      create(:industry, prefix: "13")

      data_import = create(:data_import, :pending)

      os = described_class.new(data_import).call
      expect(os).to be_a(OccupationStandard)
    end

    context "when data_import has no occupation_standard associated" do
      it "creates an occupation standards record for time-based" do
        ca_oa = create(:registration_agency, for_state_abbreviation: "CA", agency_type: :oa)
        _ca_saa = create(:registration_agency, for_state_abbreviation: "CA", agency_type: :saa)
        onet = create(:onet, code: "13-1071.01")
        industry = create(:industry, prefix: "13")

        occupation1 = create(:occupation, rapids_code: "0157")
        _occupation2 = create(:occupation, onet: onet)

        data_import = create(:data_import, :pending)

        expect {
          described_class.new(data_import).call
        }.to change(OccupationStandard, :count).by(1)

        os = OccupationStandard.last
        expect(os.data_import).to eq data_import
        expect(os.occupation).to eq occupation1
        expect(os.registration_agency).to eq ca_oa
        expect(os.title).to eq "HUMAN RESOURCE SPECIALIST"
        expect(os.existing_title).to eq "Career Development Technician"
        expect(os.term_months).to eq 12
        expect(os).to be_competency_based
        expect(os.probationary_period_months).to eq 3
        expect(os.onet_code).to eq "13-1071.01"
        expect(os.industry).to eq industry
        expect(os.rapids_code).to eq "0157"
        expect(os.apprenticeship_to_journeyworker_ratio).to eq "5:1"
        expect(os.organization_title).to eq "Hardy Corporation"
        expect(os.ojt_hours_min).to be_nil
        expect(os.ojt_hours_max).to be_nil
        expect(os.rsi_hours_min).to be_nil
        expect(os.rsi_hours_max).to be_nil
        expect(os.registration_date.to_s).to eq "1987-01-15"
        expect(os.latest_update_date.to_s).to eq "2022-10-20"
      end

      it "creates an occupation standards record for competency-based" do
        ca_oa = create(:registration_agency, for_state_abbreviation: "CA", agency_type: :oa)

        create(:onet, code: "13-1071.01")
        industry = create(:industry, prefix: "13")
        occupation = create(:occupation, rapids_code: "0157")

        data_import = create(:data_import, :hybrid, :pending)

        expect {
          described_class.new(data_import).call
        }.to change(OccupationStandard, :count).by(1)

        os = OccupationStandard.last
        expect(os.data_import).to eq data_import
        expect(os.occupation).to eq occupation
        expect(os.registration_agency).to eq ca_oa
        expect(os.title).to eq "HUMAN RESOURCE SPECIALIST"
        expect(os.existing_title).to eq "Career Development Technician"
        expect(os.term_months).to eq 12
        expect(os).to be_competency_based
        expect(os.probationary_period_months).to eq 3
        expect(os.onet_code).to eq "13-1071.01"
        expect(os.industry).to eq industry
        expect(os.rapids_code).to eq "0157"
        expect(os.apprenticeship_to_journeyworker_ratio).to eq "5:1"
        expect(os.organization_title).to eq "Hardy Corporation"
        expect(os.ojt_hours_min).to be_nil
        expect(os.ojt_hours_max).to be_nil
        expect(os.rsi_hours_min).to be_nil
        expect(os.rsi_hours_max).to be_nil
      end

      it "creates an occupation standards record when there is no RAPIDS code" do
        ca_oa = create(:registration_agency, for_state_abbreviation: "CA", agency_type: :oa)

        onet = create(:onet, code: "31-1071.01")
        industry = create(:industry, prefix: "31")
        occupation = create(:occupation, onet: onet)

        data_import = create(:data_import, :no_rapids, :pending)

        expect {
          described_class.new(data_import).call
        }.to change(OccupationStandard, :count).by(1)

        os = OccupationStandard.last
        expect(os.data_import).to eq data_import
        expect(os.occupation).to eq occupation
        expect(os.registration_agency).to eq ca_oa
        expect(os.title).to eq "HUMAN RESOURCE MANAGER"
        expect(os.existing_title).to be_nil
        expect(os.term_months).to eq 12
        expect(os).to be_time_based
        expect(os.probationary_period_months).to eq 7
        expect(os.onet_code).to eq "31-1071.01"
        expect(os.industry).to eq industry
        expect(os.rapids_code).to be_nil
        expect(os.apprenticeship_to_journeyworker_ratio).to eq "5:1"
        expect(os.organization_title).to eq "Hardy Corporation"
        expect(os.ojt_hours_min).to be_nil
        expect(os.ojt_hours_max).to eq 200
        expect(os.rsi_hours_min).to be_nil
        expect(os.rsi_hours_max).to eq 100
      end

      it "sets national standard type when no registration agency state" do
        national_agency = create(:registration_agency, state: nil, agency_type: :oa)
        occupation = create(:occupation, rapids_code: "0157")
        data_import = create(:data_import, :national_program_standard, :pending)
        industry = create(:industry, prefix: "13")

        expect {
          described_class.new(data_import).call
        }.to change(OccupationStandard, :count).by(1)

        os = OccupationStandard.last
        expect(os.data_import).to eq data_import
        expect(os.occupation).to eq occupation
        expect(os.registration_agency).to eq national_agency
        expect(os).to be_national_program_standard
        expect(os.title).to eq "HUMAN RESOURCE SPECIALIST"
        expect(os.existing_title).to eq "Career Development Technician"
        expect(os.term_months).to eq 12
        expect(os).to be_competency_based
        expect(os.probationary_period_months).to eq 3
        expect(os.onet_code).to eq "13-1071.01"
        expect(os.industry).to eq industry
        expect(os.rapids_code).to eq "0157"
        expect(os.apprenticeship_to_journeyworker_ratio).to eq "5:1"
        expect(os.organization_title).to eq "Hardy Corporation"
        expect(os.ojt_hours_min).to be_nil
        expect(os.ojt_hours_max).to be_nil
        expect(os.rsi_hours_min).to be_nil
        expect(os.rsi_hours_max).to be_nil
      end

      it "uses occupation's RAPIDS code if no RAPIDS code" do
        create(:registration_agency, for_state_abbreviation: "CA", agency_type: :oa)

        onet = create(:onet, code: "31-1071.01")
        create(:industry, prefix: "31")
        create(:occupation, onet: onet, rapids_code: "8765")

        data_import = create(:data_import, :no_rapids, :pending)

        expect {
          described_class.new(data_import).call
        }.to change(OccupationStandard, :count).by(1)

        os = OccupationStandard.last
        expect(os.rapids_code).to eq "8765"
      end

      it "does not set RAPIDS code if blank and occupation does not exist" do
        create(:registration_agency, for_state_abbreviation: "CA", agency_type: :oa)
        create(:industry, prefix: "31")

        data_import = create(:data_import, :no_rapids, :pending)

        expect {
          described_class.new(data_import).call
        }.to change(OccupationStandard, :count).by(1)

        os = OccupationStandard.last
        expect(os.rapids_code).to be_nil
      end

      it "uses occupation's ONET code if no ONET code" do
        create(:registration_agency, for_state_abbreviation: "CA", agency_type: :oa)

        onet = create(:onet, code: "13-1081.01")
        create(:industry, prefix: "13")
        create(:occupation, onet: onet, rapids_code: "1057")

        data_import = create(:data_import, :no_onet, :pending)

        expect {
          described_class.new(data_import).call
        }.to change(OccupationStandard, :count).by(1)

        os = OccupationStandard.last
        expect(os.onet_code).to eq "13-1081.01"
      end

      it "does not set ONET code if blank and occupation does not exist" do
        create(:registration_agency, for_state_abbreviation: "CA", agency_type: :oa)

        data_import = create(:data_import, :no_onet, :pending)

        expect {
          described_class.new(data_import).call
        }.to change(OccupationStandard, :count).by(1)

        os = OccupationStandard.last
        expect(os.onet_code).to be_nil
      end

      it "finds and updates the occupation standard record linked to the same source file with the same name if one exists" do
        ca_oa = create(:registration_agency, for_state_abbreviation: "CA", agency_type: :oa)

        create(:onet, code: "13-1071.01")
        industry = create(:industry, prefix: "13")
        occupation = create(:occupation, rapids_code: "0157")

        os = create(:occupation_standard, title: "HUMAN RESOURCE SPECIALIST")
        original_data_import = create(:data_import, occupation_standard: os)

        os_other = create(:occupation_standard, title: "NOT HUMAN RESOURCE SPECIALIST")
        create(:data_import, occupation_standard: os_other, source_file: original_data_import.source_file)

        new_data_import = create(:data_import, occupation_standard: nil, source_file: original_data_import.source_file)

        expect {
          described_class.new(new_data_import).call
        }.to_not change(OccupationStandard, :count)

        os.reload
        expect(os.data_import).to eq new_data_import
        expect(os.occupation).to eq occupation
        expect(os.registration_agency).to eq ca_oa
        expect(os.title).to eq "HUMAN RESOURCE SPECIALIST"
        expect(os.existing_title).to eq "Career Development Technician"
        expect(os.term_months).to eq 12
        expect(os).to be_competency_based
        expect(os.probationary_period_months).to eq 3
        expect(os.onet_code).to eq "13-1071.01"
        expect(os.industry).to eq industry
        expect(os.rapids_code).to eq "0157"
        expect(os.apprenticeship_to_journeyworker_ratio).to eq "5:1"
        expect(os.organization_title).to eq "Hardy Corporation"
        expect(os.ojt_hours_min).to be_nil
        expect(os.ojt_hours_max).to be_nil
        expect(os.rsi_hours_min).to be_nil
        expect(os.rsi_hours_max).to be_nil
      end
    end

    context "when data_import already has an occupation_standard associated" do
      it "updates the occupation standards record" do
        ca_oa = create(:registration_agency, for_state_abbreviation: "CA", agency_type: :oa)

        create(:onet, code: "13-1071.01")
        industry = create(:industry, prefix: "13")
        occupation = create(:occupation, rapids_code: "0157")

        data_import = create(:data_import)
        os = data_import.occupation_standard

        expect {
          described_class.new(data_import).call
        }.to_not change(OccupationStandard, :count)

        os.reload
        expect(os.data_import).to eq data_import
        expect(os.occupation).to eq occupation
        expect(os.registration_agency).to eq ca_oa
        expect(os.title).to eq "HUMAN RESOURCE SPECIALIST"
        expect(os.existing_title).to eq "Career Development Technician"
        expect(os.term_months).to eq 12
        expect(os).to be_competency_based
        expect(os.probationary_period_months).to eq 3
        expect(os.onet_code).to eq "13-1071.01"
        expect(os.industry).to eq industry
        expect(os.rapids_code).to eq "0157"
        expect(os.apprenticeship_to_journeyworker_ratio).to eq "5:1"
        expect(os.organization_title).to eq "Hardy Corporation"
        expect(os.ojt_hours_min).to be_nil
        expect(os.ojt_hours_max).to be_nil
        expect(os.rsi_hours_min).to be_nil
        expect(os.rsi_hours_max).to be_nil
      end
    end
  end
end
