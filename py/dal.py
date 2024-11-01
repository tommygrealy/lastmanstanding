import mysql.connector
from datetime import datetime
import os

environment = os.environ.get('RUN_ENVIRON')
if environment == None:
    print ("Env variable RUN_ENVIRON is not set! Exiting")
    exit(1)

if os.environ['RUN_ENVIRON']=='DEV':
    dbConfig = {
        "username": "lms",
        "password": os.environ.get('LMS_PASS'),
        "host": "localhost",
        "dbname": "lastmanstanding-dev",
    }
elif os.environ['RUN_ENVIRON']=='PROD':
    dbConfig = {
        "username": "lms",
        "password": os.environ.get('LMS_PASS'),
        "host": "localhost",
        "dbname": "lastmanstanding",
    }
else:
    print("Environment variable RUN_ENVIRON must be set to PROD or DEV")
    print("Run either:")
    print("export RUN_ENVIRON='PROD'")
    print("export RUN_ENVIRON='DEV'")


class dal():
    def __init__(self):
        self.db_conn = self.connect()

    def connect(self):
        return mysql.connector.connect(host=dbConfig["host"], 
                                       user=dbConfig["username"],
                                       autocommit=True,
                                       password=dbConfig["password"],
                                       database=dbConfig["dbname"]
                                       )

    def exe_sql(self, sql):
        mycursor = self.db_conn.cursor()
        mycursor.execute(sql)
        self.db_conn.commit()
        mycursor.close()
        return mycursor.rowcount
    
    def fetch_rows_with_filters(self, table, filters, operator="AND"):
        mycursor = self.db_conn.cursor(dictionary=True)
        query = f"SELECT * FROM {table}"
        if filters:
            where_clause = f" {operator} ".join([f"{column} = %s" for column in filters.keys()])
            query += f" WHERE {where_clause}"
        
        try:
            mycursor.execute(query, list(filters.values()))
            rows = mycursor.fetchall()
            return rows
        finally:
            mycursor.close()
    
    def insert_into_table(self, table_name, insert_columns):
        mycursor = self.db_conn.cursor()
        # Construct the column names and placeholders for the INSERT statement
        columns = ", ".join(insert_columns.keys())
        placeholders = ", ".join(["%s"] * len(insert_columns))
        query = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
        values = list(insert_columns.values())
        try:
            mycursor.execute(query, values)
            return True
        except mysql.connector.Error as e:
            print(f"Error inserting into table: {e}")
            return False
        finally:
            mycursor.close()

    
    def update_table(self, table_name, update_columns, filter_columns):
        mycursor = self.db_conn.cursor()
        # Construct the SET clause
        set_clause = ", ".join([f"{col} = %s" for col in update_columns.keys()])
        # Construct the WHERE clause
        where_clause = " AND ".join([f"{col} = %s" for col in filter_columns.keys()])
        
        # Prepare the full SQL query
        query = f"UPDATE {table_name} SET {set_clause} WHERE {where_clause}"
        
        # Combine values for the query execution
        values = list(update_columns.values()) + list(filter_columns.values())
        
        # Execute the query and commit the changes
        try:
            mycursor.execute(query, values)
        except mysql.connector.Error as e:
            print(f"Error updating table: {e}")
        finally:
            mycursor.close()


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
    
    def get_all_unused_teams(self):
        sql_teams_picked = """
            create TEMPORARY table alreadyPicked as 
            SELECT distinct TeamName FROM lastmanstanding.predictions where username in
            (  select UserName from users where compstatus = 'Playing' );"""
        sql_available_teams = """
            select distinct HomeTeam from fixtureresults
            where HomeTeam not in (select TeamName from alreadyPicked);
        """
        mycursor = self.db_conn.cursor()
        mycursor.execute(sql_teams_picked)
        mycursor.execute(sql_available_teams)
        result = mycursor.fetchall()
        mycursor.close()
        retval = [row[0] for row in result]
        return retval

    def get_fixture_info_by_details(self, hometeam, awayteam, gameweek_start, gameweek_end):
        sql = f"""
        select * from fixtureresults where KickOffTime between 
        '{gameweek_start}' and '{gameweek_end}' and 
        homeTeam = '{hometeam}' and awayTeam ='{awayteam}';
        """
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
    
    def get_all_fixtures_for_gameweek(self, gameweek):
        mycursor = self.db_conn.cursor(dictionary=True)
        params = (gameweek, gameweek)
        sql = f"""
                select * from fixtureresults where
                KickOfftime >  (select DateFrom from gameweekmap where gameweek = %s)
                and
                KickOffTime < (select DateTo from gameweekmap where gameweek = %s)
                order by KickOffTime;
                """
        mycursor = self.db_conn.cursor(dictionary=True)
        mycursor.execute(sql, params)
        retval = mycursor.fetchall()
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

    def set_fixture_result(self, home_team, away_team, home_score, away_score, result, round_number):
        params={
            "home_team": home_team,
            "away_team": away_team,
            "home_score": home_score,
            "away_score": away_score,
            "result": result,
            "round_number": round_number,
        }
        sql = f"""
        UPDATE fixtureresults 
        SET HomeTeamScore = %(home_score)s, AwayTeamScore = %(away_score)s, Result = %(result)s
        WHERE HomeTeam = %(home_team)s 
          AND AwayTeam = %(away_team)s
          AND KickOffTime BETWEEN 
            (SELECT DateFrom FROM gameweekmap WHERE GameWeek = %(round_number)s) 
            AND (SELECT DateTo FROM gameweekmap WHERE GameWeek = %(round_number)s);
        """
        mycursor = self.db_conn.cursor()
        mycursor.execute(sql, params)
        retval = mycursor.rowcount
        mycursor.close()
        return retval

