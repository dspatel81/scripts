#!/bin/bash

# Variables
ROOT_FOLDER="/c/path/to/your/folder"  # Use the /c/ style path for C: drive
FILE_NAME="filename.ext"  # Change this to the file name you're looking for
OUTPUT_FILE="found_files.txt"
NOT_FOUND_FILE="not_found_folders.txt"
JSON_FILE="config.json"  # Change this to the name of your JSON file
SCRIPT_FOLDER="$(dirname "$0")"  # Directory where the script is located

# Clear the output files
> "$OUTPUT_FILE"
> "$NOT_FOUND_FILE"

# Function to search for the file and copy JSON if not found
search_file() {
  local folder=$1
  local file_name=$2
  local output_file=$3
  local not_found_file=$4
  local json_file=$5
  local script_folder=$6

  # Iterate through first-level subfolders and check if the file exists
  for subfolder in "$folder"/*; do
    if [ -d "$subfolder" ]; then
      if find "$subfolder" -maxdepth 1 -type f -name "$file_name" | grep -q .; then
        find "$subfolder" -maxdepth 1 -type f -name "$file_name" | while read -r file; do
          echo "File: $(basename "$file") found in Folder: $(basename "$subfolder")" >> "$output_file"
        done
      else
        echo "Folder: $(basename "$subfolder") does not contain the file: $file_name" >> "$not_found_file"
        # Copy the JSON file to the subfolder
        cp "$script_folder/$json_file" "$subfolder"
        echo "Copied $json_file to $subfolder"

        # Change to the subfolder and commit the change
        (
          cd "$subfolder"
          BRANCH_NAME="add-json-file-$(basename "$subfolder")"
          git checkout -b "$BRANCH_NAME"
          git add "$json_file"
          git commit -m "Add $json_file to $(basename "$subfolder")"
          git push origin "$BRANCH_NAME"

          # Create a pull request
          gh pr create --title "Add $json_file to $(basename "$subfolder")" --body "This PR adds the $json_file to $(basename "$subfolder")" --base main
        )
      fi
    fi
  done
}

# Call the function to search in the root folder and its first-level subfolders
search_file "$ROOT_FOLDER" "$FILE_NAME" "$OUTPUT_FILE" "$NOT_FOUND_FILE" "$JSON_FILE" "$SCRIPT_FOLDER"

# Output message
echo "Search completed. Results are in '$OUTPUT_FILE' and '$NOT_FOUND_FILE'."
