#!/usr/bin/env coffee

fs   = require 'fs'
path = require 'path'

# Update the require paths with ./lib
require.paths.unshift "#{__dirname}/lib"

Duiker = require 'duiker'

duiker = new Duiker.Server  __dirname + '/layout',  __dirname + '/static'

# Parse through configurator/injector
(require './config') duiker