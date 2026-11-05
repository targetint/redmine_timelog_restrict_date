# redmine_timelog_restrict_date

Stops time from being logged, edited or deleted on or before a lock date
(for example the close date of the last billing period). Admins are emailed
whenever the lock date changes.

## Settings

Administration → Plugins → Redmine Timelog Restrict Date plugin → Configure

- **Lock Date for Time Log**: time entries dated on or before this date can't
  be created, edited or deleted. Leave it empty to lock nothing.
- **Move lock date automatically**: every night the lock date is moved
  forward to the end of a past month:
  - **Lock up to**: last day of last month, last day of 2 months ago, and so on.
  - **After day of the month**: how many days of the new month to wait before
    locking the period that just ended. 0 locks it from the 1st.

  The automatic job only moves the lock date forward, never back. If someone
  moves it back so people can fix old entries and forgets to restore it, it is
  put back the next night.

  Example: with "Last day of last month" and day 5, from 1 to 5 November the
  lock date is kept at 30 September at least. On 6 November it moves to
  31 October.

## Nightly job

Redmine has no built-in scheduler, so the automatic lock runs from cron.
Add this to the crontab of the user that runs Redmine to run it at midnight:

```
0 0 * * * cd /path/to/redmine && bundle exec rake redmine:timelog_restrict_date:auto_lock RAILS_ENV=production >> log/timelog_auto_lock.log 2>&1
```

The task uses the server's local date. It is safe to run more than once a day,
and it does nothing when automatic locking is off or the lock date is already
on or after the target.

To see what it would do on a particular day, run it with `DATE=YYYY-MM-DD`.
This does change the setting, so try it on a test instance.
