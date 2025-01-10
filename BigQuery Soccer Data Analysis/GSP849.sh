# Define text color variables
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

# Define background color variables
BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

# Define formatting variables
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Start of the script
echo "${YELLOW}${BOLD}Starting${RESET} ${GREEN}${BOLD}Execution${RESET}"

# Query 1: Fetch top matches based on total goals in the Spanish first division
bq query --use_legacy_sql=false <<EOF
SELECT
  date,
  label,
  (team1.score + team2.score) AS totalGoals
FROM
  \`soccer.matches\` Matches
LEFT JOIN
  \`soccer.competitions\` Competitions
ON
  Matches.competitionId = Competitions.wyId
WHERE
  status = "Played" AND
  Competitions.name = "Spanish first division"
ORDER BY
  totalGoals DESC, date DESC;
EOF

# Query 2: Fetch top 10 players with the most passes
bq query --use_legacy_sql=false <<EOF
SELECT
  playerId,
  CONCAT(Players.firstName, " ", Players.lastName) AS playerName,
  COUNT(id) AS numPasses
FROM
  \`soccer.events\` Events
LEFT JOIN
  \`soccer.players\` Players
ON
  Events.playerId = Players.wyId
WHERE
  eventName = "Pass"
GROUP BY
  playerId, playerName
ORDER BY
  numPasses DESC
LIMIT 10;
EOF

# Query 3: Fetch penalty statistics for players with at least 5 attempts
bq query --use_legacy_sql=false <<EOF
SELECT
  playerId,
  CONCAT(Players.firstName, " ", Players.lastName) AS playerName,
  COUNT(id) AS numPKAtt,
  SUM(IF(101 IN UNNEST(tags.id), 1, 0)) AS numPKGoals,
  SAFE_DIVIDE(
    SUM(IF(101 IN UNNEST(tags.id), 1, 0)),
    COUNT(id)
  ) AS PKSuccessRate
FROM
  \`soccer.events\` Events
LEFT JOIN
  \`soccer.players\` Players
ON
  Events.playerId = Players.wyId
WHERE
  eventName = "Free Kick" AND
  subEventName = "Penalty"
GROUP BY
  playerId, playerName
HAVING
  numPkAtt >= 5
ORDER BY
  PKSuccessRate DESC, numPKAtt DESC;
EOF

# End the script
echo "${RED}${BOLD}Congratulations${RESET} ${WHITE}${BOLD}for${RESET} ${GREEN}${BOLD}Completing the Lab !!!${RESET}"
echo "${GREEN}${BOLD}Subscribe${RESET}" "${GREEN}${BOLD}for${RESET}" "${GREEN}${BOLD}Cloudgoodies channel for more Solution !!!${RESET}"

