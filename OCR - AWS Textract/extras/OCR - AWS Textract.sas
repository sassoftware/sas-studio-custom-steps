proc python restart;
submit;

# Imports
import pandas as pd
import numpy as np
import os
import functools
import time
import sys
import boto3
from botocore.exceptions import ClientError, EndpointConnectionError


################### DEFINE PARAMETERS ###################
# General Input
ocr_type = SAS.symget("ocr_type") # text | form 
ocr_level = SAS.symget("ocr_level") # word | line | paragraph | page
ocr_form_type = SAS.symget("ocr_form_type") # TABLES |FORMS| QUERIES |SIGNATURES 
ocr_file_location = SAS.symget("ocr_file_location") # local | s3_bucket
ocr_input_table_name = SAS.symget("ocr_input_table") # table containing file paths
ocr_doc_column = SAS.symget("ocr_doc_column") # column that holds the path

# File location dependent (local / S3 bucket)
if ocr_file_location == 'local':
	ocr_input_type = SAS.symget("ocr_input_type_viya") # file | list 
	ocr_document_path = SAS.symget("ocr_document_path_viya") # for single file ocr
	aws_s3_bucket_name = ''
else:
	ocr_input_type = SAS.symget("ocr_input_type_bucket") # list | bucket
	aws_s3_bucket_name = SAS.symget("aws_s3_bucket_name")
	ocr_document_path = ''

# When input type is 'list'
if ocr_input_type == 'list':
	ocr_input_table = SAS.sd2df(ocr_input_table_name)
else:
	ocr_input_table = ''

# When input type is 'file'
if ocr_input_type == 'file':
	try:
		ocr_document_path = ocr_document_path.split(':', 1)[1]
	except Exception as e:
		SAS.logMessage("Please select a valid path. Files have to be located on SAS Server (not SAS Content)!", 'error')
		sys.exit()

# Ouput
output_status_table =  SAS.symget("output_status_table")

# Advanced 
overlap_threshold = float(SAS.symget("overlap_threshold")) # for paragrpah identification
n_connection_retries = int(SAS.symget("n_connection_retries")) # Default is 3
retry_delay = int(SAS.symget("retry_delay")) # Default is 2

# AWS
aws_region_name = SAS.symget("aws_region_name")  # eu-central-1 | us-east-1 | ...
aws_access_key = SAS.symget("aws_access_key")
aws_secret_key = SAS.symget("aws_secret_key")



##################### HELPER FUNCTIONS #####################
def retry_on_endpoint_connection_error(max_retries=3, delay=2):
    """
    This is a decorator function that allows a function to retry execution when an EndpointConnectionError occurs.

    Parameters:
    max_retries (int): The maximum number of retries if an EndpointConnectionError occurs. Default is 3.
    delay (int): The delay (in seconds) between retries. Default is 2.

    Returns:
    wrapper function: The decorated function that includes retry logic.
    """
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            retries = 0
            while retries < max_retries:
                try:
                    return func(*args, **kwargs)
                except EndpointConnectionError as e:
                    SAS.logMessage(f'Retrying due to EndpointConnectionError: {e}')
                    retries += 1
                    time.sleep(delay)
                except Exception as e:
                    raise e  # Let other exceptions be handled by the utility class

            if retries == max_retries:
                SAS.logMessage(f"Max retries ({max_retries}) reached. Unable to complete operation.", 'warning')
                raise RuntimeError("Max retries to contact AWS Textract endpoint reached. Unable to complete operation.")
        return wrapper

    return decorator

class ErrorHandlingUtility:
    """
    A utility class for handling exceptions related to Textract operations.

    This class provides a static method to handle exceptions that may occur during Textract operations.
    It specifically handles EndpointConnectionError and ClientError exceptions, logging the error message and re-raising the exception.
    For other types of exceptions, they are simply re-raised.

    Methods:
    handle_textract_exception(e: Exception, file: str) -> pd.Series or None:
        Handles Textract related exceptions, logs the error message, and re-raises the exception.
    """
    @staticmethod
    def handle_textract_exception(e, file):
        # handling EndpointConnectionError after number of retries
        if isinstance(e, EndpointConnectionError):
            status = pd.Series([file, False, type(e).__name__, str(e), pd.NA, pd.NA, pd.NA],
                               index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
            
            raise e

        # handle ClientErrors
        elif isinstance(e, ClientError):
            error_code = e.response['Error']['Code']
            if error_code in ['AccessDeniedException', 'InvalidParameterException', 'ServiceQuotaExceededException', 'UnrecognizedClientException']:
                SAS.logMessage(f"{error_code} occurred while processing documents.{e}", 'error')
                raise e
                
            status = pd.Series([file, False, type(e).__name__, str(e), pd.NA, pd.NA, pd.NA],
                               index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
            return status

        else:
            raise e  # Re-raise other exceptions


##################### FILE PREP STRATEGIES #####################
class DocumentInputStrategy:
    """ Document preparation strategy interface"""
    def process_files(self):
        pass

class SingleFileStrategy(DocumentInputStrategy):
    """ Document preparation strategy for single file input """

    def __init__(self, params):
        self.ocr_document_path = params.get('ocr_document_path')

    def process_files(self):
        """ Return the single file path as a dataframe """
        return pd.DataFrame({'file_path': [self.ocr_document_path]})

class FileListStrategy(DocumentInputStrategy):
    """ Document preparation strategy for list of files """

    def __init__(self, params):
        self.ocr_input_table = params.get('ocr_input_table')
        self.ocr_doc_column = params.get('ocr_doc_column')

    def process_files(self):
        """ Filter the input table to only include the specified path column """
        # filter the input table to only include path column
        file_list = self.ocr_input_table[[self.ocr_doc_column]]
        file_list = file_list.rename(columns={self.ocr_doc_column: 'file_path'})

        return file_list

class S3BucketStrategy(DocumentInputStrategy):
    """ Document preparation strategy for S3 bucket """
    def __init__(self, params):
        self.aws_region = params.get('aws_region')
        self.s3_bucket_name = params.get('s3_bucket_name')
        self.aws_access_key = params.get('aws_access_key')
        self.aws_secret_key = params.get('aws_secret_key')

    def process_files(self):
        """ Return a list of files in the specified S3 bucket """
        s3 = boto3.resource('s3',  
                            aws_access_key_id=self.aws_access_key,
                            aws_secret_access_key=self.aws_secret_key)
        
        s3_bucket = s3.Bucket(self.s3_bucket_name)

        file_paths = []
        try:
            for s3_file in s3_bucket.objects.all():
                file_paths.append(s3_file.key)
        except ClientError as e:
            if e.response['Error']['Code'] == 'InvalidS3ObjectException':
                SAS.logMessage(f"Invalid S3 object exception occurred.", 'error')
                raise e
            else:
                SAS.logMessage(f"An error occurred: {e}", 'error')
        
        file_list = pd.DataFrame({'file_path': file_paths})

        return file_list

class DocumentPreparer:
    """ Document preparation class that uses a strategy pattern to prepare documents for OCR """
    def __init__(self, ocr_input_type:str, **kwargs):
        self.ocr_input_type = ocr_input_type
        self.strategy = self._strategies.get(ocr_input_type)(**kwargs)

    _strategies = {
        "file": SingleFileStrategy,
        "list": FileListStrategy,
        "bucket": S3BucketStrategy,
    }

    def process_files(self):
        return self.strategy.process_files()


###################### OCR STRATEGIES #####################
class OCRStrategy:
    """ OCR strategy interface """
    def __init__(self, file_list, params):
        self.file_list = file_list
        self.params = params

    def process_ocr(self):
        pass

    def parse_result(self):
        self

class ExtractText(OCRStrategy):         # Textract.DetectDocumentText
    """ OCR strategy for extracting text from documents using Textract.DetectDocumentText """
    def __init__(self, file_list, ocr_params):
        #super().__init__(ocr_params)
        self.file_list = file_list
        self.aws_region_name = ocr_params["aws_region_name"]
        self.aws_ocr_access_key = ocr_params["aws_access_key"]
        self.aws_ocr_secret_key = ocr_params["aws_secret_key"]
        self.level = ocr_params["ocr_level"]

        self.ocr_file_location = ocr_params["ocr_file_location"]
        self.aws_s3_bucket_name = ocr_params["aws_s3_bucket_name"]

        self.overlap_threshold = ocr_params["overlap_threshold"]

    def merge_lines(self, df):
        """ Merge extracted text lines into paragraphs or pages 
        
        Parameters:
        df (pandas.DataFrame): dataframe containing the text lines

        Returns:
        pandas.DataFrame: dataframe containing the text in paragraphs or pages
        """
        concatenated_text = "\n ".join(df['Text'])

        # Calculate overall bounding box
        min_left = df['Left'].min()
        min_top = df['Top'].min()
        max_width = (df['Width'] + df['Left']).max() - min_left
        max_height = (df['Height'] + df['Top']).max() - min_top
        average_confidence = df['Confidence'].mean()

        page_data = {'Text': [concatenated_text],
                    'Width': [max_width],
                    'Height': [max_height],
                    'Left': [min_left],
                    'Top': [min_top],
                    'Confidence': [average_confidence]}

        return pd.DataFrame(page_data)

    def detect_paragraphs(self, df, overlap_threshold):
        """ Detect paragraphs in the extracted text based on vertical overlap of extracted text lines. 
        
        Parameters:
        df (pandas.DataFrame): dataframe containing the text lines
        overlap_threshold (float): the maximum vertical distance between two lines to be considered as part of the same paragraph
        
        Returns:
        pandas.DataFrame: dataframe containing the text in paragraphs
        """
        # Sort lines by the 'Top' coordinate
        df = df.sort_values(by='Top').reset_index(drop=True)
        overlap_threshold = self.overlap_threshold

        # Initialize a list to store paragraphs
        paragraphs = []
        current_paragraph = []
        paragraph_index = 0
        result_data = []

        # Iterate through rows 
        for index, row in df.iterrows():
            if not current_paragraph:
                current_paragraph.append({'Text': row['Text'], 'Width': row['Width'], 'Height': row['Height'],
                                        'Left': row['Left'], 'Top': row['Top'], 'Confidence': row['Confidence']})
            else:
                # Check if the current row overlaps vertically with the last row in the current paragraph
                if (row['Top'] - df.at[index - 1, 'Top']) <= overlap_threshold:
                    current_paragraph.append({'Text': row['Text'], 'Width': row['Width'], 'Height': row['Height'],
                                            'Left': row['Left'], 'Top': row['Top'], 'Confidence': row['Confidence']})
                else:
                    paragraphs.append(current_paragraph)
                    current_paragraph = [{'Text': row['Text'], 'Width': row['Width'], 'Height': row['Height'],
                                        'Left': row['Left'], 'Top': row['Top'], 'Confidence': row['Confidence']}]
                    paragraph_index += 1

        # Append the last paragraph
        paragraphs.append(current_paragraph)

        # Create the resulting DataFrame
        for i, paragraph in enumerate(paragraphs):
            for line in paragraph:
                result_data.append({'Paragraph': int(i), 'Text': line['Text'], 'Width': line['Width'], 'Height': line['Height'],
                                    'Left': line['Left'], 'Top': line['Top'], 'Confidence': line['Confidence']})

        return pd.DataFrame(result_data)

    def parse_result(self,overlap_threshold=0.1):
        """ Parse the Textract response into a dataframe
        
        Parameters:
        overlap_threshold (float): the maximum vertical distance between two lines to be considered as part of the same paragraph

        Returns:
        pandas.DataFrame: dataframe containing the parsed text
         """
        # results on page or paragraph level are not provided natively
        level = self.level
        result = self.response

        if (level.upper() == "PAGE" or level.upper() == "PARAGRAPH"):
            lod = "LINE"
        else:
            lod = level.upper()

        # initialize arrays
        text = []
        text_type = []
        block_types = []
        widths = []  
        heights = []
        lefts = []
        tops = []
        confidences = []

        # Extract words / lines from the Textract result
        for block in result["Blocks"]:
            if block["BlockType"] == lod:
                text.append(block["Text"])
                block_types.append(block["BlockType"])
                bounding_box = block["Geometry"]["BoundingBox"]
                widths.append(bounding_box["Width"])
                heights.append(bounding_box["Height"])
                lefts.append(bounding_box["Left"])
                tops.append(bounding_box["Top"])
                confidences.append(block.get("Confidence", None))

                # get the word type (only availabe when extracting on word level)
                if (lod == "WORD"):
                    text_type.append(block["TextType"])
                else:
                    text_type.append(np.nan)

        data = {
            "Text": text,
            "BlockType": block_types,
            "Width": widths,
            "Height": heights,
            "Left": lefts,
            "Top": tops,
            "Confidence": confidences
        }

        df = pd.DataFrame(data)
        
        # transform for "PAGE" output
        if (level.upper() == "PAGE"):
            df = self.merge_lines(df)

        # transform for "PARAGRAPH" output
        elif (level.upper() == "PARAGRAPH"):
            df = self.detect_paragraphs(df, overlap_threshold)
            df = df.groupby('Paragraph').apply(self.merge_lines).reset_index(level='Paragraph')
                
        return df

    @retry_on_endpoint_connection_error(max_retries=n_connection_retries, delay=retry_delay)
    def detect_document_text(self, client, file, imageBytes=None):
        """ Call the Textract.DetectDocumentText API
        
        Parameters:
        client (boto3.client): boto3 client for Textract
        file (str): the file path of the document to be processed
        imageBytes (bytearray): the byte array of the document to be processed

        Returns:
        dict: the response from the Textract.DetectDocumentText API
        
        """
        if self.ocr_file_location == 'local': 
            response = client.detect_document_text(Document={'Bytes': imageBytes})
        else: # documents are in s3 bucket
            response = client.detect_document_text(Document={'S3Object': {'Bucket': self.aws_s3_bucket_name, 'Name': file}})

        return response 

    def process_ocr(self):
        """ Process the OCR on the documents in the file list
        
        Returns:
        pandas.DataFrame: dataframe containing extracted and parsed text 
        """
        client = boto3.client('textract',
                                aws_access_key_id = self.aws_ocr_access_key, 
                                aws_secret_access_key = self.aws_ocr_secret_key,
                                region_name = aws_region_name)

        result_df = pd.DataFrame(columns=['File'])
        status_df = pd.DataFrame(columns=['File', 'Done', 'Error-Type','Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])

        # iterate through all documents
        for file in self.file_list['file_path']:
            
            # filter unsupported file types
            _, file_extension = os.path.splitext(file) 
            if file_extension.lower() in '.pdf':  # special case, because people expect this to work
                SAS.logMessage("PDF-Files are not supported! (will be skipped)", 'warning')                    

                status = pd.Series([file, False, 'File Format Error',   f"'.{file_extension.lower()}' files are not supported. Convert to .PNG or .JPEG", pd.NA, pd.NA, pd.NA],
                                    index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True) 
                continue
            elif file_extension.lower() not in ['.jpg', 'jpeg', '.png']:
                #raise ValueError(f"Unsupported file type at '{file}'.")
                status = pd.Series([file, False, 'File Format Error',   f"'.{file_extension.lower()}' files are not supported. Convert to .PNG or .JPEG", pd.NA, pd.NA, pd.NA],
                                    index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True) 
            
            # load files (if files are local)
            if self.ocr_file_location == 'local':
                try: 
                    with open(file, 'rb') as document:
                        imageBytes = bytearray(document.read())
                except Exception as e:
                        SAS.logMessage(f"An unexpected error occurred: {e}", 'error')                    
                        status = pd.Series([file, False, 'File Access Error',  e, pd.NA, pd.NA, pd.NA],
                                        index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                        status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True) 
                        continue

            # call textract api
            try:
                if self.ocr_file_location == 'local':
                    self.response = self.detect_document_text(client, file, imageBytes)
                else:
                    self.response = self.detect_document_text(client, file, )
            except ClientError as e:
                SAS.logMessage(f"Client Error: {e}", 'error')
                status = ErrorHandlingUtility.handle_textract_exception(e, file)
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True)
            except Exception as e:
                status = pd.Series([file, False, 'Textract-Error', f'{e}', pd.NA, pd.NA, pd.NA], #Unkonwn problem while parsing Textract response: 
                                index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True)  
                raise e

            # log files with erroneous calls 
            try:
                if (self.response['ResponseMetadata']['HTTPStatusCode'] != 200):
                    status = pd.Series([file, False, 'HTTP',  self.response['ResponseMetadata']['HTTPStatusCode'], pd.NA, pd.NA, pd.NA],
                                    index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                    status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True) 
                    continue
            except:
                pass
            
            # parse OCR result
            try:
                ocr_result = self.parse_result(self)
            except Exception as e:
                status = pd.Series([file, False, 'Parse-Error', f'{e}', pd.NA, pd.NA, pd.NA], #Unkonwn problem while parsing Textract response: 
                                index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True)  
                continue

            # track status of file processing
            try:
                status = pd.Series([file, True, '', '', 
                                ocr_result['Confidence'].mean(), 
                                ocr_result['Confidence'].max(), 
                                ocr_result['Confidence'].min()],
                                index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True)
            except KeyError as e:
                status = pd.Series([file, False, 'KeyError', f'{e}', pd.NA, pd.NA, pd.NA], #Unkonwn problem while parsing Textract response: 
                                index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True)  
                continue

            # add result to dataframe
            ocr_result['File'] = file
            result_df = pd.concat([result_df, ocr_result], ignore_index=True)

            
        if self.level.upper() == 'PARAGRAPH': # for some reason this turns to a float at some point
            result_df['Paragraph'] = result_df['Paragraph'].astype(int)

        return result_df, status_df
    
class ExtractForm(OCRStrategy):         # Textract.AnalyzeDocument
    """ OCR strategy for extracting key-value pairs from documents using Textract.AnalyzeDocument """

    def __init__(self, file_list, ocr_params):
        #super().__init__(ocr_params)
        self.file_list = file_list
        self.aws_region_name = ocr_params['aws_region_name']
        self.aws_ocr_access_key = ocr_params["aws_access_key"]
        self.aws_ocr_secret_key = ocr_params["aws_secret_key"]
        self.ocr_file_location = ocr_params["ocr_file_location"]
        self.aws_s3_bucket_name = ocr_params["aws_s3_bucket_name"]
        self.ocr_form_type = ocr_params ["ocr_form_type"]

    def find_value_block(self, key_block, value_map):
        """ Find the value block for a given key block
        
        Parameters:
        key_block (dict): the key block
        value_map (dict): the value map
        
        Returns:
        dict: the value block corresponding to the given key block """
        for relationship in key_block['Relationships']:
            if relationship['Type'] == 'VALUE':
                for value_id in relationship['Ids']:
                    value_block = value_map[value_id]
        return value_block

    def get_text(self, result, blocks_map):
        """ Get the text for a given block 
        
        Parameters:
        result (dict): the result containing the block
        blocks_map (dict): the map of blocks
        
        Returns:
        str: the text corresponding to the given block
        """
        text = ''
        if 'Relationships' in result:
            for relationship in result['Relationships']:
                if relationship['Type'] == 'CHILD':
                    for child_id in relationship['Ids']:
                        word = blocks_map[child_id]
                        if word['BlockType'] == 'WORD':
                            text += word['Text'] + ' '
                        if word['BlockType'] == 'SELECTION_ELEMENT':
                            if word['SelectionStatus'] == 'SELECTED':
                                text += 'X '

        return text

    def parse_result(self, ocr_form_type):
        """ Parse the Textract response into a dataframe
        
        Parameters:
        ocr_form_type (str): the type of form to extract (FORMS, TABLES, SIGNATURES, or ALL)
        
        Returns:
        pandas.DataFrame: dataframe containing the parsed key-value pairs """
        response = self.response

        if ocr_form_type == 'FORMS':
            blocks = response['Blocks']

            key_map = {}
            value_map = {}
            block_map = {}

            # create key and value map
            for block in blocks:
                block_id = block['Id']
                block_map[block_id] = block
                if block['BlockType'] == "KEY_VALUE_SET":
                    if 'KEY' in block['EntityTypes']:
                        key_map[block_id] = block
                    else:
                        value_map[block_id] = block

            kv_data = []

            # extract key-value data
            for key_block_id, key_block in key_map.items():
                value_block = self.find_value_block(key_block, value_map)
                key_bounding_box = key_block['Geometry']['BoundingBox']  # BoundingBox for the key
                value_bounding_box = value_block['Geometry']['BoundingBox']  # BoundingBox for the value

                kv_data.append({
                    'key': self.get_text(key_block, block_map),
                    'value': self.get_text(value_block, block_map),
                    'key_confidence': key_block['Confidence'],
                    'value_confidence': value_block['Confidence'],
                    'key_width' : key_bounding_box["Width"],
                    'key_height' :  key_bounding_box["Height"],
                    'key_left' : key_bounding_box["Left"],
                    'key_top' : key_bounding_box["Top"],
                    'value_width' : value_bounding_box["Width"],
                    'value_height' : value_bounding_box["Height"],
                    'value_left' : value_bounding_box["Left"],
                    'value_top' : value_bounding_box["Top"],
                })

            df = pd.DataFrame(kv_data)

        return df

    @retry_on_endpoint_connection_error(max_retries=n_connection_retries, delay=retry_delay)
    def analyze_document(self, client, file, imageBytes=None):
        """ Call the Textract.AnalyzeDocument API 
        
        Parameters:
        client (boto3.client): boto3 client for Textract
        file (str): the file path of the document to be processed
        imageBytes (bytearray): the byte array of the document to be processed
        
        Returns:
        dict: the response from the Textract.AnalyzeDocument API
        """
        if self.ocr_file_location == 'local': 
            response = client.analyze_document(Document={'Bytes': imageBytes,},
                                                FeatureTypes=["FORMS"])   
        else: # documents are in s3 bucket
            response = client.analyze_document(Document={'S3Object': {'Bucket': self.aws_s3_bucket_name, 
                                                                        'Name': file}},
                                                FeatureTypes=["FORMS"])  

        return response

    def process_ocr(self):
        """ Process the OCR on the documents in the file list
        
        Returns:
        pandas.DataFrame: dataframe containing extracted and parsed key-value pairs
        """
        client = boto3.client('textract',
                                aws_access_key_id = self.aws_ocr_access_key, 
                                aws_secret_access_key = self.aws_ocr_secret_key,
                                region_name = aws_region_name)
        result_df = pd.DataFrame(columns=['File'])
        status_df = pd.DataFrame(columns=['File', 'Done', 'Error-Type','Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])

        # iterate through all documents
        for file in self.file_list['file_path']:
            
            # filter unsupported file types
            _, file_extension = os.path.splitext(file)

            if file_extension.lower() in '.pdf':  # special case, because people expect this to work                      
                status = pd.Series([file, False, 'File Format Error',   f"'.{file_extension.lower()}' files are not supported. Convert to .PNG or .JPEG", pd.NA, pd.NA, pd.NA],
                                    index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True) 
                continue
            elif file_extension.lower() not in ['.jpg', 'jpeg', '.png']:
                status = pd.Series([file, False, 'File Format Error',   f"'.{file_extension.lower()}' files are not supported. Convert to .PNG or .JPEG", pd.NA, pd.NA, pd.NA],
                                    index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True) 
            
            # load files (if files are local)
            if self.ocr_file_location == 'local':
                try: 
                    with open(file, 'rb') as document:
                        imageBytes = bytearray(document.read())
                except Exception as e:
                        SAS.logMessage(f"An unexpected error occurred: {e}", 'error') 
                        status = pd.Series([file, False, 'File Access Error',  e, pd.NA, pd.NA, pd.NA],
                                        index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                        status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True) 
                        continue
           
            # call textract api
            try:
                if self.ocr_file_location == 'local':
                    self.response = self.analyze_document(client, file, imageBytes)
                else:
                    self.response = self.analyze_document(client, file)
            except ClientError as e:
                SAS.logMessage(f"Client Error: {e}", 'error') 
                status = ErrorHandlingUtility.handle_textract_exception(e, file)
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True)
            except Exception as e:
                status = pd.Series([file, False, 'Textract-Error', f'{e}', pd.NA, pd.NA, pd.NA], #Unkonwn problem while parsing Textract response: 
                                index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True)  
                raise e

            # log files with erroneous calls 
            try:
                if (self.response['ResponseMetadata']['HTTPStatusCode'] != 200):
                    status = pd.Series([file, False, 'HTTP',  self.response['ResponseMetadata']['HTTPStatusCode'], pd.NA, pd.NA, pd.NA],
                                    index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                    status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True) 
                    continue
            except:
                pass
            
            # parse OCR result
            try:
                ocr_result = self.parse_result(self.ocr_form_type)
            except Exception as e:
                status = pd.Series([file, False, 'Parse-Error', f'Unkonwn problem when parsing Textract response: {e}', pd.NA, pd.NA, pd.NA],
                                index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True)  
                continue
            
            # track status of file processing
            try:
                status = pd.Series([file, True, '', '', 
                                ocr_result[['key_confidence', 'value_confidence']].values.mean(), 
                                ocr_result[['key_confidence', 'value_confidence']].values.max(), 
                                ocr_result[['key_confidence', 'value_confidence']].values.min()],
                                index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True)
            except Exception as e:
                status = pd.Series([file, True, 'No detections',  'No key-value pairs were detected', pd.NA, pd.NA, pd.NA],
                                index=['File', 'Done', 'Error-Type', 'Message', 'Avg_Confidence', 'Max_Confidence', 'Min_Confidence'])
                status_df = pd.concat([status_df, status.to_frame().T], ignore_index=True)
                continue

            # add result to dataframe
            ocr_result['File'] = file
            result_df = pd.concat([result_df, ocr_result], ignore_index=True)

        return result_df, status_df

class OCRProcessor:
    """ OCR processing class that uses a strategy pattern to process OCR on documents """
    
    def __init__(self, ocr_type:str, file_list:pd.DataFrame, ocr_params:dict):
        self.ocr_type = ocr_type 
        self.file_list = file_list
        self.ocr_params = ocr_params

        # Define the strategy mapping
        self.strategy_mapping = {
            ("text"): ExtractText,
            ("form"): ExtractForm
        }

        # Get the strategy class, parameters and initiate strategy
        strategy_class = self.strategy_mapping[(self.ocr_type)]
        #strategy_params = ocr_params.get("strategy_params", {})
        self.strategy = strategy_class(self.file_list, ocr_params)

    def process_ocr(self):
        return self.strategy.process_ocr()


################### EXECUTION ###################
# Document Preparer
input_params={# General Input Parameters
                'ocr_document_path': ocr_document_path,
                'ocr_input_table': ocr_input_table,
                'ocr_doc_column': ocr_doc_column,
                'ocr_document_path': ocr_document_path,
                
                # AWS Parameter
                'aws_region': aws_region_name,
                's3_bucket_name': aws_s3_bucket_name,
                'aws_access_key': aws_access_key,
                'aws_secret_key': aws_secret_key
                }

document_preparer = DocumentPreparer(ocr_input_type = ocr_input_type, params = input_params)

try:
    file_list = document_preparer.process_files()
except Exception as e:
    SAS.logMessage(e, 'error')
    sys.exit()

# OCR Processor
try:
	ocr_params={# General OCR Parameters
	            'ocr_level': ocr_level,
	            'ocr_form_type': ocr_form_type,
	            'ocr_file_location': ocr_file_location,
	            'overlap_threshold': overlap_threshold,
	
	            # AWS Parameters
	            'aws_access_key': aws_access_key,
	            'aws_secret_key': aws_secret_key,
	            'aws_region_name': aws_region_name,
	            'aws_s3_bucket_name': aws_s3_bucket_name
	            }
	ocr_processor = OCRProcessor(ocr_type = ocr_type,
	                             file_list = file_list,
	                             ocr_params = ocr_params
	                            )
	
	ocr_result, processing_status = ocr_processor.process_ocr()
	
	n_total = file_list.shape[0]
	n_processed = processing_status['Done'].sum()
except Exception as e:
    SAS.logMessage(e, 'error')
    sys.exit()

# Final table
if ocr_input_type == 'list': # merge with input table to retain other information
    final_df = pd.merge(ocr_result, ocr_input_table, left_on='File',right_on=ocr_doc_column, how='left')
else: 
    final_df = ocr_result

final_df = SAS.df2sd(final_df,SAS.symget("_output1"))
if output_status_table == '1':
    processing_status = SAS.df2sd(processing_status,SAS.symget("_output2"))

SAS.logMessage(f'{int(n_processed)} out of {n_total} documents were processed.')

endsubmit;
run;

proc python terminate; quit; 
