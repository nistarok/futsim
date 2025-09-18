puts "Divisions count: #{Division.count}"
if Division.any?
  Division.all.each { |d| puts "Division: #{d.name} (level #{d.level})" }
else
  puts "Creating default divisions..."
  Division.create!(name: "Série A", level: 1)
  Division.create!(name: "Série B", level: 2)
  Division.create!(name: "Série C", level: 3)
  Division.create!(name: "Série D", level: 4)
  puts "Created #{Division.count} divisions"
end