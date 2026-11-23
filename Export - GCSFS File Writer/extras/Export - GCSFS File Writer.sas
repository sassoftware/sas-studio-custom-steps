/***********************************************************************
 Custom Step for reading parquet files from GCSFS, supports reading from 
 partitioned directory structure and also can apply filtering criteria
 up to 3 conditions.

***********************************************************************/

%macro getCredentialsFile();
    %let locationType=%sysfunc(scan(&infileCredentialsFile,1,:,M));
    %let fullpath=%sysfunc(scan(&infileCredentialsFile,2,:,M));
    %if &locationType=sascontent %then %do;
        %let file = %scan(&fullpath., -1, '/');
        %let path = %substr(&fullpath.,1,%length(&fullpath.)-%length(&file.));
        %let infileCredentialsFile=&_SASWORKINGDIR./key.json;
        filename src filesrvc folderpath="&path." filename="&file.";
        filename target disk "&infileCredentialsFile.";
        data _null_;
            length msg $ 384;
            rc=fcopy('src', 'target');
            if rc=0 then
                put 'Copied SRC to TARGET.';
            else do;
                msg=sysmsg();
                put rc= msg=;
            end;
        run;   
    %end;
    %else %if &locationType=sasserver %then %do;
        %let infileCredentialsFile=&fullpath.;
    %end;
%mend getCredentialsFile;

%getCredentialsFile();


proc python terminate;
submit;

import logging
from abc import ABCMeta

from cloud_arrow.gcsfs import GCSFSObjectStorage
from cloud_arrow.core import DeltaLakeWriteOptions, ParquetWriteOptions
from saspy import SASsession



# -------------  INI Utilities --------------------------------------------------------------------------
class GCSFSFileWriter(metaclass=ABCMeta):
    """
    Pyarrow expression filter generator
    """

    def __init__(self,
                 SAS: SASsession,
                 project: str,
                 access: str,
                 token: str,
                 bucket: str,
                 default_location: str,
                 sas_format_selector_id: str,
                 existing_data_behavior: str,
                 compression_codec: str,
                 partition_table: bool,
                 sas_part_selector_id: str):
        """

        :param SAS:
        :param project:
        :param access:
        :param token:
        :param bucket:
        :param default_location:
        :param sas_format_selector_id:
        :param existing_data_behavior:
        :param compression_codec:
        :param partition_table:
        :param sas_part_selector_id:
        """

        self._logger = logging.getLogger('sas.customSteps.GCSFSFileWriter')

        if SAS is None:
            self._logger.error("The SAS object is mandatory")
            raise ValueError("The SAS object is mandatory")
        else:
            self._SAS = SAS

        self._project = project
        self._access = access
        self._token = token

        format_selector = self._SAS.symget(f"{sas_format_selector_id}")
        self._logger.debug(
            f" SAS macro '{sas_format_selector_id}' Type: {type(format_selector)}, Value: {format_selector}")
        if format_selector not in ["parquet", "deltalake"]:
            raise ValueError(f"The format must be one of: 'parquet', 'deltalake'")
        self._format = format_selector
        self._bucket = bucket
        self._default_location = default_location

        if compression_codec not in [None, 'snappy']:
            self._logger.error("The param 'compression_codec' should be one of ['None', 'snappy'].")
            raise ValueError("compression_codec should be one of ['None', 'snappy'].")
        else:
            self._compression_codec = compression_codec

        if format == "parquet":
            if existing_data_behavior not in ['error', 'overwrite_or_ignore', 'delete_matching']:
                self._logger.error("The param 'existing_data_behavior' should be one of ['error', "
                                   "'overwrite_or_ignore','delete_matching'].")
                raise ValueError("existing_data_behavior should be one of ['error', 'overwrite_or_ignore', "
                                 "'delete_matching'].")
        elif format == "deltalake":
            if existing_data_behavior not in ['error', 'append', 'overwrite', 'ignore']:
                self._logger.error("The param 'existing_data_behavior' should be one of ['error', 'append', "
                                   "'overwrite', 'ignore'].")
                raise ValueError("existing_data_behavior should be one of ['error', 'append', 'overwrite', 'ignore'].")

        self._existing_data_behavior = existing_data_behavior

        if partition_table:
            sas_part_selector = self._SAS.symget(f"{sas_part_selector_id}")
            self._logger.debug(
                f" SAS macro '{sas_part_selector_id}' Type: {type(sas_part_selector_id)}, Value: {sas_part_selector_id}")

            if sas_part_selector is None or sas_part_selector == "":
                raise ValueError(
                    f"When 'partition' value is True the {sas_part_selector_id} macro {sas_part_selector_id} was not found on the SASsession")
            else:
                self._sas_part_selector_id = sas_part_selector_id
        else:
            self._sas_part_selector_id = None

        # if self._existing_data_behavior == "delete_matching":
        #     self.__delete_dir_contents()

    # def __delete_dir_contents(self):
    #     info = self._filesystem.get_file_info(self._root_path)
    #
    #     # FileInfo:
    #     #     base_name: str
    #     #     extension: str
    #     #     is_file: bool
    #     #     mtime: datetime
    #     #     mtime_ns: int
    #     #     path: str
    #     #     size: int
    #     #     type: FileType
    #
    #     if not info.is_file:  # is directory
    #         self._filesystem.delete_dir_contents(self._root_path)

    def __generate_partitions_list(self, sas_part_selector_id):
        """

        :param sas_part_selector_id:
        :return:
        """

        self._logger.debug(
            f" SAS macro 'sas_part_selector_id' Type: {type(sas_part_selector_id)}, Value: {sas_part_selector_id}")

        if sas_part_selector_id is None:
            return None

        sas_part_selector_id_count = self._SAS.symget(f"{sas_part_selector_id}_count")
        self._logger.info(
            f" SAS macro '{sas_part_selector_id}_count' Type: {type(sas_part_selector_id_count)},"
            f" Value: {sas_part_selector_id_count}")

        partitions_no = int(sas_part_selector_id_count)
        self._logger.info(f" Python var 'partitions_no' Type: {type(partitions_no)}, Value: {partitions_no}")
        if partitions_no is None or partitions_no == "":
            return None
        else:
            partitions = []
            for i in range(1, partitions_no + 1):
                column_name = self._SAS.symget(f"{sas_part_selector_id}_{i}_name")
                self._logger.debug(
                    f" SAS macro '{sas_part_selector_id}_{i}_name' Type: {type(column_name)}, Value: {column_name}")

                partitions.append(column_name)

            self._logger.info(f" result 'partitions' Type: {type(partitions)}, Value: {partitions}")
            return partitions

    def write(self, table, path):

        # https://arrow.apache.org/docs/10.0/python/generated/pyarrow.dataset.write_dataset.html
        writer = GCSFSObjectStorage(
            project=self._project,
            access=self._access,
            token=self._token,
            bucket=self._bucket,
            default_location=self._default_location
        )

        if self._format == "parquet":

            writer.write(table=table, file_format=self._format,
                         path=path,
                         write_options=ParquetWriteOptions(
                             partitions=self.__generate_partitions_list(self._sas_part_selector_id),
                             compression_codec=self._compression_codec,
                             existing_data_behavior=self._existing_data_behavior)
                         )

        elif self._format == "deltalake":

            writer.write(table=table, file_format=self._format,
                         path=path,
                         write_options=DeltaLakeWriteOptions(
                             partitions=self.__generate_partitions_list(self._sas_part_selector_id),
                             compression_codec=self._compression_codec,
                             existing_data_behavior=self._existing_data_behavior)
                         )

# -------------  END Utilities --------------------------------------------------------------------------



# -------------  INI CustomStep Logic --------------------------------------------------------------------
logging.basicConfig(level=logging.ERROR)

# create logger
logger = logging.getLogger('sas.customsteps.gcsfsFileWriter')
logger.setLevel(logging.INFO)

credentials_file = SAS.symget('infileCredentialsFile')
project = SAS.symget('intextProject')
bucket = SAS.symget('intextBucket')
file_path = SAS.symget('intextFilePath')
dpdownFormat = SAS.symget('dpdownFormat')
chkCompression = SAS.symget('chkCompression')
chkPartitioned = SAS.symget('chkPartitioned')

logger.info(f" SAS macro 'infileCredentialsFile' Type: {type(credentials_file)}, Value: {credentials_file}")
logger.info(f" SAS macro 'intextProject' Type: {type(project)}, Value: {project}")
logger.info(f" SAS macro 'intextBucket' Type: {type(bucket)}, Value: {bucket}")
logger.info(f" SAS macro 'intextFilePath' Type: {type(file_path)}, Value: {file_path}")
logger.info(f" SAS macro 'dpdownFormat' Type: {type(dpdownFormat)}, Value: {dpdownFormat}")
logger.info(f" SAS macro 'chkCompression' Type: {type(chkCompression)}, Value: {chkCompression}")
logger.info(f" SAS macro 'chkPartitioned' Type: {type(chkPartitioned)}, Value: {chkPartitioned}")

useCompression = (int(chkCompression) == 1)
isParted = (int(chkPartitioned) == 1)

logger.info(f" Python var 'useCompression' Type: {type(useCompression)}, Value: {useCompression}")
logger.info(f" Python var 'isParted' Type: {type(isParted)}, Value: {isParted}")


useCompression = (int(chkCompression) == 1)
isParted = (int(chkPartitioned) == 1)

logger.info(f" Python var 'useCompression' Type: {type(useCompression)}, Value: {useCompression}")
logger.info(f" Python var 'isParted' Type: {type(isParted)}, Value: {isParted}")

if dpdownFormat == "parquet":
    dpdownExistingDataBeh = SAS.symget('dpdownExistingDataBehParq')

elif dpdownFormat == "deltalake":
    dpdownExistingDataBeh = SAS.symget('dpdownExistingDataBehDelta')

dpdownCompressCodec = SAS.symget('dpdownCompressCodec')

logger.info(f" SAS macro 'dpdownCompressCodec' Type: {type(dpdownCompressCodec)}, Value: {dpdownCompressCodec}")

intblid_source = SAS.symget('intblid_source')
inputdf = SAS.sd2df(intblid_source)

GCSFSFileWriter(
    SAS=SAS,
    token=credentials_file,
    project=project,
    bucket=bucket,
    access="read_write",
    default_location="",
    sas_format_selector_id="dpdownFormat",
    existing_data_behavior=dpdownExistingDataBeh,
    compression_codec=dpdownCompressCodec if useCompression else None,
    partition_table=isParted,
    sas_part_selector_id="colselPartitionCols"
).write(table=inputdf, path=file_path)

# -------------  END CustomStep Logic --------------------------------------------------------------------

endsubmit;
quit;


