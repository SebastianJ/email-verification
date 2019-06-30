# Email::Verification

Email::Verification is a gem that helps out with retrieving emails and parsing out confirmation/verification codes.

Currently supported providers are Gmail and Hotmail but adding custom providers is fairly straightforward.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'email-verification'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install email-verification

## Usage

Email::Verification expects a settings hash in the following format:

settings = {
  address: "confirmation@foo.com",
  from:    "Confirmation",
  subject: /Confirm your email!/i,
  regex:   /<a href=['"](?<match>[^"]*)['"]>\s*Click here\s*<\/a>/i
}

Note that the regex must present a :match capture group!

Then the client is invoked using:

Email::Verification.retrieve_verification_code(email: 'email.address@gmail.com', password: 's0mEpasSwOrD', settings: settings)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SebastianJ/email-verification. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Email::Verification project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/SebastianJ/email-verification/blob/master/CODE_OF_CONDUCT.md).
