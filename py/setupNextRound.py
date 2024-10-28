#!/usr/bin/python3
from dal import dal
import requests
import argparse
import json
import sys
from datetime import datetime, timedelta

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
if args.round:
    round_number = args.round
else:
    today = datetime.now()
    # Saturday is day 5 in Python's weekday(), Monday is 0
    days_since_saturday = (today.weekday() + 2) % 7
    last_saturday = today - timedelta(days=days_since_saturday)
    last_saturday_dtstr = last_saturday.strftime('%Y-%m-%d')
    last_round_number = int(conn.datestamp_to_gameweek(last_saturday_dtstr))
    round_number = last_round_number + 1

local_mode = args.local

# Team names vary depending on results API in use. Use the team mapping JSON to
# ensure the team names match our lms DB
with open("team_names.json", "r") as team_name_fh:
    team_names_map=json.loads(team_name_fh.read())

if local_mode:
    with open("matches_by_round_example.json", "r") as json_fh:
        response_json = json.loads(json_fh.read())
else:
    fixtures_url = f"https://footapi7.p.rapidapi.com/api/tournament/17/season/61627/matches/round/{round_number}"
    headers = {
        'X-RapidAPI-Key': 'ab673339a3msh5690b3b9cb81b6dp106c1ejsn8aa70579921e',
        'X-RapidAPI-Host': 'footapi7.p.rapidapi.com'
    }
    response = requests.request("GET", fixtures_url, headers=headers)
    response_json = json.loads(response.text)



match_start_times = [event['startTimestamp'] for event in response_json['events']]

gameweek_start_dt = datetime.fromtimestamp(min(match_start_times))
gameweek_end_dt = datetime.fromtimestamp(max(match_start_times))
gameweek_full_time = gameweek_end_dt + timedelta(hours=2, minutes=15)


for match_data in response_json['events']:
    existing_details_correct = True
    kick_off_time = datetime.fromtimestamp(match_data['startTimestamp'])
    home_team = match_data['homeTeam']['name']
    away_team = match_data['awayTeam']['name']
    db_home_team = team_names_map[home_team]
    db_away_team = team_names_map[away_team]

    existing_fixture_in_db = conn.get_fixture_info_by_details(
        db_home_team, db_away_team, gameweek_start_dt, gameweek_end_dt)
    if len(existing_fixture_in_db) == 1:  # exists already in DB
        # check start time 
        if not(existing_fixture_in_db[0][1] == kick_off_time):
            # DB has incorrect time - update it
            fixture_time_updated = conn.exe_sql(f"update fixtureresults set KickOffTime " + \
                        f"= '{kick_off_time}' " + \
                        f"where FixtureId = {existing_fixture_in_db[0][0]}")
            print(f"Fixture {home_team} vs {away_team}, kickoff time changed to {kick_off_time}")
        else:
            print(f"Fixture {home_team} vs {away_team} is already correct: {existing_fixture_in_db[0][1]}")
    
gameweek_defined = conn.exe_sql(f"""
        insert into gameweekmap (GameWeek, DateFrom, DateTo) values
                ({round_number}, '{gameweek_start_dt}', '{gameweek_full_time}')
                """)

if gameweek_defined > 0:
    print(f"Gameweek {round_number} has been inserted")

