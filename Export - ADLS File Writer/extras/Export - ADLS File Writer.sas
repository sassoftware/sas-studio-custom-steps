/***********************************************************************
 Custom Step for reading parquet files from ADLS, supports reading from 
 partitioned directory structure and also can apply filtering criteria
 up to 3 conditions.

***********************************************************************/

proc python terminate;
submit;

import logging
from abc import ABCMeta

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from adlfs import AzureBlobFileSystem
from saspy import SASsession


# -------------  INI Utilities --------------------------------------------------------------------------
class ADLSFilerWriter(metaclass=ABCMeta):
    """

    """

    def __init__(self,
                 SAS: SASsession,
                 tenant_id: str,
                 client_id: str,
                 client_secret: str,
                 account_name: str,
                 container: str,
                 existing_data_behavior: str,
                 compression_codec: str,
                 partition_table: bool,
                 sas_part_selector_id: str):
        """

        :param SAS:
        :param tenant_id:
        :param client_id:
        :param client_secret:
        :param account_name:
        :param container:
        :param existing_data_behavior:
        :param compression_codec:
        :param partition_table:
        :param sas_part_selector_id:
        """

        self._logger = logging.getLogger('sas.customsteps.adlsFileWriter')

        if SAS is None:
            self._logger.error("The SAS object is mandatory")
            raise ValueError("The SAS object is mandatory")
        else:
            self._SAS = SAS

        self._container = container

        self._filesystem = AzureBlobFileSystem(
            account_name=account_name,
            tenant_id=tenant_id,
            client_id=client_id,
            client_secret=client_secret
        )

        if compression_codec not in [None, 'snappy']:
            self._logger.error("The param 'compression_codec' should be one of ['None', 'snappy'].")
            raise ValueError("compression_codec should be one of ['None', 'snappy'].")
        else:
            self._compression_codec = compression_codec

        if existing_data_behavior not in ['error', 'overwrite_or_ignore', 'delete_matching']:
            self._logger.error("The param 'existing_data_behavior' should be one of ['error', 'overwrite_or_ignore', "
                               "'delete_matching'].")
            raise ValueError("existing_data_behavior should be one of ['error', 'overwrite_or_ignore', "
                             "'delete_matching'].")
        else:
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
            f" SAS macro '{sas_part_selector_id}_count' Type: {type(sas_part_selector_id_count)}, Value: {sas_part_selector_id_count}")

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

        if isinstance(table, pd.DataFrame):
            pyarr_table = pa.Table.from_pandas(table)
        elif isinstance(table, pa.Table):
            pyarr_table = table
        else:
            raise f"The parameter 'table' type must be one of [pandas.DataFrame, pyarrow.Table]"

        if path is None or path == "":
            raise "The path argument can not be empty"

        root_path = path[:-1] if path.endswith("/") else path

        partitions = self.__generate_partitions_list(
            self._sas_part_selector_id if self._sas_part_selector_id is not None else None
        )

        self._logger.debug(f""" Write to Dataset: 
                                root_path: '{root_path}'
                                filesystem: {type(self._filesystem)}
                                file_format:{self._compression_codec}
                                existing_data_behavior:{self._existing_data_behavior}
                                partition_cols: {partitions}
                            """)

        if self._compression_codec == "snappy":
            pq.write_to_dataset(
                pyarr_table,
                root_path=f"{self._container}/{root_path}",
                filesystem=self._filesystem,
                existing_data_behavior=self._existing_data_behavior,
                partition_cols=partitions
            )
        else:
            pq.write_to_dataset(
                pyarr_table,
                root_path=f"{self._container}/{root_path}",
                filesystem=self._filesystem,
                compression=self._compression_codec,
                existing_data_behavior=self._existing_data_behavior,
                partition_cols=partitions
            )

# -------------  END Utilities --------------------------------------------------------------------------



# -------------  INI CustomStep Logic --------------------------------------------------------------------
logging.basicConfig(level=logging.ERROR)

# create logger
logger = logging.getLogger('sas.customsteps.adlsFileWriter')
logger.setLevel(logging.INFO)

tenant_id = SAS.symget('intextTenantId')
client_id = SAS.symget('intextClientid')
client_secret = SAS.symget('intextClientSec')
storage_account_name = SAS.symget('intextStorageAccount')
container_name = SAS.symget('intextContainer')
intextFilePath = SAS.symget('intextFilePath')
dpdownFormat = SAS.symget('dpdownFormat')
chkCompression = SAS.symget('chkCompression')
chkPartitioned = SAS.symget('chkPartitioned')

logger.info(f" SAS macro 'intextTenantId' Type: {type(tenant_id)}, Value: {tenant_id}")
logger.info(f" SAS macro 'intextClientid' Type: {type(client_id)}, Value: {client_id}")
logger.info(f" SAS macro 'intextClientSec' Type: {type(client_secret)}, Value: {client_secret}")
logger.info(f" SAS macro 'intextStorageAccount' Type: {type(storage_account_name)}, Value: {storage_account_name}")
logger.info(f" SAS macro 'intextContainer' Type: {type(container_name)}, Value: {container_name}")
logger.info(f" SAS macro 'intextFilePath' Type: {type(intextFilePath)}, Value: {intextFilePath}")
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

dpdownExistingDataBeh = SAS.symget('dpdownExistingDataBeh')
dpdownCompressCodec = SAS.symget('dpdownCompressCodec')

intblid_source = SAS.symget('intblid_source')
inputdf = SAS.sd2df(intblid_source)

ADLSFilerWriter(
    SAS=SAS,
    tenant_id=tenant_id,
    client_id=client_id,
    client_secret=client_secret,
    account_name=storage_account_name,
    container=container_name,
    existing_data_behavior=dpdownExistingDataBeh,
    compression_codec=dpdownCompressCodec if useCompression else None,
    partition_table=isParted,
    sas_part_selector_id="colselPartitionCols"
).write(table=inputdf, path=intextFilePath)
# -------------  END CustomStep Logic --------------------------------------------------------------------

endsubmit;
quit;


