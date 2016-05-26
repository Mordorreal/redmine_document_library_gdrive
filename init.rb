require 'redmine'
require 'omniauth'
require 'omniauth-google-oauth2'
# Patches to the Redmine core.

# This is the important line.
# It requires the file in lib/document_library/hooks.rb
require_dependency 'document_library/hooks'

ActionDispatch::Callbacks.to_prepare do
  require_dependency 'project'
  Project.send(:include, DocumentLibrary::ProjectPatch)

  require_dependency 'issue'
  Issue.send(:include, DocumentLibrary::IssuePatch)

  require_dependency 'attachment'
  Attachment.send(:include, DocumentLibrary::AttachmentPatch)

  require_dependency 'roles_controller'
  RolesController.send(:include, DocumentLibrary::RolesControllerPatch)

  require_dependency 'tracker'
  Tracker.send(:include, DocumentLibrary::TrackerPatch)

end

Redmine::Plugin.register :redmine_document_library_gdrive do
  name 'Redmine Document library plugin'
  author 'Denis Savchuk'
  description 'This is a plugin for Redmine that attach GDrive to projects'
  version '0.1.0'
  url 'https://github.com/Mordorreal/redmine_document_library_gdrive'
  author_url 'https://github.com/Mordorreal'

  project_module :redmine_document_library_gdrive do
    permission :redmine_document_library_gdrive, { :redmine_document_library_gdrive => [:oauth2callback, :create_workspace, :new_google_file] }, :public => true
    Tracker.all.each do |t|
      DocumentLibrary::TrackerHelper.add_tracker_permission(t, 'view_gdrive')
    end
  end

  settings :default => {'empty' => false}, :partial => 'settings/gdrive_settings'

end

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'],
           {
               scope: %w(https://www.googleapis.com/auth/drive email profile),
               prompt: 'consent'
           }
end

# Little hack for deface in redmine:
# - redmine plugins are not railties nor engines, so deface overrides are not detected automatically
# - deface doesn't support direct loading anymore ; it unloads everything at boot so that reload in dev works
# - hack consists in adding "app/overrides" path of all plugins in Redmine's main #paths
Rails.application.paths['app/overrides'] ||= []
Dir.glob("#{Rails.root}/plugins/*/app/overrides").each do |dir|
  Rails.application.paths['app/overrides'] << dir unless Rails.application.paths['app/overrides'].include?(dir)
end
