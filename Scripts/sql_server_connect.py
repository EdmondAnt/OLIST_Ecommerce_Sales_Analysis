from sqlalchemy import create_engine, engine, text
from pathlib import Path
from pandas import read_sql_query, DataFrame
from sqlalchemy.exc import SQLAlchemyError


def mssql_engine(server : int, database : int
                 ):
    """Creates a SQLAlchemy engine for Microsoft SQL Server using ODBC Driver 18.
    :param server: Server hostname, IP, or instance (e.g., 'localhost' or
    'localhost\\SQLEXPRESS')
    :param database: Name of the target SQL Server database
    """

    connection_string = (
    'DRIVER={ODBC Driver 18 for SQL Server};'
    f'SERVER={server};'
    f'DATABASE={database};'
    'Trusted_Connection=yes;'
    'Encrypt=yes;'
    'TrustServerCertificate=yes;'
)
    connection_url = engine.URL.create(
    'mssql+pyodbc',
    query={'odbc_connect': connection_string},
)
# Create the engine instance
    sql_engine = create_engine(connection_url)
    
    # Test connection immediately to catch wrong parameters right away
    try:
        with sql_engine.connect() as connection:
            pass  # Connection successful
    except SQLAlchemyError as e:
        raise ConnectionError(
            f"Failed to connect to SQL Server! "
            f"Please verify your parameters -> Server: '{server}', Database: '{database}'.\n"
            f"Underlying error: {e}"
        ) from e
        
    return sql_engine

def generic_engine(
    db_type: str, server: str, database: str, user: str = None, password: str = None
):
    if db_type == "mssql":
        conn_str = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={server};DATABASE={database};Trusted_Connection=yes;Encrypt=yes;TrustServerCertificate=yes;"
        url = engine.URL.create("mssql+pyodbc", query={"odbc_connect": conn_str})
    elif db_type == "postgresql":
        url = f"postgresql+psycopg2://{user}:{password}@{server}/{database}"
    elif db_type == "mysql":
        url = f"mysql+pymysql://{user}:{password}@{server}/{database}"
    else:
        raise ValueError(f"Unsupported database type: {db_type}")

    return create_engine(url)

def load_sql_to_df(file_path : str, connection : str) -> DataFrame:
    """Reads SQL file using SQLAlchemy text function, Path from pathlib and and pd.read_to_sql. 
    Executes it with engine connection.
    Returns pd.DataFrame
    """
    path = Path(file_path)
    #assert path.exists() , f"File not found at {path.absolute()}"

    try:     
        raw_sql = path.read_text(encoding="utf-8")

    except FileNotFoundError as error:
        raise FileNotFoundError(
            f"  File not found at {path.absolute()}"
            f"  Current Working Dir: {Path.cwd()}"
        ) from error
    
    query = text(raw_sql)
    df = read_sql_query(query, con = connection)
    return df



if __name__ == "__main__":
    SERVER = r'localhost\SQLEXPRESS'  # Change to the server name supplied by your instructor.
    DATABASE = 'OlistDB'
    mssql_engine(SERVER, DATABASE)