# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Vyrail
  module Preflight
    SITE = "https://vyrail.com"
    GITHUB = "https://github.com/vyrail"
    SOLANA_RELAY_CHAIN_ID = 792_703_809
    PUBLIC_SOLANA_RPC = "https://api.mainnet-beta.solana.com"

    REQUIRED = %w[node npm git].freeze
    OPTIONAL = %w[python3 go rustc cargo jq].freeze

    SECRET_GLOBS = %w[
      .env
      .env.*
      *.pem
      *.p12
      id_rsa
      id_ed25519
      *credentials*.json
      *secret*
    ].freeze

    module_function

    def which(cmd)
      ENV["PATH"].split(File::PATH_SEPARATOR).each do |dir|
        path = File.join(dir, cmd)
        return path if File.executable?(path)
      end
      nil
    end

    def check_tools
      rows = []
      REQUIRED.each do |c|
        rows << { name: c, required: true, path: which(c) }
      end
      OPTIONAL.each do |c|
        rows << { name: c, required: false, path: which(c) }
      end
      rows
    end

    def scan_secrets(root)
      return [] unless root && Dir.exist?(root)

      hits = []
      Dir.chdir(root) do
        SECRET_GLOBS.each do |pat|
          Dir.glob("**/#{pat}", File::FNM_DOTMATCH).each do |f|
            next if f.include?("node_modules/")
            next if f.include?(".git/")
            next if f.end_with?(".example") || f.include?(".env.example")
            hits << f
          end
        end
      end
      hits.uniq
    end

    def rpc_ping(url = PUBLIC_SOLANA_RPC)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 8
      http.read_timeout = 8
      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req["User-Agent"] = "vyrail-dev-preflight/0.1"
      req.body = { jsonrpc: "2.0", id: 1, method: "getHealth" }.to_json
      res = http.request(req)
      { ok: res.code.to_i == 200, code: res.code, body: res.body[0, 200] }
    rescue StandardError => e
      { ok: false, error: e.message }
    end

    def report(path: nil, rpc: false, strict: false)
      puts "VYRAIL Dev Preflight"
      puts "Site:   #{SITE}"
      puts "GitHub: #{GITHUB}"
      puts "Relay Solana chain id: #{SOLANA_RELAY_CHAIN_ID}"
      puts "-" * 48

      miss = false
      check_tools.each do |t|
        if t[:path]
          puts "OK   tool #{t[:name]} -> #{t[:path]}"
        elsif t[:required]
          puts "MISS tool #{t[:name]}"
          miss = true
        else
          puts "WARN tool #{t[:name]} (optional)"
        end
      end

      if path
        hits = scan_secrets(path)
        if hits.empty?
          puts "OK   no obvious secret filenames under #{path}"
        else
          puts "WARN possible secret filenames (contents not displayed):"
          hits.first(20).each { |h| puts "       - #{h}" }
          puts "       … #{hits.size - 20} more" if hits.size > 20
        end
      end

      if rpc
        r = rpc_ping
        if r[:ok]
          puts "OK   public Solana RPC health HTTP #{r[:code]}"
        else
          puts "WARN public Solana RPC probe failed: #{r[:error] || r[:code]}"
        end
      end

      puts "-" * 48
      puts miss ? "Result: incomplete toolchain" : "Result: ready enough to develop"
      return 1 if strict && miss

      0
    end
  end
end
