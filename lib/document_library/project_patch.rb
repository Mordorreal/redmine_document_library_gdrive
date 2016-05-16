module DocumentLibrary
  module ProjectPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)

      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will not be unloaded in development

        after_create :create_workspace
        before_destroy :delete_workspace
      end
    end

    module ClassMethods
    end

    module InstanceMethods

      def get_gdrive_id
        initial_gdrive
      end

      def create_workspace
        initial_gdrive
      end

      def delete_workspace
        @gdrive.delete_file(self.gdrive_id) if initial_gdrive
      end

      private

      def initial_gdrive
        if project.module_enabled? :document_library
          @gdrive ||= Gdrive.first
          return nil unless @gdrive
          unless self.gdrive_id
            self.gdrive_id = @gdrive.create_folder("#{name}", @gdrive.application_root_folder)
            self.save
          end
          self.gdrive_id
        end
      end
    end
  end
end