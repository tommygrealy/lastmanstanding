#!/usr/bin/python3
from dal import dal
import requests
import argparse
import json
import sys
from datetime import datetime, timedelta

print(f"py interpreter is: {sys.executable}")

conn = dal()

parser = argparse.ArgumentParser()
parser.add_argument(
    "--round",
    type=int,
    required=False,
    help="An integer value for the 'round' argument"
)
parser.add_argument(
    "--local",
    action="store_true",
    help="Enable local mode if specified - script gets data from local json file instead of api call"
)

# Parse the arguments
args = parser.parse_args()

# Access the arguments
local_mode = args.local

if args.round:
    round_number = args.round
else:
    today = datetime.now()
    round_number = int(conn.datestamp_to_gameweek(today.strftime("%Y-%m-%d %H:%M:%S")))

# Team names vary depending on results API in use. Use the team mapping JSON to
# ensure the team names match our lms DB
with open("team_names.json", "r") as team_name_fh:
    team_names_map=json.loads(team_name_fh.read())

if local_mode:
    with open("matches_by_round_example.json", "r") as json_fh:
        result_data = json.loads(json_fh.read())
else:
    rapid_api_tournament_id = 17 # https://footapi7.p.rapidapi.com/api/tournament/all/category/1
    rapid_api_season_id = 96668 # 26/27 season, Premier League https://footapi7.p.rapidapi.com/api/tournament/17/seasons
    
    results_url = f"https://footapi7.p.rapidapi.com/api/tournament/{rapid_api_tournament_id}/season/{rapid_api_season_id}/matches/round/{round_number}"
    headers = {
        'X-RapidAPI-Key': 'ab673339a3msh5690b3b9cb81b6dp106c1ejsn8aa70579921e',
        'X-RapidAPI-Host': 'footapi7.p.rapidapi.com'
    }
    response = requests.request("GET", results_url, headers=headers)
    result_data = json.loads(response.text)
    with open ("matches_by_round_example.json", "w") as out_json:
        out_json.write(response.text)

for match_data in result_data['events']:
    home_team = match_data['homeTeam']['shortName']
    away_team = match_data['awayTeam']['shortName']
    if match_data['status']['code'] == 100:  # status code 100 means match has ended
        home_team_score = match_data['homeScore']['normaltime']
        away_team_score = match_data['awayScore']['normaltime']
        score_text = f"{str(home_team_score)} - {str(away_team_score)}"
        if home_team_score > away_team_score:
            lms_result = 1
            print(f"{home_team} won at home to {away_team}, score: {score_text}")
        elif home_team_score == away_team_score:
            lms_result = 2
            print(f"{home_team} vs {away_team} was a draw, score: {score_text} ")
        else:
            lms_result = 3
            print(f"{away_team} won away to {home_team}, score: {score_text}")
        # update result
        conn.set_fixture_result(team_names_map[home_team],
                               team_names_map[away_team],
                               home_team_score,
                               away_team_score,
                               lms_result,
                               round_number)
    else:
        print(f"No result available for {home_team} vs {away_team} at present")

print("Calling checkResultsVsPredictions");
conn.exe_sql("call checkResultsVsPredictions")

## TODO: Now apply dynamite based on predictions list
# get round fixtures
round_fixtures = conn.fetch_rows_with_filters(
    table="fixtures_join_gameweek",
    filters={'gameweek': round_number}
    )

# get round predictions
round_predictions = conn.fetch_rows_with_filters(table='predictions', filters={"GameWeek": round_number})

# filter for dynamite
dynamite_fixtures = {}
for fixture in round_fixtures:
    if fixture['KillerTeam']==1 or fixture['KillerTeam']==3:
        dynamite_fixtures[fixture['FixtureId']] = fixture['KillerTeam']

usernames_ids={}
userinfo = conn.fetch_rows_with_filters('users', {'CompStatus':'Playing'})
for user in userinfo:
    usernames_ids[user['username']] = user['id']

dynamite_winners = []
for prediction in round_predictions:
    if prediction['PredictionCorrect']==1:
        if prediction['FixtureID'] in dynamite_fixtures.keys():
            if prediction['PredictedResult']==dynamite_fixtures[prediction['FixtureID']]:
                dynamite_winners.append({
                    "username":[prediction['UserName']][0],
                    "fixtureId":[prediction['FixtureID']][0]
                    })

print("Winners of dynamite:")
for user in dynamite_winners:
    username = user['username']
    fixtureid = user['fixtureId']
    expiry_time = datetime.now() + timedelta(hours=24)  # Calculate expiry time
    success = conn.insert_into_table(
        table_name="dynamite",
        insert_columns={
            "granted_to_user_fk":f"{usernames_ids[username]}",
            "won_in_fixture_id":f"{fixtureid}",
            "status": 1,
            "expiry": expiry_time.strftime('%Y-%m-%d %H:%M:%S'),  # Format datetime as a string
        }
    )
    if success:
        print(f"Dynamite awarded to {username} for fixture {fixtureid}")