from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL, Engine
from pathlib import Path
from pandas import read_sql_query, DataFrame
from sqlalchemy.exc import SQLAlchemyError


def mssql_engine(server : int, 
                 database : int
                 ):
    """Creates a SQLAlchemy engine for Microsoft SQL Server using ODBC Driver 18.
    :param server: Server hostname, IP, or instance (e.g., 'localhost' or
    'localhost\\SQLEXPRESS')
    :param database: Name of the target SQL Server database
    """

    connection_string = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        f"SERVER={server};"
        f"DATABASE={database};"
        "Trusted_Connection=yes;"
        "Encrypt=yes;"
        "TrustServerCertificate=yes;"  # fine for a local copy, not for a production server
    )
    connection_url = URL.create(
        "mssql+pyodbc",
        query={"odbc_connect": connection_string},
    )
    sql_engine = create_engine(connection_url)
 
    # Test the connection immediately to catch wrong parameters right away
    try:
        with sql_engine.connect():
            pass
    except SQLAlchemyError as error:
        raise ConnectionError(
            f"Failed to connect to SQL Server! "
            f"Please verify your parameters -> Server: '{server}', Database: '{database}'.\n"
            f"Underlying error: {error}"
        ) from error
 
    return sql_engine

def generic_engine(
    db_type: str, server: str, database: str, user: str = None, password: str = None
):
    if db_type == "mssql":
        conn_str = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={server};DATABASE={database};Trusted_Connection=yes;Encrypt=yes;TrustServerCertificate=yes;"
        url = Engine.URL.create("mssql+pyodbc", query={"odbc_connect": conn_str})
    elif db_type == "postgresql":
        url = f"postgresql+psycopg2://{user}:{password}@{server}/{database}"
    elif db_type == "mysql":
        url = f"mysql+pymysql://{user}:{password}@{server}/{database}"
    else:
        raise ValueError(f"Unsupported database type: {db_type}")

    return create_engine(url)

def load_sql_to_df( file_path: str | Path,
    sql_engine: Engine,
) -> DataFrame:
    """Read a .sql file, run it on the engine and return the result as a DataFrame.
 
    The function opens and closes its own connection, so pass it the engine.
    The file should hold a single query, because only the first result is returned.
 
    :param file_path: Path to the .sql file
    :param sql_engine: Engine created by mssql_engine()
    """
    path = Path(file_path)
 
    # Read the file first, so a missing file never leaves a connection open.
    # utf-8-sig copes with files saved with or without a byte order mark.
    try:
        raw_sql = path.read_text(encoding="utf-8-sig")
    except FileNotFoundError as error:
        raise FileNotFoundError(
            f"File not found at {path.absolute()}\n"
            f"Current working directory: {Path.cwd()}"
        ) from error
 
    with sql_engine.connect() as conn:
        return read_sql_query(text(raw_sql), con=conn, params=params)


if __name__ == "__main__":
    SERVER = r'localhost\SQLEXPRESS'  # Change to the server name supplied by your instructor.
    DATABASE = 'OlistDB'
    mssql_engine(SERVER, DATABASE)