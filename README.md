# kemal-crustache-example

Simple wiki with kemal and crustache

Demo: <https://kemal-crustache-example.herokuapp.com/>

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

## Install and Run

```console
$ git clone https://github.com/MakeNowJust/kemal-crustache-example

$ cd kemal-crustache-example

Resolve dependencies
$ crystal deps

Build executable
development build, loading view files dynamically
$ crystal build src/kemal-crustache-example.cr

release build, compiling and bundled view files with executable
$ crystal build --release src/kemal-crustache-example.cr

Run!!
$ ./kemal-crustache-example && open http://localhost:3000/
```

## Contributing

1. Fork it ( https://github.com/MakeNowJust/kemal-crustache-example/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [@MakeNowJust](https://github.com/MakeNowJust) TSUYUSATO Kitsune - creator, maintainer
