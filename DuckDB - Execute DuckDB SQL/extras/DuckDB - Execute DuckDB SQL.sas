PROC Python;
submit;

#################################################################################
import duckdb
import os
import time

#################################################################################
#function to remoce comment from SQL statement. We need to do this as the sql statement
#is being passed in by SAS without end of line.
#For this custom step we expect a semicolon (;) as an end of comment sign.
#################################################################################
def removeComment(stmt):
    while True:
        comStart= stmt.find('--')
        if comStart >= 0:
            stmtS= stmt[0:comStart]
            stmtE= stmt[comStart:]
            comEnd= stmtE.find(';')
            if comEnd >= 0:
                stmt= stmtS + ' ' + stmtE[comEnd+1:]
            else:
                print("Missing semicolon (;) for end of comment!")
                break
            idx= comEnd
        else:
            break
    return stmt
#################################################################################
#function to output message and stop executing the step
#################################################################################
def abortStep(msg):
    print('*******************************************************************')
    print(msg)
    print('*******************************************************************')
    sas_stmt='data _null_;put "Error executing in DuckDB! See message below (after proc printto) for more details."; abort;run;'
    SAS.submit(sas_stmt)

#################################################################################
#function to read general csv parameters
#################################################################################
def readCsvGeneralParameters(files):
    parameters={}
    parameters["sample_size"]= int(SAS.symget("_sample_size_gen"))
    parameters["skip"]= int(SAS.symget("_skip_gen"))
    parameters["all_varchar"]= int(SAS.symget("_all_varchar_gen"))
    parameters["union_by_name"]= int(SAS.symget("_union_by_name_csv_gen"))
    parameters["filename"]= int(SAS.symget("_filename_csv_gen"))
    parameters["delim"]= SAS.symget("_delim_gen")
    parameters["quote"]= SAS.symget("_quote_gen")
    parameters["dateformat"]= SAS.symget("_dateformat_gen")
    parameters["decimal_separator"]= SAS.symget("_decimal_separator_gen")
    parameters["nullstr"]= SAS.symget("_nullstr_gen")

    files['general']= parameters
    return files
#################################################################################
#function to read file csv parameters
#################################################################################
def readCsvFileParameters(files):
    file_cnt= int(SAS.symget("_csv_files_cnt")) +1

    for i in range(1,file_cnt):
        if len(SAS.symget("_filename_f" +str(i))) > 0:
            parameters={}
            parameters["names"]= SAS.symget("_names_f" +str(i))
            parameters["columns"]= SAS.symget("_columns_f" +str(i))
            parameters["sample_size"]= int(SAS.symget("_sample_size_f" +str(i)))
            parameters["skip"]= int(SAS.symget("_skip_f" +str(i)))
            parameters["all_varchar"]= int(SAS.symget("_all_varchar_f" +str(i)))
            parameters["delim"]= SAS.symget("_delim_f" +str(i))
            parameters["quote"]= SAS.symget("_quote_f" +str(i))
            parameters["dateformat"]= SAS.symget("_dateformat_f" +str(i))
            parameters["decimal_separator"]= SAS.symget("_decimal_separator_f" +str(i))
            parameters["nullstr"]= SAS.symget("_nullstr_f" +str(i))
            
            files[SAS.symget("_filename_f" +str(i))]= parameters
    return files
#################################################################################
#function to prepare the sql statement for csv files
#################################################################################
def prepCSV(stmt):
    files= {}
    files= readCsvGeneralParameters(files)
    files= readCsvFileParameters(files)

    stmt_csv= ''
    for line in stmt.split('\n'):
        for token in line.split(' '):
            idx= token.find(".csv")
            if idx >= 0:
                stmt_csv= stmt_csv + " read_csv_auto('" + token[0:idx+4].strip() +"'"
                #in case there is something after .csv we save it here and add it at the end
                token_end= token[idx+4:]
                #determin if we have to use the general file parameters or the flie overwrite parameters
                if token[0:idx+4].strip() not in files:
                    token= 'general'

                for parameter in files[token]:
                    if type(files[token][parameter]) == int:
                        stmt_csv= stmt_csv +"," +parameter +"=" +str(files[token][parameter])
                    elif type(files[token][parameter]) == str:
                        if len(files[token][parameter]) > 0:
                            if parameter == 'columns':
                                stmt_csv= stmt_csv +"," +parameter +'= ' +files[token][parameter]
                            elif parameter == 'quote' and files[token][parameter] == '"':
                                stmt_csv= stmt_csv +"," +parameter +"= '" +files[token][parameter] +"'"
                            else:
                                stmt_csv= stmt_csv +"," +parameter +'= "' +files[token][parameter] +'"'

                stmt_csv= stmt_csv + ")" + token_end

            else:
                stmt_csv= stmt_csv + ' ' + token.strip()
        stmt_csv= stmt_csv.strip() + '\n'
    return stmt_csv
#################################################################################
#function to prepare the sql statement for parquet files
#################################################################################
def prepParquet(stmt):
    #get Parquet parameters
    filename= int(SAS.symget("_filename"))
    file_row_number= int(SAS.symget("_file_row_number"))
    union_by_name= int(SAS.symget("_union_by_name"))

    stmt_parquet= ''
    for line in stmt.split('\n'):
        for token in line.split(' '):
            idx= token.find(".parquet")
            if idx >= 0:
                stmt_parquet= stmt_parquet + " read_parquet('" + token[0:idx+8].strip() +"'"
                if filename:
                    stmt_parquet= stmt_parquet + ", filename=true"
                if file_row_number:
                    stmt_parquet= stmt_parquet + ", file_row_number=true"
                if union_by_name:
                    stmt_parquet= stmt_parquet + ", union_by_name=true"
                stmt_parquet= stmt_parquet + ")" +token[idx+8:]
            else:
                stmt_parquet= stmt_parquet + ' ' + token.strip()
        stmt_parquet= stmt_parquet.strip() + '\n'
    return stmt_parquet  
#################################################################################
#function to connect to Postgres database
#################################################################################
def connectPostgres(con): 
    #we need a database for the Postgres views. We put it in '/tmp/duckdb'
    home_directory= '/tmp/duckdb'
    try:
        os.mkdir(home_directory)
    except:
        pass
    #set the DuckDB home directory
    con.execute("PRAGMA home_directory='" + home_directory +"'")
    con.execute("INSTALL postgres")
    con.execute("LOAD postgres")

    #Get Postgres connection parameters
    pg_host= SAS.symget("_pg_host")
    pg_port= SAS.symget("_pg_port")
    pg_user= SAS.symget("_pg_user")
    pg_pwd= SAS.symget("_pg_pwd")
    pg_database= SAS.symget("_pg_database")
    pg_schema= SAS.symget("_pg_schema")
    ddb_schema= SAS.symget("_ddb_schema")

    #if the DuckDB schema does not exist yet, we create it
    try:
        con.execute("CREATE SCHEMA IF NOT EXISTS " + ddb_schema)
    except Exception as err:
        abortStep(str(err))

    #Connect to Postgres
    connectStmt="CALL postgres_attach('host=" + pg_host +" port=" +pg_port +" user=" +pg_user +" password=" +pg_pwd +" dbname=" +pg_database +"', source_schema='" +pg_schema +"', sink_schema='" +ddb_schema +"', overwrite=true)"
    try:
        con.execute(connectStmt)
    except Exception as err:
        abortStep(str(err))

    return
#################################################################################
#Main. The script start executing here
#################################################################################
time_step_s= time.time()
DuckDB= ":memory:"
#check if we use persistent database 
if int(SAS.symget("_duckdb_persist")) == 1:
    #get the name for the DuckDB for persistent database. If not set we connect as :memory:
    DuckDB= SAS.symget("_duckdbName")
    if len(DuckDB) > 0:
        if DuckDB[0:10] != "sasserver:":
            abortStep("DuckDB must be on SAS Server not on SAS Content!")

        #cut off sasserver:
        DuckDB= DuckDB[10:]

        #if there is no fuffix yet we add the suffix duckdb
        if DuckDB.split('/')[len(DuckDB.split('/'))-1].find('.') < 0:
            DuckDB+= '.duckdb'
    else:
        DuckDB= ":memory:"

#connect to memory database
con= duckdb.connect(DuckDB)

#set the search path for parquet, csv, and json files
file_search_path= SAS.symget("_file_search_path")
con.execute("set file_search_path to '" + file_search_path +"'")

#get the configuration settings and submit them in one execution line
configuration= SAS.symget("_configuration")
if len(configuration) > 0:
    configStmt= ''
    for setStmt in configuration.split(';'):
        if len(setStmt) > 0:
            configStmt+= 'set ' +setStmt.strip() +'; '
    try:
        con.execute(configStmt)
    except Exception as err:
        abortStep(str(err))

#read input table (if there is one) into a dataframe
#We can use the name "_flow_table" in the sql statement to reference the input table
inputtable= SAS.symget("_inputtable")
#if there is a flow input table we assign it to a dataframe
if len(inputtable) > 0:
    _flow_table= SAS.sd2df(inputtable)

#connect to Postgres if needed
if int(SAS.symget("_pg_connect")):
    connectPostgres(con)

#get the SQL statement
sqlstmt= SAS.symget("_sqlstmt")

#we need to remove SQL comments as the SQL comes in as one long string without and end of line which we would need for the comments
sqlstmt= removeComment(sqlstmt)

#do not run file parameters if switch off (in SQL page)
#if switched off the use can run pass through DuckDB SQL symtax
if int(SAS.symget("_ignore_file_options")) == 0:
    #prepare sql statement for parquet files
    sqlstmt= prepParquet(sqlstmt)

    #prepare sql statement for csv files
    sqlstmt= prepCSV(sqlstmt)

#execute sql statement
try:
    time_sql_s= time.time()
    df_out= con.execute(sqlstmt).df()
    time_sql_e= time.time()
except Exception as err:
    abortStep(str(err))
else:
    #get the name for the step output table and pass the SQL result to the output table
    outputtable= SAS.symget("_outputtable")
    SAS.df2sd(df_out, outputtable)
    time_step_e= time.time()

    print("#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#")
    print("Step stats:")
    print("Time to execute Step " +str(round(time_step_e - time_step_s, 3)) +" sec")
    print("Time to execute SQL  " +str(round(time_sql_e - time_sql_s, 3)) +" sec")
    print("#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#*#")

con.close()


#################################################################################

endsubmit;
QUIT;