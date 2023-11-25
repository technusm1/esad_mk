# Issue 1 - Event Stream Not Implemented

The EventStream module is not complete.

An stream is a set of input and output events. A set of functions defined
in configuration should, given the existing state, be used to fold over a
sequence of events and produce a new state and a new sequence of events that
can be read by another stream.

 * [ ] Store and retrieve state of individual streams
 * [ ] Allow fetching the current input/outputs of a stream
 * [ ] Calculate the hourly error rate
  

Calling `input/1` should automatically send input to the stream, if the stream
does not exists it should be automatically be created.


The `metric!/1` function is expected to return a `StreamState`
structure with `output`, `input` and `hourly_error_rate` set.

The `stop/1` function should force the EventStream to stop accepting new events
and gracefully stop.