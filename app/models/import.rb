class Import < ApplicationRecord
  belongs_to :parent, polymorphic: true
  belongs_to :assignee, class_name: "User", optional: true

  # DataImport records can only be linked to type Imports::Pdf,
  # but these associations are needed for all types due to limitations
  # of Administrate.
  has_many :data_imports, -> { none }, inverse_of: "import"
  has_many :associated_occupation_standards, -> { none }, through: :data_imports, source: :occupation_standard

  # Only Imports::DocxListing have multiple imports, but this
  # association is needed for all types due to limitation of Administrate
  has_many :imports, -> { none }

  enum :status, [
    :pending,
    :completed,
    :needs_support,
    :needs_human_review,
    :archived,
    :needs_backend_support,
    :unfurled
  ]
  enum courtesy_notification: [
    :not_required,
    :pending,
    :completed
  ], _prefix: true

  scope :needs_unfurling, -> { unfurled.where("created_at < ?", 1.day.ago) }

  def filename
    file&.blob&.filename.to_s
  end

  def redacted_pdf
  end

  def redacted_pdf_url
  end

  def import_root
    parent.import_root
  end
end
