#!/bin/bash

# Define text colors and styles
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

#---------------------------------------------------- Start ----------------------------------------------------#

echo "${YELLOW}${BOLD}Starting${RESET}" "${GREEN}${BOLD}Execution${RESET}"

# Create GetShotDistanceToGoal function
bq query --use_legacy_sql=false "
CREATE FUNCTION \`soccer.GetShotDistanceToGoal\`(x INT64, y INT64)
RETURNS FLOAT64
AS (
  SQRT(
    POW((100 - x) * 105 / 100, 2) +
    POW((50 - y) * 68 / 100, 2)
  )
);
"

# Create GetShotAngleToGoal function
bq query --use_legacy_sql=false "
CREATE FUNCTION \`soccer.GetShotAngleToGoal\`(x INT64, y INT64)
RETURNS FLOAT64
AS (
  SAFE.ACOS(
    SAFE_DIVIDE(
      (
        POW(105 - (x * 105 / 100), 2) + POW(34 + 7.32 / 2 - (y * 68 / 100), 2) +
        POW(105 - (x * 105 / 100), 2) + POW(34 - 7.32 / 2 - (y * 68 / 100), 2) -
        POW(7.32, 2)
      ),
      (
        2 *
        SQRT(POW(105 - (x * 105 / 100), 2) + POW(34 + 7.32 / 2 - (y * 68 / 100), 2)) *
        SQRT(POW(105 - (x * 105 / 100), 2) + POW(34 - 7.32 / 2 - (y * 68 / 100), 2))
      )
    )
  ) * 180 / ACOS(-1)
);
"

# Create logistic regression model
bq query --use_legacy_sql=false "
CREATE MODEL \`soccer.xg_logistic_reg_model\`
OPTIONS(
  model_type = 'LOGISTIC_REG',
  input_label_cols = ['isGoal']
) AS
SELECT
  Events.subEventName AS shotType,
  (101 IN UNNEST(Events.tags.id)) AS isGoal,
  \`soccer.GetShotDistanceToGoal\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotDistance,
  \`soccer.GetShotAngleToGoal\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotAngle
FROM
  \`soccer.events\` Events
LEFT JOIN
  \`soccer.matches\` Matches ON Events.matchId = Matches.wyId
LEFT JOIN
  \`soccer.competitions\` Competitions ON Matches.competitionId = Competitions.wyId
WHERE
  Competitions.name != 'World Cup' AND
  (eventName = 'Shot' OR (eventName = 'Free Kick' AND subEventName IN ('Free kick shot', 'Penalty')))
;
"

# Retrieve model weights
bq query --use_legacy_sql=false "
SELECT * 
FROM ML.WEIGHTS(MODEL \`soccer.xg_logistic_reg_model\`);
"

# Create boosted tree classifier model
bq query --use_legacy_sql=false "
CREATE MODEL \`soccer.xg_boosted_tree_model\`
OPTIONS(
  model_type = 'BOOSTED_TREE_CLASSIFIER',
  input_label_cols = ['isGoal']
) AS
SELECT
  Events.subEventName AS shotType,
  (101 IN UNNEST(Events.tags.id)) AS isGoal,
  \`soccer.GetShotDistanceToGoal\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotDistance,
  \`soccer.GetShotAngleToGoal\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotAngle
FROM
  \`soccer.events\` Events
LEFT JOIN
  \`soccer.matches\` Matches ON Events.matchId = Matches.wyId
LEFT JOIN
  \`soccer.competitions\` Competitions ON Matches.competitionId = Competitions.wyId
WHERE
  Competitions.name != 'World Cup' AND
  (eventName = 'Shot' OR (eventName = 'Free Kick' AND subEventName IN ('Free kick shot', 'Penalty')))
;
"

# Generate predictions with logistic regression model
bq query --use_legacy_sql=false "
SELECT *
FROM ML.PREDICT(
  MODEL \`soccer.xg_logistic_reg_model\`,
  (
    SELECT
      Events.subEventName AS shotType,
      (101 IN UNNEST(Events.tags.id)) AS isGoal,
      \`soccer.GetShotDistanceToGoal\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotDistance,
      \`soccer.GetShotAngleToGoal\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotAngle
    FROM
      \`soccer.events\` Events
    LEFT JOIN
      \`soccer.matches\` Matches ON Events.matchId = Matches.wyId
    LEFT JOIN
      \`soccer.competitions\` Competitions ON Matches.competitionId = Competitions.wyId
    WHERE
      Competitions.name = 'World Cup' AND
      (eventName = 'Shot' OR (eventName = 'Free Kick' AND subEventName IN ('Free kick shot', 'Penalty')))
  )
);
"

# Generate detailed predictions with additional information
bq query --use_legacy_sql=false "
SELECT
  predicted_isGoal_probs[ORDINAL(1)].prob AS predictedGoalProb,
  * EXCEPT (predicted_isGoal, predicted_isGoal_probs)
FROM
  ML.PREDICT(
    MODEL \`soccer.xg_logistic_reg_model\`,
    (
      SELECT
        Events.playerId,
        CONCAT(Players.firstName, ' ', Players.lastName) AS playerName,
        Teams.name AS teamName,
        CAST(Matches.dateutc AS DATE) AS matchDate,
        Matches.label AS match,
        CAST(
          (CASE
            WHEN Events.matchPeriod = '1H' THEN 0
            WHEN Events.matchPeriod = '2H' THEN 45
            WHEN Events.matchPeriod = 'E1' THEN 90
            WHEN Events.matchPeriod = 'E2' THEN 105
            ELSE 120
          END) + CEILING(Events.eventSec / 60) AS INT64
        ) AS matchMinute,
        Events.subEventName AS shotType,
        (101 IN UNNEST(Events.tags.id)) AS isGoal,
        \`soccer.GetShotDistanceToGoal\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotDistance,
        \`soccer.GetShotAngleToGoal\`(Events.positions[ORDINAL(1)].x, Events.positions[ORDINAL(1)].y) AS shotAngle
      FROM
        \`soccer.events\` Events
      LEFT JOIN
        \`soccer.matches\` Matches ON Events.matchId = Matches.wyId
      LEFT JOIN
        \`soccer.competitions\` Competitions ON Matches.competitionId = Competitions.wyId
      LEFT JOIN
        \`soccer.players\` Players ON Events.playerId = Players.wyId
      LEFT JOIN
        \`soccer.teams\` Teams ON Events.teamId = Teams.wyId
      WHERE
        Competitions.name = 'World Cup' AND
        (eventName = 'Shot' OR (eventName = 'Free Kick' AND subEventName = 'Free kick shot')) AND
        (101 IN UNNEST(Events.tags.id))
    )
  )
ORDER BY predictedGoalProb;
"

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"
echo "${GREEN}${BOLD}Subscribe${RESET}" "${GREEN}${BOLD}for${RESET}" "${GREEN}${BOLD}Cloudgoodies channel for more Solution !!!${RESET}"

#----------------------------------------------------- End -----------------------------------------------------#
