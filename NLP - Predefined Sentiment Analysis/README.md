# Natural Language Processing (NLP) - Predefined Sentiment Analysis

This custom step helps you analyse a text corpus for the sentiment expressed in the same.  It uses a SAS Cloud Analytics Services (CAS) action, sentimentAnalysis.applySentimentConcepts, along with a language-specific, predefined, document-level sentiment analysis model, following a symbolic AI (rules-based) approach.

Use this to classify customer reviews, voice of customer / survey responses, public opinion and any other text data which reflects attitudes and emotions, into positive or negative sentiment.

This custom step uses a CAS action which requires a SAS Visual Analytics license.
 
## A general idea

![Predefined Sentiment Analysis](./img/predefined_sentiment_analysis_general_idea.gif)

## SAS Viya Version Support
Tested in Viya 4, Stable 2023.03

## Requirements

1. A SAS Viya 4 environment (monthly release 2023.03 or later) with SAS Studio Flows.

2. **At runtime: an active connection to CAS:** This custom step requires SAS Cloud Analytics Services (CAS). Ensure you have an active CAS connection available prior to running the same.

3. A SAS Visual Analytics (VA) license. VA is a foundational technology available with most SAS Viya offerings.


## User Interface

### Parameters:

Note that this custom step runs on data loaded in SAS Cloud Analytics Services (CAS). Ensure you are connected to CAS before running this step.

#### Input parameters:

1. Input table (input port,required): connect a CAS table containing text intended for sentiment analysis.  The table should contain at least one character / varchar variable with the text to be scored, along with a document ID.

2. Text column (required): select either a char/ varchar column from the input table.

3. Document ID column (required): select a column which provides an ID for each observation.

4. Language (default is English): select the language in which you wish to perform sentiment analysis.  You have a choice of 17 languages, with English as the default selection.


#### Output specifications:

1. Additional columns (optional): select additional columns from the input table which you would like to carry over to the output table.

2. Output table (output port, required): connect a CAS table to contain the document-level sentiment and the score.

3. Matches table (output port, required): connect a CAS table to obtain keyword matches per document, corresponding to the concepts within the sentiment analysis model.


## Documentation:

- The [sentimentAnalysis.applySentimentConcepts CAS action](https://go.documentation.sas.com/doc/en/sasstudiocdc/default/pgmsascdc/casanpg/cas-sentimentanalysis-applysentimentconcepts.htm)


## Installation & Usage
- Refer to the [steps listed here](https://github.com/sassoftware/sas-studio-custom-steps#getting-started---making-a-custom-step-from-this-repository-available-in-sas-studio).

### Sample Data
In case you would like to test this step with some sample data, run this code prior to the custom step.  This example is adapted from the one provided in the documentation link above, with an additional column added to help you experience the full range of functionality provided by this step.

```sas

/* Connect to CAS, if not done already */

cas my_cas_session;

/* 'PUBLIC' refers to the libref for the shared PUBLIC caslib, which is automatically assigned when the next line is run */

caslib _ALL_ assign;

/* This generates a small sample CAS table which you can use as the input table for the custom step */

data PUBLIC.apply_sent_text;                           
   length text $200  additional_field $100 ;
   infile datalines delimiter='|' missover;
   input docid text$ additional_field $;
   datalines;     
     1| Somewhere over the rainbow.| Carry me over.        
     2| Perfectly good camera for the average user! | Not completely useless.
     3| This is a great camera. | Carry me over.
     4| Very bad experience with Nikon S200. | Useful for something.
   ;
run;

```

If you'd prefer more sample data, feel free to add additional lines, with | as the delimiter between fields.  A gentle (and not very serious) suggestion, in case you are looking for a way to generate additional data, would be to use an external tool called [ChatGPT](http://chat.openai.com) (use at your own discretion) to generate random sentences with positive sentiment :).  


## Created / contact : 

- Sundaresh Sankaran (sundaresh.sankaran@sas.com)

## Change Log

Version : 1.0.   (04APR2023)