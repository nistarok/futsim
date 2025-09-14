# FutSim - Football Simulator

This is a Ruby on Rails 8 application for simulating football (soccer) matches and managing teams, players, and leagues. The application allows users to create teams, manage player rosters, simulate matches, and track statistics.

## Features Implemented

### Authentication System
- OAuth 2.0 authentication with Google
- Invitation-based access control
- Session management
- User management interface

### Technical Implementation
- Ruby 3.4.4 with Rails 8.0.2.1
- PostgreSQL database
- Redis for caching and background jobs
- Docker containerization
- Tailwind CSS for styling

## Development Setup

1. Install Docker and Docker Compose
2. Run `docker-compose build` to build the containers
3. Run `docker-compose up` to start the services
4. Access the application at http://localhost:3000

## Authentication Flow

1. Users must be invited by an administrator before they can access the application
2. Invited users can sign in with their Google account
3. Upon successful authentication, users are granted access to the application

## How to Invite Users

1. Sign in with an existing invited account
2. Navigate to the "Invitations" page
3. Enter the email address of the user you want to invite
4. Click "Send Invitation"
5. The invited user can now sign in with their Google account

## Project Status

The authentication system is fully functional with OAuth and invitation-based access control. Users can be invited through the administrative interface, and invited users can authenticate with Google OAuth.

Next steps include implementing team management, player rosters, match simulation, and league organization features.