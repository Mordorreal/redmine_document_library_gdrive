# Helper module
module DocumentLibrary
  module TrackerHelper
    def self.add_tracker_permission(tracker, permtype)
      Redmine::AccessControl.map { |map| map.project_module(:tracker_permissions) { |map2| map2.permission(permission(tracker, permtype), { issues: :index }, {}) } }
    end

    def self.remove_tracker_permission(tracker, permtype)
      perm = Redmine::AccessControl.permission(permission(tracker, permtype))
      Redmine::AccessControl.permissions.delete perm unless perm.nil?
    end

    def self.permission(tracker, permtype = 'view_gdrive')
      (permtype + "_tracker#{tracker.id}").to_sym
    end
    # Gets the list of valid trackers for the project for the current user
    def self.valid_trackers_list(project, permtype = 'view_gdrive')
      if project
        if project.enabled_modules.where(name: 'document_library').count == 1
          project.trackers.select { |t| User.current.allowed_to?(permission(t, permtype), project, global: true) }.collect { |t| [t.name, t.id] }
        else
          project.trackers.collect { |t| [t.name, t.id] }
        end
      end
    end
    # Gets the list of valid trackers for the project for the current user
    def self.trackers_ids_by_role(role, permtype = 'view_gdrive')
      if role
        Tracker.all.select { |t| role.allowed_to?(permission(t, permtype)) }.map(&:id)
      else
        Tracker.all.collect(&:id)
      end
    end
    # Gets the list of valid trackers for the project for the current user
    def self.valid_trackers_ids(project, permtype = 'view_gdrive', usr = nil)
      if project
        if project.enabled_modules.where(name: 'document_library').count == 1
          project.trackers.select { |t| (usr || User.current).allowed_to?(permission(t, permtype), project, global: true) }.map(&:id)
        else
          project.trackers.collect(&:id)
        end
      end
    end
    # Gets the list of valid trackers for the project for the current user
    def self.issue_has_valid_tracker?(issue, permtype = 'view_gdrive', usr = nil)
      if issue
        unless issue.project.nil?
          if issue.project.enabled_modules.where(name: 'document_library').count == 1
            l_trackers = valid_trackers_ids(issue.project, permtype, usr)
            return !l_trackers.nil? && !l_trackers.empty? && (l_trackers.include?(issue.tracker.id) || (issue.author == (usr || User.current)) || (usr || User.current).is_or_belongs_to?(issue.assigned_to))
          end
        end
      end
      true
    end
  end
end
