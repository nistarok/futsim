#!/usr/bin/env ruby

puts "=== Debug de Gems ==="
puts "Ruby Version: #{RUBY_VERSION}"
puts "Rails Version: #{Rails::VERSION::STRING}" if defined?(Rails)
puts "Bundle Path: #{Bundler.bundle_path}"
puts "Gemfile Path: #{Bundler.default_gemfile}"
puts "Gemfile.lock Path: #{Bundler.default_lockfile}"
puts

puts "=== Verificando Gemfile vs Bundler ==="
gemfile_gems = File.readlines('Gemfile').grep(/^\s*gem\s+/).map do |line|
  line.match(/gem\s+['"']([^'"']+)['"']/)[1]
rescue
  nil
end.compact

puts "Gems no Gemfile: #{gemfile_gems.count}"
puts "Gems instaladas pelo Bundler: #{Bundler.load.specs.count}"
puts

puts "=== Gems no Gemfile mas não instaladas ==="
gemfile_gems.each do |gem_name|
  begin
    spec = Bundler.load.specs.find { |s| s.name == gem_name }
    if spec.nil?
      puts "❌ #{gem_name} - NÃO ENCONTRADA"
    else
      puts "✅ #{gem_name} - #{spec.version}"
    end
  rescue => e
    puts "⚠️  #{gem_name} - ERRO: #{e.message}"
  end
end

puts
puts "=== Últimas 5 gems instaladas ==="
sorted_specs = Bundler.load.specs.sort_by(&:name)
sorted_specs.last(5).each do |spec|
  puts "  #{spec.name} (#{spec.version})"
end

puts
puts "=== Bundle Outdated ==="
begin
  system("bundle outdated --parseable")
rescue => e
  puts "Erro ao verificar gems desatualizadas: #{e.message}"
end