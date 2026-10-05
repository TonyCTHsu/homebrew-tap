#!/usr/bin/env ruby
# frozen_string_literal: true

# Rewrite the formula for the newest simple_english on rubygems.
# Bumps the gem url and sha256 only. Prints nothing and exits 0 when
# the formula is current. Prints "simple-english A -> B" after a
# rewrite: bump.yml turns that line into a branch and a draft pull
# request. This script never runs git or gh.

require "digest"
require "json"
require "net/http"

FORMULA = File.expand_path("../Formula/simple-english.rb", __dir__).freeze

def rubygems(path)
  JSON.parse(Net::HTTP.get(URI("https://rubygems.org#{path}")))
end

body = File.read(FORMULA)
current = body[/simple_english-(\d+(?:\.\d+)*)\.gem/, 1]
latest = rubygems("/api/v1/gems/simple_english.json")["version"]
abort "rubygems served no version" if latest.to_s.empty?
# The version flows into a shell variable in bump.yml, so it must
# stay a plain number list.
abort "rubygems served an odd version: #{latest}" unless
  latest.match?(/\A\d+(?:\.\d+)*\z/)
exit 0 if latest == current

gem_url = "https://rubygems.org/gems/simple_english-#{latest}.gem"
sha = Digest::SHA256.hexdigest(Net::HTTP.get(URI(gem_url)))
# The formula's own sha256 is the first one in the file. The
# resource blocks come after it.
updated = body
          .sub(%r{url "https://rubygems\.org/gems/simple_english-[\d.]+\.gem"},
               %Q{url "#{gem_url}"})
          .sub(/sha256 "[0-9a-f]{64}"/, %Q{sha256 "#{sha}"})
File.write(FORMULA, updated)
puts "simple-english #{current} -> #{latest}"
