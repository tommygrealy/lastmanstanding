from dal import dal

import random


conn = dal()

teams_available = conn.get_all_unused_teams()

random_teams = random.sample(teams_available, 3)

for teamName in random_teams:
    teamNextFixtureDetails = conn.get_next_fixture_for_team(teamName)
    if teamNextFixtureDetails[0][2]==teamName: # home
        print (f"Dynamite {teamName} home to {teamNextFixtureDetails[0][3]}")
        conn.exe_sql(f"UPDATE `lastmanstanding`.`fixtureresults` " \
                + f"SET `KillerTeam` = '1' WHERE (`FixtureId` = '{teamNextFixtureDetails[0][0]}');")
    if teamNextFixtureDetails[0][3]==teamName: # away
        print (f"Dynamite {teamName} away to {teamNextFixtureDetails[0][2]}")
        conn.exe_sql(f"UPDATE `lastmanstanding`.`fixtureresults` " \
                + f"SET `KillerTeam` = '3' WHERE (`FixtureId` = '{teamNextFixtureDetails[0][0]}');")