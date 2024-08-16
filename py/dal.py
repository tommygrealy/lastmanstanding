import mysql.connector
from datetime import datetime

dbConfig = {
    "username": "lms",
    "password": "th!isisnew12@",
    "host": "localhost",
    "dbname": "lastmanstanding",
}


class dal():
    def __init__(self):
        self.db_conn = self.connect()

    def connect(self):
        return mysql.connector.connect(host=dbConfig["host"], user=dbConfig["username"], autocommit=True,
                                       password=dbConfig["password"], database=dbConfig["dbname"])

    def exe_sql(self, sql):
        mycursor = self.db_conn.cursor()
        mycursor.execute(sql)
        self.db_conn.commit()
        mycursor.close()
        return mycursor.rowcount

    def get_users_not_submitted(self):
        sql = "SELECT * FROM `usersnotsubmitted`;"
        mycursor = self.db_conn.cursor()
        mycursor.execute(sql)
        retval = mycursor.fetchall()
        mycursor.close()
        return retval

    def get_teams_available(self, username):
        sql = "SELECT DISTINCT HomeTeam from fixtureresults" \
              + " where HomeTeam not in " \
              + " (SELECT predictions.TeamName from predictions " \
              + f"WHERE predictions.UserName = '{username}');"
        mycursor = self.db_conn.cursor()
        mycursor.execute(sql)
        retval = mycursor.fetchall()
        mycursor.close()
        return retval

    def get_next_fixture_for_team(self, teamname):
        sql = f"""
        select * from fixtureresults
        where KickOffTime > (select now())
        and (HomeTeam = '{teamname}' or AwayTeam = '{teamname}')
        order by KickOffTime asc
        limit 1;
        """
        mycursor = self.db_conn.cursor()
        mycursor.execute(sql)
        retval = mycursor.fetchall()
        mycursor.close()
        return retval

    def datestamp_to_gameweek(self, in_dt):
        params = (in_dt, in_dt)
        sql = f"""
                select GameWeek from gameweekmap
                where dateFrom <= %s
                and dateTo > %s
                """
        mycursor = self.db_conn.cursor()
        mycursor.execute(sql, params)
        retval = mycursor.fetchall()[0][0]
        mycursor.close()
        return retval


    def submit_prediction(self, entry_type, gameweek, fixtureId, username, teamname, prediction):
        params=[entry_type, gameweek, fixtureId, username, teamname, prediction]
        mycursor = self.db_conn.cursor()
        sql = """ insert into predictions 
        (
            `DateTimeEntered`,
            `EntryType`,
            `GameWeek`,
            `FixtureID`,
            `UserName`,
            `TeamName`,
            `PredictedResult`,
            `PredictionStatus`
        )
        VALUES
         ((select now()), %s, %s, %s, %s, %s, %s, 'A')
        """
        mycursor.execute(sql, params)
        self.db_conn.commit()
        mycursor.close()

