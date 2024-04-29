module Imports
  class DocxListing < Import
    has_many :imports, as: :parent, dependent: :destroy, autosave: true
    has_one_attached :file

    def process(**kwargs)
      transaction do
        DocxListingSplitter.split(id, file) do |file_names|
          file_names.each do |file_name|
            import = imports.build(
              type: "Imports::Uncategorized",
              status: :pending,
              assignee_id: assignee_id,
              public_document: public_document,
              courtesy_notification: courtesy_notification,
              metadata: metadata,
            )
            import.save!
            require'irb';binding.irb
            p import.file.attach(
              io: File.open(file_name),
              filename: File.basename(file_name),
            )
            # require'irb';binding.irb
            import.save!
          end
        end

        imports.each { _1.process(**kwargs) }

      #   update!(
      #     processed_at: Time.current,
      #     processing_errors: nil,
      #     status: :archived,
      #   )
      # rescue DocxListingSpliter::SplitError => e
      #   update!(
      #     processed_at: nil,
      #     processing_errors: e.message,
      #     status: :needs_backend_support,
      #   )
      end
    end
  end
end
