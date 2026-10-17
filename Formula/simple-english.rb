class SimpleEnglish < Formula
  desc "Lint Markdown prose with the SimpleEnglish Plain-mode rules"
  homepage "https://github.com/TonyCTHsu/simple-english"
  url "https://rubygems.org/gems/simple_english-0.11.1-arm64-darwin.gem"
  sha256 "9aa94c27ff2ccefe3cece2c11b74ec4fe55fce67ba87604a250c134b7861c65f"
  license "MIT"

  livecheck do
    url :homepage
    strategy :github
    regex(/^v?(\d+(?:\.\d+)*)$/i)
  end

  depends_on "ruby"

  # The gem publishes arm64-darwin only for macOS; no x86_64-darwin
  # build exists.
  on_macos do
    depends_on arch: :arm
  end
  on_linux do
    on_arm do
      url "https://rubygems.org/gems/simple_english-0.11.1-aarch64-linux.gem"
      sha256 "b8e6ecfe6d036eaa07240552c4a2b1e6118f4dd105f28ff9fba676651db5af6d"
    end
    on_intel do
      url "https://rubygems.org/gems/simple_english-0.11.1-x86_64-linux.gem"
      sha256 "09c3442605f161895c24f88c8889afcf2631f0724551d7aa0131e1e76eb1e175"
    end
  end

  resource "tree_sitter_language_pack" do
    on_macos do
      url "https://rubygems.org/gems/tree_sitter_language_pack-1.20.0-arm64-darwin.gem"
      sha256 "b5e6899bedaa750f030a12bfd5db96fe9ed6a0617eee37119c0ffafd49d5baae"
    end
    on_linux do
      on_arm do
        url "https://rubygems.org/gems/tree_sitter_language_pack-1.20.0-aarch64-linux.gem"
        sha256 "8b43f4c3d18705d4211a5dc0d9281f5e68616c8dd6b323df411b9ee026894f6f"
      end
      on_intel do
        url "https://rubygems.org/gems/tree_sitter_language_pack-1.20.0-x86_64-linux.gem"
        sha256 "ce5e910a1443afbc770eb6cd18d33b08327fed1ef721f6c9a15e0dfccf7327a4"
      end
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

    (bin/"se").write_env_script libexec/"bin/se",
      GEM_HOME: libexec, GEM_PATH: libexec
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
