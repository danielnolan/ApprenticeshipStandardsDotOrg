module Admin
  class DataImportsController < Admin::ApplicationController
    before_action :set_parent, except: [:show]

    def new
      resource = new_resource
      if Flipper.enabled?(:show_imports_in_administrate)
        resource.import = @parent
      else
        resource.source_file = @parent
      end
      authorize_resource(resource)
      render locals: {
        page: Administrate::Page::Form.new(dashboard, resource)
      }
    end

    def create
      data_import = @parent.data_imports.build(resource_params)
      data_import.user = current_user
      authorize_resource(data_import)

      if data_import.save
        ProcessDataImportJob.perform_later(data_import: data_import, last_file: last_file_flag)

        redirect_to(
          after_data_import_created_path(@parent, data_import)
        )
      else
        render :new, locals: {
          page: Administrate::Page::Form.new(dashboard, data_import)
        }, status: :unprocessable_entity
      end
    end

    def update
      if requested_resource.update(resource_params)
        ProcessDataImportJob.perform_later(data_import: requested_resource, last_file: last_file_flag)
        redirect_to(
          after_resource_updated_path(@parent, requested_resource),
          notice: translate_with_resource("update.success")
        )
      else
        render :edit, locals: {
          page: Administrate::Page::Form.new(dashboard, requested_resource)
        }, status: :unprocessable_entity
      end
    end

    def destroy
      authorize(requested_resource)
      if requested_resource.destroy
        occupation_standard = requested_resource.occupation_standard
        if occupation_standard && occupation_standard.data_imports.empty?
          occupation_standard.destroy!
        end
        flash[:notice] = translate_with_resource("destroy.success")
      else
        flash[:error] = requested_resource.errors.full_messages.join("<br/>")
      end
      redirect_to after_resource_destroyed_path(@parent)
    end

    private

    def set_parent
      @parent = if Flipper.enabled?(:show_imports_in_administrate)
        Imports::Pdf.find(params[:import_id])
      else
        SourceFile.find(params[:source_file_id])
      end
    end

    def last_file_flag
      params[:last_file] == "1"
    end

    def after_data_import_created_path(parent, data_import)
      if Flipper.enabled?(:show_imports_in_administrate)
        admin_import_data_import_path(parent, data_import)
      else
        admin_source_file_data_import_path(parent, data_import)
      end
    end

    def after_resource_updated_path(parent, data_import)
      if Flipper.enabled?(:show_imports_in_administrate)
        admin_import_data_import_path(parent, data_import)
      else
        admin_source_file_data_import_path(parent, data_import)
      end
    end

    def after_resource_destroyed_path(parent)
      if Flipper.enabled?(:show_imports_in_administrate)
        admin_import_path(parent)
      else
        admin_source_file_path(parent)
      end
    end
  end
end
