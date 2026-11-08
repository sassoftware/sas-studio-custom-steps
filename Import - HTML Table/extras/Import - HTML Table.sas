proc python restart;
submit;
import sys
try:
	import pandas as pd
	import lxml
except:
	SAS.logMessage('Ensure that both the pandas and lxml package are installed for Python', 'error')
	sys.exit()

# Pattern to work with SAS column names
ihtToReplacePattern = '[() -#$&,.]'

# Check if there is a table on the page
try:
	if SAS.symget('ihtScrappingType') == 'id':
		ihtDF = pd.read_html(SAS.symget('ihtURL'), attrs = {'id': SAS.symget('ihtTableID')})
	else:
		ihtDF = pd.read_html(SAS.symget('ihtURL'))
except:
	SAS.logMessage('No table found on the page.', 'error')
	SAS.logMessage('Tables build with HTML divs are not supported.', 'error')
	sys.exit()

# Check if there is more then one table returned
if len(ihtDF) > 1:
	SAS.logMessage(f"{len(ihtDF)} HTML tables have been found.")
	if SAS.symget('ihtScrappingType') == 'all':
		for i, currentDF in enumerate(ihtDF):
			currentDF.columns = [str(i) for i in currentDF.columns]
			valueList = currentDF.columns
			currentDF.columns = currentDF.columns.str.replace(ihtToReplacePattern, '', regex=True)[:32]
			labelDict = dict(zip(currentDF.columns, valueList))
			SAS.df2sd(currentDF, f"{SAS.symget('ihtOutputTable_lib')}.{SAS.symget('ihtOutputTable_name')[:28]}_{i}", labels=labelDict)
	else:
		ihtNthTable = int(SAS.symget('ihtNthTable'))
		ihtDF[ihtNthTable].columns = [str(i) for i in ihtDF[ihtNthTable].columns]
		valueList = ihtDF[ihtNthTable].columns
		ihtDF[ihtNthTable].columns = ihtDF[ihtNthTable].columns.str.replace(ihtToReplacePattern, '', regex=True)[:32]
		labelDict = dict(zip(ihtDF[ihtNthTable].columns, valueList))
		SAS.df2sd(ihtDF[ihtNthTable], SAS.symget('ihtOutputTable'), labels=labelDict)
else:
	ihtDF[0].columns = [str(i) for i in ihtDF[0].columns]
	valueList = ihtDF[0].columns
	ihtDF[0].columns = ihtDF[0].columns.str.replace(ihtToReplacePattern, '', regex=True)[:32]
	labelDict = dict(zip(ihtDF[0].columns, valueList))
	SAS.df2sd(ihtDF[0], SAS.symget('ihtOutputTable'), labels=labelDict)
endsubmit;
quit;

proc python terminate;
quit;