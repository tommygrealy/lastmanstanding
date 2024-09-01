from dal import dal
import requests
import argparse
import json

conn = dal()

parser = argparse.ArgumentParser()
parser.add_argument(
    "--round",
    type=int,
    required=True,
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
round_number = args.round
local_mode = args.local

# Team names vary depending on results API in use. Use the team mapping JSON to
# ensure the team names match our lms DB
with open("team_names.json", "r") as team_name_fh:
    team_names_map=json.loads(team_name_fh.read())

if local_mode:
    with open("matches_by_round_example.json", "r") as json_fh:
        result_data = json.loads(json_fh.read())
else:
    results_url = f"https://footapi7.p.rapidapi.com/api/tournament/17/season/61627/matches/round/{round_number}"
    headers = {
        'X-RapidAPI-Key': 'ab673339a3msh5690b3b9cb81b6dp106c1ejsn8aa70579921e',
        'X-RapidAPI-Host': 'footapi7.p.rapidapi.com'
    }
    response = requests.request("GET", results_url, headers=headers)
    result_data = json.loads(response.text)

for match_data in result_data['events']:
    home_team = match_data['homeTeam']['name']
    away_team = match_data['awayTeam']['name']
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
 
 print("Final step - call checkResultsVsPredictions");
 conn.exe_sql("call checkResultsVsPredictions")
 
