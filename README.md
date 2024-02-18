# smart_params

Work smart, not strong. This gem gives developers an easy to understand and easy to maintain schema for request parameters. Meant as a drop-in replacement for strong_params.


## Using

So lets say you have a complex set of incoming data, say a JSON:API-specification compliant payload that contains the data to create an account on your server. Of course, your e-commerce platform is pretty flexible; You don't stop users from creating an account just because they don't have an email or password. So let's see how this would play out:

``` ruby
module AccountSchema
  include SmartParams::FluentLanguage

  schema do |root|
    field root, :data, subschema: true do |data|
      field data, :id, type: Coercible::String.optional
      field data, :type, type: Strict::String
      field data, :attributes do |attributes|
        field attributes, :email, type: Strict::String
        field attributes, :username, type: Strict::String.optional
        field attributes, :name, type: Strict::String.optional
        field attributes, :password, type: Strict::String.default { SecureRandom.hex(32) }.optional
      end
    end
    field :meta, Strict::Hash.optional
    field :included, type: Strict::Array.optional
  end
end
```

And now using that schema in the controller:

``` ruby
class AccountsController < ApplicationController
  def create
    payload = SmartParams.from(AccountSchema, params)
    # parameters will be a SmartParams::Dataset, which will respond to the various fields you defined

    # Here we're pulling out the id and data properties defined above
    record = Account.create({id: payload[:data][:id], **payload[:data][:attributes]})

    redirect_to account_url(record)
  end
end
```

Okay, so lets look at some scenarios.

First, lets try an empty payload:

``` ruby

SmartParams.from(AccountSchema, {}).payload
# returns [InvalidPropertyTypeException | MissingPropertyException]

SmartParams.validate!(AccountSchema, {})
# raises SmartParams::InvalidPayloadException(failures: [InvalidPropertyTypeException | MissingPropertyException])
```

Great, we've told SmartParams we need `data` and it enforced this! The exception class knows the "key chain" path to the property that was missing and the value that was given. Lets experiment with that:

``` ruby
SmartParams.from(AccountSchema, {data: ""})
# returns [MissingPropertyException(path: [:data], last: {data: ""})]
```

Sweet, we can definitely catch this and give the client a meaningful error! Okay, so to show off a good payload I'm going to do two things: Examine the properties and turn it to a JSON compatible structure. Lets see a minimum viable account according to our schema:


``` ruby
payload = SmartParams.from(AccountSchema, {
  data: {
    type: "accounts",
    attributes: {
      email: "kurtis@example.com"
    }
  }
})

payload[:data][:type]
# "accounts"

payload.as_json
# {
#   "data" => {
#     "type" => "accounts",
#     "attributes" => {
#       "email" => "kurtis@example.com",
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

https://github.com/diaspora/diaspora/blob/744f5449fb7bfd1ac2bfd50d2e157d97c77a3bca/app/controllers/users_controller.rb#L132

Which while fine to start with usually evolves into:

https://github.com/discourse/discourse/blob/82a56334a3099297d14e1a0355e8ad19e61631e3/app/controllers/application_controller.rb#L565

None of this is very maintainable and it's definitely not easy to teach. So my solution is to follow the wake of other libraries: Define a maintainable interface that can be easily tested and easily integrated. It doesn't require wholesale adoption nor is it hard to remove.


### Why not have this in the controller?

First and foremost because the controller already has a job: Determining the course of action for a request. Why complicate it with yet another responsibility? Second because it makes testing that much harder. Instead of just testing the correctness of your schema, you now have to mock authentication and authorization.


### Why not use before_validation or before_save?

Your model is already complex enough and it doesn't need the added baggage of figuring out how to transform incoming data. We learned that lesson the hard way with `attr_accessible`. Further, it's not vary sharable or understandable over large time periods.


## Installing

Run this command:

    $ bundle add smart_params

Or install it yourself with:

    $ gem install smart_params


## Contributing

  1. Read the [Code of Conduct](/CONDUCT)
  2. Fork it
  3. Create your feature branch (`git checkout -b my-new-feature`)
  4. Test your code: `rake spec`
  5. Commit your changes (`git commit -am 'Add some feature'`)
  6. Push to the branch (`git push origin my-new-feature`)
  7. Create new Pull Request
