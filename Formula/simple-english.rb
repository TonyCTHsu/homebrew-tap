class SimpleEnglish < Formula
  desc "Lint Markdown prose with the SimpleEnglish Plain-mode rules"
  homepage "https://github.com/TonyCTHsu/simple-english"
  url "https://rubygems.org/gems/simple_english-0.4.2.gem"
  sha256 "d1e4935c32c248e4d7fe0fda7097ec5100b35b581d5212bdd494d4c73488f653"
  license "MIT"

  livecheck do
    url "https://rubygems.org/api/v1/gems/simple_english.json"
    regex(/"version":\s*"([^"]+)"/i)
  end

  depends_on "openjdk@17"
  depends_on "ruby"

  # Prebuilt darwin gems. The source (-ruby) gem needs the rb_sys
  # build gem and compiles every tree-sitter grammar: far too slow for
  # an install. ponytail: darwin only. Linux support needs the -ruby
  # gem plus an rb_sys resource.
  resource "tree_sitter_language_pack" do
    on_arm do
      url "https://rubygems.org/gems/tree_sitter_language_pack-1.20.0-arm64-darwin.gem"
      sha256 "b5e6899bedaa750f030a12bfd5db96fe9ed6a0617eee37119c0ffafd49d5baae"
    end
    on_intel do
      url "https://rubygems.org/gems/tree_sitter_language_pack-1.20.0-x86_64-darwin.gem"
      sha256 "8c33f147b46b768a8c333fe8ee3924279feed0c39819232cd92a73d8d34826d6"
    end
  end

  # tree_sitter_language_pack needs sorbet-runtime; that chain reaches
  # benchmark, minitest, drb. Homebrew's Ruby ships none of them.
  resource "sorbet-runtime" do
    url "https://rubygems.org/gems/sorbet-runtime-0.6.13508.gem"
    sha256 "011ee266adead459077ebc0058d36aeb75d6c90968db8524916050ce3c62e526"
  end

  resource "benchmark" do
    url "https://rubygems.org/gems/benchmark-0.5.0.gem"
    sha256 "465df122341aedcb81a2a24b4d3bd19b6c67c1530713fd533f3ff034e419236c"
  end

  resource "minitest" do
    url "https://rubygems.org/gems/minitest-6.0.6.gem"
    sha256 "153ea36d1d987a62942382b61075745042a2b3123b1cd48f4c3675af9cc7d6f1"
  end

  resource "drb" do
    url "https://rubygems.org/gems/drb-2.2.3.gem"
    sha256 "0b00d6fdb50995fe4a45dea13663493c841112e4068656854646f418fda13373"
  end

  resource "thor" do
    url "https://rubygems.org/gems/thor-1.5.0.gem"
    sha256 "e3a9e55fe857e44859ce104a84675ab6e8cd59c650a49106a05f55f136425e73"
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
    java_bin = formula_opt_bin("openjdk@17")/"java"
    (bin/"se").write_env_script libexec/"bin/se",
      GEM_HOME: libexec, GEM_PATH: libexec, SE_JAVA: java_bin
  end

  def caveats
    <<~EOS
      The first `brew services start simple-english` downloads the
      pinned LanguageTool (about 300 MB) and then keeps a warm daemon.
      Run `se setup` ahead of time to download it first.
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
