# Omniauth::Mixin

OmniAuth OAuth2 strategy for Mixin authentication.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-mixin'
```

And then execute:

```bash
bundle install
```

## Usage

```ruby
use OmniAuth::Builder do
  provider :mixin, ENV['MIXIN_CLIENT_ID'], ENV['MIXIN_CLIENT_SECRET']
end
```

## Configuration

You need to register your application in Mixin Developer Dashboard to get the client ID and client secret.

Required parameters:

- `client_id`: Your Mixin application's client ID
- `client_secret`: Your Mixin application's client secret

### Auth Hash

Here's an example of the Auth Hash available in `request.env['omniauth.auth']`:

```ruby
{
  "provider"=>"mixin",
  "uid"=>"1234567890",
  "info"=>{"name"=>"John Doe", "email"=>"john.doe@example.com", "nickname"=>"john_doe"},
  "extra"=>{"raw_info"=>{"user_id"=>"1234567890", "full_name"=>"John Doe", "identity_number"=>"1234567890", "avatar_url"=>"https://example.com/avatar.png"}}
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/an-lee/omniauth-mixin>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/an-lee/omniauth-mixin/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Omniauth::Mixin project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/an-lee/omniauth-mixin/blob/main/CODE_OF_CONDUCT.md).
