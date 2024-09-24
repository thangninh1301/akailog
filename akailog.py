import os
import pandas as pd
import pyodbc
from datetime import datetime

# Function to find today's file in the directory (Nexus)
def find_today_file(directory):
    today = datetime.now().strftime("%Y-%m-%d")  # Format: YYYY-MM-DD
    for file_name in os.listdir(directory):
        if file_name.startswith('result-') and today in file_name:
            return os.path.join(directory, file_name)
    return None

# Function to read the Excel file and convert to list of dictionaries
def read_excel_to_dict(excel_file_path):
    df = pd.read_excel(excel_file_path)
    return df.to_dict(orient='records')  # Converts to list of dicts (Array of objects)

# Function to import data into MSSQL database
def import_data_to_mssql(data, table_name, conn_str):
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()

    # Assuming that the column names in the DataFrame match the SQL table column names
    for row in data:
        columns = ', '.join(row.keys())
        placeholders = ', '.join('?' * len(row))
        sql = f"INSERT INTO {table_name} ({columns}) VALUES ({placeholders})"
        
        # Execute the SQL with the row values
        cursor.execute(sql, tuple(row.values()))
    
    # Commit the transaction
    conn.commit()
    cursor.close()
    conn.close()

# Main function to execute the process
def main():
    directory = "/path/to/nexus"  # Replace with the actual path to the Nexus folder
    excel_file = find_today_file(directory)
    
    if excel_file is None:
        print("No file found for today.")
        return
    
    # Read the Excel file
    data = read_excel_to_dict(excel_file)
    
    # Connection string for MSSQL (replace with your own connection details)
    conn_str = (
        'DRIVER={SQL Server};'
        'SERVER=your_server_name;'
        'DATABASE=your_database_name;'
        'UID=your_username;'
        'PWD=your_password'
    )
    
    # Import data into the desired MSSQL table
    table_name = 'your_table_name'
    import_data_to_mssql(data, table_name, conn_str)
    print(f"Data from {excel_file} has been successfully imported into {table_name}.")

if __name__ == "__main__":
    main()
