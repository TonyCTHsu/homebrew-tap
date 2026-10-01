#!/usr/bin/env ruby
# frozen_string_literal: true

# Open a pull request when rubygems serves a newer simple_english
# than the formula pins. Bumps the gem url and sha256 only: the
# resource gems drift rarely, and ci catches drift by failing to
# install or test. Exits 0 when the formula is current or a bump
# pull request already exists.

require "digest"
require "json"
require "net/http"
require "open-uri"

FORMULA = File.expand_path("../Formula/simple-english.rb", __dir__)

def rubygems(path)
  JSON.parse(Net::HTTP.get(URI("https://rubygems.org#{path}")))
end

body = File.read(FORMULA)
current = body[/simple_english-(\d+(?:\.\d+)*)\.gem/, 1]
latest = rubygems("/api/v1/gems/simple_english.json")["version"]
abort "rubygems served no version" if latest.to_s.empty?
exit 0 if latest == current

branch = "bump/v#{latest}"
open_prs = `gh pr list --repo #{ENV.fetch("GITHUB_REPOSITORY", "TonyCTHsu/homebrew-tap")} --head #{branch} --state open`
exit 0 unless $?.success? && open_prs.strip.empty?

gem_url = "https://rubygems.org/gems/simple_english-#{latest}.gem"
sha = Digest::SHA256.hexdigest(URI.open(gem_url).read)

updated = body
  .sub(%r{url "https://rubygems\.org/gems/simple_english-[\d.]+\.gem"},
    %(url "#{gem_url}"))
  # The formula's own sha256 is the first one in the file. The
  # resource blocks come after it.
  .sub(/sha256 "[0-9a-f]{64}"/, %(sha256 "#{sha}"))
File.write(FORMULA, updated)

system("git", "checkout", "-q", "-b", branch) || abort("cannot branch")
system("git", "add", FORMULA) || abort("cannot stage")
system("git", "commit", "-q", "-m", "simple-english #{current} -> #{latest}") ||
  abort("cannot commit")
system("git", "push", "-q", "origin", branch) || abort("cannot push")
system("gh", "pr", "create", "--fill", "--draft") || abort("cannot open the pull request")
puts "simple-english #{current} -> #{latest}: pull request open"
