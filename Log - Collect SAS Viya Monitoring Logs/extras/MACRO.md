# Rake Macro Usage Guide

This document describes how to use the `%rake` SAS macro to extract and analyze logs from OpenSearch in SAS Viya.

The goal of this document is to provide a small, practical guide for users who run the macro directly from SAS Studio.
It focuses on what you need to know to run the macro, understand its results, and adjust basic settings when necessary.

## 1. About This Document

### Scope

This document covers:
- How to execute the `%rake` macro
- Typical usage patterns and examples
- Macro parameters and their behavior
- The configuration file (`rakeConfig.txt`)
- Output datasets and their structure

This document does not cover:
- Custom Step UI usage
- Internal macro implementation details



## 2. Quick Start

### 2.1 Run with Defaults

```sas
%rake;
```

This is the simplest way to execute the macro.

When a configuration file already exists and encoded credentials are stored in it, the macro can be executed without explicitly specifying a user name or password.

Default behavior:
- Extracts logs from the last 15 minutes
- Outputs results to `WORK.LOG`
- Uses credentials stored in `rakeConfig.txt`
- Creates the configuration file automatically if it does not exist

### 2.2 Specify Credentials Explicitly

```sas
%rake(user=admin, password=foobar);
```

Use this pattern when:
- Running the macro for the first time
- Updating credentials
- Avoiding reliance on an existing configuration file

### 2.3 Specify a Time Range

```sas
%rake(from="now-3h", to="now-1h");
```

This extracts logs between the specified start and end times.

### 2.4 Filter by Log Message

```sas
%rake(
  from="2024-06-18T12:00:00",
  to="now",
  message="failed"
);
```

This extracts only log entries whose message field contains the specified string.

### 2.5 Update or Recreate the Configuration File

```sas
%rake(save=1, user=admin, password=foobar, url=default);
%rake(reset=1);
```

- `save=1` stores credentials and URL in the configuration file
- `reset=1` deletes and recreates the configuration file

## 3. Execution Model (Overview)

At a high level, the macro performs the following steps:

1. Parse macro arguments
2. Load or initialize the configuration file
3. Execute OpenSearch REST API calls repeatedly to bypass the 10,000-record limit
4. Merge and normalize the retrieved log data
5. Generate SAS datasets
6. Optionally aggregate logs and check for known error patterns

## 4. Macro Parameter Reference

This section explains what each macro parameter does.

|No.|Parameters and Defaults|Description and Examples|
|---|---|---|
|1|out=work.log|Specify the name of the dataset to be logged. If omitted, WORK.LOG is used. <br>out=work.log|
|2|from="now-15m"<br>to="now"|Specify the period of time from which logs are to be extracted.<br>From is the starting point and to is the ending point, and only one of them cannot be omitted.<br>Values in the following format, enclosed in double quotes that can be specified. Postfixes indicating time relative to the current time, where s means seconds, m means minutes, h means hours, d means days, w means weeks, and M means months. now-3h means 3 hours before the current time.<br><br>Sepcify local date and time<br>from="2024-06-30T12:00:15"<br><br>current time<br>from="now"<br><br>30 seconds before the current time<br>from="now-30s"<br><br>1 minute before the current time<br>from="now-1m"<br><br>1 day before the current time<br>from="now-1d"<br><br>1 week before the current time<br>from="now-1w"<br><br>1 month before the current time<br>from="now-1M"|
|3|tz=default| Specify the time zone used to interpret timestamps. The default value is "default", which uses the session’s default time zone. Other valid values include JST, UTC, or a time zone ID such as America/New_York. <br>tz=Asia/Tokyo|
|4|user=|Specify an OpenSearch user name. Instead of the argument, it can be specified by the global macro variable opensearch_user. <br>user=%str(admin)|
|5|password=|Specify the OpenSearch password. Instead of the argument, it can be specified by the global macro variable opensearch_password. <br>password=%str(foobar)|
|6|message=|Specify the characters contained in the MESSAGE field as log extraction criteria. This option is intended to capture specific error messages over a relatively broad time period. <br>message="failed container"|
|7|debug=0|Arguments for debugging. Set debug=1 to output detailed logs.|
|8|verbose=0|Arguments for debugging. Set verbose=1 to log NOTE information.|
|9|summary=0|Arguments to enable/disable the ability to aggregate logs. When summary=0 is set, the log frequency summary and plotting are not performed. This should be specified when the amount of logs is large and the time for frequency aggregation and plotting is desired to be omitted.|
|10|check=0|Argument to enable/disable the error pattern checking function. If check=0 is set, no error pattern check is performed. Error patterns are defined as multiple strings, such as "Out Of Memory" or "SAS/TK is aborting". The pattern is checked to see if it is included in the message, and if so, the variable check in the log is set to the number of the pattern. Error patterns are defined in the configuration file (rakeConfig.txt). Any pattern can be added by editing the configuration file with an editor.|
|11|save=0|If save=1 is specifed, the encoded credentials and URL will be saved in the configuration file. No search is performed. <br>This option has been added to allow you to change the username and password from the custom step UI and have the changes reflected in the configuration file. |
|12|reset=0|If reset=1 is specified, the config file is deleted and recreated. If the encodedCredential value can be obtained from the file before it is deleted, that value is reused. No search is performed. <br>Since the OpenSearch URL may differ depending on the environment, this option has been added so that the default value can be changed from the UI.|
|13|url=|Specify the OpenSearch URL. This will be used instead of the URL value in the configuration file. If you specify url=default, the default URL will be applied.|
|14|query=work.query|Holds the number of cases matching the pattern contained in WORK.LOG.|


## 5. Configuration File: rakeConfig.txt

The macro uses a configuration file to persist settings across runs.

### What Is Stored

- Encoded credentials
- OpenSearch API URL
- Error message patterns used for log checking

### Location and Constraints

- Created under **My Folder** in SAS Contents
- Not stored as an OS-level file on the SAS server

### Typical Lifecycle

- Created automatically on first run
- Updated with `save=1`
- Recreated with `reset=1` if necessary

## 6. Output Datasets

Understanding the output datasets is essential for effective use of the macro.

### 6.1 WORK.LOG

`WORK.LOG` is the primary output dataset containing the extracted log entries.

The format of the data set WORK.LOG is shown below.

|No.|Column name|type|length|Description.|
|---|---|---|---|---|
|1|timestamp|number|8|Date and time of E8601DT23.3 format|
|2|hour|number|8|timestamp time|
|3|minute|number|8|minutes of timestamp|
|4|second|number|8|Timestamp seconds|
|5|check|number|8|Error message pattern number|
|6|utc|character|32|UTC date and time|
|7|id|character|64|id|
|8|level|character|16|level|
|9|logsource|character|64|logsource|
|10|container|character|64|kube.container|
|11|pod|character|64|kube.pod|
|12|message|character|4096|message|
|13|username|character|32|launcher_sas_com/username|
|14|client|character|32|launcher_sas_com/requested-by-client|
|15|pattern|character|132|Patterns included in the message|
|16|n|number|8|Variable added to maintain log order|

This dataset is intended for:
- Interactive filtering in SAS Studio
- Reviewing detailed log messages
- Further analysis using SAS procedures such as `PROC FREQ` or `PROC SGPLOT`

### 6.2 WORK.QUERY

`WORK.QUERY` is an auxiliary dataset created during processing.
It contains Counts of log entries that match defined error patterns.

The dataset layout is shown below.


|No.|Column name|type|length|Description.|
|---|---|---|---|---|
|1|n|number|8|Identifier of the matched error pattern|
|2|text|character|132|Pattern matching string|


## 7. Settings

This section describes configuration options that may need to be adjusted depending on your environment and operational requirements.

For initial testing, these settings usually do not need to be changed.  
However, they often become important when the macro is used continuously in daily operations.

### Macro Variables Defined in Rake.step

Some default settings are defined as macro variables at the top of the SAS program embedded in `Rake.step`.

These macro variables control core behavior such as where the configuration file is created and how the macro accesses OpenSearch.

Typical settings defined in `Rake.step` include:
|No.| Macro variable|Description.|
|---|---|---|
|1|configFolder|The folder for the configuration file. By adjusting this values, `Rake.step` can be shared and used by multiple users.|
|2|configFile|The name of the configuration file.|
|3|configUrl|URL of the OpenSearch API.|
|4|configMaxLoop|The maximum number of times the OpenSearch API can be called.|

If you need to change the default location of the configuration file or allow multiple users to use a shared setup, update these macro variables in `Rake.step`.

### Error Checking Patterns

Error checking patterns are defined in the configuration file (`rakeConfig.txt`).

These patterns are used to detect known or frequently occurring errors by matching text strings in log messages.  
While the default patterns cover common cases, operational use often requires adding or updating patterns as new error messages are identified.

Only a subset of error patterns is shown here.
Because these patterns may change over time, refer to the configuration file for the complete and up-to-date list.

- SAS/TK is aborting
- Error creating compute session
- Unable to launch node
- Error stopping CAS session
- ObjectOptimisticLockingFailureException
- ServerOperationException
- ODBC SQL Server Wire Protocol driver
- Internal Server Error
- Child terminated by signal
- Unhandled Exception
- killed
- OOM
- OutOfMemory

You can edit the configuration file to customize the error checking patterns according to your environment and operational needs.

---
End of document.