# Gitable

[![Gem Version](https://badge.fury.io/rb/gitable.png)][gem]
[![Build Status](https://travis-ci.org/martinemde/gitable.png?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/martinemde/gitable.png?travis)][gemnasium]
[![Code Climate](https://codeclimate.com/github/martinemde/gitable.png)][codeclimate]

[gem]: https://rubygems.org/gems/gitable
[travis]: https://travis-ci.org/martinemde/gitable
[gemnasium]: https://gemnasium.com/martinemde/gitable
[codeclimate]: https://codeclimate.com/github/martinemde/gitable

## A git remote URI parser backed by Addressable

Works with any valid Git URI as described in the git docs.

`git clone` accepts many different URI formats for remote repositories.
Unfortunately, not all of them are actually URIs. Addressable is able to parse
many of the standard URIs accepted by git, and this library extends Addressable
to handle the non-standard scp-style repository locations.

Gitable provides a uniform way to parse a git repository location and determine
information about the project. Gitable can determine whether or not a repository
will require authentication before actually using `git` to clone the repository.
Gitable is also very useful for determining equivalence between git remotes that
are entered slightly differently (e.g. trailing slashes, uri scheme, uri format)

This is *not* a general substitute for Addressable, but rather a specific solution
for accepting git repository addresses and confirming validity and authentication.
Gitable *should not* be used as a general URI parser for anything other than git
repository locations.

Many thanks to [Bob Aman (sporkmonger)](https://github.com/sporkmonger) for his
work on Addressable and for his feedback on this gem.

## Example

    require 'gitable/uri'
    uri = Gitable::URI.parse('git@github.com:martinemde/gitable.git')

    uri.path   # => 'martinemde/gitable.git'
    uri.user   # => 'git'
    uri.host   # => 'github.com'

Maintain the same url format.

    uri.to_s   # => 'git@github.com:martinemde/gitable.git'

Uses ssh?

    uri.ssh?   # => true

SCP format?

    uri.scp?   # => true

If it can't guess the name, you named your repository wrong.

    uri.project_name   # => 'gitable'

Will this uri require authentication?

    uri.authenticated? # => true

Will I have to interactively type something into git (a password)?

    uri.interactive_authenticated? # => false

Matching public to private git uris?

    uri.equivalent?('git://github.com/martinemde/gitable.git') # => true
    uri.equivalent?('https://martinemde@github.com/martinemde/gitable.git') # => true

Link to the web page for a project (github)

    if uri.github?
      uri.to_web_uri # => <Addressable::URI https://github.com/martinemde/gitable>
    end

Inherited from Addressable::URI

    uri.kind_of?(Addressable::URI)   # => true

Teenage Mutant Ninja Urls (mutable uris like Addressable, if you want)

    uri.path = 'someotheruser/gitable.git'
    uri.basename = 'umm.git'
    uri.to_s    # => 'git@github.com:someotheruser/umm.git'

## `Gitable::URI.heuristic_parse`

`Gitable::URI.heuristic_parse` can be used to accept user input.

Currently this supports the mistake of copying the url bar instead of the git
uri for a few of the popular git webhosts. It also runs through Addressable's
`heuristic_parse` so it will correct some poorly typed URIs.

    uri = Gitable::URI.heuristic_parse('http://github.com:martinemde/gitable')
    uri.to_s   # => 'git://github.com/martinemde/gitable.git'

`heuristic_parse` is currently very limited. If the url doesn't end in .git, it
switches http:// to git:// and adds .git to the basename.
This works fine for github.com and gitorious.org but will happily screw up other
URIs.

## Copyright

Copyright (c) 2014 Martin Emde. See LICENSE for details.
