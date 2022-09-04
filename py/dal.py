import mysql.connector

dbConfig = {
    "username" : "lms",
    "password" : "th!isisnew12@",
    "host" : "localhost",
    "dbname" : "lastmanstanding",
}


class dal():
    def __init__(self):
        self.db_conn = self.connect()

    def connect(self):
        return  mysql.connector.connect(host=dbConfig["host"], user=dbConfig["username"],
                                        password=dbConfig["password"], database=dbConfig["dbname"])

    def exe_sql(self, sql):
        mycursor = self.db_conn.cursor()
        mycursor.execute(sql)
        self.db_conn.commit()
        return mycursor.rowcount
