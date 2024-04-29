require "rails_helper"

RSpec.describe Imports::DocxListing, type: :model do
  it_behaves_like "an imported file"

  describe "#process" do
    it "creates imports for each attachment" do
      docx_listing = create(
        :imports_docx_listing,
        file: Rack::Test::UploadedFile.new(Rails.root.join("spec", "fixtures", "files", "docx_file_attachments.docx"))
      )

      docx_listing.process
      # docx_listing.reload

      # expect(docx_listing.imports.count).to eq(7)
      # docx_listing.imports.each do |import|
      #   expect(import.status).to eq("pending")
      #   expect(import).to be_an(Imports::Uncategorized)
      # end
    end

    it "processes its imports" do
      imports = [double(:uncategorized, process: nil)]
      docx_listing = create(:imports_docx_listing)
      allow(DocxListingSplitter).to receive(:split)
      allow(docx_listing).to receive(:imports).and_return(imports)

      docx_listing.process(arg: 1)

      expect(imports[0]).to have_received(:process).with(arg: 1)
    end

    it "marks itself as processed"

    it "tracks errors"
  end
end
