require "administrate/base_dashboard"

class StandardsImportDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::String,
    email: Field::String,
    name: Field::String,
    notes: Field::Text,
    organization: Field::String,
    files: Field::ActiveStorage,
    imports: Field::HasMany,
    source_files: HasManySourceFilesField,
    courtesy_notification: EnumField.with_options(searchable: false),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    created_at
    name
    organization
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    email
    source_files
    name
    notes
    organization
    courtesy_notification
    imports
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    email
    organization
    notes
    files
    courtesy_notification
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def permitted_attributes(action = nil)
    super + [attachments: []]
  end
end
