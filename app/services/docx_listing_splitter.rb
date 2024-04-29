class DocxListingSplitter
  def self.split(id, file, &block)
    new(id, file).split(&block)
  end

  def initialize(id, file)
    @id = id
    @file = file
  end

  def split(&block)
    zip_file = create_zip_version_of_source_file
    file_names = unzip_attachments_and_list_file_names(zip_file)

    block.call(file_names)
  ensure
    delete_extracted_files(file_names, zip_file)
  end

  private

  def create_zip_version_of_source_file
    zip_file = Tempfile.open(temp_file_path, encoding: "ascii-8bit")
    @file.blob.download { |chunk| zip_file.write(chunk) }
    zip_file
  end

  def unzip_attachments_and_list_file_names(zip_file)
    file_names = []

    unless File.zero?(zip_file)
      Zip::File.open(zip_file) do |zip_file|
        zip_file.each do |entry|
          next unless entry.name.end_with?(".doc", ".docx", ".bin")
          entry.name.sub!(".bin", ".pdf")

          FileUtils.mkdir_p(Rails.root.join("tmp", @id))
          file_path = Rails.root.join("tmp", @id, File.basename(entry.name)).to_s
          entry.extract(@entry_path = file_path)
          file_names << file_path
        end
      end
    end

    file_names
  end

  def delete_extracted_files(file_names, temp_file)
    temp_file.unlink
    file_names.each do |file_name|
      File.delete(file_name)
    end
  end

  def temp_file_path
    Rails.root.join("tmp", "#{@id}.zip").to_s
  end
end
