# How to provide AWS credentials to your SAS session

AWS S3 buckets, unless explicitly made publicly accessible, require credentials to access.  

While there are potentially several ways in which those options can be passed, the following are the most common patterns.

1. **Option statements in autoexec.sas**

In a SAS compute session, an `option` statement can be used to set environmental variables.

```sas

option set=AWS_ACCESS_KEY_ID="Your Access Key";
option set=AWS_SECRET_ACCESS_KEY="Your Secret";
option set=AWS_REGION="Your bucket's AWS region e.g. us-east-1";

option set=AWS_SESSION_TOKEN="Your short-term session token if applicable";

```

While these potentially can be set anytime before your main code that consumes the token is run, it's recommended to confine these to your autoexec to avoid unnecessary exposure.  *Also, note that the autoexec is safer, but not foolproof and should not be viewed as a long-term credential store.*

2. **Set these in the preamble of a custom step when running in a Flow**

If you're using the custom step as part of a Flow in SAS Studio (now known as SAS Data and AI Studio), you can also use the preamble section of the customm step to run the same `option set=` statements as above.  Note that this is less secure and can potentially compromise your credentials if you make the Flow available to others, so we recommend you use this only for testing purposes.

