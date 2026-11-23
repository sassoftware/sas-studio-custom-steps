/***********************************************************************
 Custom Step for reading parquet files from ADLS, supports reading from 
 partitioned directory structure and also can apply filtering criteria
 up to 3 conditions.

***********************************************************************/

proc python terminate;
submit;

import json
import logging
import re
from abc import ABCMeta, abstractmethod
from copy import deepcopy
from typing import Union

import pandas as pd
import pyarrow as pa
import pyarrow.dataset as ds
import pyarrow.parquet as pq
from adlfs import AzureBlobFileSystem
from fsspec.implementations.local import LocalFileSystem
from fsspec.spec import AbstractFileSystem
from pyarrow.dataset import dataset as pyarrow_dataset
from saspy import SASsession

# -------------  INI Utilities --------------------------------------------------------------------------
class ADLSFilerReader(metaclass=ABCMeta):
    """
    Pyarrow expression filter generator
    """

    def __init__(self,
                 SAS: SASsession,
                 tenant_id: str,
                 client_id: str,
                 client_secret: str,
                 account_name: str,
                 container: str,
                 sas_format_selector_id: str,
                 apply_filters: bool,
                 sas_num_cond_selector_id: str,
                 sas_cond_field_sel_prefix_id: str,
                 sas_cond_isnum_sel_prefix_id: str,
                 sas_cond_operator_sel_prefix_id: str,
                 sas_cond_value_sel_prefix_id: str,
                 sas_cond_chain_sel_prefix_id: str):
        """

        :param SAS:
        :param tenant_id:
        :param client_id:
        :param client_secret:
        :param account_name:
        :param container:
        :param sas_format_selector_id:
        :param apply_filters:
        :param sas_num_cond_selector_id:
        :param sas_cond_field_sel_prefix_id:
        :param sas_cond_isnum_sel_prefix_id:
        :param sas_cond_operator_sel_prefix_id:
        :param sas_cond_value_sel_prefix_id:
        :param sas_cond_chain_sel_prefix_id:
        """

        self._logger = logging.getLogger('sas.customsteps.adlsFileReader')

        if SAS is None:
            self._logger.error("The SAS object is mandatory")
            raise ValueError("The SAS object is mandatory")
        else:
            self._SAS = SAS

        self._tenant_id = tenant_id
        self._client_id = client_id
        self._client_secret = client_secret
        self._account_name = account_name

        format_selector = self._SAS.symget(f"{sas_format_selector_id}")
        self._logger.debug(
            f" SAS macro '{sas_format_selector_id}' Type: {type(format_selector)}, Value: {format_selector}")
        if format_selector not in ["parquet", "deltalake"]:
            raise ValueError(f"The format must be one of: 'parquet', 'deltalake'")
        self._format = format_selector
        self._container = container

        self._apply_filters = apply_filters

        if self._apply_filters:
            num_cond_sel = self._SAS.symget(f"{sas_num_cond_selector_id}")
            self._logger.debug(
                f" SAS macro '{sas_num_cond_selector_id}' Type: {type(num_cond_sel)}, Value: {num_cond_sel}")

            if num_cond_sel not in ["1", "2", "3"]:
                raise ValueError(f"The number of partitions must be between 1 and 3")

            self._num_cond = int(num_cond_sel)

            self._filter_conditions = []
            self._filter_chain_opp = []

            """
            Generates the fields _filter_conditions and _filter_chain_opp
            The _filter_conditions property is a json object describing the filter condition with the following structure:
            {
                field: str      -> "holds the value of the 'intextPartFieldCond{i}' field",
                isNum: bool     -> "holds the value of the 'chkIsNumCond{i}' field",
                operator: str   -> "holds the value of the 'dpdownOperatorsCond{i}' field",
                value1: str/int -> "holds the value of the 'intextCond1Val{i}' field",
                value2: str/int -> "holds the value of the 'intextCond2Val1{i}' field",
            }
            """
            for i in range(1, self._num_cond + 1):
                filter_cond = {}
                condition_field = self._SAS.symget(f"{sas_cond_field_sel_prefix_id}{i}")
                self._logger.debug(
                    f" SAS macro '{sas_cond_field_sel_prefix_id}{i}' Type: {type(condition_field)}, Value: {condition_field}")
                filter_cond["field"] = condition_field

                cond_isnum_sel = self._SAS.symget(f"{sas_cond_isnum_sel_prefix_id}{i}")
                self._logger.debug(
                    f" SAS macro '{sas_cond_isnum_sel_prefix_id}{i}' Type: {type(cond_isnum_sel)}, Value: {cond_isnum_sel}")
                filter_cond["isNum"] = (int(cond_isnum_sel) == 1)

                cond_filter_oper_sel = self._SAS.symget(f"{sas_cond_operator_sel_prefix_id}{i}")
                self._logger.debug(
                    f" SAS macro '{sas_cond_operator_sel_prefix_id}{i}' Type: {type(cond_filter_oper_sel)}, Value: {cond_filter_oper_sel}")
                if cond_filter_oper_sel not in ["eq", "neq", "lt", "lte", "gt", "gte", "btw"]:
                    raise ValueError(f"The filter condition operator must be one of: 'eq', 'neq', 'lt', 'lte', 'gt', "
                                     f"'gte','btw'")
                filter_cond["operator"] = cond_filter_oper_sel

                cond1_value_sel = self._SAS.symget(f"{sas_cond_value_sel_prefix_id}{i}Val1")
                self._logger.debug(
                    f" SAS macro '{sas_cond_value_sel_prefix_id}{i}Val1' Type: {type(cond1_value_sel)}, Value: {cond1_value_sel}")
                filter_cond["value1"] = int(cond1_value_sel) if filter_cond["isNum"] else cond1_value_sel

                if cond_filter_oper_sel == "btw":
                    cond2_value_sel = self._SAS.symget(f"{sas_cond_value_sel_prefix_id}{i}Val2")
                    self._logger.debug(
                        f" SAS macro '{sas_cond_value_sel_prefix_id}{i}Val2' Type: {type(cond2_value_sel)}, Value: {cond2_value_sel}")
                    filter_cond["value2"] = int(cond2_value_sel) if filter_cond["isNum"] else cond2_value_sel

                self._filter_conditions.append(filter_cond)

                if 1 < i <= self._num_cond:
                    cond_chain_sel = self._SAS.symget(f"{sas_cond_chain_sel_prefix_id}{(i - 1)}")
                    self._logger.debug(
                        f" SAS macro '{sas_cond_chain_sel_prefix_id}{i - 1}' Type: {type(cond_chain_sel)}, Value: {cond_chain_sel}")
                    if cond_chain_sel not in ["Or", "And"]:
                        raise ValueError(
                            f"The filter condition chain must be one of: 'or', 'and'")
                    self._filter_chain_opp.append(cond_chain_sel)
        else:
            self._num_cond = None

    class Condition(metaclass=ABCMeta):
        def __init__(self, key, value_1):
            """
            :param key:
            :param value_1:
            """
            self._key = key
            self._value_1 = value_1
            self._type_1 = type(value_1)

        @abstractmethod
        def genExpression(self, **kwargs):
            """
            Abstract definition for getting the operation tuple
            Returns
            -------
            :return: condition : Tuple
            """
            pass

    class BinaryCondition(Condition, metaclass=ABCMeta):
        def __init__(self, key, value_1, value_2):
            """
            :param key:
            :param value_1:
            :param value_2:
            """
            super().__init__(key, value_1)
            self._value_2 = value_2
            self._type_2 = type(value_2)

        @abstractmethod
        def genExpression(self, **kwargs):
            """
            Abstract definition for getting the operation tuple
            Returns
            -------
            :return: condition : Tuple
            """
            pass

    class Eq(Condition, metaclass=ABCMeta):
        def genExpression(self, **kwargs):
            """
            Definition for getting the operation tuple for the EQ operator
            Returns
            -------
            :return: condition : Tuple
            """
            return ds.field(self._key) == self._value_1

    class Neq(Condition, metaclass=ABCMeta):
        def genExpression(self, **kwargs):
            """
            Definition for getting the operation tuple for the NEQ operator
            Returns
            -------
            :return: condition : Tuple
            """
            return (ds.field(self._key) != self._value_1)

    class Lt(Condition, metaclass=ABCMeta):
        def __init__(self, key, value_1, equals=False):
            super().__init__(key, value_1)
            self._equals = equals

        def genExpression(self, **kwargs):
            """
            Abstract definition for getting the operation tuple
            Returns
            -------
            :return: condition : Tuple
            """
            if self._equals:
                return (ds.field(self._key) <= self._value_1)
            else:
                return (ds.field(self._key) < self._value_1)

    class Gt(Condition, metaclass=ABCMeta):
        def __init__(self, key, value_1, equals=False):
            super().__init__(key, value_1)
            self._equals = equals

        def genExpression(self, **kwargs):
            """
            Definition for getting the operation tuple for the GT operator
            Returns
            -------
            :return: condition : Tuple
            """
            if self._equals:
                return (ds.field(self._key) >= self._value_1)
            else:
                return (ds.field(self._key) > self._value_1)

    class Btw(BinaryCondition, metaclass=ABCMeta):
        def genExpression(self, **kwargs):
            """
            Definition for getting the operation tuple for the BTW operator
            Returns
            -------
            :return: condition : Tuple
            """
            return ((ds.field(self._key) >= self._value_1) & (ds.field(self._key) <= self._value_2))

    class DeltaTable:
        """
        Taken from https://github.com/jeppe742/DeltaLakeReader under the Apache Licence.

        Access Delta tables on different filesystems.
        Parameters
        -----------
        path:  string
            Path to the table in the file system.
            Note that for Azure, AWS and GCP you need to include the container/bucket name in the path
        file_system: FSSpec compliant filesystem
            Filesystem to be used for reading the Delta files.
        """

        def __init__(self, path, file_system=None):
            if not isinstance(file_system, AbstractFileSystem) and file_system is not None:
                raise TypeError("file_system must be a fsspec compliant filesystem")

            self.path = path
            self.log_path = f"{self.path}/_delta_log"
            self.version = 0
            self.checkpoint = 0
            self.files = set()
            if file_system is None:
                file_system = LocalFileSystem()
            self.filesystem = file_system

            if not self._is_delta_table():
                raise ValueError(
                    f"""Could not find transaction logs in path {self.log_path}.
                    Make sure you point to the root of a delta table"""
                )
            self._as_newest_version()

            # The PyArrow Dataset is exposed by a factory class,
            # which makes it hard to inherit from it directly.
            # Instead we will just have the dataset as an attribute and expose the important methods.
            self.pyarrow_dataset = self._pyarrow_dataset()

        def _pyarrow_dataset(self):
            return pyarrow_dataset(
                source=list(self.files),
                filesystem=self.filesystem,
                partitioning="hive",
                format="parquet",
                schema=self.schema,
            )

        def _is_delta_table(self):
            return self.filesystem.exists(f"{self.log_path}")

        def _reset_state(self):
            self.files = set()

        def _apply_from_checkpoint(self, checkpoint_version: int):

            # reset file set, and checkpoint version
            self._reset_state()
            self.checkpoint = checkpoint_version

            if self.checkpoint == 0:
                return

            # read latest checkpoint. It might be a multi-part checkpoint for very large checkpoints
            checkpoint_files = self.filesystem.glob(
                f"{self.log_path}/{self.checkpoint:020}.checkpoint*.parquet"
            )
            for checkpoint_path in checkpoint_files:
                with self.filesystem.open(checkpoint_path) as checkpoint_file:
                    checkpoint = pq.read_table(checkpoint_file).to_pandas()

                    for _, row in checkpoint.iterrows():
                        if row["metaData"]:
                            schema_string = row["metaData"]["schemaString"]
                            self.schema = self._schema_from_string(schema_string)
                        elif row["add"]:
                            added_file = f"{self.path}/{row['add']['path']}"
                            if added_file:
                                self.files.add(added_file)

        def _apply_partial_logs(self, version: int):
            # Checkpoints are created every 10 transactions,
            # so we need to find all log files with version
            # up to 9 higher than checkpoint.
            # Effectively, this means that we can just create a
            # wild card for the first decimal of the checkpoint version

            log_files = self.filesystem.glob(
                f"{self.log_path}/{self.checkpoint // 10:019}*.json"
            )
            # sort the log files, so we are sure we get the correct order
            log_files = sorted(log_files)
            for log_file in log_files:

                # Get version from log name
                log_version = re.findall(r"(\d{20})", log_file)[0]
                self.version = int(log_version)

                # Download log file
                with self.filesystem.open(log_file) as log:
                    for line in log:
                        meta_data = json.loads(line)

                        # Log contains other stuff, but we are only
                        # interested in the add or remove entries
                        if "add" in meta_data.keys():
                            file = f"{self.path}/{meta_data['add']['path']}"
                            self.files.add(file)

                        elif "remove" in meta_data.keys():
                            remove_file = f"{self.path}/{meta_data['remove']['path']}"
                            # To handle 0 checkpoints, we might read the log file with
                            # same version as checkpoint. this means that we try to
                            # remove a file that belongs to an ealier version,
                            # which we don't have in the list
                            if remove_file in self.files:
                                self.files.remove(remove_file)
                        elif "metaData" in meta_data.keys():
                            schema_string = meta_data["metaData"]["schemaString"]
                            self.schema = self._schema_from_string(schema_string)
                    # Stop if we have reatched the desired version
                    if self.version == version:
                        break

        def _as_newest_version(self):
            # Try to get the latest checkpoint info
            try:
                # get latest checkpoint version
                with self.filesystem.open(f"{self.log_path}/_last_checkpoint") as lst_check:
                    checkpoint_info = lst_check.read()
                checkpoint_info = json.loads(checkpoint_info)
                self._apply_from_checkpoint(checkpoint_info["version"])

            except FileNotFoundError:
                pass

            # apply remaining versions. This can be a maximum of 9 versions.
            # we will just break when we don't find any newer logs
            self._apply_partial_logs(version=self.checkpoint + 9)

        def to_table(self, *args, **kwargs):
            """
            Convert to a pyarrow Table.
            Is based on the `to_pandas` function from `pyarrow.Table.to_pandas`,
            so any this will accept the same arguments.
            For more information see https://arrow.apache.org/docs/python/generated/pyarrow.dataset.FileSystemDataset.html#pyarrow.dataset.FileSystemDataset.to_table
            """  # noqa E501
            return self.pyarrow_dataset.to_table(*args, **kwargs)

        def to_pandas(self, *args, **kwargs):
            """
            Convert to a pandas dataframe.
            Is based on the `to_pandas` function from `pyarrow.Table.to_pandas`,
            so any this will accept the same arguments.
            For more information see https://arrow.apache.org/docs/python/generated/pyarrow.Table.html?highlight=to_pandas#pyarrow.Table.to_pandas
            """  # noqa E501
            return self.to_table().to_pandas(*args, **kwargs)

        def as_version(self, version: int, inplace=True):
            """
            Find the files for a specific version of the table.
            Parameters:
            ----------
            version: int
                The table version number that should be loaded
            inplace: Bool
                Specify wether the object should be modified inplace or not.
                If `True`, the current object will be modified.
                if `False`, a new instance of the `DeltaTable` will be returned with the given version.
            Returns:
            -------
            dr : (DeltaTable)
                Delta table that has parsed the log files for the specific version
            """
            nearest_checkpoint = version // 10 * 10
            if inplace:
                self._apply_from_checkpoint(nearest_checkpoint)
                self._apply_partial_logs(version=version)
                self.pyarrow_dataset = self._pyarrow_dataset()
                return self

            deltaTable = deepcopy(self)
            deltaTable._apply_from_checkpoint(nearest_checkpoint)
            deltaTable._apply_partial_logs(version=version)
            deltaTable.pyarrow_dataset = deltaTable._pyarrow_dataset()

            return deltaTable

        def _schema_from_string(self, schema_string: str):

            fields = []
            schema = json.loads(schema_string)
            for field in schema["fields"]:
                name = field["name"]
                type = field["type"]
                nullable = field["nullable"]
                metadata = field["metadata"]
                pa_type = self._map_type(type)

                fields.append(pa.field(name, pa_type, nullable=nullable, metadata=metadata))
            return pa.schema(fields)

        def _map_type(self, input_type: Union[dict, str]):

            simple_type_mapping = {
                "byte": pa.int8(),
                "short": pa.int16(),
                "integer": pa.int32(),
                "long": pa.int64(),
                "float": pa.float32(),
                "double": pa.float64(),
                "string": pa.string(),
                "boolean": pa.bool_(),
                "binary": pa.binary(),
                "date": pa.date32(),
                "timestamp": pa.timestamp("ns"),
            }

            # If type is string, it should be a "simple" datatype
            if isinstance(input_type, str):

                # map simple data types, that can be directly converted
                if input_type in simple_type_mapping:
                    pa_type = simple_type_mapping[input_type]
                else:
                    # check for decimal types
                    match = re.findall(r"decimal\(([0-9]*),([0-9]*)\)", input_type)
                    if len(match) > 0:
                        pa_type = pa.decimal128(int(match[0][0]), int(match[0][1]))
                    else:
                        raise TypeError(
                            f"Got type unsupported {input_type} when trying to parse schema"
                        )

            # nested field needs special handling
            else:
                if input_type["type"] == "array":
                    # map list type to pyarrow types
                    element_type = self._map_type(input_type["elementType"])
                    # pass a field as the type to the list with a name of "element".
                    # This is just to comply with the way pyarrow creates lists when infering schemas
                    pa_field = pa.field("element", element_type)
                    pa_type = pa.list_(pa_field)

                elif input_type["type"] == "map":
                    key_type = self._map_type(input_type["keyType"])
                    item_type = self._map_type(input_type["valueType"])
                    pa_type = pa.map_(key_type, item_type)

                elif input_type["type"] == "struct":
                    fields = []
                    for field in input_type["fields"]:
                        name = field["name"]
                        input_type = field["type"]
                        nullable = field["nullable"]
                        metadata = field["metadata"]
                        field_type = self._map_type(input_type)

                        fields.append(
                            pa.field(name, field_type, nullable=nullable, metadata=metadata)
                        )
                    pa_type = pa.struct(fields)

                else:
                    raise TypeError(
                        f"Got type unsupported {input_type} when trying to parse schema"
                    )

            return pa_type

    def __instance_condition(self, condition_name, key, value_1, value_2) -> Condition:
        """
        :param condition_name: Literal value representing the condition to be instanciated
        :param key: Name of the field
        :param value_1: Value of the field1
        :param value_2: Value od the field2 only valid for the btw condition
        :return:
        """

        if condition_name == "eq":
            condition = self.Eq(key, value_1)
        elif condition_name == "neq":
            condition = self.Neq(key, value_1)
        elif condition_name == "lt":
            condition = self.Lt(key, value_1, equals=False)
        elif condition_name == "lte":
            condition = self.Lt(key, value_1, equals=True)
        elif condition_name == "gt":
            condition = self.Gt(key, value_1, equals=False)
        elif condition_name == "gte":
            condition = self.Gt(key, value_1, equals=True)
        elif condition_name == "btw":
            condition = self.Btw(key, value_1, value_2)
        else:
            raise ValueError("type should be one of: ['eq', 'neq', 'lt', 'lte', 'gt', 'gte', 'btw'].")

        return condition

    def __generate_conditions(self, iterative=False):
        """
        :param iterative: Boolean value to use a more generic or predefined implemetation for chaining the filter conditions
        :return:
        """
        conditions = []
        """
        Iterates over the _filter_conditions property and generate a condition object array 
        """
        for i in range(0, self._num_cond):
            filter_condition = self._filter_conditions[i]
            conditions.append(
                self.__instance_condition(
                    condition_name=filter_condition["operator"],
                    key=filter_condition["field"],
                    value_1=filter_condition["value1"],
                    value_2=filter_condition["value2"] if filter_condition["operator"] == 'btw' else None
                )
            )

        if iterative:
            return self.__chain_conditions_iter(conditions)
        else:
            return self.__chain_conditions(conditions)

    def __chain_conditions_iter(self, conditions):
        # """
        # Generic implementation for generating the chaining the filter conditions and generating the pyarrow filter expression
        # @TODO still a work in progress
        #
        # :param conditions: List of filter expressions
        # :param conditionChainsOp: List of chain operators
        # :param logger: python logger
        # :return: Array representing the final filtering expression (Pyarrow filter predicate must be expressed in DNF)
        # """
        #
        # def genSingleCond(condition):
        #     return condition.genExpression()
        #
        # def genDualCond(condition1, condition2, operator):
        #     if operator == "Or":
        #         return (
        #                 condition1.genExpression() |
        #                 condition2.genExpression()
        #         )
        #     elif operator == "And":
        #         return (
        #                 condition1.genExpression() &
        #                 condition2.genExpression()
        #         )
        #     else:
        #         raise ValueError("Conditions Chains Operations can only be one of: ['Or', 'And']")
        #
        # result = None
        # extractFirst = False
        #
        # while len(conditions) > 0:
        #     if len(conditions) == 1:
        #         if result is None:
        #             result = genSingleCond(conditions[0])
        #         else:
        #             if self._filter_chain_opp[0] == "Or":
        #                 result = result | conditions[0].genExpression()
        #             elif conditionChainsOp[0] == "And":
        #                 result = result & conditions[0].genExpression()
        #     elif extractFirst == False:
        #         result = genSingleCond(conditions[0])
        #         extractFirst = True
        #     else:
        #         if self._filter_chain_opp[0] == "Or":
        #             result = result | conditions[0].genExpression()
        #         elif self._filter_chain_opp[0] == "And":
        #             result = result & conditions[0].genExpression()
        #         conditionChainsOp = self._filter_chain_opp[1:]
        #
        #     conditions = conditions[1:]
        # return result
        pass

    def __chain_conditions(self, conditions):
        """
        Fixed implementation for generating the chaining up to 3 filter conditions and generating the pyarrow filter expression

        :param conditions: List of filter expressions
        :param conditionChainsOp: List of chain operators
        :param logger: python logger
        :return: Array representing the final filtering expression (Pyarrow filter predicate must be expressed in DNF)
        """
        if len(conditions) == 1:
            result = conditions[0].genExpression()
        elif len(conditions) == 2:
            if self._filter_chain_opp[0] == "Or":
                result = (
                        (conditions[0].genExpression()) |
                        (conditions[1].genExpression())
                )
            elif self._filter_chain_opp[0] == "And":
                result = (
                        (conditions[0].genExpression()) &
                        (conditions[1].genExpression())
                )
            else:
                raise ValueError("Conditions Chains Operations can only be one of: ['Or', 'And']")
        elif len(conditions) == 3:
            if self._filter_chain_opp[0] == "Or" and self._filter_chain_opp[1] == "Or":
                result = (
                        (conditions[0].genExpression()) |
                        (conditions[1].genExpression()) |
                        (conditions[2].genExpression())
                )
            elif self._filter_chain_opp[0] == "And" and self._filter_chain_opp[1] == "And":
                result = (
                        (conditions[0].genExpression()) &
                        (conditions[1].genExpression()) &
                        (conditions[2].genExpression())
                )
            elif self._filter_chain_opp[0] == "Or" and self._filter_chain_opp[1] == "And":
                result = (
                        (conditions[0].genExpression()) |
                        (conditions[1].genExpression()) &
                        (conditions[2].genExpression())
                )
            elif self._filter_chain_opp[0] == "And" and self._filter_chain_opp[1] == "Or":
                result = ((conditions[0].genExpression()) & (conditions[1].genExpression()) | (
                    conditions[2].genExpression()))
            else:
                raise ValueError("Conditions Chains Operations can only be one of: ['Or', 'And']")

        self._logger.debug(f" Python var 'chain_conditions_result': {str(result)}")
        return result

    def read(self, path):
        if path is None or path == "":
            raise "The path argument can not be empty"

        root_path = path[:-1] if path.endswith("/") else path

        self._filesystem = AzureBlobFileSystem(
            account_name=self._account_name,
            tenant_id=self._tenant_id,
            client_id=self._client_id,
            client_secret=self._client_secret
        )

        if self._format == "parquet":
            if self._apply_filters:
                return pd.read_parquet(
                    path=f"{self._container}/{root_path}",
                    filesystem=self._filesystem,
                    partitioning='hive',
                    filters=self.__generate_conditions()
                )
            else:
                return pd.read_parquet(
                    path=f"{self._container}/{root_path}",
                    filesystem=self._filesystem
                )
        elif self._format == "deltalake":
            if self._apply_filters:
                return self.DeltaTable(
                    path=f"{self._container}/{root_path}",
                    file_system=self._filesystem
                ).to_table(filter=self.__generate_conditions())\
                    .to_pandas()
            else:
                return self.DeltaTable(
                    path=f"{self._container}/{root_path}",
                    file_system=self._filesystem
                ).to_pandas()
# -------------  END Utilities --------------------------------------------------------------------------



# -------------  INI CustomStep Logic --------------------------------------------------------------------
logging.basicConfig(level=logging.ERROR)

# create logger
logger = logging.getLogger('sas.customsteps.adlsFileReader')
logger.setLevel(logging.INFO)

tenant_id = SAS.symget('intextTenantId')
client_id = SAS.symget('intextClientid')
client_secret = SAS.symget('intextClientSec')
storage_account_name = SAS.symget('intextStorageAccount')
container_name = SAS.symget('intextContainer')
intextFilePath = SAS.symget('intextFilePath')
chkApplyFilters = SAS.symget('chkApplyFilters')


logger.info(f" SAS macro 'intextTenantId' Type: {type(tenant_id)}, Value: {tenant_id}")
logger.info(f" SAS macro 'intextClientid' Type: {type(client_id)}, Value: {client_id}")
logger.info(f" SAS macro 'intextClientSec' Type: {type(client_secret)}, Value: {client_secret}")
logger.info(f" SAS macro 'intextStorageAccount' Type: {type(storage_account_name)}, Value: {storage_account_name}")
logger.info(f" SAS macro 'intextContainer' Type: {type(container_name)}, Value: {container_name}")
logger.info(f" SAS macro 'intextFilePath' Type: {type(intextFilePath)}, Value: {intextFilePath}")
logger.info(f" SAS macro 'chkApplyFilters' Type: {type(chkApplyFilters)}, Value: {chkApplyFilters}")

applyFilters = (int(chkApplyFilters) == 1)
logger.info(" Python var 'applyFilters' Type: %s, Value: %s" % (type(applyFilters), applyFilters))

df = ADLSFilerReader(
    SAS=SAS,
    tenant_id=tenant_id,
    client_id=client_id,
    client_secret=client_secret,
    account_name=storage_account_name,
    container=container_name,
    sas_format_selector_id='dpdownFormat',
    apply_filters=applyFilters,
    sas_num_cond_selector_id='dpdownFilterCondNum',
    sas_cond_field_sel_prefix_id='intextPartFieldCond',
    sas_cond_isnum_sel_prefix_id='chkIsNumCond',
    sas_cond_operator_sel_prefix_id='dpdownOperatorsCond',
    sas_cond_value_sel_prefix_id='intextCond',
    sas_cond_chain_sel_prefix_id='dpdownOp'
).read(path=intextFilePath)

SAS.df2sd(df, SAS.symget('outtblid_dest'))
# -------------  END CustomStep Logic --------------------------------------------------------------------

endsubmit;
quit;


