module RedmineGdrive
  module AttachmentPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        # after_save :upload_to_gdrive
        # after_commit :delete_from_gdrive, :on => :destroy
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      def upload_to_gdrive
        return unless initial_gdrive
        file = File.open(self.diskfile)
        if container_type == 'Issue' && file
          media = Google::APIClient::UploadIO.new(file, self.content_type)
          self.gdrive_id = @gdrive.upload_file(self.filename, self.content_type, media, self.container.gdrive_id)
          return unless self.gdrive_id
          self.save
        end
      end

      def delete_from_gdrive
        @gdrive.delete_file(self.gdrive_id) if initial_gdrive
      end

      private

      def initial_gdrive
        if self.gdrive_id.nil? && project.try(:module_enabled?, 'gdrives')
          @gdrive ||= Gdrive.first
        end
        @gdrive
      end
    end
  end
end