# Patches Redmine's Tracker. Adds callback to manipulate permission
require 'redmine_track_control/tracker_helper'

module RedmineGdrive
  module TrackerPatch
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)
      # Same as typing in the class
      base.class_eval do
        unloadable
        after_create :add_tracker_permission, on: :create
        after_destroy :remove_tracker_permission
      end
    end

    module ClassMethods
    end

    module InstanceMethods
      private
      def add_tracker_permission
        RedmineGdrive::TrackerHelper.add_tracker_permission(self, 'view_gdrive')
      end

      def remove_tracker_permission
        RedmineGdrive::TrackerHelper.remove_tracker_permission(self, 'view_gdrive')
      end
    end
  end
end
