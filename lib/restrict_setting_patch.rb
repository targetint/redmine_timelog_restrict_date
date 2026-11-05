module RestrictSettingPatch
  SETTING_NAME = 'plugin_redmine_timelog_restrict_date'.freeze

  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    base.class_eval do
      before_save :track_lock_date_change, if: Proc.new {|s| s.name == SETTING_NAME }
      after_commit :notify_lock_date_change, on: [:create, :update], if: Proc.new {|s| s.name == SETTING_NAME }
    end
  end

  # Extracts the lock date string from a plugin settings value, or nil
  def self.lock_date_from(settings)
    return nil unless settings.is_a?(Hash)

    (settings['lock_date'] || settings[:lock_date]).to_s.presence
  end

  module InstanceMethods
    # Records the old and new lock dates before saving. The email itself is
    # only sent once the change has been committed.
    def track_lock_date_change
      @lock_date_change = nil

      # Read the previous value through Redmine's own Setting#value so we do
      # not have to deserialize the YAML ourselves. A new record (first save
      # of the plugin settings) has no previous value.
      old_value = new_record? ? nil : self.class.find_by(id: id)&.value
      was = RestrictSettingPatch.lock_date_from(old_value)
      now = RestrictSettingPatch.lock_date_from(value)

      changed_by = RestrictAutoLock.changed_by || User.current.name
      @lock_date_change = [changed_by, now, was] unless now == was
      true
    end

    def notify_lock_date_change
      return unless @lock_date_change

      changed_by, now, was = @lock_date_change
      @lock_date_change = nil
      begin
        RestrictMailer.deliver_settings_changes(changed_by, now, was).deliver_later
      rescue StandardError => e
        # Never let a mail problem break saving the settings
        Rails.logger.error "redmine_timelog_restrict_date: could not send lock date change email: #{e.class}: #{e.message}"
      end
    end
  end # module InstanceMethods
end # module RestrictSettingPatch

# Add module to Setting class
Setting.send(:include, RestrictSettingPatch)
