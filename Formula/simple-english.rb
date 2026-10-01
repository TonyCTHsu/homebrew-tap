class SimpleEnglish < Formula
  desc "Lint Markdown prose with the SimpleEnglish Plain-mode rules"
  homepage "https://github.com/TonyCTHsu/simple-english"
  url "https://rubygems.org/gems/simple_english-0.3.0.gem"
  sha256 "cc69dd63a84113f4218387760d71c0f40347033361c656b152bc3c5d8baede67"
  license "MIT"

  depends_on "openjdk@17"
  depends_on "ruby"

  livecheck do
    url "https://rubygems.org/api/v1/gems/simple_english.json"
    regex(/"version":\s*"([^"]+)"/)
  end

  # Prebuilt darwin gems. The source (-ruby) gem needs the rb_sys
  # build gem and compiles every tree-sitter grammar: far too slow for
  # an install. ponytail: darwin only. Linux support needs the -ruby
  # gem plus an rb_sys resource.
  on_arm do
    resource "tree_sitter_language_pack" do
      url "https://rubygems.org/gems/tree_sitter_language_pack-1.20.0-arm64-darwin.gem"
      sha256 "b5e6899bedaa750f030a12bfd5db96fe9ed6a0617eee37119c0ffafd49d5baae"
    end
  end
  on_intel do
    resource "tree_sitter_language_pack" do
      url "https://rubygems.org/gems/tree_sitter_language_pack-1.20.0-x86_64-darwin.gem"
      sha256 "8c33f147b46b768a8c333fe8ee3924279feed0c39819232cd92a73f8d34826d6"
    end
  end

  resource "thor" do
    url "https://rubygems.org/gems/thor-1.5.0.gem"
    sha256 "e3a9e55fe857e44859ce104a84675ab6e8cd59c650a49106a05f55f136425e73"
  end

  resource "rubyzip" do
    url "https://rubygems.org/gems/rubyzip-3.7.0.gem"
    sha256 "65c19294da75297a939006f3516deacc33185fbd721ff1954f7a231db6d3e121"
  end

  resource "rexml" do
    url "https://rubygems.org/gems/rexml-3.4.4.gem"
    sha256 "19e0a2c3425dfbf2d4fc1189747bdb2f849b6c5e74180401b15734bc97b5d142"
  end

  def install
    ENV["GEM_HOME"] = libexec
    ENV["GEM_PATH"] = libexec
    resources.each do |r|
      system "gem", "install", "--no-document", "--ignore-dependencies",
        r.cached_download
    end
    system "gem", "install", "--no-document", "--ignore-dependencies",
      cached_download

    # The gem resolves Java itself: PATH, then the Homebrew opt path,
    # then SE_JAVA. openjdk@17 is keg-only, so hand the resolution over
    # directly instead of relying on the opt-path guess.
    java_bin = Formula["openjdk@17"].opt_bin/"java"
    (bin/"se").write_env_script libexec/"bin/se",
      GEM_HOME: libexec, GEM_PATH: libexec, SE_JAVA: java_bin
  end

  def caveats
    <<~EOS
      The daemon downloads the pinned LanguageTool (about 300 MB) on its
      first start. Run `se setup` once to do that ahead of time, or just
      start it and wait:

        brew services start simple-english
    EOS
  end

  service do
    run [opt_bin/"se", "serve"]
    run_type :immediate
    keep_alive true
    log_path var/"log/simple-english.log"
    error_log_path var/"log/simple-english.log"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/se version")
  end
end
