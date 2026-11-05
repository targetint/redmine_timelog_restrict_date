module RestrictTimeEntryPatch
  LOCKED_MESSAGE = "You have missed the time log deadline. Please contact your manager.".freeze

  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      validate :check_restrict_date
      before_destroy :check_restrict_date_on_destroy
    end
  end

  # Returns the configured lock date as a Date, or nil when no (valid) lock
  # date is set. A missing or blank setting means nothing is locked.
  def self.lock_date
    settings = Setting.plugin_redmine_timelog_restrict_date
    return nil unless settings.respond_to?(:[])

    raw = settings['lock_date'] || settings[:lock_date]
    return nil if raw.blank?

    raw.to_date
  rescue ArgumentError
    # Unparseable value stored in the settings: treat as not set
    nil
  end

  def self.locked?(date)
    lock = lock_date
    return false if lock.nil? || date.nil?

    date.to_date <= lock
  end

  module InstanceMethods
    def check_restrict_date
      if RestrictTimeEntryPatch.locked?(spent_on)
        errors.add(:base, RestrictTimeEntryPatch::LOCKED_MESSAGE)
      end
    end

    def check_restrict_date_on_destroy
      # Deleting a whole project removes its time entries along with it;
      # that is an admin-only operation and is not blocked here.
      return if destroyed_by_association&.active_record == Project

      # Use the stored date so an unsaved in-memory change cannot bypass the lock
      if RestrictTimeEntryPatch.locked?(spent_on_in_database || spent_on)
        errors.add(:base, RestrictTimeEntryPatch::LOCKED_MESSAGE)
        throw :abort
      end
    end
  end # module InstanceMethods
end # module RestrictTimeEntryPatch

# Add module to TimeEntry class
TimeEntry.send(:include, RestrictTimeEntryPatch)
