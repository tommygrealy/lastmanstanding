import requests



url = "https://heisenbug-premier-league-live-scores-v1.p.rapidapi.com/api/premierleague?matchday=6"

payload={}
headers = {
  'X-RapidAPI-Key': 'ab673339a3msh5690b3b9cb81b6dp106c1ejsn8aa70579921e',
  'X-RapidAPI-Host': 'heisenbug-premier-league-live-scores-v1.p.rapidapi.com'
}

response = requests.request("GET", url, headers=headers, data=payload)

print(response.text)

