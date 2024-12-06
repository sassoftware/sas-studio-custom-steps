# Query Decision-Flow in batch mode
The example is calling a decision flow from SAS Intelligent Decisioning. The decision flow is running in MAS and is called via its REST API.<br>
The decision flow is looking for Comedy movies with actors  'Adam Sandler', 'Emma Thompson' or 'John Cleese' in it and sets an appropriate flag.<br>
To be able to run the decision flow in batch mode it takes a list of movies in a datagrid as input parameter and returns the datagrid with an additional flag to mark the movies.<br>
In SAS Studio we have a table listing 9000+ movies. We use the HTTP Request Step in batch mode to take slices of 2000 movies per HTTP request. This way we call the decision flow 5 times instead of 9000+ times.


![](../../img/HTTPRequest_ex7.gif)

---

## Run the demo in your environment

To run the demo in your Viya environment follow the steps below:

1.  Download files *Decision-Flow-Batch.json* and *n_movies.csv.zip*.
2.  Unzip *n_movies.csv.zip*.
3.  Import *n_movies.csv* into SAS Viya library *CASUSER*.<br>
    If you cannot import into *CASUSER* chose different library.
4.  Import Decision-Flow-Batch.json into SAS Viya.<br>
    Import through Environment Manager or through Intelligent Decisioning (right burger menu 'Import objects from JSON file' - Viya 2024.06 or later)
5.  Go to Intelligent Decisioning:<br>
    5.1 Publish Decision-Flow *selectMovies* to MAS with published name: *selectMovies*
6.  Go to SAS Studio:<br>
    6.1 Open *SAS Content/Public/Demo/HTTP Request/movie/Call Decisionflow – Batch.flw*<br>
    6.2 Ensure the step N_MOVIES is pointing at the imported dataset n_movies. If N_MOVIES is not in CASUSER point to the correct location.
7.  Run Flow job

![](../../img/HTTPRequest_ex7_install.gif)
