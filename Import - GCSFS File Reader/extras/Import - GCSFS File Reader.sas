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
import pandas as pd
import pyarrow as pa
import pyarrow.dataset as ds
import pyarrow.parquet as pq
from cloud_arrow.core import ConditionFactory
from cloud_arrow.gcsfs import GCSFSObjectStorage
from saspy import SASsession

# -------------  INI Utilities --------------------------------------------------------------------------
class GCSFSFileReader(metaclass=ABCMeta):
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
                 apply_filters: bool,
                 sas_num_cond_selector_id: str,
                 sas_cond_field_sel_prefix_id: str,
                 sas_cond_isnum_sel_prefix_id: str,
                 sas_cond_operator_sel_prefix_id: str,
                 sas_cond_value_sel_prefix_id: str,
                 sas_cond_chain_sel_prefix_id: str):
        """

        :param SAS:
        :param project:
        :param access:
        :param token:
        :param bucket:
        :param default_location:
        :param sas_format_selector_id:
        :param apply_filters:
        :param sas_num_cond_selector_id:
        :param sas_cond_field_sel_prefix_id:
        :param sas_cond_isnum_sel_prefix_id:
        :param sas_cond_operator_sel_prefix_id:
        :param sas_cond_value_sel_prefix_id:
        :param sas_cond_chain_sel_prefix_id:
        """

        self._logger = logging.getLogger('sas.customSteps.GCSFSFileReader')

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

        self._apply_filters = apply_filters

        if self._apply_filters:
            num_cond_sel = self._SAS.symget(f"{sas_num_cond_selector_id}")
            self._logger.debug(
                f" SAS macro '{sas_num_cond_selector_id}' Type: {type(num_cond_sel)}, Value: {num_cond_sel}")

            if num_cond_sel not in ["1", "2", "3"]:
                raise ValueError(f"The number of partitions must be between 1 and 3")

            self._num_cond = int(num_cond_sel)
            self._filter_exp = self.generate_filter_exp(
                sas_cond_field_sel_prefix_id,
                sas_cond_isnum_sel_prefix_id,
                sas_cond_operator_sel_prefix_id,
                sas_cond_value_sel_prefix_id,
                sas_cond_chain_sel_prefix_id
            )
        else:
            self._num_cond = None


    def generate_filter_exp(self,
                            sas_cond_field_sel_prefix_id,
                            sas_cond_isnum_sel_prefix_id,
                            sas_cond_operator_sel_prefix_id,
                            sas_cond_value_sel_prefix_id,
                            sas_cond_chain_sel_prefix_id):
        """
        Generates the filter_expression
        The _filter_conditions property is a json object describing the filter condition with the following structure:
        {
            field: str      -> "holds the value of the 'intextPartFieldCond{i}' field",
            isNum: bool     -> "holds the value of the 'chkIsNumCond{i}' field",
            operator: str   -> "holds the value of the 'dpdownOperatorsCond{i}' field",
            value1: str/int -> "holds the value of the 'intextCond1Val{i}' field",
            value2: str/int -> "holds the value of the 'intextCond2Val1{i}' field",
        }
        """
        filter_conditions = []
        filter_chain_opp = []
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

            filter_conditions.append(
                ConditionFactory.get_condition(
                    condition_name=filter_cond["operator"],
                    key=filter_cond["field"],
                    value_1=filter_cond["value1"],
                    value_2=filter_cond["value2"] if filter_cond["operator"] == 'btw' else None
                )
            )

            if 1 < i <= self._num_cond:
                cond_chain_sel = self._SAS.symget(f"{sas_cond_chain_sel_prefix_id}{(i - 1)}")
                self._logger.debug(
                    f" SAS macro '{sas_cond_chain_sel_prefix_id}{i - 1}' Type: {type(cond_chain_sel)}, Value: {cond_chain_sel}")
                if cond_chain_sel not in ["Or", "And"]:
                    raise ValueError(
                        f"The filter condition chain must be one of: 'or', 'and'")
                filter_chain_opp.append(cond_chain_sel)

        """
        Fixed implementation for generating the chaining up to 3 filter conditions and generating the pyarrow filter
        expressionresult = {Expression} (Pregnancies == 0)
        """
        filter_exp = None
        if len(filter_conditions) == 1:
            filter_exp = filter_conditions[0].gen_expression()
        elif len(filter_conditions) == 2:
            if filter_chain_opp[0] == "Or":
                filter_exp = (
                        (filter_conditions[0].gen_expression()) |
                        (filter_conditions[1].gen_expression())
                )
            elif filter_chain_opp[0] == "And":
                filter_exp = (
                        (filter_conditions[0].gen_expression()) &
                        (filter_conditions[1].gen_expression())
                )
            else:
                raise ValueError("Conditions Chains Operations can only be one of: ['Or', 'And']")
        elif len(filter_conditions) == 3:
            if filter_chain_opp[0] == "Or" and filter_chain_opp[1] == "Or":
                filter_exp = (
                        (filter_conditions[0].gen_expression()) |
                        (filter_conditions[1].gen_expression()) |
                        (filter_conditions[2].gen_expression())
                )
            elif filter_chain_opp[0] == "And" and filter_chain_opp[1] == "And":
                filter_exp = (
                        (filter_conditions[0].gen_expression()) &
                        (filter_conditions[1].gen_expression()) &
                        (filter_conditions[2].gen_expression())
                )
            elif filter_chain_opp[0] == "Or" and filter_chain_opp[1] == "And":
                filter_exp = (
                        (filter_conditions[0].gen_expression()) |
                        (filter_conditions[1].gen_expression()) &
                        (filter_conditions[2].gen_expression())
                )
            elif filter_chain_opp[0] == "And" and filter_chain_opp[1] == "Or":
                filter_exp = (
                            (filter_conditions[0].gen_expression()) & (filter_conditions[1].gen_expression()) | (
                        filter_conditions[2].gen_expression()))
            else:
                raise ValueError("Conditions Chains Operations can only be one of: ['Or', 'And']")

            self._logger.debug(f" Python var 'chain_conditions_result': {str(filter_exp)}")

        return filter_exp

    def get_filters(self):
        return self._filter_exp if self._apply_filters else None

    def read(self, path):
        reader = GCSFSObjectStorage(
            project=self._project,
            access=self._access,
            token=self._token,
            bucket=self._bucket,
            default_location=self._default_location
        )

        return reader.read_to_pandas(self._format, path, filters=self.get_filters())

# -------------  END Utilities --------------------------------------------------------------------------


# -------------  INI CustomStep Logic --------------------------------------------------------------------
logging.basicConfig(level=logging.ERROR)

# create logger
logger = logging.getLogger('sas.customsteps.gcsfsFileReader')
logger.setLevel(logging.DEBUG)

credentials_file = SAS.symget('infileCredentialsFile')
project = SAS.symget('intextProject')
bucket = SAS.symget('intextBucket')
file_path = SAS.symget('intextFilePath')
chk_apply_filters = SAS.symget('chkApplyFilters')

logger.info(f" SAS macro 'infileCredentialsFile' Type: {type(credentials_file)}, Value: {credentials_file}")
logger.info(f" SAS macro 'intextProject' Type: {type(project)}, Value: {project}")
logger.info(f" SAS macro 'intextBucket' Type: {type(bucket)}, Value: {bucket}")
logger.info(f" SAS macro 'intextFilePath' Type: {type(file_path)}, Value: {file_path}")
logger.info(f" SAS macro 'chkApplyFilters' Type: {type(chk_apply_filters)}, Value: {chk_apply_filters}")

is_parted = (int(chk_apply_filters) == 1)
logger.info(" Python var 'applyFilters' Type: %s, Value: %s" % (type(chk_apply_filters), chk_apply_filters))


df = GCSFSFileReader(
    SAS=SAS,
    token=credentials_file,
    project=project,
    bucket=bucket,
    access="read_only",
    default_location="",
    sas_format_selector_id='dpdownFormat',
    apply_filters=is_parted,
    sas_num_cond_selector_id='dpdownFilterCondNum',
    sas_cond_field_sel_prefix_id='intextPartFieldCond',
    sas_cond_isnum_sel_prefix_id='chkIsNumCond',
    sas_cond_operator_sel_prefix_id='dpdownOperatorsCond',
    sas_cond_value_sel_prefix_id='intextCond',
    sas_cond_chain_sel_prefix_id=''
).read(path=file_path)

SAS.df2sd(df, SAS.symget('outtblid_dest'))
# -------------  END CustomStep Logic --------------------------------------------------------------------

endsubmit;
quit;