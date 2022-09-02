import requests
import json
from datetime import datetime


#mode="api"
mode="local"


with open("team_names.json", "r") as teaminfofile:
    teaminfojson = teaminfofile.read()

team_translator = json.loads(teaminfojson)

url = "https://heisenbug-premier-league-live-scores-v1.p.rapidapi.com/api/premierleague?matchday=5"

if mode == "api":
    payload={}
    headers = {
        'X-RapidAPI-Key': 'ab673339a3msh5690b3b9cb81b6dp106c1ejsn8aa70579921e',
        'X-RapidAPI-Host': 'heisenbug-premier-league-live-scores-v1.p.rapidapi.com'
    }
    response = requests.request("GET", url, headers=headers, data=payload)
    response_json=response.text

if mode == "local":
    with open ("sample_response.json", "r") as in_json:
        response_json=in_json.read()

if mode == "api":
    with open ("sample_response.json", "w") as json_outfile:
        json_outfile.writelines(response_json)


data = json.loads(response_json)


gameweek_query = "SELECT * FROM fixtureresults "
gameweek_query += "WHERE KickOffTime > (SELECT gameweekmap.DateFrom from gameweekmap WHERE gameweekmap.GameWeek=5)"
gameweek_query += "and KickOffTime < (SELECT gameweekmap.DateTo from gameweekmap WHERE gameweekmap.GameWeek = 5)"

for match in data['matches']:
    result=0
    if match['team1']['teamScore'] > match['team2']['teamScore']:
        result=1 # home win
    if match['team1']['teamScore'] == match['team2']['teamScore']:
        result=2 # draw
    if match['team1']['teamScore'] < match['team2']['teamScore']:
        result=3  # away win
    sql = "update fixtureresults set result = " + str(result)
    sql += ", HomeTeamScore = " + str(match['team1']['teamScore'])
    sql += ", AwayTeamScore = " + str(match['team2']['teamScore'])
    sql += " where HomeTeam = '" + team_translator[str(match['team1']['teamName'])] + "'"
    sql += " and AwayTeam = '" + team_translator[match['team2']['teamName']] + "';"
    print(sql)



