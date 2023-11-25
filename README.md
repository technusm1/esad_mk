# Elixir Dummy Signal Analyzer

Collect and tag data from remote APIs and detect anamolies.

Works by setting up a polling service to a remote API and processing the
incoming data locally in a stream. Any anamolies are made available as
new streams.

The following signals can be detected:

 * Value differs by more than ±40%
 * Value above/below threshold for `n` periods
 * Missing data


## Getting Started

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
