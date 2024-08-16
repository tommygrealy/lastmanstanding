import requests
import json
from datetime import datetime
from dal import dal
import argparse

#mode = "api"
mode = "local"

conn = dal()

matchday = 1

with open("team_names.json", "r") as teaminfofile:
    teaminfojson = teaminfofile.read()

team_translator = json.loads(teaminfojson)

url = "https://livescore-football.p.rapidapi.com/soccer/matches-by-date"

if mode == "api":
    payload = {'date': 20220904,
               'league_code': 'premier-league',
               'timezone_utc': '00:00',
               'country_code': 'england'}
    headers = {
        'X-RapidAPI-Key': 'ab673339a3msh5690b3b9cb81b6dp106c1ejsn8aa70579921e',
        'X-RapidAPI-Host': 'livescore-football.p.rapidapi.com'
    }
    response = requests.request("GET", url, headers=headers, params=payload, proxies={'http': '', 'https': ''})
    response_json = response.text

if mode == "local":
    with open ("match_results_example.json", "r") as in_json:
        response_json=in_json.read()

if mode == "api":
    with open ("sample_response.json", "w") as json_outfile:
        json_outfile.writelines(response_json)


data = json.loads(response_json)


gameweek_query = "SELECT * FROM fixtureresults "
gameweek_query += "WHERE KickOffTime > (SELECT gameweekmap.DateFrom from gameweekmap WHERE gameweekmap.GameWeek=5)"
gameweek_query += "and KickOffTime < (SELECT gameweekmap.DateTo from gameweekmap WHERE gameweekmap.GameWeek = 5)"

for match in data['events']:
    if match['status'] == 'FT':
        homeTeam = match.get('homeTeam').get('name')
        awayTeam = match.get('awayTeam').get('name')
        homeTeamScore = int(match.get('score').get('full_time').get('team_1'))
        awayTeamScore = int(match.get('score').get('full_time').get('team_2'))
        result=0
        if homeTeamScore > awayTeamScore:
            result = 1 # home win
        if homeTeamScore == awayTeamScore:
            result = 2 # draw
        if homeTeamScore < awayTeamScore:
            result = 3  # away win
        sql = "update fixtureresults set result = " + str(result)
        sql += ", HomeTeamScore = " + str(homeTeamScore)
        sql += ", AwayTeamScore = " + str(awayTeamScore)
        sql += " where HomeTeam = '" + team_translator[homeTeam] + "'"
        sql += " and AwayTeam = '" + team_translator[awayTeam] + "';"
        conn.exe_sql(sql)
        print(sql)



