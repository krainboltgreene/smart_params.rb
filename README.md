# smart_params

  - [![Build](http://img.shields.io/travis-ci/krainboltgreene/smart_params.svg?style=flat-square)](https://travis-ci.org/krainboltgreene/smart_params)
  - [![Downloads](http://img.shields.io/gem/dtv/smart_params.svg?style=flat-square)](https://rubygems.org/gems/smart_params)
  - [![Version](http://img.shields.io/gem/v/smart_params.svg?style=flat-square)](https://rubygems.org/gems/smart_params)


Work smart, not strong. This gem gives developers an easy to understand and easy to maintain schema for request parameters. Meant as a drop-in replacement for strong_params.


## Using

So lets say you have a complex set of incoming data, say a JSON:API-specification compliant payload that contains the data to create an account on your server. Of course, your e-commerce platform is pretty flexible; You don't stop users from creating an account just because they don't have an email or password. So let's see how this would play out:

``` ruby
class CreateAccountSchema
  include SmartParams

  schema type: Strict::Hash do
    field :data, type: Strict::Hash do
      field :id, type: Coercible::String.optional
      field :type, type: Strict::String
      field :attributes, type: Strict::Hash.optional do
        field :email, type: Strict::String.optional
        field :username, type: Strict::String.optional
        field :name, type: Strict::String.optional
        field :password, type: Strict::String.optional.default { SecureRandom.hex(32) }
      end
    end
    field :meta, type: Strict::Hash.optional
    field :included, type: Strict::Array.optional
  end
end
```

And now using that schema in the controller:

``` ruby
class AccountsController < ApplicationController
  def create
    schema = CreateAccountSchema.new(params)
    # parameters will be a SmartParams::Dataset, which will respond to the various fields you defined

    # Here we're pulling out the id and data properties defined above
    record = Account.create({id: schema.data.id, **schema.data.attributes})

    redirect_to account_url(record)
  end
end
```

Okay, so lets look at some scenarios.

First, lets try an empty payload:

``` ruby
CreateAccountSchema.new({})
# raises SmartParams::Error::InvalidPropertyType, keychain: [:data], wanted: Hash, raw: nil

# You can return the exception directly by providing :safe => false

CreateAccountSchema.new({}, safe: false).payload
# return #<SmartParams::Error::InvalidPropertyType... keychain: [:data], wanted: Hash, raw: nil>
```

Great, we've told SmartParams we need `data` and it enforced this! The exception class knows the "key chain" path to the property that was missing and the value that was given. Lets experiment with that:

``` ruby
CreateAccountSchema.new({data: ""})
# raise SmartParams::Error::InvalidPropertyType, keychain: [:data], wanted: Hash, raw: ""
```

Sweet, we can definitely catch this and give the client a meaningful error! Okay, so to show off a good payload I'm going to do two things: Examine the properties and turn it to a JSON compatible structure. Lets see a minimum viable account according to our schema:


``` ruby
schema = CreateAccountSchema.new({
  data: {
    type: "accounts"
  }
})

schema.payload.data.type
# "accounts"

schema.data.type
# "accounts"

schema.as_json
# {
#   "data" => {
#     "type" => "accounts",
#     "attributes" => {
#       "password" => "1a6c3ffa4e96ad1660cb819f52a3393d924ac20073e84a9a6943a721d49bab38"
#     }
#   }
# }
```

Wait, what happened here? Well we told SmartParams that we're going to want a default password, so it delivered!


### Types

For more information on what types and options you can use, please read: http://dry-rb.org/gems/dry-types/


### Why not strong_params?

Okay so sure strong_params exists and it's definitely better than `attr_accessible` (if you remember that mess), but it often leaves you with code like this:

https://github.com/diaspora/diaspora/blob/develop/app/controllers/users_controller.rb#L140-L158

Which while fine to start with usually evolves into:

https://github.com/discourse/discourse/blob/master/app/controllers/posts_controller.rb#L592-L677

None of this is very maintainable and it's definitely not easy to teach. So my solution is to follow the wake of other libraries: Define a maintainable interface that can be easily tested and easily integrated. It doesn't require wholesale adoption nor is it hard to remove.


### Why not have this in the controller?

First and foremost because the controller already has a job: Determining the course of action for a request. Why complicate it with yet another responsibility? Second because it makes testing that much harder. Instead of just testing the correctness of your schema, you now have to mock authentication and authorization.


### Why not use before_validation or before_save?

Your model is already complex enough and it doesn't need the added baggage of figuring out how to transform incoming data. We learned that lesson the hard way with `attr_accessible`. Further, it's not vary sharable or understandable over large time periods.


## Installing

Add this line to your application's Gemfile:

    gem "smart_params", "2.0.6"

And then execute:

    $ bundle

Or install it yourself with:

    $ gem install smart_params


## Contributing

  1. Read the [Code of Conduct](/CONDUCT.md)
  2. Fork it
  3. Create your feature branch (`git checkout -b my-new-feature`)
  4. Commit your changes (`git commit -am 'Add some feature'`)
  5. Push to the branch (`git push origin my-new-feature`)
  6. Create new Pull Request
