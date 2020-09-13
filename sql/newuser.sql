-- Use this script to create a new user.
INSERT INTO ry_users (username, token) VALUES ('ramya', SHA2('ramya123', 256));
