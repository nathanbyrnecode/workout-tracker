# Active workout recovery

The earlier plan remains applicable: workout, exercise and set mutations already
persist to Supabase, but the app did not recover active state after process death.
No database migration is required by the schema checked into this repository.

After session restoration or Google/Apple sign-in, the app reads only the latest
workout belonging to the signed-in user, ordered by start time and then ID.
It resumes that workout only if its end time is null and its start time is less
than 12 hours ago. A finished, expired, missing or future-dated latest workout
does not cause the app to look for an older unfinished workout.

Recovery preserves IDs, completed exercises, the active exercise, saved sets,
and original start/end timestamps. Sets are ordered by set number and then ID.
Elapsed timers include time spent with the app closed and update immediately
on foregrounding. No background timer service is necessary.

Workout actions stay unavailable during recovery. Failed queries time out after
15 seconds and show a retry action. Recovery never creates, deletes, or finishes
workout rows. Unfinished workouts are excluded from history, including expired
ones. A response arriving after sign-out/reset cannot repopulate the next user's
state. Invalid child data causes a recoverable error instead of partial recovery.

This is Supabase-only recovery: it requires connectivity and restores data whose
save has reached Supabase. Unsubmitted text fields and offline edits are outside
this feature. The 12-hour limit is measured from workout start, not app closure.

## Verification

Automated tests cover the age boundary, time zones, empty workouts/exercises,
completed and active exercise mapping, set order, scoped latest-only queries,
failed recovery/retry, account/reset races, continued set edits, duplicate start
prevention, history filtering, and loading/retry UI.

For a final device check against the configured Supabase project:

1. Sign in, start a workout, complete an exercise, then start another and save sets.
2. Force-close the app and reopen while the workout is under 12 hours old.
3. Verify the same workout and exercises resume, sets retain their order, and
   workout/exercise timers include elapsed time while the app was closed.
4. Continue adding/removing sets, end the exercise and workout, then reopen.
   Verify the completed workout appears in history and does not resume.
5. Reopen offline with an unfinished workout; confirm recovery offers retry and
   blocks starting a duplicate. Reconnect and retry.
6. Verify a workout at least 12 hours old does not resume or appear in history.

The configured Supabase project was restored on 30 September 2026 and reported
`ACTIVE_HEALTHY`. Its authentication API responded successfully, database queries
succeeded, and the `workouts`, `exercises`, and `exercise_sets` tables were present.
SDK queries are verified with mocked HTTP responses; the authenticated device
check above remains necessary to confirm the full recovery flow against the
deployed database.
