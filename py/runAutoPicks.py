from dal import dal

import json
from datetime import datetime
from dal import dal
import argparse
import random

# mode = "api"
mode = "local"

conn = dal()

result = conn.get_users_not_submitted()

for user in result:
    teamsAvailableForUser = conn.get_teams_available(user[2])
    random_team = random.choice(teamsAvailableForUser)[0]
    print(f"{user[1]} has {str(len(teamsAvailableForUser))} teams available, {random_team} was chosen")
    next_fixture = conn.get_next_fixture_for_team(random_team)
    prediction_text = {0: "Undefineed", 1: "HOME", 3: "AWAY"}
    prediction = 0
    if next_fixture[0][2] == random_team:
        prediction = 1  # HOME WIN
        opponent = next_fixture[0][3]
    else:
        prediction = 3  # AWAY WIN
        opponent = next_fixture[0][2]

    gameweek = conn.datestamp_to_gameweek(next_fixture[0][1])

    print(f"Submitting auto-pick entry for {user[2]} - {random_team} " \
          + f"to win {prediction_text[prediction]} vs {opponent}")

    submitted = conn.submit_prediction(entry_type='AUTO', fixtureId=next_fixture[0][0], gameweek=gameweek,
                                       username=user[2], teamname=random_team, prediction=prediction)
    print()

print("Done")
