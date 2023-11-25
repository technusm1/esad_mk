# Issue 2 - Timeout an event stream in case of no new events

Requires `01-event-stream-not-implemented` to be completed.

When a stream is created it should have a user configurable timer
for when it should gracefully shutdown itself in case of no data.