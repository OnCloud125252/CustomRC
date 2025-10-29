#!/bin/sh

# Function to create a directory with a random name
random_mkdir() {
  # Generate a random string using /dev/urandom, tr, and head
  # - /dev/urandom provides random bytes
  # - LC_ALL=C ensures tr handles bytes correctly across systems
  # - tr filters to alphanumeric characters (a-z, A-Z, 0-9)
  # - head limits to 12 characters
  random_name=$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 12)

  # Create the directory
  mkdir "$random_name"

  # Print the created directory name
  echo "Created directory: $random_name"

  # Return the directory name for potential use
  return 0
}