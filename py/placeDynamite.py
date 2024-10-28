from dal import dal

import random


conn = dal()

teams_available = conn.get_all_unused_teams()

random_teams = random.sample(teams_available, 3)

for teamName in random_teams:
    teamNextFixtureDetails = conn.get_next_fixture_for_team(teamName)
    if teamNextFixtureDetails[0][2]==teamName: # home
        print (f"Dynamite {teamName} home to {teamNextFixtureDetails[0][3]}")
        conn.update_table('fixtureresults', 
                          update_columns={'KillerTeam': 1},
                          filter_columns={'FixtureId': teamNextFixtureDetails[0][0]}
                          )
    if teamNextFixtureDetails[0][3]==teamName: # away
        print (f"Dynamite {teamName} away to {teamNextFixtureDetails[0][2]}")
        conn.update_table('fixtureresults', 
                          update_columns={'KillerTeam': 3},
                          filter_columns={'FixtureId': teamNextFixtureDetails[0][0]}
                          )