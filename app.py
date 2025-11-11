import pyodbc
from flask import Flask, render_template, request, redirect, url_for, flash
import os 

# --- PATH FIX: Ensures Flask finds the 'templates' folder correctly ---
basedir = os.path.abspath(os.path.dirname(__file__))
app = Flask(
    __name__,
    template_folder=os.path.join(basedir, 'templates') 
)
app.secret_key = 'super_secret_key_for_dbms_project' 

# --- Database Connection Configuration ---
CONNECTION_STRING = (
    'DRIVER={ODBC Driver 17 for SQL Server};'
    'SERVER=localhost\\SQLEXPRESS;'
    'DATABASE=FuelManagementSystem;'
    'Trusted_Connection=yes;' 
)

def get_db_connection():
    """Establishes and returns a pyodbc connection object."""
    try:
        conn = pyodbc.connect(CONNECTION_STRING)
        return conn
    except pyodbc.Error as ex:
        sqlstate = ex.args[0]
        print(f"Database Connection Error: {sqlstate}")
        # Only flash the error message if it's not the initial load trying to connect
        if request.path != '/':
            flash(f"Database connection failed! Error: {sqlstate}", 'error')
        return None

# --- Core Application Routes ---

@app.route('/')
def index():
    """Dashboard: Displays current fuel prices and tank levels (Read Operation)."""
    conn = get_db_connection()
    if conn is None:
        return render_template('index.html', tanks=[], fuels=[])

    cursor = conn.cursor()
    
    try:
        # 1. Get Tank Levels 
        cursor.execute("SELECT Tank_ID, Current_Level_Liters, Capacity_Liters, T.Fuel_Type_ID, F.Name FROM TANKS T JOIN FUEL_TYPES F ON T.Fuel_Type_ID = F.Fuel_Type_ID;")
        tanks = [dict(zip([column[0] for column in cursor.description], row)) for row in cursor.fetchall()]
        
        # 2. Get Fuel Prices
        cursor.execute("SELECT Fuel_Type_ID, Name, Current_Price_Per_Liter FROM FUEL_TYPES;")
        fuels = [dict(zip([column[0] for column in cursor.description], row)) for row in cursor.fetchall()]
    
    except Exception as e:
        flash(f"Error fetching data from database: {e}", 'error')
        tanks = []
        fuels = []
        
    finally:
        cursor.close()
        conn.close()
    
    return render_template('index.html', tanks=tanks, fuels=fuels)


@app.route('/process_sale', methods=['POST'])
def process_sale():
    """Calls the ProcessSale stored procedure (Sale/Deduction logic)."""
    if request.method == 'POST':
        conn = get_db_connection()
        if conn is None:
            return redirect(url_for('index'))
            
        try:
            pump_id = int(request.form['pump_id'])
            employee_id = int(request.form['employee_id'])
            liters_sold = float(request.form['liters_sold'])

            cursor = conn.cursor()
            
            # Calling the Stored Procedure for sale
            cursor.execute(
                "{CALL dbo.ProcessSale (?, ?, ?)}",
                pump_id, employee_id, liters_sold
            )
            conn.commit()
            flash("Sale processed successfully! Inventory updated by Trigger.", 'success')
        
        except pyodbc.ProgrammingError as e:
            # Catching custom RAISERROR messages from SQL procedures
            error_message = str(e).split(']')[2].strip() if '50000' in str(e) else str(e)
            flash(f"Sale failed: {error_message}", 'error')
            conn.rollback()
        except ValueError:
            flash("Invalid input. Please enter valid numbers for IDs and Liters.", 'error')
            conn.rollback()
        except Exception as e:
            flash(f"An unexpected error occurred: {e}", 'error')
            conn.rollback()
        finally:
            if 'cursor' in locals():
                cursor.close()
            if conn:
                conn.close()

    return redirect(url_for('index'))


@app.route('/restock_tank', methods=['POST'])
def restock_tank():
    """NEW ROUTE: Calls the RestockTank stored procedure (Addition logic with capacity check)."""
    if request.method == 'POST':
        conn = get_db_connection()
        if conn is None:
            return redirect(url_for('index'))
            
        try:
            tank_id = int(request.form['tank_id'])
            liters_added = int(request.form['liters_added'])

            cursor = conn.cursor()
            
            # Calling the new Stored Procedure for restock
            cursor.execute(
                "{CALL dbo.RestockTank (?, ?)}",
                tank_id, liters_added
            )
            conn.commit()
            flash(f"Tank {tank_id} restocked successfully by {liters_added}L.", 'success')
        
        except pyodbc.ProgrammingError as e:
            # Catching the RAISERROR for capacity overflow
            error_message = str(e).split(']')[2].strip() if '50000' in str(e) else str(e)
            flash(f"Restock Failed (Capacity Check): {error_message}", 'error')
            conn.rollback()
        except ValueError:
            flash("Invalid input. Please enter valid numbers for Tank ID and Liters Added.", 'error')
            conn.rollback()
        except Exception as e:
            flash(f"An unexpected error occurred: {e}", 'error')
            conn.rollback()
        finally:
            if 'cursor' in locals():
                cursor.close()
            if conn:
                conn.close()

    return redirect(url_for('index'))


@app.route('/reports')
def reports():
    """Runs the complex T-SQL queries (Complex Queries with GUI)."""
    conn = get_db_connection()
    if conn is None:
        return render_template('reports.html', joins=[], aggregates=[], nesteds=[])

    cursor = conn.cursor()
    
    joins, aggregates, nesteds = [], [], []

    try:
        # 1. Join Query
        JOIN_QUERY = """
            SELECT T.Transaction_ID, E.Name AS Employee_Name, P.Pump_Number, F.Name AS Fuel_Type, T.Liters_Sold, T.Total_Amount
            FROM TRANSACTIONS T JOIN EMPLOYEES E ON T.Employee_ID = E.Employee_ID
            JOIN PUMPS P ON T.Pump_ID = P.Pump_ID JOIN FUEL_TYPES F ON P.Fuel_Type_ID = F.Fuel_Type_ID
            ORDER BY T.[datetime] DESC;
        """
        cursor.execute(JOIN_QUERY)
        joins = [dict(zip([column[0] for column in cursor.description], row)) for row in cursor.fetchall()]

        # 2. Aggregate Query
        AGGREGATE_QUERY = """
            SELECT F.Name AS Fuel_Type, SUM(T.Total_Amount) AS Total_Revenue, SUM(T.Liters_Sold) AS Total_Liters_Sold, COUNT(T.Transaction_ID) AS Number_of_Sales
            FROM TRANSACTIONS T JOIN PUMPS P ON T.Pump_ID = P.Pump_ID
            JOIN FUEL_TYPES F ON P.Fuel_Type_ID = F.Fuel_Type_ID GROUP BY F.Name ORDER BY Total_Revenue DESC;
        """
        cursor.execute(AGGREGATE_QUERY)
        aggregates = [dict(zip([column[0] for column in cursor.description], row)) for row in cursor.fetchall()]

        # 3. Nested Query
        NESTED_QUERY = """
            SELECT E.Employee_ID, E.Name FROM EMPLOYEES E
            WHERE E.Employee_ID IN (
                SELECT T.Employee_ID FROM TRANSACTIONS T
                WHERE T.Total_Amount > (SELECT AVG(Total_Amount) FROM TRANSACTIONS)
            );
        """
        cursor.execute(NESTED_QUERY)
        nesteds = [dict(zip([column[0] for column in cursor.description], row)) for row in cursor.fetchall()]

    except Exception as e:
        flash(f"Error running reports: {e}", 'error')

    finally:
        cursor.close()
        conn.close()
    
    return render_template('reports.html', joins=joins, aggregates=aggregates, nesteds=nesteds)


if __name__ == '__main__':
    app.run(debug=True)