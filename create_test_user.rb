# Create a test invited user
user = User.invite!('udo.schmidt.jr@gmail.com')
puts "Created invited user: #{user.email}"
puts "Invitation token: #{user.invitation_token}"
puts "Status: #{user.status}"