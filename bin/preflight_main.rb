#!/usr/bin/env ruby
# frozen_string_literal: true

require "preflight"

path = nil
rpc = false
strict = false
argv = ARGV.dup
while argv.any?
  a = argv.shift
  case a
  when "--path"
    path = argv.shift
  when "--rpc-ping"
    rpc = true
  when "--strict"
    strict = true
  when "-h", "--help"
    puts "Usage: vyrail-preflight [--path DIR] [--rpc-ping] [--strict]"
    exit 0
  else
    warn "Unknown arg: #{a}"
    exit 2
  end
end
exit Vyrail::Preflight.report(path: path, rpc: rpc, strict: strict)
