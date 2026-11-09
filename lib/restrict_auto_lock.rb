# Automatic lock date: once a set number of days of the new month have
# passed, the lock date is moved to the last day of a month in the past
# (e.g. the last day of last month). This puts the lock back on the billing
# period close date if someone moved it back and forgot to restore it.
#
# Run nightly from cron with:
#   bundle exec rake redmine:timelog_restrict_date:auto_lock RAILS_ENV=production
module RestrictAutoLock
  SETTING = 'plugin_redmine_timelog_restrict_date'.freeze
  CHANGED_BY_KEY = :restrict_timelog_lock_changed_by
  CHANGED_BY_NAME = 'Automatic nightly lock'.freeze

  MIN_DAY = 0
  MAX_DAY = 28
  MAX_MONTHS_BACK = 12

  # Returns the lock date the settings ask for on the given day.
  #
  # after_day:   number of days of the new month that must pass first
  #              (0 = from the 1st of the month)
  # months_back: 1 = last day of last month, 2 = last day of the month
  #              before that, and so on
  #
  # Until the grace period is over the previous period stays locked: with
  # after_day 5 and months_back 1 the target is 30 Sep from 1 to 5 Nov and
  # 31 Oct from 6 Nov.
  def self.target_date(today, after_day, months_back)
    months = months_back
    months += 1 unless today.day > after_day
    today.beginning_of_month.prev_month(months).end_of_month
  end

  # Reads and validates the auto lock settings. Returns
  # [after_day, months_back], or nil if auto lock is off or misconfigured.
  def self.config(settings = Setting.plugin_redmine_timelog_restrict_date)
    return nil unless settings.is_a?(Hash)
    return nil unless %w(1 true).include?(fetch(settings, 'auto_lock_enabled').to_s)

    after_day = Integer(fetch(settings, 'auto_lock_after_day').to_s, 10)
    months_back = Integer(fetch(settings, 'auto_lock_months_back').to_s, 10)
    return nil unless after_day.between?(MIN_DAY, MAX_DAY)
    return nil unless months_back.between?(1, MAX_MONTHS_BACK)

    [after_day, months_back]
  rescue ArgumentError, TypeError
    nil
  end

  # Moves the lock date forward to the target date if it is blank or
  # earlier than the target. A lock date that is already later is left
  # alone: this job only ever locks more, never unlocks.
  #
  # Returns a short message describing what happened.
  def self.run!(today = Date.today)
    settings = Setting.plugin_redmine_timelog_restrict_date
    conf = config(settings)
    return 'Auto lock is disabled or not configured; nothing to do.' unless conf

    target = target_date(today, *conf)
    current = RestrictTimeEntryPatch.lock_date
    if current && current >= target
      return "Lock date #{current} is already on or after #{target}; nothing to do."
    end

    with_changed_by(CHANGED_BY_NAME) do
      Setting.plugin_redmine_timelog_restrict_date = settings.merge('lock_date' => target.to_s)
    end
    "Lock date changed from #{current || '(none)'} to #{target}."
  end

  # Name shown in the change email for saves made inside the block
  def self.with_changed_by(name)
    previous = Thread.current[CHANGED_BY_KEY]
    Thread.current[CHANGED_BY_KEY] = name
    yield
  ensure
    Thread.current[CHANGED_BY_KEY] = previous
  end

  def self.changed_by
    Thread.current[CHANGED_BY_KEY]
  end

  def self.fetch(settings, key)
    settings[key] || settings[key.to_sym]
  end
  private_class_method :fetch
end
