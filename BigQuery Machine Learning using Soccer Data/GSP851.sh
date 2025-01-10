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

# 1. Create Functions in Parallel
(
  bq query --batch --use_legacy_sql=false "
  CREATE FUNCTION \`soccer.GetShotDistanceToGoal\`(x INT64, y INT64)
  RETURNS FLOAT64
  AS (
    SQRT(
      POW((100 - x) * 105 / 100, 2) +
      POW((50 - y) * 68 / 100, 2)
    )
  );
  "
) &

(
  bq query --batch --use_legacy_sql=false "
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
) &
wait

# 2. Create Temporary Table for Filtered Events (Reduces Joins and Repeated Filtering)
bq query --batch --use_legacy_sql=false "
CREATE OR REPLACE TABLE \`soccer.filtered_events\` AS
SELECT
  Events.matchId,
  Events.subEventName AS shotType,
  Events.positions[ORDINAL(1)].x AS x,
  Events.positions[ORDINAL(1)].y AS y,
  Events.tags.id AS tags,
  (101 IN UNNEST(Events.tags.id)) AS isGoal,
  Matches.competitionId,
  Matches.wyId AS matchWyId,
  Competitions.name AS competitionName
FROM
  \`soccer.events\` Events
LEFT JOIN
  \`soccer.matches\` Matches ON Events.matchId = Matches.wyId
LEFT JOIN
  \`soccer.competitions\` Competitions ON Matches.competitionId = Competitions.wyId
WHERE
  (eventName = 'Shot' OR (eventName = 'Free Kick' AND subEventName IN ('Free kick shot', 'Penalty')));
"

# 3. Create Logistic Regression Model
bq query --batch --use_legacy_sql=false "
CREATE MODEL \`soccer.xg_logistic_reg_model\`
OPTIONS(
  model_type = 'LOGISTIC_REG',
  input_label_cols = ['isGoal']
) AS
SELECT
  shotType,
  isGoal,
  \`soccer.GetShotDistanceToGoal\`(x, y) AS shotDistance,
  \`soccer.GetShotAngleToGoal\`(x, y) AS shotAngle
FROM
  \`soccer.filtered_events\`
WHERE
  competitionName != 'World Cup';
"

# 4. Create Boosted Tree Classifier Model
bq query --batch --use_legacy_sql=false "
CREATE MODEL \`soccer.xg_boosted_tree_model\`
OPTIONS(
  model_type = 'BOOSTED_TREE_CLASSIFIER',
  input_label_cols = ['isGoal']
) AS
SELECT
  shotType,
  isGoal,
  \`soccer.GetShotDistanceToGoal\`(x, y) AS shotDistance,
  \`soccer.GetShotAngleToGoal\`(x, y) AS shotAngle
FROM
  \`soccer.filtered_events\`
WHERE
  competitionName != 'World Cup';
"

# 5. Generate Predictions in Parallel
(
  bq query --batch --use_legacy_sql=false "
  SELECT *
  FROM ML.PREDICT(
    MODEL \`soccer.xg_logistic_reg_model\`,
    (
      SELECT
        shotType,
        isGoal,
        \`soccer.GetShotDistanceToGoal\`(x, y) AS shotDistance,
        \`soccer.GetShotAngleToGoal\`(x, y) AS shotAngle
      FROM
        \`soccer.filtered_events\`
      WHERE
        competitionName = 'World Cup'
    )
  );
  "
) &

(
  bq query --batch --use_legacy_sql=false "
  SELECT
    predicted_isGoal_probs[ORDINAL(1)].prob AS predictedGoalProb,
    playerId,
    CONCAT(Players.firstName, ' ', Players.lastName) AS playerName,
    Teams.name AS teamName,
    CAST(Matches.dateutc AS DATE) AS matchDate,
    Matches.label AS match,
    shotType,
    \`soccer.GetShotDistanceToGoal\`(x, y) AS shotDistance,
    \`soccer.GetShotAngleToGoal\`(x, y) AS shotAngle
  FROM
    ML.PREDICT(
      MODEL \`soccer.xg_logistic_reg_model\`,
      (
        SELECT
          *
        FROM
          \`soccer.filtered_events\`
        WHERE
          competitionName = 'World Cup' AND
          (101 IN UNNEST(tags))
      )
    )
  LEFT JOIN
    \`soccer.players\` Players ON playerId = Players.wyId
  LEFT JOIN
    \`soccer.teams\` Teams ON teamId = Teams.wyId;
  "
) &
wait

echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"
echo "${GREEN}${BOLD}Subscribe${RESET}" "${GREEN}${BOLD}for${RESET}" "${GREEN}${BOLD}Cloudgoodies channel for more Solution !!!${RESET}"

#----------------------------------------------------- End -----------------------------------------------------#
