#!/usr/bin/env ruby
# frozen_string_literal: true

# Rewrite the formula for the newest simple_english on rubygems.
# The gem publishes platform builds only, so the formula carries one
# url/sha256 pair per platform and this script rewrites them all.
# Prints nothing and exits 0 when the formula is current. Prints
# "simple-english A -> B" after a rewrite: bump.yml turns that line
# into a branch and a draft pull request. This script never runs git
# or gh.

require "digest"
require "json"
require "net/http"

FORMULA = File.expand_path("../Formula/simple-english.rb", __dir__).freeze
PLATFORMS = %w[arm64-darwin aarch64-linux x86_64-linux].freeze

def rubygems(path)
  JSON.parse(Net::HTTP.get(URI("https://rubygems.org#{path}")))
end

body = File.read(FORMULA)
current = body[/simple_english-(\d+(?:\.\d+)*)-/, 1]
abort "error: the formula declares no simple_english version" if current.nil?

# The versions endpoint lists every platform build; the gems endpoint
# tracks the platformless ruby build, which no longer ships.
versions = rubygems("/api/v1/versions/simple_english.json")
latest = versions.dig(0, "number")
abort "error: rubygems served no version" if latest.to_s.empty?
# The version flows into a shell variable in bump.yml, so it must
# stay a plain number list.
abort "error: rubygems served an odd version: #{latest}" unless
  latest.match?(/\A\d+(?:\.\d+)*\z/)
exit 0 if latest == current

published = versions.select { |v| v["number"] == latest }.map { |v| v["platform"] }
missing = PLATFORMS - published
unless missing.empty?
  abort "error: rubygems published #{latest} for #{published.join(", ")}, " \
        "missing #{missing.join(", ")}"
end

updated = body
PLATFORMS.each do |platform|
  gem_url = "https://rubygems.org/gems/simple_english-#{latest}-#{platform}.gem"
  sha = Digest::SHA256.hexdigest(Net::HTTP.get(URI(gem_url)))
  pair = %r{url "https://rubygems\.org/gems/simple_english-[\d.]+-#{platform}\.gem"\n(\s*)sha256 "[0-9a-f]{64}"}
  match = updated.match(pair)
  abort "error: the formula has no #{platform} pair" if match.nil?
  updated = updated.sub(pair, %Q(url "#{gem_url}") + "\n#{match[1]}sha256 \"#{sha}\"")
end
File.write(FORMULA, updated)
puts "simple-english #{current} -> #{latest}"
