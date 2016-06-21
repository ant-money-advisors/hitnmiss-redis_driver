[![Build Status](https://travis-ci.com/Acornsgrow/hitnmiss-redis_driver.svg?token=GGEgqzL4zt7sa3zVgspU&branch=master)](https://travis-ci.com/Acornsgrow/hitnmiss-redis_driver)
[![Code Climate](https://codeclimate.com/repos/567a3c3140bbd1610000173b/badges/9a198fe818cfd8a5e5d6/gpa.svg)](https://codeclimate.com/repos/567a3c3140bbd1610000173b/feed)
[![Test Coverage](https://codeclimate.com/repos/567a3c3140bbd1610000173b/badges/9a198fe818cfd8a5e5d6/coverage.svg)](https://codeclimate.com/repos/567a3c3140bbd1610000173b/coverage)
[![Issue Count](https://codeclimate.com/repos/567a3c3140bbd1610000173b/badges/9a198fe818cfd8a5e5d6/issue_count.svg)](https://codeclimate.com/repos/567a3c3140bbd1610000173b/feed)

# Hitnmiss::RedisDriver

This gem provides a Redis driver for the
[Hitnmiss](https://github.com/Acornsgrow/hitnmiss) caching library.  It
does this so that people can easily use Redis as a cache store when
using [Hitnmiss](https://github.com/Acornsgrow/hitnmiss).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hitnmiss-redis_driver'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hitnmiss-redis_driver

## Usage

You can use this driver by simply doing the following in your
[Hitnmiss](https://github.com/Acornsgrow/hitnmiss) cache repository.


Register the driver with `Hitnmiss` in your application using the following.

```ruby
Hitnmiss.register_driver(:redis_driver, Hitnmiss::RedisDriver.new("redis://your_redis_urle"))
```

Then use the registered driver in your cache repository as follows.

```ruby
# lib/cache_repositories/most_recent_price.rb
class MostRecentPrice
  include Hitnmiss::Repository

  driver :redis_driver
end
```

Thats it. *Note:* Registering a driver basically creates a singleton version of
that driver instance. So, if you want multiple redis drivers with different
configurations you will need to register multiple instances of the redis driver.

More details about how to set drivers can be found at
[Hitnmiss](https://github.com/Acornsgrow/hitnmiss).

## Contributing

If you are interested in contributing to Hitnmiss. There is a guide (both code
and general help) over in
[CONTRIBUTING](https://github.com/Acornsgrow/hitnmiss-redis_driver/blob/master/CONTRIBUTING.md).

## License

The gem is available as open source under the terms of the [MIT
License](http://opensource.org/licenses/MIT).

