class Scraper::ApprenticeshipBulletinsJob < ApplicationJob
  queue_as :default

  BULLETIN_LIST_URL = "https://www.apprenticeship.gov/about-us/legislation-regulations-guidance/bulletins/export?search=&category%5B0%5D=National%20Guideline%20Standards&category%5B1%5D=National%20Program%20Standards&category%5B2%5D=Occupations&page&_format=csv"

  def perform
    xlsx = Roo::Spreadsheet.open(BULLETIN_LIST_URL, extension: :csv)

    xlsx.parse(headers: true).each_with_index do |row, index|
      next if index < 1

      file_uri = row["File URI"]
      standards_import = StandardsImport.where(
        name: file_uri,
        organization: row["Title"]
      ).first_or_initialize(
        notes: "From Scraper::ApprenticeshipBulletinsJob",
        public_document: true,
        source_url: BULLETIN_LIST_URL,
        bulletin: true,
        metadata: {date: row["Date"]}
      )

      # Create a StandardsImport record and one UncategorizedUpload child record.
      # Have a background job that further processes the UnprocessedUpload
      # records.

      if standards_import.new_record?
        standards_import.save!

        if standards_import.files.attach(io: URI.parse(file_uri).open, filename: File.basename(file_uri))

          # SourceFile is created in background job so wait until it exists
          source_file = nil
          until source_file.present?
            source_file = standards_import.reload.files.last.source_file
          end

          source_file.update!(
            bulletin: true
          )
          if source_file.docx?
            Scraper::ExportFileAttachmentsJob.perform_later(source_file)
          end
        end
      end
    end
  end
end


class StandardsImport
  has_many :uploads, polymophic: true # Uncategorized, Imports::Pdf
end
class Imports::Uncategorized # Delete this record after transferred to Pdf, Doc, Docx
  belong_to :standards_import
  has_attachment :file

  def process
    # In a background job:
    # Identify what kind of file it is
    # Give back an AR class (pdf, docx listing, docx, doc)
    # Will call .new on that class. Will pass in parent is standards_import and
    # file = self.file
    # Will persist that record, and then call "process" method
  end
end
# Schema: Add processed_at on all these tables
class Imports::Pdf # "SourceFile" (mostly match existing SourceFile schema)
  # belongs_to parent_id, parent_type - belongs_to a DocxListing or Doc or Docx or StandardsImport
  has_attachment :file
  belongs_to :parent # standard_import or docx or doc (polymorphic)

  def process
    noop
  end
end
class Imports::DocxListing # Bulletin with attachments (will not convert to pdf)
  # belongs_to standards_import_id
  has_many :attachments # doc, docx, pdf files
  has_attachment :file

  def process
    # Extract attachments and create new UncategorizedUpload files
  end
end
class Import::Doc
  # belongs_to parent_id, parent_type - StandardsImport, DocxListing
  has_attachment :file
  has_one :pdf

  def process
    # convert to pdf
  end
end
class Import::Docx
  # belongs_to parent__id, parent_type - DocxListing, StandardsImport
  has_attachment :file
  has_one :pdf

  def process
    # convert to pdf
  end
end
