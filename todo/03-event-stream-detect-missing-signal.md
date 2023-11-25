# Issue 3 - Detect missing data

Requires `01-event-stream-not-implemented` to be completed.

After a stream has been created it expects to get data on a periodic
interval. The interval is not explicitly set but must be detected
by application based on timing of inputs.

After a minimum of two events have been received the next event must
be received within 1.5x of that interval. If no event has been received
a error must be added to the output of the stream.