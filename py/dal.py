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
        return  mysql.connector.connect(host=ps_cfg["host"], user=ps_cfg["user"],
                                        password=ps_cfg["password"], database=ps_cfg["database"])

    def exe_sql(self, sql):
        mycursor = self.db_conn.cursor()
        mycursor.execute(sql)
        self.db_conn.commit()
        return mycursor.rowcount
