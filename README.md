Resque-timed-round-robin
==================

A plugin for Resque that implements round-robin behavior for workers.

Resque 2.6.0 is the only requirement.

The standard behavior for Resque workers is to pull a job off a queue,
and continue until the queue is empty.  Once empty, the worker moves
on to the next queue (if available).

This gem changes that behavior and will work a single queue for a specified amount of time (default is 60s) before rotating to a new queue.

## Installation

Add this line to your application's Gemfile:

    gem 'resque-round-robin'

And then execute:

    bundle

## Usage

Nothing special.  This gem monkey-patches things so this is automatic.

Set the `RESQUE_SLICE_LENGTH` environment variable to specify the amount of time (in seconds) to work a single queue before rotating.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
