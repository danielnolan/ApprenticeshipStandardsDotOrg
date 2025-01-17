class CreateSourceFileJob < ApplicationJob
  queue_as :default

  def perform(attachment)
    standards_import = attachment.record
    linkable_word_files =
      SourceFile
        .where(active_storage_attachment_id: standards_import.files.map(&:id))
        .word_attachment
        .where.not(link_to_pdf_filename: nil)

    courtesy_notification = standards_import.courtesy_notification
    Rails.error.handle do
      SourceFile.transaction do
        SourceFile
          .create_with(
            courtesy_notification:,
            public_document: standards_import.public_document,
            metadata: standards_import.metadata
          )
          .find_or_create_by!(active_storage_attachment_id: attachment.id)
          .tap { maybe_link_to_original_source_file(_1, linkable_word_files) }
      end
    end
  end

  def maybe_link_to_original_source_file(source_file, linkable_word_files)
    return unless source_file.pdf?
    return if linkable_word_files.blank?

    filename = source_file.active_storage_attachment.filename.to_s
    original_source_file = linkable_word_files.find do |other|
      other.link_to_pdf_filename == filename
    end

    if original_source_file.present?
      source_file.update!(
        original_source_file:,
        assignee: original_source_file.assignee
      )
      original_source_file.update!(
        link_to_pdf_filename: nil,
        status: :archived,
        courtesy_notification: :not_required,
        assignee: nil
      )
    end
  end
end
