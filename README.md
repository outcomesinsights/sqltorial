# SQLtorial

Create your own SQL Tutorials with SQLtorial.


## Motivation

SQLtorial is a gem I cooked up because I was frequently demonstrating how to write certain queries or how to explore data in certain databases.  Generally, I wanted each example SQL statement to have a bit of explanation about how it works or what I’m looking for, followed by the query itself, followed by the results that SQL statement generated.

So I decided to write SQLtorial, a command that will process all files ending in \*.sql and generate a Markdown document with all the examples concatenated together.

The gem will process each .sql statement in the following manner:
- The first line is considered the title for the entire example
- Comments placed above a SQL query will be run through a Markdown formatter and placed as formatted text before the SQL query
- SQL queries must end with a ;
- SQL queries are run through [pgFormatter](https://github.com/darold/pgFormatter) to create a consistent presentation for queries
- Results from the query are shown in a table after the query.  Only the first ten results are shown.

See the examples directory.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sqltorial'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sqltorial

## Usage

Create a directory for your SQL examples.  Create at least one file ending with `.sql` and add comments and example queries as you see fit.

When you are ready to execute your examples against a database and compile the examples into a markdown file, create a configuration file following the instructions in the [sequelizer](https://github.com/outcomesinsights/sequelizer) README.

Once your sequelizer configuration is set up, run

    $ bundle exec sqltorial

The `sqltorial` command will convert each `.sql` file into a markdown and concatenate the files into a single markdown file called `output.md`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/outcomesinsights/sqltorial/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Thanks

- [Outcomes Insights, Inc.](http://outins.com)
    - Many thanks for allowing me to release a portion of my work as Open Source Software!
- [knitr](http://yihui.name/knitr/)
    - Thanks for the inspiration!

## License
Released under the MIT license, Copyright (c) 2015 Outcomes Insights, Inc.
