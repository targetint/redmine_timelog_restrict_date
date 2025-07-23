module RestrictSettingPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)
    base.class_eval do
      before_save :check_restrict_date, if: Proc.new{|s| s.name == 'plugin_redmine_timelog_restrict_date' }
    end
  end

  module InstanceMethods

    def check_restrict_date
      _v = value[:lock_date]
      _was = YAML.safe_load(self.value_was, permitted_classes: Rails.configuration.active_record.yaml_column_permitted_classes)[:lock_date]
      unless _v == _was
        RestrictMailer.deliver_settings_changes(User.current, _v, _was).deliver_now
      end
    end      
  end # module InstanceMethods
end # module MultiSenderMailerPatch

# Add module to Mailer class
Setting.send(:include, RestrictSettingPatch)
