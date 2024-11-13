#!/bin/bash

# Update package lists
sudo apt update

# Install PostgreSQL
sudo apt install -y postgresql postgresql-contrib

# Configure PostgreSQL to listen on all interfaces
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf

# Allow remote connections from the web server subnet
echo "host    all             all             10.0.1.0/24            md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf

# Restart PostgreSQL to apply changes
sudo systemctl restart postgresql

# Set up the PostgreSQL database, user, and table
sudo -u postgres psql <<EOF
-- Create the database
CREATE DATABASE flask_db;

-- Create the user with a password
CREATE USER postgres WITH PASSWORD 'password';

-- Grant all privileges on the database to the user
GRANT ALL PRIVILEGES ON DATABASE flask_db TO postgres;
EOF

# Create the required table in the database
sudo -u postgres psql -d flask_db <<EOF
CREATE TABLE table_gifts_yovel (
    name VARCHAR(50) PRIMARY KEY,
    age_value INTEGER,
    time TIMESTAMP
);
EOF
