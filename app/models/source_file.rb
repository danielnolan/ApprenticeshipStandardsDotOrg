class SourceFile < ApplicationRecord
  belongs_to :active_storage_attachment, class_name: "ActiveStorage::Attachment"
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :original_source_file, class_name: "SourceFile", optional: true
  has_one :converted_source_file, class_name: "SourceFile", foreign_key: :original_source_file_id
  has_many :data_imports, -> { includes(:occupation_standard, file_attachment: :blob) }
  has_many :associated_occupation_standards, -> { distinct }, through: :data_imports, source: :occupation_standard
  has_one_attached :redacted_source_file
  has_one :import, class_name: "Imports::Uncategorized"

  enum :status, [:pending, :completed, :needs_support, :needs_human_review, :archived]
  enum courtesy_notification: [:not_required, :pending, :completed], _prefix: true

  after_create_commit :convert_doc_file_to_pdf

  WORD_FILE_CONTENT_TYPES = [
    Mime::Type.lookup_by_extension("docx").to_s,
    Mime::Type.lookup_by_extension("doc").to_s
  ]
  PDF_CONTENT_TYPE = Mime::Type.lookup_by_extension("pdf").to_s

  def self.missing_import
    not_archived.left_outer_joins(:import).where(imports: {id: nil})
  end

  def self.pdf_attachment
    includes(active_storage_attachment: :blob).where(
      active_storage_attachment: {
        active_storage_blobs: {
          content_type: PDF_CONTENT_TYPE
        }
      }
    )
  end

  def self.word_attachment
    joins(active_storage_attachment: :blob).where(
      active_storage_attachment: {
        active_storage_blobs: {content_type: WORD_FILE_CONTENT_TYPES}
      }
    )
  end

  def self.recently_redacted(start_time: Time.zone.yesterday.beginning_of_day, end_time: Time.zone.yesterday.end_of_day)
    where(
      redacted_at: (
        start_time..end_time
      )
    )
  end

  def self.not_redacted
    includes(:redacted_source_file_attachment).where(
      redacted_source_file_attachment: {
        id: nil
      }
    )
  end

  def self.already_redacted
    not_redacted.invert_where
  end

  def self.ready_for_redaction
    where(public_document: false).completed.not_redacted.pdf_attachment
  end

  def create_import!
    if !archived? && import.nil?
      import = standards_import.imports.create(
        type: "Imports::Uncategorized",
        public_document: public_document,
        metadata: metadata,
        status: :unfurled,
        source_file: self
      )

      import.file.attach(active_storage_attachment.blob)
      import
    end
  end

  def filename
    active_storage_attachment.blob.filename
  end

  def url
    active_storage_attachment.blob.url
  end

  def needs_courtesy_notification?
    completed? && courtesy_notification_pending?
  end

  # This saves the metadata as JSON instead of string.
  # See https://github.com/codica2/administrate-field-jsonb/issues/1
  def metadata=(value)
    self[:metadata] = value.is_a?(String) ? JSON.parse(value) : value
  end

  def organization
    standards_import.organization
  end

  def notes
    standards_import.notes
  end

  def claimed?
    assignee.present?
  end

  def standards_import
    active_storage_attachment.record
  end

  def pdf?
    active_storage_attachment.content_type == Mime::Type.lookup_by_extension("pdf").to_s
  end

  def docx?
    active_storage_attachment.content_type == Mime::Type.lookup_by_extension("docx").to_s
  end

  def word?
    WORD_FILE_CONTENT_TYPES.include?(active_storage_attachment.content_type)
  end

  def redacted_source_file_url
    redacted_source_file&.blob&.url
  end

  def file_for_redaction
    redacted_source_file.attached? ? redacted_source_file : active_storage_attachment
  end

  def can_be_converted_to_pdf?
    word? && !bulletin? && !archived?
  end

  private

  def convert_doc_file_to_pdf
    if can_be_converted_to_pdf?
      DocToPdfConverterJob.perform_later(self)
    end
  end
end
