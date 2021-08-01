# Logging your [Grape](https://github.com/ruby-grape/grape) apps

Logs:
  * Request path
  * Parameters
  * Endpoint class name and handler
  * Response status
  * Duration of the request
  * Exceptions
  * Error responses from `error!`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'grape', '>= 0.17'
gem 'grape-middleware-logy'
```

## Usage
```ruby
require 'grape'
require 'grape/middleware/logy'

class API < Grape::API
  # @note Make sure this is above your first +mount+
  insert_after Grape::Middleware::Formatter, Grape::Middleware::Logy
end
```

Server requests will be logged to STDOUT by default.

## Example output
Request
```
I, [2021-08-02T02:40:06.790675 #496952]  INFO -- : Started POST "/api/v1/open/user_registration" at 2021-08-01 19:40:06 UTC
I, [2021-08-02T02:40:06.790784 #496952]  INFO -- : Processing by Web::V1::Opens::Resource/open/user_registration
I, [2021-08-02T02:40:06.790918 #496952]  INFO -- :   Parameters: {"name"=>"haidar adi", "email"=>"example@gmail.com", "username"=>"haidar", "status"=>"Active"}
I, [2021-08-02T02:40:06.791225 #496952]  INFO -- :   Headers: {"Accept"=>"*/*", "Accept-Encoding"=>"gzip, deflate, br", "Cache-Control"=>"no-cache", "Connection"=>"keep-alive", "Host"=>"localhost:3000", "Postman-Token"=>"d8d0370a-f5e5-4ad1-a86c-00483fe15e59", "User-Agent"=>"PostmanRuntime/7.28.0", "Version"=>"HTTP/1.1"}
```
Respose
```
W, [2021-08-02T02:40:08.050482 #496952]  WARN -- : 💥 ActiveRecord::RecordInvalid: Validation failed: Email is invalid, Phone has already been taken, Username has already been taken, Username has been registered, Phone has been registered
I, [2021-08-02T02:40:08.050710 #496952]  INFO -- : 
I, [2021-08-02T02:40:08.051080 #496952]  INFO -- : Completed 422 in 1.2627 s (ActiveRecord: 0.7631 s | View: 0.4995 s)
I, [2021-08-02T02:40:08.051145 #496952]  INFO -- : 

```


## Customization

The middleware logger can be customized with the following options:

* The `:logger` option can be any object that responds to `.info(String)`
* The `:filter` option can be any object that responds to `.filter(Hash)` and returns a hash.
* The `:headers` option can be either `:all` or array of strings.
    + If `:all`, all request headers will be output.
    + If array, output will be filtered by names in the array. (case-insensitive)

For example:

```ruby
insert_after Grape::Middleware::Error, Grape::Middleware::Logger, {
  logger: Logger.new(STDERR),
  condensed: true,
  filter: Class.new { def filter(opts) opts.reject { |k, _| k.to_s == 'password' } end }.new,
  headers: %w(version cache-control)
}
```
Register Exception Statues
```ruby
Grape::Middleware::Logy.register_status_exception do |status|
  status.register "ActiveRecord::RecordNotFound", 404
  status.register "Grape::Exceptions::ValidationErrors", 422
  status.register "JWT::DecodeError", 403
  status.register 'JWT::ExpiredSignature', 403
  status.register "ActiveRecord::RecordInvalid", 422
end
```

## Using Rails?
`Rails.logger` and `Rails.application.config.filter_parameters` will be used automatically as the default logger and
param filterer, respectively. This behavior can be overridden by passing the `:logger` or
`:filter` option when mounting.

You may want to disable Rails logging for API endpoints, so that the logging doesn't double-up. You can achieve this
by switching around some middleware. For example:

```ruby
# config/application.rb
config.middleware.swap 'Rails::Rack::Logger', 'SelectiveLogger'

# config/initializers/selective_logger.rb
class SelectiveLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'] =~ %r{^/api}
      @app.call(env)
    else
      Rails::Rack::Logger.new(@app).call(env)
    end
  end
end
```

## Rack

If you're using the `rackup` command to run your server in development, pass the `-q` flag to silence the default rack logger.

## Credits

Big thanks to [grape-middleware-logger](https://github.com/aserafin/grape_logging), because this gem comes from the gem he made.

## Contributing

1. Fork it ( https://github.com/9edang/grape-middleware-logy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request