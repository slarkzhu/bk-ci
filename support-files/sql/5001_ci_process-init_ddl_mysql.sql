SET NAMES utf8mb4;
USE devops_ci_process;

-- 空白流水线模板
INSERT IGNORE INTO `T_TEMPLATE` (`VERSION`, `ID`, `TEMPLATE_NAME`, `PROJECT_ID`, `VERSION_NAME`, `CREATOR`, `CREATED_TIME`, `TEMPLATE`, `TYPE`, `CATEGORY`, `LOGO_URL`, `SRC_TEMPLATE_ID`, `STORE_FLAG`, `WEIGHT`) VALUES
  (1, '072d516d300b4812a4f652f585eacc36', 'Blank', '', 'init', '', '2019-05-23 16:24:02', '{\n  \"name\" : \"Blank\",\n  \"desc\" : \"\",\n  \"stages\" : [ {\n    \"containers\" : [ {\n      \"@type\" : \"trigger\",\n      \"name\" : \"Trigger\",\n      \"elements\" : [ {\n        \"@type\" : \"manualTrigger\",\n        \"name\" : \"Manual\",\n        \"id\" : \"T-1-1-1\",\n        \"properties\" : [ ]\n      } ]\n    } ],\n    \"id\" : \"stage-1\"\n  }]\n}', 'PUBLIC', '', NULL, NULL, 0, 100);

-- Stage预置标签
REPLACE INTO `T_PIPELINE_STAGE_TAG` (`ID`, `STAGE_TAG_NAME`, `WEIGHT`, `CREATOR`, `MODIFIER`, `CREATE_TIME`, `UPDATE_TIME`) VALUES
	('28ee946a59f64949a74f3dee40a1bda4','Build',99,'system','system','2020-03-03 18:07:12','2020-03-19 16:29:38'),
	('53b4d3f38e3e425cb1aaa97aa1b37857','Deploy',0,'system','system','2020-03-19 18:00:04','2020-03-19 18:00:04'),
	('d0a06f6986fa4670af65ccad7bb49d3a','Test',50,'system','system','2020-03-19 16:29:45','2020-03-19 16:29:45');

-- 配置流水线规则
REPLACE INTO `T_PIPELINE_RULE`(`ID`, `RULE_NAME`, `BUS_CODE`, `PROCESSOR`) VALUES ('0042ea36599a4adf8c26cf23f5edca45', 'MINUTE', 'BUILD_NUM', 'DefaultCalendarProcessor');
REPLACE INTO `T_PIPELINE_RULE`(`ID`, `RULE_NAME`, `BUS_CODE`, `PROCESSOR`) VALUES ('110575a0246f491aa297c9bd2452c34b', 'DAY_OF_YEAR', 'BUILD_NUM', 'DefaultCalendarProcessor');
REPLACE INTO `T_PIPELINE_RULE`(`ID`, `RULE_NAME`, `BUS_CODE`, `PROCESSOR`) VALUES ('20d66e6e9eb04df7ac029cbacddda8ef', 'MONTH_OF_YEAR', 'BUILD_NUM', 'BkCalendarProcessor');
REPLACE INTO `T_PIPELINE_RULE`(`ID`, `RULE_NAME`, `BUS_CODE`, `PROCESSOR`) VALUES ('4f78736b80d449c192cc96bfb9de9dbe', 'DATE:\"(.+?)\"', 'BUILD_NUM', 'BkCalendarProcessor');
REPLACE INTO `T_PIPELINE_RULE`(`ID`, `RULE_NAME`, `BUS_CODE`, `PROCESSOR`) VALUES ('69209588979d4c08b971a653708e0ce1', 'HOUR_OF_DAY', 'BUILD_NUM', 'DefaultCalendarProcessor');
REPLACE INTO `T_PIPELINE_RULE`(`ID`, `RULE_NAME`, `BUS_CODE`, `PROCESSOR`) VALUES ('8bd2fe3620ec408b8310ed20d37b0ac5', 'YEAR', 'BUILD_NUM', 'DefaultCalendarProcessor');
REPLACE INTO `T_PIPELINE_RULE`(`ID`, `RULE_NAME`, `BUS_CODE`, `PROCESSOR`) VALUES ('bb0d1167f20d4d3dbd131ef55fe8304c', 'SECOND', 'BUILD_NUM', 'DefaultCalendarProcessor');
REPLACE INTO `T_PIPELINE_RULE`(`ID`, `RULE_NAME`, `BUS_CODE`, `PROCESSOR`) VALUES ('c3b2b8a80b114b48bbe535bf075fdc1f', 'DAY_OF_MONTH', 'BUILD_NUM', 'DefaultCalendarProcessor');
REPLACE INTO `T_PIPELINE_RULE`(`ID`, `RULE_NAME`, `BUS_CODE`, `PROCESSOR`) VALUES ('faadf27e703b4ee08b98fd6e4958e2b4', 'BUILD_NO_OF_DAY', 'BUILD_NUM', 'BuildNoOfDayProcessor');	
	
