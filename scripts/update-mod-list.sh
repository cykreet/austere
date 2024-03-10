#!/bin/bash

TITLE="${README_TITLE:-Austere}"
DESCRIPTION="${README_DESCRIPTION:-Fabric modpack with a little spice. Currently enjoying the following mods:}"

mods_path="$(pwd)/mods"

if [[ -z $CURSEFORGE_SECRET ]]; then
  echo "CURSEFORGE_SECRET is not set."
  exit 1
fi

> $(pwd)/README.md
>> $(pwd)/README.md echo "# ${TITLE}"
>> $(pwd)/README.md echo -e "${DESCRIPTION}\n"

>> $(pwd)/README.md echo "| Mod Name | Author | Description |"
>> $(pwd)/README.md echo "| --- | --- | --- |"

for file in "$mods_path"/*.pw.toml; do
  if [[ -f "${file}" ]]; then
    # mod-id is used for mods from modrinth
    # modrinth is useful for mods with api restrictions on curseforge or mods just not available on curseforge
    if grep -q "mod-id" "${file}"; then
      id=$(grep -oP 'mod-id\s*=\s*"\K[^"]+' ${file})
      project_json=$(curl https://api.modrinth.com/v2/project/${id} -H "Content-Type: application/json" -H "Accept: application/json")
      name=$(echo $project_json | jq -r '.title')
      description=$(echo $project_json | jq -r '.description' | sed 's/\r//g' | sed ':a; N; $!ba; s/\n/\<br\>/g')
      slug=$(echo $project_json | jq -r '.slug')

      project_author_json=$(curl https://api.modrinth.com/v2/project/${id}/members -H "Content-Type: application/json" -H "Accept: application/json")
      author=$(echo $project_author_json | jq -r '.[0].user.username')
      hyperlink="https://modrinth.com/mod/${slug}"

      # Escape pipe characters in name, author, and description
      name=$(echo "$name" | sed 's/|/\\|/g')
      author=$(echo "$author" | sed 's/|/\\|/g')
      description=$(echo "$description" | sed 's/|/\\|/g')

      echo "| [${name}](${hyperlink}) | ${author} | ${description} |" >> $(pwd)/README.md
    # project-id is used for mods from curseforge
    elif grep -q "project-id" "${file}"; then
      id=$(grep -oP 'project-id\s*=\s*\K\d+' ${file})
      project_json=$(curl https://api.curseforge.com/v1/mods/${id} -H "Content-Type: application/json" -H "Accept: application/json" -H "X-Api-Key: ${CURSEFORGE_SECRET}")
      name=$(echo $project_json | jq -r '.data.name')
      description=$(echo $project_json | jq -r '.data.summary' | sed 's/\r//g' | sed ':a; N; $!ba; s/\n/\<br\>/g')
      slug=$(echo $project_json | jq -r '.data.slug')
      author=$(echo $project_json | jq -r '.data.authors[0].name')
      hyperlink="https://www.curseforge.com/minecraft/mc-mods/${slug}"

      # Escape pipe characters in name, author, and description
      name=$(echo "$name" | sed 's/|/\\|/g')
      author=$(echo "$author" | sed 's/|/\\|/g')
      description=$(echo "$description" | sed 's/|/\\|/g')

      echo "| [${name}](${hyperlink}) | ${author} | ${description} |" >> $(pwd)/README.md
    else
      echo "Neither mod-id nor project-id found in ${file}"
      continue
    fi
  fi
done
