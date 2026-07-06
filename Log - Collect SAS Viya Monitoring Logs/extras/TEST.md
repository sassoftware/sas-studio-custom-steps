# Test Patterns
The following test patterns are used during development.

- Macro
  - Normal use cases
  - Timezone test patterns
  - Debug-related test patterns
  - Error handling test patterns
  - Save and reset test patterns

## Macro

### Normal use cases
```
options notes nosource nomprint nomlogic nomlogicnest nosymbolgen;
%let passwd=foobar;

filename rakeConf filesrvc folderpath="&configFolder" filename="&configFile";
data _null_;
  rc=fdelete("rakeConf");
run;

/* Create the configuration file. */
%rake(user=admin, password=%str(&passwd.));

%let opensearch_user=admin;
%let opensearch_password=%str(&passwd.);
%rake;
%symdel opensearch_user /nowarn;
%symdel opensearch_password /nowarn;

%rake(out=work.test);
proc datasets lib=work nolist;
  delete test;
quit;

data _null_;
  call symputx('from', put(datetime()-180, e8601dt.), 'G');
  call symputx('to', put(datetime(), e8601dt.), 'G');
run;

%put NOTE: &=from &=to;
%rake(from="&from", to="&to");

%rake(from="now-30s", to="now");

%rake(from="now-5m", to="now-1m");

%rake(from="now-1h", to="now-30m");

%rake(from="now-1d", to="now-23h");

%rake(from="now-1w", to="now-6d");

%rake(from="now-1M", to="now-29d");

%rake(from="now-1y", to="now-364d");

%rake(message="NOTE");

%rake(from="now-3m", to="now", tsvdir="sasserver:/tmp");
```


### Timezone test patterns

Examples using the `tz` option.


These test cases verify how the macro interprets timestamps when different time zone settings are specified.
Both time zone abbreviations and IANA timezone identifiers are included as test inputs.

```
%rake(from="2026-05-01T09:00:00", to="2026-05-01T09:00:00");

%rake(from="2026-05-01T09:00:00", to="2026-05-01T09:00:00", tz=default);

%rake(from="2026-05-01T09:00:00", to="2026-05-01T09:00:00", tz=HKT);

%rake(from="2026-05-01T09:00:00", to="2026-05-01T09:00:00", tz=HST);

%rake(from="2026-05-01T09:00:00", to="2026-05-01T09:00:00", tz=UTC);

%rake(from="2026-05-01T09:00:00", to="2026-05-01T09:00:00", tz=Africa/Nairobi);

%rake(from="2026-05-01T09:00:00", to="2026-05-01T09:00:00", tz=America/Bogota);

```


### Debug test patterns
Examples using debug, verbose, and related options.

```
%rake(from="now-3m", to="now", debug=1);

%rake(from="now-3m", to="now", verbose=1);

%rake(from="now-3m", to="now", summary=0);

%rake(from="now-3m", to="now", check=0);
```

### Error test patterns
Test cases that intentionally trigger errors.

```
%rake(user=admin, password=%str(xyz));

%rake(out=WOOORK.LOG);

%rake(from="now-2m", to="now-3m");

%rake(from="now-100M", to="now-99M", message="failed");

%rake(from="now-1m", to="now", tsvdir="sasserver:/var/tmp");

%rake(from="now-3m", to="now", tsvdir="sascontent:/NoFolder");
```

### Save and reset test patterns
The save= and reset= options were added to allow the UI to update and recreate the configuration file as needed.

```
%rake(save=1, user=admin, password=blahblah);
%rake(save=0);

%rake(save=1, user=admin, password=&passwd., url=http://www.sas.com/index.html);
%rake(save=0);

%rake(reset=1);
%rake(reset=0);
```
