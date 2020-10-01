# Xlog v0.1.6

Xlog - awesome logger for your Rails app. Logs everything you need in well-formatted view with timestamp, caller path and tags.

## Usage

### `.info`

Log any info with `.info` method

```ruby
Xlog.info('Some info text') # [2019-04-30 12:29:13 UTC] [ArtilesController.show] [info] Message: Some info text
```


### `.warn`

Log important info with `.warn` method

```ruby
Xlog.warn('Validation failed') # [2019-04-30 12:29:13 UTC] [ArticlesController.update] [warn] Message: Validation failed
```

### `.error` and `.and_raise_error`

Xlog has awesome `.error` and `.and_raise_error` methods

```ruby
def index
  10 / 0  
  @orders = Order.all  
  rescue StandardError => e
    Xlog.and_raise_error(e, data: { params: params }, message: 'Some message text here')
end
```

...and the output

```
[2019-04-30 11:48:33 UTC] [Admin::OrdersController.index] [error] ZeroDivisionError: divided by 0. 
  | Message: Some message text here
  | Data: {:params=><ActionController::Parameters {"controller"=>"admin/orders", "action"=>"index"} permitted: false>} 
  | Error backtrace: 
  | /home/me/test_app/app/controllers/admin/orders_controller.rb:7:in `/'
  | /home/me/test_app/app/controllers/admin/orders_controller.rb:7:in `index'
```

The only difference between `Xlog.error` and `Xlog.and_raise_error` is that second one raises error after logging.

Log any info with `.info` method

Xlog automatically defines Rails application name and environment.
It writes logs into `log/xlog_[environement].log`

### Data

Any log method (`.info`, `.warn`, `.error`, `.and_raise_error`) supports `data: ` - named argument. Put any object as `data: my_object`
and it will be logged as "inspected" object.


```ruby
Xlog.info('test info', data: { my: 'hash' })
# [2020-10-01 15:41:45 +0300] [(irb):4:in `irbBinding'.irb_binding] [info] Message: test info
#   | Data: {:my=>"hash"}

```

### Tags

As far as `.tag_logger` is deprecated as it's not thread-safe, the new tags mechanism is presented.
Any log method (`.info`, `.warn`, `.error`, `.and_raise_error`) supports `tag: ` - named argument

```ruby
Xlog.info('Some info text', tags: 'my_custom_tag') # [2019-04-30 12:29:13 UTC] [ArtilesController.show] [info] [my_custom_tag] Message: Some info text
Xlog.warn('Validation failed', tags: %w[validation input_error]) # [2019-04-30 12:29:13 UTC] [ArticlesController.update] [warn] [validation] [input_error] Message: Validation failed
Xlog.warn(error, tags: %w[fatal]) # [2019-04-30 12:29:13 UTC] [ArticlesController.update] [error] [fatal] Message: Zero division error
```


### `.tag_logger` [DEPRECATED]

```ruby
Xlog.tag_logger('custom_tag')
Xlog.info('Some text') # [2019-04-30 12:29:13 UTC] [ArtilesController.show] [info] [custom_tag] Message: Some info text
```

Clear tags with: [DEPRECATED]

```ruby
Xlog.clear_tags
```

## Middleware

From version 0.1.4 Xlog could be used as Rails middleware. It catches `StandardError` using `Xlog.and_raise_error`.

```ruby
# /config/application.rb
 module MyApp
   class Application < Rails::Application
     # some configs...

     config.middleware.use Xlog::Middleware
   end
 end
```

## Configuration

Xlog is ready to use right out of the box, but it's possible to reconfigure default logger. Default logger is simple `Logger.new`. Add this code to `config/initializers/xlog.rb` and set any custom logger you want.

```ruby
Xlog.configure do |config|
  config.custom_logger = Logger.new(STDOUT) # or Logger.new('foo.log', 10, 1024000) or any other
end
```

It's possible to set third-party logger like Logentries(r7rapid)

```ruby
require 'le'

Xlog.configure do |config|
  config.custom_logger = Le.new(logentries_key, 'eu', tag: true)
end
```

Look [here](https://ruby-doc.org/stdlib-2.4.0/libdoc/logger/rdoc/Logger.html) to know more about `Logger` configuration.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'xlog'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install xlog

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/coaxsoft/xlog. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Xlog project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/coaxsoft/xlog/blob/master/CODE_OF_CONDUCT.md).

## Idea
Initially designed and created by [Orest Falchuk (OrestF)](https://github.com/OrestF)