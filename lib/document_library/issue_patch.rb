module DocumentLibrary
  module IssuePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        before_destroy :delete_workspace

        alias_method_chain :copy_from, :gdrive_remove
      end
    end

    module ClassMethods
    end

    module InstanceMethods

      # Override method from Issue model and add gdrive_id to ignore
      def copy_from_with_gdrive_remove(arg, options={})
        issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
        self.attributes = issue.attributes.dup.except("id", "root_id", "parent_id", "lft", "rgt", "created_on", "updated_on", "gdrive_id")
        self.custom_field_values = issue.custom_field_values.inject({}) {|h,v| h[v.custom_field_id] = v.value; h}
        self.status = issue.status
        self.author = User.current
        if options[:attachments]
          self.attachments = issue.attachments.map do |attachement|
            attachement.copy(:container => self)
          end
        end
        @copied_from = issue
        @copy_options = options
        self
      end

      def get_gdrive_id
        initial_gdrive
      end

      def create_workspace
        @gdrive.set_permission_close(self.gdrive_id) if initial_gdrive
      end

      def delete_workspace
        @gdrive.delete_file(self.gdrive_id) if self.gdrive_id && initial_gdrive
      end

      def workspace_link
        @gdrive.download_link(self.gdrive_id) if initial_gdrive
      end

      # Return hash of attachments in Gdrive folder
      def attachments_in_gdrive
        files_array = []
        list = @gdrive.get_children(self.gdrive_id) if initial_gdrive
        if list
          list.each do |file_id|
            file = @gdrive.get_file_title(file_id)
            # add array [title, link_to_icon, link_to_download] to array
            files_array << [file[0], file[1], @gdrive.download_link(file_id)]
          end
          files_array
        end
      end

      def new_file(title, type)
        return unless initial_gdrive
        case type
          when 'doc'
            @gdrive.create_file_doc title, self.gdrive_id
          when 'spread'
            @gdrive.create_file_spreadsheet title, self.gdrive_id
          when 'pptp'
            @gdrive.create_file_presentation title, self.gdrive_id
        end
      end

      def file_type
      end

      def file_title
      end

      def upload_file(file)
        return unless initial_gdrive
        media = Google::APIClient::UploadIO.new(File.open(file.tempfile), file.content_type)
        @gdrive.upload_file(file.original_filename, file.content_type, media, self.gdrive_id)
      end

      def visible_with_gdrive?(usr = nil)
        RedmineTrackControl::TrackerHelper.issue_has_valid_tracker?(self, 'view_gdrive', usr) || (usr || User.current).admin?
      end

      private

      def initial_gdrive
        if project.module_enabled? :document_library
          @gdrive ||= Gdrive.first
          return unless @gdrive
          unless self.gdrive_id
            self.gdrive_id = @gdrive.create_folder("#{subject}", project.get_gdrive_id)
            self.save
          end
          self.gdrive_id
        end
      end
    end
  end
end