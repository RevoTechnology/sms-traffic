# Smstraffic

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/smstraffic`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'smstraffic'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smstraffic

## Usage


Define settings:

    Smstraffic::SMS.settings = {
      login: login,
      password: password,
      server: server,
      translit: true # default is false
    }

Initialize sms:

    sms = Smstraffic::SMS.new('phone','title','text') # initialize sms
    sms = Smstraffic::SMS.new('phone','title','text',false) # last parameter overrides 'translit' option

Send it and get sent sms id and dispatch code:

    sms.send # send sms. returns sms id or dispatch code if something went wrong
    sms.id # get sms id

Get current sms status and update it:

    sms.status # get sms delivery status
    sms.update_status # updates sms delivery status. returns status or status check response code on error

Get any sms status:

    code, status = Smstraffic::SMS.status(sms_id) # status - sms delivery status unless error or return error

Ex.:

    sms = Smstraffic::SMS.new('79031111111','MyFavouriteCompany','Testing mfms gem')
    sms.send # => 1032
    sms.id # => 1032

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake false` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/smstraffic.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

